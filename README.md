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

## Create your Kinesis Stream

```
Amazon Kinesis -> Data streams -> Create data stream

Data stream name:
mytest-ocp-kinesis-stream

Data stream capacity
Number of open shards
2

Click on: Create data stream
```

Take note if the ARN, it will be used with your IAM + Policy

## Create your AWS IAM with Policy

```
Create a new user:
ocp4-kinesis-user
```

Take note of the `AWS_KEY_ID` and `AWS_SEC_KEY`, it will be used during the installation.

## Attach Policy

You should further restrict the following policy.

```
{
    "Version": "2012-10-17",
    "Statement": {
        "Action": [
            "kinesis:PutRecords",
            "kinesis:DescribeStream"
        ],
        "Effect": "Allow",
        "Resource": [
            "arn:aws:kinesis:AWS-REGION:AWS-ACCOUNT-NUMBER:stream/AWS-STREAM-NAME"
        ]
    }
}
```

## Build with container with buildah

Export your registry.redhat.io user + pass to environmental variables

```
export RH_REG_USER=YourUsername
export RH_REG_PASS=YourPassword
```

Log into the registry (previously set the environment variables `RH_REG_USER` and `RH_REG_PASS` with my credentials).

```
cd containers/
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

Export your quay.io user + pass to environment variables

```
export QUAY_USER=YourUsername
export QUAY_PASS=YourPassword

Log into quay.

```
podman login -u $QUAY_USER -p $QUAY_PASS quay.io
```

Push the image.

```
podman push quay.io/worsco/ocp4-fluentd-kinesis-forwarder:latest
```

Run the installer, replace the environment variables with your data

```
cd ../scripts
AWS_KEY_ID=YOUR-AWS-KEY-ID \
AWS_SEC_KEY=YOUR-AWS-SEC-KEY \
SHARED_KEY=TheSecureForwardSharedKeyChangeMe \
KINESIS_STREAM_NAME="your-kinesis-stream-name" \
KINESIS_REGION="your-aws-region" \
./install_log_forwarding_kinesis.sh

```

## To uninstall

```
./uninstall_log_forwarding_kinesis.sh
