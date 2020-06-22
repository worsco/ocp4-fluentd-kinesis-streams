{{/* vim: set filetype=mustache: */}}

{{/*
Generate certificates for the fluentd forwarder. The Sprig library provides proper support.
Create the CA and the Cert with an expiration of two years (730 days).
*/}}
{{- define "openshift-logforwarding-kinesis.gen-fluentd-certs" -}}
{{- $fullname := include "openshift-logforwarding-kinesis.fullname" . -}}
{{- $altNames := list ( printf "%s.%s.svc" $fullname .Release.Namespace ) ( printf "%s.%s.svc.cluster.local" $fullname .Release.Namespace ) -}}
{{- $ca := genCA  (printf "%s.%s.svc" $fullname .Release.Namespace) 730 -}}
{{- $cert := genSignedCert  (printf "%s-%s.svc" $fullname .Release.Namespace) nil $altNames 730 $ca -}}
tls.crt: {{ printf "%s\n%s" $cert.Cert $ca | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
ca-bundle.crt: {{ printf "%s\n%s" $cert.Cert $ca | b64enc }}
{{- end -}}
