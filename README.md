# ocp4-fluentd-kinesis-streams

**WORK IN PROGRESS**

## Use registry.redhat.io/openshift4/ose-logging-fluentd as the base image

* As of 2020-05-20, image tag is v4.3.20-202005121847

https://catalog.redhat.com/software/containers/detail/5cd9744edd19c778293af093?tag=v4.3.20-202005121847&container-tabs=overview

## Determine method of adding the kinesis-streams plugin for fluentd

## Possible sources of code:
* https://github.com/aws/aws-for-fluent-bit
* https://github.com/aws/amazon-kinesis-streams-for-fluent-bit

### Source of upstream fluentd container

**Master**

* https://github.com/openshift/origin-aggregated-logging/blob/master/fluentd/Dockerfile

**4.3**

* https://github.com/openshift/origin-aggregated-logging/blob/release-4.3/fluentd/Dockerfile

## New project/namespace for the fluentd secure forwarder
* Example:  XXX-fluentd-forwarder
* Replace XXX with custom local code for client

https://docs.openshift.com/container-platform/4.3/logging/config/cluster-logging-external.html#cluster-logging-collector-fluentd_cluster-logging-external

## Testing

* Stand up AWS OCP 4.3 cluster
* Install logging stack
* Enable kinesis stream
* Deploy fluentd-forwarder with creds and kinesis endpoint for ingest
* Alter cluster logging configmap to forward via secure fluentd forwarder
* Generate traffic (logs)
* Inspect kinesis
