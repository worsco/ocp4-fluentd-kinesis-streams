# ocp4-fluentd-kinesis-streams

**WORK IN PROGRESS**

Stream of thought

### Initial Idea

This is the design to create an external fluentd fowarder for splunk.  It was used as the starting point for this idea.

http://v1.uncontained.io/playbooks/operationalizing/secure-forward-splunk.html

### What would be the base image?

### Considering registry.redhat.io/openshift4/ose-logging-fluentd as the base image

* As of 2020-05-20, image tag is v4.3.20-202005121847

https://catalog.redhat.com/software/containers/detail/5cd9744edd19c778293af093?tag=v4.3.20-202005121847&container-tabs=overview

### Determine method of adding the kinesis-streams plugin for fluentd

#### Possible sources of code:
* https://github.com/fluent/fluentd-forwarder
* https://github.com/aws/aws-for-fluent-bit
* https://github.com/aws/amazon-kinesis-streams-for-fluent-bit

### Source of upstream openshift fluentd container

**Master branch**

* https://github.com/openshift/origin-aggregated-logging/blob/master/fluentd/Dockerfile

**4.3 branch**

* https://github.com/openshift/origin-aggregated-logging/blob/release-4.3/fluentd/Dockerfile

### New project/namespace for the fluentd secure forwarder if hosted within OpenShift

* Example:  XXX-fluentd-forwarder
* Replace XXX with custom local 'code' for client name

### OpenShift configuration to forward

https://docs.openshift.com/container-platform/4.3/logging/config/cluster-logging-external.html#cluster-logging-collector-fluentd_cluster-logging-external

### Testing

* Stand up AWS OCP 4.3 cluster
* Install logging stack
* Enable kinesis stream API endpoint service on AWS
* Deploy fluentd-forwarder(+kinesis endpoint) and auth creds via secret (not IAM)
* Alter cluster logging configmap to forward to the secure fluentd forwarder
* Generate traffic in logs
* Inspect AWS kinesis (analytics)?

## QUESTIONS

* If the custom fluentd-kinesis forwarder pod generates logs, how do you stop it from logging its own logs?
* Does the fluentd-kinesis forwarder have to be outside/standalone?
