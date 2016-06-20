#!/bin/bash

pushd ..

# run the postgres entrypoint script
./docker-entrypoint.sh postgres &

# allow enough time for initialization
sleep 10 

popd

# run the benchmark tests
./run-benchmarks