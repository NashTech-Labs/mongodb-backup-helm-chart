{{ define "isenabled.workloadorserviceaccount" }}
{{- if and (not .Values.workloadIdentity.enabled) (not .Values.gcs_serviceaccount.enabled) }}
{{- fail "Either Workload Identity or GCP service Account secret should be enabled to access the GCS Bucket" -}}
{{- end }}
{{- end -}}

{{ define "backup.serviceaccount" }}
{{- if .workloadIdentity.enabled }}
serviceAccountName: {{ required "Kubernetes service account having workload identity is mandatory" .workloadIdentity.serviceAccountonKuberenetes }}
{{- else }}
serviceAccountName: default
{{- end }}
{{- end }}

{{- define "backup.gcp_serviceaccount" }}
{{- if .Values.gcs_serviceaccount.enabled -}}
{{- if .Values.gcs_serviceaccount.existing_secret.enabled }}
{{- with .Values.gcs_serviceaccount.existing_secret }}
- name: gcloud-key
  secret:
    secretName: {{ required "Secret Name is required containing the service account private key as json" .secretName | quote }}
    items:
      - key: {{ required "Secret Key is required containing the service account private key as json" .secretKey | quote }}
        path: serviceaccount.json
{{- end }}
{{- else }}
- name: gcloud-key
  secret:
    secretName: {{ .Chart.Name }}-serviceaccount-key
    items:
      - key: serviceaccount.json
        path: serviceaccount.json
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "backup.gcp_creds" }}
- name: GOOGLE_APPLICATION_CREDENTIALS
  value: "/gcloud-key/serviceaccount.json"
{{- end -}}

{{ define "mongodb.secretresource" }}
{{- with .Values.mongodb_existing_secret }}
{{- if .enabled }}
- name: MONGO_ADMIN_USER
  valueFrom:
    secretKeyRef:
      name: {{ required "mongodb admin user Secret key required" .mongodb_admin_user.secretName }}
      key: {{ required "mongodb secret Name required" .mongodb_admin_user.secretKey }}
- name: MONGOPASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ required "mongodb admin password secret key required" .mongodb_password.secretName }}
      key: {{ required "mongodb secret Name required" .mongodb_password.secretKey }}
{{- else }}
- name: MONGO_ADMIN_USER
  value: {{ default "mongodb" $.Values.mongodb_admin_user | quote }}
- name: "MONGOPASSWORD"
  value: {{ required "mongodb Password required" $.Values.mongodb_Password | quote }}
{{- end }}
{{- end }}
{{- end }}