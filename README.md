# ocp4-fluentd-kinesis-streams

**WORK IN PROGRESS**

Stream of thought

## Use-Case

We have a need to keep short-term logs (3 to 14 days) in OpenShift using the provided EFK stack.  
In addition, we have a need to keep logs for a much longer duration (half year to multiple years).
Since the cluster is on AWS, we have the capability to use AWS's Kinesis Analytics product.  
To ingest logs into Kinesis, we plan on using the Kinesis Streams API on AWS.

OpenShift provides the capability to fork log output to the internal Elastic and to another fluentd
using the fluentd-secure-forwarder method.

**Initial Idea**

The following URL contains a design to stand up an external fluented forwarder as stand-alone.

http://v1.uncontained.io/playbooks/operationalizing/secure-forward-splunk.html

**Base Image**

Q: What would be the source of a base image?

A: Perhaps registry.redhat.io/openshift4/ose-logging-fluentd

* As of 2020-05-20, image tag is v4.3.20-202005121847

* https://catalog.redhat.com/software/containers/detail/5cd9744edd19c778293af093?tag=v4.3.20-202005121847&container-tabs=overview

**Q: How do you add the kinesis-streams plugin for fluentd?**

Possible sources of code:

* https://github.com/fluent/fluentd-forwarder
* https://github.com/aws/aws-for-fluent-bit
* https://github.com/aws/amazon-kinesis-streams-for-fluent-bit

**Q: What is the source of upstream openshift fluentd container?**

**Master branch:**

* https://github.com/openshift/origin-aggregated-logging/blob/master/fluentd/Dockerfile

**4.3 branch:**

* https://github.com/openshift/origin-aggregated-logging/blob/release-4.3/fluentd/Dockerfile

**Q: If we can host the fluentd-kinesis-forwarder in OpenShift, what would we name the project/namespace?**

A:  example:  `XXX-fluentd-forwarder`

Replace `XXX` with custom local 'code' for client name

**Q: How do you configure OpenShift to fork logs to the fluentd-kinesis-forwader?**

A: Examine the following insturctions:

* https://docs.openshift.com/container-platform/4.3/logging/config/cluster-logging-external.html#cluster-logging-collector-fluentd_cluster-logging-external

## Process

* Stand up AWS OCP 4.3 cluster
* Install logging stack
* Investigate how to enable Kinesis stream on AWS (maybe on personal AWS account)
* Enable kinesis stream API endpoint service on AWS
* Deploy fluentd-kinesis-forwarder on OpenShift including configmaps for auth-creds for API access
* Generate shared key for the OpenShift fluentd and the fluentd-kinesis-forwarder
* Alter the OpenShift cluster logging configmap to forward to the secure fluentd-kinesis-forwarder
* Generate traffic in logs
* Inspect AWS kinesis (analytics)?

## QUESTIONS

* If the custom fluentd-kinesis forwarder pod generates logs, how do you stop it from logging its own logs?
* Does the fluentd-kinesis forwarder have to be outside/standalone?
