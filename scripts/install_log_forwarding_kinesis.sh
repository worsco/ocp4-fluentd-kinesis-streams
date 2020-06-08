#!/bin/bash
# install_log_forwarding_kinesis.sh

if [[ -z "$AWS_KEY_ID" ]]; then
  echo "You need to set the AWS_KEY_ID environment variable"
  exit 1
fi

if [[ -z "$AWS_SEC_KEY" ]]; then
  echo "You need to set the AWS_SEC_KEY environment variable"
  exit 1
fi

if [[ -z "$LOGGINGNAMES" ]]; then
  echo "You need to set the LOGGINGNAMES environment variable"
  exit 1
fi

#if [[ -z "$SHARED_KEY_PREFIX" ]]; then
#  echo "You need to set the SHARED_KEY_PREFIX environment variable"
#  exit 1
#fi

#if [[ -z "$SHARED_KEY_ENV" ]]; then
#  echo "You need to set the SHARED_KEY_ENV environment variable"
#  exit 1
#fi

if [[ -z "$KINESIS_STREAM_NAME" ]]; then
  echo "You need to set the KINESIS_STREAM_NAME environment variable"
  exit 1
fi

if [[ -z "$KINESIS_REGION" ]]; then
  echo "You need to set the KINESIS_REGION environment variable"
  exit 1
fi


# Create the AWS Kinesis credentials secret
oc create secret generic log-forwarding-kinesis-aws -n openshift-logging \
--from-literal=AWS_KEY_ID="$AWS_KEY_ID" \
--from-literal=AWS_SEC_KEY="$AWS_SEC_KEY"

# Need to loop through the values of LOGGINGNAME and create a service for each.

# log-forwarding-kinesis-service needs SERVICENAME replace with LOGGINGNAME
cd ../deployment/
for LOGNAME in $LOGGINGNAMES; do
  cp service.yaml /tmp/service.yaml && \
  sed -i "s/SERVICENAME/$LOGNAME/g" /tmp/service.yaml && \
  oc create -f /tmp/service.yaml
done

echo "Pause for 5 seconds."
sleep 5

for LOGNAME in $LOGGINGNAMES
do
  until oc get secret log-forwarding-kinesis-$LOGNAME -n openshift-logging
  do
    echo "Not ready yet."
    sleep 2
  done
done

export MYINDEX=0
export MYSTREAM=($KINESIS_STREAM_NAME)
for LOGNAME in $LOGGINGNAMES
do
  # Create the TLS certificates for OpenShift fluentd and the fluentd forwarder
  export TLS_KEY=$(oc get secret log-forwarding-kinesis-$LOGNAME -n openshift-logging -o jsonpath="{.data['tls\.key']}" | base64 -d) 
  export TLS_CRT=$(oc get secret log-forwarding-kinesis-$LOGNAME -n openshift-logging -o jsonpath="{.data['tls\.crt']}" | base64 -d) 

  oc create secret generic log-forwarding-kinesis-secure-$LOGNAME -n openshift-logging \
  --from-literal=tls.crt="$TLS_CRT" \
  --from-literal=tls.key="$TLS_KEY" \
  --from-literal=ca-bundle.crt="$TLS_CRT" \
  --from-literal=shared_key="${MYSTREAM[MYINDEX]}-fluentdSecretSharedKey"
  MYINDEX=$((MYINDEX + 1))
done

oc create configmap log-forwarding-kinesis-config --from-file=td-agent.conf -n openshift-logging

export MYINDEX=0
export MYSTREAM=($KINESIS_STREAM_NAME)
for LOGNAME in $LOGGINGNAMES
do
# Do a variable substitution on the deployment file
  cd ../deployment
  cp -f deployment.yaml /tmp/deployment.yaml
  sed -i "s/DEPLOYMENTNAME/$LOGNAME/g" /tmp/deployment.yaml
  sed -i "s/CHANGEME-KINESIS-STREAM-NAME/${MYSTREAM[MYINDEX]}/g" /tmp/deployment.yaml
  sed -i "s/CHANGEME-KINESIS-REGION/$KINESIS_REGION/g" /tmp/deployment.yaml
  oc create -f /tmp/deployment.yaml
  MYINDEX=$((MYINDEX + 1))
done

# Annotate to enable the LogForwarding API

oc annotate ClusterLogging/instance clusterlogging.openshift.io/logforwardingtechpreview="enabled"

# Create the LogForwarding instance Custom Resource

oc create -f logforwarding_cr.yaml

# Done
echo "END_OF_JOB"
