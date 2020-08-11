# NDT Load Test

## Pre-Requisites

* Access to at least one M-Lab sandbox node from which you will launch the
  load test.
* **IMPORTANT**: disable the TxController of the target ndt-server. If you do
  not do this, the load testing will not work. One easy way to do this is to
  manually edit the `ndt` DaemonSet in the mlab-sandbox cluster (`kubectl
  edit ds ndt`) and set `-txcontroller.max-rate=0`. This will affect all
  ndt-servers in the mlab-sandbox cluster, so don't forget to undo this
  change when you are done.

## Running tests

On the M-Lab sandbox node, run something like the following:

```
# docker run --rm --workdir=/root/bin --net=host --tty \
    measurementlab/node-loadtesting:v1.0.0 ./run.sh 50 250 10
```

run.sh accepts five arguments, the first three of which are required:

```
./run.sh <start> <stop> <step> <target> <period>
```

Option descriptions:

* _\<start\>_: The initial/starting number of concurrent NDT clients to launch
  against _server_.
* _\<stop\>_: The maximum number of concurrent tests to launch against _server_.
* _\<step\>_: Increments the number of concurrent tests against _\<server\>_ by
  this amount each _\<period\>_ from _\<start\>_ until _\<stop\>_ count is reached.
* _\<target\>_: The target server to run the tests against.
  Default: mlab3v4-lga0t.mlab-sandbox.measurement-lab.org.
* _\<period\>_: The amount of time to run each incremental number of concurrent
  tests before adding _\<step\>_ more concurrent tests.
