variable "aks_cluster_name" {
  type = string
  description = "Name of the AKS cluster where resources will be deployed"
  default = "k8stest"
  
}

variable "resource_group_name" {
  type = string
  description = "Name of the resource group where the AKS cluster and Azure Key Vault are"
  default     = "azure-k8stest"
}

variable "keyvault_name" {
  type = string
  description = "Globally unique name to give to the Key Vault instance"
  default     = "kv01312023"
}

variable "keyvault_identity_name" {
  type = string
  description = "Name to give to the managed identity with Key Vault permissions"
  default = "keyvault-mi"
}

variable "kubernetes_service_account_name" {
  type = string
  description = "Name to give to the kubernetes service account to map to a user managed identity"
  default = "keyvaultserviceaccount"
}

variable "federated_identity_credential_name" {
  type = string
  description = "Name of the Federated Identity Credential to use from AKS to connect to Azure Key Vault."
  default = "aksToKeyvaultFederatedIdentity"
}

variable "keyvault_client_namespace" {
  type = string
  description = "Kubernetes namespace to create and use for the keyvault client workload and service account"
  default = "csi"
}
