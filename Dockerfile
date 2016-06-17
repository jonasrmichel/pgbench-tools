FROM postgres:9.5.3

RUN apt-get update \
  && apt-get install -y gnuplot \
  && apt-get install -y python-pip \
  && pip install python-dateutil

ADD . /pgbench-tools/

WORKDIR /pgbench-tools
CMD ["./run-benchmarks"]