#!/bin/bash
# install_log_forwarding_kinesis.sh

if [[ -z "$LOGGINGNAMES" ]]; then
  echo "You need to set the LOGGINGNAMES environment variable"
  exit 1
fi

if [[ -z "$FILEDEST" ]]; then
  echo "You need to set the FILEDEST environment variable"
  exit 1
fi

# Test that "$FILEDEST" exists/is-valid


for LOGNAME in $LOGGINGNAMES
do
  openssl genrsa -out $FILEDEST/$LOGNAME-ca.key 2048
  openssl req -new -x509 -days 730 -key $FILEDEST/$LOGNAME-ca.key -subj "/CN=Acme Root CA" -out $FILEDEST/$LOGNAME-ca.crt
  openssl req -newkey rsa:2048 -nodes -keyout $FILEDEST/$LOGNAME-server.key -subj "/CN=log-forwarding-kinesis-$LOGNAME.openshift-logging.svc" -out $FILEDEST/$LOGNAME-server.csr

  openssl x509 -req \
  -extfile <(printf "subjectAltName=DNS:log-forwarding-kinesis-$LOGNAME.openshift-logging.svc,DNS:log-forwarding-kinesis-$LOGNAME.openshift-logging.svc.cluster.local") \
  -days 730 -in $FILEDEST/$LOGNAME-server.csr \
  -CA $FILEDEST/$LOGNAME-ca.crt \
  -CAkey $FILEDEST/$LOGNAME-ca.key \
  -CAcreateserial \
  -out $FILEDEST/$LOGNAME-server.crt
done

# Done
echo "END_OF_JOB"
