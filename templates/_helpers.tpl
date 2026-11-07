{{- define "wg-easy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "wg-easy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "wg-easy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "wg-easy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wg-easy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "wg-easy.labels" -}}
helm.sh/chart: {{ include "wg-easy.chart" . }}
{{ include "wg-easy.selectorLabels" . }}
app.kubernetes.io/version: {{ (default .Chart.AppVersion .Values.image.tag) | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "wg-easy.image" -}}
{{- if .Values.image.digest }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}
{{- end }}

{{- define "wg-easy.pvcName" -}}
{{- default (include "wg-easy.fullname" .) .Values.persistence.existingClaim }}
{{- end }}

{{- define "wg-easy.initSecretName" -}}
{{- default (printf "%s-init" (include "wg-easy.fullname" .)) .Values.init.existingSecret }}
{{- end }}

{{/* Fail early on invalid unattended-setup combinations. */}}
{{- define "wg-easy.validate" -}}
{{- if .Values.init.enabled }}
{{- if not .Values.init.host }}
{{- fail "init.host is required when init.enabled=true" }}
{{- end }}
{{- if and (not .Values.init.existingSecret) (not .Values.init.password) }}
{{- fail "set init.password or init.existingSecret when init.enabled=true" }}
{{- end }}
{{- if ne (empty .Values.init.ipv4Cidr) (empty .Values.init.ipv6Cidr) }}
{{- fail "init.ipv4Cidr and init.ipv6Cidr must be set together" }}
{{- end }}
{{- end }}
{{- if not (has .Values.sysctls.mode (list "initContainer" "securityContext" "none")) }}
{{- fail "sysctls.mode must be initContainer, securityContext or none" }}
{{- end }}
{{- end }}
