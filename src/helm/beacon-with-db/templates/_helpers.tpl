{{- define "beaconwithdb.namespace" -}}
{{- if eq .Release.Namespace "default" }}
{{- print "beaconwithdbns" }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{- define "beaconwithdb.allLabels" -}}
app_name: {{ .Chart.Name }}
app_version: "{{ .Chart.Version }}"
release_name: {{ .Release.Name }}
release_revision: "{{ .Release.Revision | toString }}"
{{- end }}

{{- define "beaconwithdb.allLabelswithname" -}}
{{- $appName := .appName -}}
app_name: {{ .Chart.Name }}
app_target: {{ $appName }}
app_version: "{{ .Chart.Version }}"
release_name: {{ .Release.Name }}
release_revision: "{{ .Release.Revision | toString }}"
{{- end }}