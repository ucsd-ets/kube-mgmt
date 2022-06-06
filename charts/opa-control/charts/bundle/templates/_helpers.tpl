{{- define "bundle-server-chart.deployment.labels" -}}
app: bundle-server
{{- end }}
{{- define "bundle-server-chart.service.labels" -}}
app: bundle-server
{{- end }}
{{- define "bundle-server-chart.ingress.annotations" -}}
kubernetes.io/ingress.class: nginx
nginx.ingress.kubernetes.io/rewrite-target: /
{{- end }}