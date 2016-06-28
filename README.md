postgres-tests
==============

This testing framework is a modification of Greg Smith's 
[pgbench-tools](https://github.com/gregs1104/pgbench-tools) with some
additional JSON tooling assistance from EnterpriseDB's
[pg_nosql_benchmark](https://github.com/EnterpriseDB/pg_nosql_benchmark).
pgbench-tools automates running PostgreSQL's built-in 
[pgbench](https://www.postgresql.org/docs/9.5/static/pgbench.html) 
tool in useful ways. It will run some number of database sizes (the database
scale) and various concurrent client count combinations.
Scale/client runs with some common characteristic--perhaps one
configuration of the postgresql.conf--can be organized into a "set"
of runs. The program graphs transaction rate during each test,
latency, and comparisons between test sets.

Here, pgbench-tools has been modified in two important ways. First, the
built-in pgbench tables and data are not used. Instead, these tests target a 
single table (of configurable size) populated with 
[jsonb](https://www.postgresql.org/docs/current/static/datatype-json.html) 
JSON data. Second, an additional test "layer" has been added that enables
a single test run to include multiple custom scripts each having their own
configurations.

By default, data is stored as `jsonb` in a single column and the benchmark 
tests are run under three scenarios:

1. *plain*: No indexes are created.

2. *gin*: The default `json_ops` generalized inverted index 
   ([GIN](https://www.postgresql.org/docs/current/static/datatype-json.html#JSON-INDEXING))
   is created on the `jsonb` data column.

3. *jpo*: The `json_path_ops` GIN is created on the `jsonb` data column.

If you wish to modify these tests, please be sure to refer to the official
pgbench documentation for information about configuration settings, script
commands, and more:

https://www.postgresql.org/docs/9.5/static/pgbench.html


Requirements
============

* At least one running PostgreSQL 9.5+ server
* gnuplot


Setup Configurations
====================

These tests can either be executed locally or within one of two Docker
setups.


Running Tests Locally
---------------------

* Ensure you have at least one running instance of a PostgreSQL 9.5+ server

  The tests create two databases: one for the *tests* and another for *results*. 
  Both databases can be the same, but there may be more shared_buffers
  cache churn in that case. Some amount of cache disruption
  is unavoidable unless the result database is remote, because
  of the OS cache. The recommended and default configuration
  is to have a pgbench database and a results database. This also
  keeps the size of the result dataset from being included in the
  total database size figure recorded by the test.

* Create test script(s)

  A single test run comrpises one or more *scripts*. A script file may contain
  SQL queries and pgbench commands (see the 
  [pgbench docs](https://www.postgresql.org/docs/9.5/static/pgbench.html) 
  for more info). All commands in a script file will be executed as a single
  transaction. The custom JSON scripts are stored in `tests-json/`.
  Script-specific settings may be specified in a file of the same name as the
  script stored in `settings/`.

* Configure your tests

  Global (cross-script) test congifuration parameters are specified in `config`.
  Edit the `config` file to reference the test and results database, as
  well as list the tests you want to run.

* Run your tests

  `$ ./run-benchmarks`

* Test results

  Each script's results will be stored in its own directory in `results/`.
  Open `results/<my-script>/index.html` to view aggregate test results.
  Numbered directories in `results/<my-script>` contain fine grained results
  for each parameter combination.


Running Tests in Docker
-----------------------

* Follow the instructions in the previous subsection to create test script(s) 
  and configure the tests.

* Within this directory build the Docker image.

  `$ docker build -t pgbench-tools .`

* Use Docker Compose to create and run the necessary container(s). There are
  three container configurations that can be run with the compose files in
  `compose/`. (Be sure to edit the representative compose file to use the
  correct image.)

  1. **Local** 

     Test driver and tests will be deployed within a single container.

     `$ docker-compose -f compose/docker-compose-local.yml up -d`
  
  2. **Remote**

    Test driver and tests will be deployed on separate containers.

    `$ docker-compose -f compose/docker-compose-remote.yml up -d`
  
* Once the container(s) boot the tests will begin automaticaly.

* When the tests complete you will have to manually extract the test results.

  `$ docker cp <test-driver-container-id>:postgres-tests/results results/`

Results
=======

* You can check results even as the tests are running

  `$ ./report <CMD>`

  `<CMD>` may be one of the following reports (stored in `reports/`):
  `bufreport`, `bufstats`, `bufsummary`, `fastest`, `report`, `summary`,
  `tps-per-client`.

  These are unlikely to disrupt the test results very much unless you've
  run an enormous number of tests already.

* The `set-times` script will show how long past tests have taken to
  complete. This can be useful to get an idea how long the currently running
  test or test set will actually take to finish.

* Once the tests are done, each script's results will be stored in its own 
  subdirectory in `results/`.

  Open `results/<my-script>/index.html` to view aggregate test results.
  Numbered directories in `results/<my-script>` contain fine grained results
  for each parameter combination.


Version compatibility
=====================

The default configuration aims to support the pgbench that ships with
PostgreSQL 9.5 and later versions.

Support for PostgreSQL versions 9.3 and 9.4 is possible if the `update` script
is not executed--that script uses the `jsonb_set` command, which was introduced
in 9.5.

Support for earlier versions of PostgreSQL is not possible since they do not
include sufficient JSON support. Specifically, the `jsonb` data type and its
operators were not introduced until 9.3.


Multiple worker support
-----------------------

Starting in PostgreSQL 9.0, pgbench allows splitting up the work pgbench
does into multiple worker threads or processes (which depends on whether
the database client libraries haves been compiled with thread-safe 
behavior or not).

This feature is extremely valuable, as it's likely to give at least
a 15% speedup on common hardware. And it can more than double throughput
on operating systems that are particularly hostile to running the
pgbench client. One known source of this problem is Linux kernels
using the Completely Fair Scheduler introduced in 2.6.23,
which does not schedule the pgbench program very well when it's connecting
to the database using the default method, Unix-domain sockets.

(Note that pgbench-tools doesn't suffer greatly from this problem itself, as
it connects over TCP/IP using the `-H` parameter. Manual pgbench runs that
do not specify a host, and therefore connect via a local socket can be
extremely slow on recent Linux kernels.)

Taking advantage of this feature is done in pgbench-tools by increasing the
`MAX_WORKERS` setting in the configuration file. It takes the value of `nproc`
by default, or where that isn't available (typically on systems without a
recent version of GNU coreutils), the default can be set to blank, which avoids
using this feature altogether -- thereby remaining compatible not only with
systems lacking the nproc program, but also with PostgreSQL/pgbench versions
before this capability was added.

When using multiple workers, each must be allocated an equal number of
clients. That means that client counts that are not a multiple of the
worker count will result in pgbench not running at all.

Accordingly, if you set `MAX_WORKERS` to a number to enable this capability,
pgbench-tools picks the maximum integer of that value or lower that the client
count is evenly divisible by. For example, if `MAX_WORKERS` is 4, running with 8
clients will use 4 workers, while 9 clients will shift downward to 3 workers as
the best option.

A reasonable setting for `MAX_WORKERS` is the number of physical cores
on the server, typically giving best performance. And when using this feature,
it's better to tweak test client counts toward ones that are divisible by as
many factors as possible. For example, if you wanted approximately 15
clients, it would be best to use 16, allowing worker counts of 2, 4, or 8, 
all likely to match common core counts. Second choice would be 14,
compatible with 2 workers. Third is 15, which would allow 3 workers--not
improving upon a single worker on common dual-core systems. The worst
choices would be 13 or 17 clients, which are prime and therefore cannot
be usefully allocated more than one worker on common hardware.


Known issues
============

* On OS X, the `nproc` command is not available so `MAX_WORKERS` cannot be
  set automatically. 

* On Solaris, where the benchwarmer script calls tail it may need
  to use /usr/xpg4/bin/tail instead


Credits
=======

Copyright (c) 2007-2014, Gregory Smith
All rights reserved.
See COPYRIGHT file for full license details and HISTORY for a list of
other contributors to the program.