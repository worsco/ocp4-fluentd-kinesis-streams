# ocp4-fluentd-kinesis-streams

**WORK IN PROGRESS**

## Use-Case

We need to keep short-term logs (from 3 to 14 days) in OpenShift using the provided EFK stack.  In addition, we need to keep logs for a much longer duration (months to possibly years).  The OpenShift cluster is in AWS, and we have the capability to use AWS's Kinesis Streams.  

Red Hat OpenShift 4.3 provides the capability to fork log output to the internal Elastic.  To do so, you have to stand up a custom fluentd (and install the AWS plugins) and configure the stock fluentd to forward to the external fluentd
using the fluentd-secure-forwarder method.

### Externally Hosted fluentd forwarder

The following URL contains a design to stand up an external fluented forwarder as stand-alone.

http://v1.uncontained.io/playbooks/operationalizing/secure-forward-splunk.html

### Hosted fluentd-forwarder within OpenShift

After considering standing up a single VM, it was determined to host the fluentd-forwarder within the OpenShift cluster.  This design will be tested to see if the pod can be scaled up for high availability as well as redundancy.

### Base Image

**Q: If we were to host the custom fluentd fowarder to Kinesis Streams as a container, what would be the source of a base image?**

A: docker://registry.redhat.io/openshift4/ose-logging-fluentd

* As of 2020-05-20, image tag is v4.3.20-202005121847

* https://catalog.redhat.com/software/containers/detail/5cd9744edd19c778293af093?tag=v4.3.20-202005121847&container-tabs=overview

**Q: How do you add the kinesis-streams plugin for fluentd?**

A: Install the plugin into the base-image as a rugy gem.

This is the source of the gem:

* https://github.com/awslabs/aws-fluent-plugin-kinesis

Installation process directions from above:

This Fluentd plugin is available as the fluent-plugin-kinesis gem from RubyGems.

`gem install fluent-plugin-kinesis`

Dependencies to use the `aws-fluent-plugin-kinesis`:

* Ruby 2.3.0+
* Fluentd 0.14.22+ (td-agent v3.1.0+)

**Q: What is the source of upstream openshift fluentd container?**

**Master branch:**

* https://github.com/openshift/origin-aggregated-logging/blob/master/fluentd/Dockerfile

**4.3 branch:**

* https://github.com/openshift/origin-aggregated-logging/blob/release-4.3/fluentd/Dockerfile

**Q: If we can host the fluentd-kinesis-forwarder in OpenShift, what would we name the project/namespace?**

A: A possible example:  `XXX-fluentd-forwarder`

Replace `XXX` with custom local 'code' for customer name

**Q: How do you configure OpenShift to fork logs to the fluentd-kinesis-forwader?**

A: Follow these instructions:

* https://docs.openshift.com/container-platform/4.3/logging/config/cluster-logging-external.html#cluster-logging-collector-fluentd_cluster-logging-external

## Installation Process

* Stand up AWS OCP 4.3 cluster
* Install logging stack
* Investigate how to enable Kinesis stream on AWS (maybe on personal AWS account)
* Enable kinesis stream API endpoint service on AWS
* Generate shared key for the OpenShift fluentd and the fluentd-kinesis-forwarder
* Deploy fluentd-kinesis-forwarder on OpenShift including configmaps for auth-creds for AWS API access
* Alter the OpenShift cluster logging configmap to forward to the secure fluentd-kinesis-forwarder
* Generate traffic in logs
* Inspect AWS kinesis (analytics?)

## QUESTIONS

* If the custom fluentd-kinesis forwarder pod generates logs, how do you stop it from logging its own logs (will it log its own logs and become exponentially redundant)?
* Will this work?  Is the fluentd-kinesis forwarder required to be outside of the cluster and standalone?

## NOTES

Image used:

`registry.redhat.io/openshift4/ose-logging-fluentd@sha256:40edd9833d5a4290f63cfbc7a442f6ce5ba4f21c2acd252e0ec4a0db9a25b7c5`

Inspecting the fluentd image via `oc rsh <fluentd-HASH>` in namespace `openshift-logging` on a cluster with the logging EFK stack installed. 


What files are named `fluentd` in the container?

```
sh-4.2# find / -name "fluentd"
/run/ocp-collector/secrets/fluentd
/var/lib/fluentd
/var/log/pods/openshift-logging_fluentd-6655j_71e70f39-7a64-4087-bdc4-810bfc477d54/fluentd
/var/log/fluentd
/opt/rh/rh-ruby25/root/usr/local/bin/fluentd
/opt/rh/rh-ruby25/root/usr/local/share/gems/gems/fluent-plugin-remote-syslog-1.1/lib/fluentd
/opt/rh/rh-ruby25/root/usr/local/share/gems/gems/fluentd-1.7.4/bin/fluentd
```

What files are named `fluent.gem`?

```
sh-4.2# find / -name "fluent*gem"
/opt/rh/rh-ruby25/root/usr/local/bin/fluent-gem
/opt/rh/rh-ruby25/root/usr/local/share/gems/gems/fluentd-1.7.4/bin/fluent-gem
```

I saw `rh/rh-ruby25`. This is a software collection library package! What version is it?

```
sh-4.2# scl --list
rh-ruby25

sh-4.2# scl enable rh-ruby25 bash
bash-4.2# ruby --version
ruby 2.5.5p157 (2019-03-15 revision 67260) [x86_64-linux]
```

What's the version of `fluentd`?

```
bash-4.2# fluentd --version
fluentd 1.7.4
```

The container image has the SCL edition of Ruby 2.5, does it include gem? Yes it does, see below.

```sh-4.2# scl --list
rh-ruby25

sh-4.2# scl enable rh-ruby25 bash
bash-4.2# which gem
/opt/rh/rh-ruby25/root/usr/bin/gem

bash-4.2# gem --version
2.7.6.2
```

## MANUAL BUILD (pre-Dockerfile)

Log into the registry (previously set the environment variables `RH_REG_USER` and `RH_REG_PASS` with my credentials).

```
podman login -u $RH_REG_USER -p $RH_REG_PASS registry.redhat.io 
```

Execute the container.

```
podman run -it \
registry.redhat.io/openshift4/ose-logging-fluentd@sha256:40edd9833d5a4290f63cfbc7a442f6ce5ba4f21c2acd252e0ec4a0db9a25b7c5 bash
```

Install software and their dependencies for installing via `gem` command.

``` yum -y install rh-ruby25-ruby-devel \
rh-ruby25-rubygems-devel \
gcc-c++ \
make
```

Enable the ruby 2.5 environment.

```
scl enable rh-ruby25 bash
```

Install fluent-plugin-kinesis via gem.

```
gem install fluent-plugin-kinesis --verbose
```

## Build with buildah

Log into the registry (previously set the environment variables `RH_REG_USER` and `RH_REG_PASS` with my credentials).

```
buildah login -u $RH_REG_USER -p $RH_REG_PASS registry.redhat.io
```

Build the container.

```
buildah bud -t fluentd-custom-kinesis .
```

Tag the image.

```
podman tag localhost/fluentd-custom-kinesis quay.io/worsco/ocp4-fluentd-kinesis-forwarder:latest
```

Log into quay.

```
podman login -u worsco quay.io
```

Push the image.

```
podman push quay.io/worsco/ocp4-fluentd-kinesis-forwarder:latest
```