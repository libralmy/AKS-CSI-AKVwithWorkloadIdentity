variable "resource_group_name" {
  type        = string
  description = "name for the resource group"
  default     = "csiRGTF"
}

variable "keyvault_name" {
  type = string
  description = "Globally unique name for the Key Vault instance to create"
  default     = "kv02012023e"
}

variable "location" {
  type        = string
  description = "location for the resource group"
  default     = "eastus"
}
