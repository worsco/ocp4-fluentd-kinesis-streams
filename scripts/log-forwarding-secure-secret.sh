#!/bin/bash

if [[ -z "$SHARED_KEY" ]]; then
    echo "You need to set the SHARED_KEY environment variable"
    exit 1
fi

export TLS_KEY=$(oc get secret -n openshift-logging log-forwarding-kinesis -o jsonpath="{.data['tls\.key']}" | base64 -d)
export TLS_CRT=$(oc get secret -n openshift-logging log-forwarding-kinesis -o jsonpath="{.data['tls\.crt']}" | base64 -d)

#oc delete secret log-forwarding-kinesis-secure -n openshift-logging

oc create secret generic log-forwarding-kinesis-secure -n openshift-logging \
--from-literal=tls.crt="$TLS_CRT" \
--from-literal=tls.key="$TLS_KEY" \
--from-literal=ca-bundle.crt="$TLS_CRT" \
--from-literal=shared_key="$SHARED_KEY"

oc get secret log-forwarding-kinesis-secure -o yaml

oc rollout restart deployment log-forwarding-kinesis
oc rollout restart ds fluentd
