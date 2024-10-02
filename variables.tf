variable "ARM_CLIENT_ID" {
  description = "Azure Client ID"
}

variable "ARM_CLIENT_SECRET" {
  description = "Azure Client Secret"
}

variable "ARM_SUBSCRIPTION_ID" {
  description = "Azure Subscription ID"
}

variable "ARM_TENANT_ID" {
  description = "Azure Tenant ID"
}

variable "host_os" {
  description = "The host operating system (e.g., linux or windows)"  
  type = string
  default = "linux"
}

variable "ssh_public_key_path" {
  description = "Path to the locally stored SSH public key file"
  default     = ".ssh/mtcazurekey.pub"  # Path to the locally fetched public key
}
