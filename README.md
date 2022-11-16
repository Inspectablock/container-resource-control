# Container Resource Control

A simple proof of concept demonstrating how one can use Docker control options to limit the resource utilization of low priority services contained in a docker container.

### Dependencies

* docker-compose (at least version 1.29)

### Execution

The shell script quick-start.sh will create all the necessary docker containers required for the test.

To run a test with dynamic threshold adjustments 

`./quick-start.sh  -d [DURATION OF TEST IN SECONDS] -o [OUTPUT FILE]`

To run a test without the dynamic threshold adjustments pass in the `-n` flag on the command line.

CPU utilization metrics will be saved into the OUTPUT FILE you specify.

### Test Parameters

Test parameters can be found in the docker-compose.yml file and can be adjusted to cater for your system specifications.

* JOBS: The number of transcoding jobs to run to run on the Portal container.
* CPUS: Number of cpus to stress using stress-ng.