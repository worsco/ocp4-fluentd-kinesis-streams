{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "openshift-logforwarding-kinesis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to that
length (by the DNS naming spec -- see https://www.ietf.org/rfc/rfc1035.txt).
If .Release.Name contains .Chart.Name it will be used as the fullname.
*/}}
{{- define "openshift-logforwarding-kinesis.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openshift-logforwarding-kinesis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "openshift-logforwarding-kinesis.labels" -}}
app: {{ .Release.Name }}
helm.sh/chart: {{ include "openshift-logforwarding-kinesis.chart" . }}
{{ include "openshift-logforwarding-kinesis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "openshift-logforwarding-kinesis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openshift-logforwarding-kinesis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use.
Function is not yet utilized in the templates.
*/}}
{{- define "openshift-logforwarding-kinesis.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "openshift-logforwarding-kinesis.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Generate certificates for the fluentd forwarder. The Sprig library provides proper support.
Create the CA and the Cert with an expiration of two years (730 days).
*/}}
{{- define "openshift-logforwarding-kinesis.gen-fluentd-certs" -}}
{{- $fullname := include "openshift-logforwarding-kinesis.fullname" . -}}
{{- $ca := genCA  (printf "%s.%s.svc" $fullname .Release.Namespace) 730 -}}
{{- $cert := genSignedCert  (printf "%s-%s.svc" $fullname .Release.Namespace) nil nil 730 $ca -}}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
ca-bundle.crt: {{ $cert.Cert | b64enc }}
{{- end -}}
