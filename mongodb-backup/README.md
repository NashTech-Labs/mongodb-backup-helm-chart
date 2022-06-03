# mongodb-Backup

This chart creates a cronjob which backups the database as tarball and uploads it to Google Cloud Storage.

* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Introduction](#introduction)
* [Parameters](#parameters)
    * [Cronjob Parameters](#cronjob-parameters)
    * [mongodb and GCS Parameters](#mongodb-and-gcs-parameters)
    * [Workload Identity and Service account parameters](#workload-identity-and-service-account-parameters)
* [Creating Workload Identity](#creating-workload-identity)

## Prerequisites

* Kuberentes 1.19+
* Helm3
* GCS bucket
* Permission to manage service accounts on GCP

## Installation

```
helm install RELEASE-NAME mongodb-backup
```

## Uninstallation

```
helm uninstall RELEASE-NAME
```

## Introduction

The chart deploys a cron job which executes a script to backup the mongodb database into tarball archive and upload them to GCS bucket. To authorize the cronjob pod to access the GCS bucket, one of the following authorization method is needed:
* IAM service Account on GCP with proper permissions to write to the bucket(preferably storage object admin). Then the key for the service account needs to be passed to chart.
* Using [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity). The Kubernetes service account to which the indentity is bound is needed to be passed to the chart.

## Parameters

### Cronjob Parameters

| Name                             | Description                                      | Default Value 
| -------------------------------- | ------------------------------------------------ | ------------- 
| `cronjob.schedule`               | Cron schedule when the backup will be done       | `"0 0 * * *"`
| `cronjob.concurrencyPolicy`      | Specifies how to treat concurrent executions of a Job | `Forbid` 
| `cronjob.completionCount`        | Completion Count to consider the job successful  | `1` 
| `cronjob.ttlSecondsAfterFinished`| Time to live for the pod after backup completion | `30`
| `cronjob.parallelism `           | No. of pods to run at a time                     | `1`
| `cronjob.restartPolicy`          | Pod restart policy                               | `OnFailure`
| `cronjob.image`                  | Image to be used for the pod                     | `google/cloud-sdk:latest`
| `cronjob.imagePullPolicy`        | Image Pull Policy                                | `IfNotPresent`

### mongodb and GCS Parameters

| Name                         | Description | Default Value  |
| -----------------------------| ----------- | -------------  |
| `mongodb_admin_user`        | mongodb Root Username       | `mongodb`
| `mongodb_Password`          | mongodb Root user password  | `""` 
| `mongodb_existing_secret.enabled` | If the mongodb admin user and password should be fetched from an existing secret. If enabled, overrides the `mongodb_admin_user` and `mongodb_Password` | `false`
| `mongodb_existing_secret.mongodb_admin_user.secretName` | Name of the secret containing the mongodb admin username | `""`
| `mongodb_existing_secret.mongodb_admin_user.secretKey` | Name of the key in the secret containing the mongodb admin username | `""`
| `mongodb_existing_secret.mongodb_password.secretName` | Name of the secret containing the mongodb admin password | `""`
| `mongodb_existing_secret.mongodb_password.secretKey` | Name of the key in the secret containing the mongodb password | `""`
| `mongodb_host`              | mongodb host                | `""`
| `mongodb_port `             | mongodb Port                | `5432`
| `gcs_bucket_name`            | GCS bucket name              | `""`
| `gcloud_project`             | GCS project name             | `""`

### Workload Identity and Service account parameters

| Name                         | Description | Default Value |
| -----------------------------| ----------- | ------------- |
| `workloadIdentity.enabled`                     | If Workload Identity is used to provide permissions to pod. Becomes invalid if authentication methods `is gcs_serviceaccount.enabled`                                                                                      | `false`
| `workloadIdentity.serviceAccountonKuberenetes` | Kubernetes Service account which is mapped to GCP service account                                                                                                                                                          | `""` 
| `gcs_serviceaccount.enabled`                   | If authentication for pod is done using service account private key. If enabled takes precedence over `workloadIdentity.enabled`. Either one of `workloadIdentity.enabled` or `gcs_serviceaccount.enabled` should be used  | `false`
| `gcs_serviceaccount.existing_secret.enabled`   | If enabled, the GCP service account private key will be fetched from an existing secret. Useful when the Kubernetes Cluster is not hosted on GCP and needs permission to access the GCS Bucket | `false`
| `gcs_serviceaccount.existing_secret.secretName`   | Secret Name storing the GCP service account private key json | `""`
| `gcs_serviceaccount.existing_secret.secretKey`   | Key in the Secret having the GCP service account private key json as value | `""`
| `gcs_serviceaccount.privatekey`                | Private key of the GCP service account                                                                                                                                                                                     | `""`

## Creating Workload Identity

To bind a GCP service account to Kubernetes Service account, follow these steps:
* Create Service Account in GCP with permission `storage object admin`
* Create a Kubernetes Service Account to bind to the IAM service account.
```
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    iam.gke.io/gcp-service-account: <Service_Account_Name>@<Project_ID>.iam.gserviceaccount.com
  name: mongodb-backup
```
* Bind the service account of GCP to the service account of Kubernetes in a specific namespace
```
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:<PROJECT_ID>.svc.id.goog[<NAMESPACE>/<SERVICE_ACCOUNT_NAME>]" \
  <Service_Account_Name>@<Project_ID>.iam.gserviceaccount.com
```