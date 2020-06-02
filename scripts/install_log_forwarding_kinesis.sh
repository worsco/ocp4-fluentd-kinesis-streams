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

if [[ -z "$SHARED_KEY" ]]; then
  echo "You need to set the SHARED_KEY environment variable"
  exit 1
fi

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

# Create the Log Forwarding Kinesis OpenShift service
oc create -f ../deployment/log-forwarding-kinesis-service.yaml

echo "Pause for 5 seconds."
sleep 5

until oc get secret log-forwarding-kinesis -n openshift-logging
do
    echo "Not ready yet."
    sleep 2
done

# Create the TLS certificates for OpenShift fluentd and the fluentd forwarder
export TLS_KEY=$(oc get secret log-forwarding-kinesis -n openshift-logging -o jsonpath="{.data['tls\.key']}" | base64 -d) 
export TLS_CRT=$(oc get secret log-forwarding-kinesis -n openshift-logging -o jsonpath="{.data['tls\.crt']}" | base64 -d) 

oc create secret generic log-forwarding-kinesis-secure -n openshift-logging \
--from-literal=tls.crt="$TLS_CRT" \
--from-literal=tls.key="$TLS_KEY" \
--from-literal=ca-bundle.crt="$TLS_CRT" \
--from-literal=shared_key="$SHARED_KEY"

cd ../deployment
oc create configmap log-forwarding-kinesis-config --from-file=td-agent.conf -n openshift-logging

# Do a variable substitution on the deployment file
cp -f deployment-secure-forward.yaml /tmp/deployment-secure-forward.yaml
sed -i "s/CHANGEME-KINESIS-STREAM-NAME/$KINESIS_STREAM_NAME/g" /tmp/deployment-secure-forward.yaml
sed -i "s/CHANGEME-KINESIS-REGION/$KINESIS_REGION/g" /tmp/deployment-secure-forward.yaml
oc create -f /tmp/deployment-secure-forward.yaml

# Annotate to enable the LogForwarding API

oc annotate ClusterLogging/instance clusterlogging.openshift.io/logforwardingtechpreview="enabled"

# Create the LogForwarding instance Custom Resource

oc create -f logforwarding_cr.yaml

# Done
echo "END_OF_JOB"
