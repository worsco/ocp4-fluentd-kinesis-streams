# ocp4-fluentd-kinesis-streams

**WORK IN PROGRESS**

## Use-Case

We need to keep short-term logs (from 3 to 14 days) in OpenShift using the provided
EFK stack.  In addition, we need to keep logs for a much longer duration (months to
possibly years).  The OpenShift cluster is in AWS, and we have the capability to
use AWS's Kinesis Streams.  

Red Hat OpenShift 4.3 provides the capability to fork log output to the internal Elastic
 and to another fluentd instance.  To do so, you have to stand up a custom fluentd
 (and install the AWS plugins) and configure the stock fluentd to forward to the external
 fluentd using the fluentd-secure-forwarder method.

---

### Externally Hosted fluentd-secure-forwarder

The following URL contains a design to stand up an external fluentd-secure-forwarder as stand-alone.

http://v1.uncontained.io/playbooks/operationalizing/secure-forward-splunk.html

---

### fluentd-secure-forwarder within OpenShift

After considering standing up a single VM, it was decided to host the fluentd-secure-forwarder
within OpenShift.  This design will allow scaling the pod for high availability as well as
scaling under CPU load.

---

### Base Image

**Q: If we were to host the custom fluentd fowarder to Kinesis Streams as a container, what would be the source of a base image?**

A: docker://registry.redhat.io/openshift4/ose-logging-fluentd

* As of 2020-07-10, image tag is v4.3.28-202006290519.p0

* https://catalog.redhat.com/software/containers/detail/5cd9744edd19c778293af093?tag=v4.3.28-202006290519.p0&container-tabs=overview

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

---

## Architecture Diagram

![Architecture Diagram](/diagram/fluentd_kinesis_forwarder.png "Architecture Diagram")

---

## PRE-REQUISITES
* AWS
  * An Account
* IAM User
  - Access to AWS Stream(s)
* AWS Kinesis Stream(s)
  - audit stream
  - operations stream
  - projects stream
* Container Image Repositories
  - Quay.io
    - An account
    - One image repository
  - registry.redhat.io
    - An account
* OpenShift 4.3+ Cluster
  - OCP4 < 4.3 does not contain the LogForwarder API
  - Operators Installed:
    - Cluster Logging
    - Elastic

---

### Installation Process

* AWS OCP 4.3 cluster
* Install logging stack
* Investigate how to enable Kinesis stream on AWS (maybe on personal AWS account)
* Enable kinesis stream API endpoint service on AWS
* Generate shared key for the OpenShift fluentd and the fluentd-kinesis-forwarder
* Deploy fluentd-kinesis-forwarder on OpenShift including configmaps for auth-creds for AWS API access
* Alter the OpenShift cluster logging configmap to forward to the secure fluentd-kinesis-forwarder
* Generate traffic in logs
* Inspect AWS kinesis monitoring graphs

### Create your Kinesis Streams

```bash
Amazon Kinesis -> Data streams -> Create data stream

Data stream name:
mytest-ocp-kinesis-stream-[projects | operations | audit]

Data stream capacity
Number of open shards
2

Click on: Create data stream

Repeat above to create all streams
```

Take note of the ARN, it will be used with your the policy attached to your IAM User

---

### Create your AWS IAM User

Create an IAM user and name it to your liking.

Create a new user either through the AWS Console or scripts.  I've named my user `ocp4-kinesis-user`
```bash
ocp4-kinesis-user
```

When the user is created, be sure to take note of the `AWS_KEY_ID` and `AWS_SEC_KEY` as both will be used during the installation.

---

### Attach Policy

You should further restrict the following policy.

```json
{
    "Version": "2012-10-17",
    "Statement": {
        "Action": [
            "kinesis:PutRecords",
            "kinesis:DescribeStream"
        ],
        "Effect": "Allow",
        "Resource": [
            "arn:aws:kinesis:AWS-REGION:AWS-ACCOUNT-NUMBER:stream/AWS-STREAM-NAME-FOR-PROJECTS",
            "arn:aws:kinesis:AWS-REGION:AWS-ACCOUNT-NUMBER:stream/AWS-STREAM-NAME-FOR-OPERATIONS",
            "arn:aws:kinesis:AWS-REGION:AWS-ACCOUNT-NUMBER:stream/AWS-STREAM-NAME-FOR-AUDIT"
        ]
    }
}
```
---

### Build container with buildah

Export your registry.redhat.io user + password to environmental variables.

```bash
export RH_REG_USER=YourUsername
export RH_REG_PASS=YourPassword
```

Log into the registry (previously set the environment variables `RH_REG_USER` and `RH_REG_PASS` with my credentials).

```bash
cd containers/
buildah login -u $RH_REG_USER -p $RH_REG_PASS registry.redhat.io
```

Build and tag the image.  In my use case, the quay repo is named 'worsco'
-- change it to your repo name.

```bash
buildah bud -t quay.io/worsco/ocp4-fluentd-kinesis-forwarder:latest .
```

I will be pushing my container into quay.  To do so, I will be logging into quay.io and will need to
export my quay.io user + password to environment variables.

```bash
export QUAY_USER=YourUsername
export QUAY_PASS=YourPassword
```

Log into quay.

```bash
podman login -u $QUAY_USER -p $QUAY_PASS quay.io
```

Push the image into your repository.

```bash
podman push quay.io/worsco/ocp4-fluentd-kinesis-forwarder:latest
```
---

### Customize the k8s deployment

The file `deployment/deployment.yaml` contains a directive to
pull the container image from `quay.io/worsco/ocp4-fluentd-kinesis-forwarder:latest`.
Please customize it to your repository.

---

### Install

Run the installer, replace the environment variables with your data.

```bash
cd ./scripts

AWS_KEY_ID=YOUR-AWS-KEY-ID \
AWS_SEC_KEY=YOUR-AWS-SEC-KEY \
LOGGINGNAMES="projects operations audit" \
KINESIS_STREAM_NAME="your-kinesis-stream-projects your-kinesis-stream-operations your-kinesis-stream-audit" \
KINESIS_REGION="your-aws-region" \
./install_log_forwarding_kinesis.sh
```

---

### Uninstall

To completely uninstall and revert all settings back.

```
LOGGINGNAMES="projects operations audit" \
./uninstall_log_forwarding_kinesis.sh
```
---

## Todo

* Pod Autoscaler based on CPU usage
* Pod anti-affininty rule to stop two pods in same Node (or same AZ?)
