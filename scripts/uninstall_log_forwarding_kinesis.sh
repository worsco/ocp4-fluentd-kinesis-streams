#!/bin/bash

if [ -z "$LOGGINGNAMES" ]; then
  echo "You need to set the LOGGINGNAMES environment variable"
  exit 1
fi

# Remove the LogForwarding instance
oc delete ClusterLogForwarder instance -n openshift-logging

# Clean up artifacts
oc delete secret log-forwarding-kinesis-aws -n openshift-logging
oc delete configmap log-forwarding-kinesis-config -n openshift-logging

for LOGNAME in $LOGGINGNAMES
do
  oc delete service log-forwarding-kinesis-$LOGNAME -n openshift-logging
  oc delete deployment log-forwarding-kinesis-$LOGNAME -n openshift-logging
  oc delete secret log-forwarding-kinesis-secure-$LOGNAME -n openshift-logging
done
