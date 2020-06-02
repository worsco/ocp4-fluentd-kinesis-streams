#!/bin/bash

# Remove the annotation from ClusterLogging
oc annotate ClusterLogging/instance clusterlogging.openshift.io/logforwardingtechpreview-

# Remove the LogForwarding instance
oc delete LogForwarding instance -n openshift-logging

# Clean up artifacts
oc delete deployment log-forwarding-kinesis -n openshift-logging
oc delete service log-forwarding-kinesis -n openshift-logging
oc delete secret log-forwarding-kinesis-aws -n openshift-logging
oc delete secret log-forwarding-kinesis-secure -n openshift-logging
oc delete configmap log-forwarding-kinesis-config -n openshift-logging

# Only if build the image within OpenShift
#oc delete buildconfig log-forwarding-kinesis -n openshift-logging
#oc delete imagestream ose-logging-fluentd -n openshift

