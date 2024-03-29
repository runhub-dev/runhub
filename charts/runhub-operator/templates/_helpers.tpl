{{- define "infra.repository" }}
  {{- if get .Values "dev" }}
    {{- .Values.dev.repository }}
  {{- else }}
    {{- .Values.infra.repository }}
  {{- end }}
{{- end }}

{{- define "infra.revision" }}
  {{- if get .Values "dev" }}
    {{- .Values.dev.revision }}
  {{- else }}
    {{- .Values.infra.revision }}
  {{- end }}
{{- end }}

{{- define "runhub.repository" }}
  {{- if get .Values "dev" }}
    {{- .Values.dev.repository }}
  {{- else }}
    {{- `{{ .runhub.repository }}` }}
  {{- end }}
{{- end }}

{{- define "runhub.revision" }}
  {{- if get .Values "dev" }}
    {{- .Values.dev.revision }}
  {{- else }}
    {{- `{{ .runhub.revision }}` }}
  {{- end }}
{{- end }}
