{{/*
Expand the chart name.
*/}}
{{- define "music-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "music-platform.fullname" -}}
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
Chart label.
*/}}
{{- define "music-platform.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "music-platform.labels" -}}
helm.sh/chart: {{ include "music-platform.chart" . }}
app.kubernetes.io/name: {{ include "music-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "music-platform.selectorLabels" -}}
app.kubernetes.io/name: {{ include "music-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "music-platform.apiName" -}}
{{- printf "%s-api" (include "music-platform.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "music-platform.dbName" -}}
{{- printf "%s-db" (include "music-platform.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "music-platform.configMapName" -}}
{{- printf "%s-config" (include "music-platform.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "music-platform.secretName" -}}
{{- if .Values.db.existingSecret -}}
{{- .Values.db.existingSecret | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-secret" (include "music-platform.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "music-platform.dbServiceName" -}}
{{- include "music-platform.dbName" . -}}
{{- end -}}

{{- define "music-platform.apiServiceAccountName" -}}
{{- printf "%s-api-sa" (include "music-platform.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "music-platform.dbServiceAccountName" -}}
{{- printf "%s-db-sa" (include "music-platform.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
