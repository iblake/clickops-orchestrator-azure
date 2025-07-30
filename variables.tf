# JSON Configuration Variables (OCI Landing Zones pattern)
variable "resource_groups" {
  description = "Resource groups configuration from JSON"
  type = map(object({
    name     = string
    location = string
  }))
  default = {}
}

variable "networks" {
  description = "Networks configuration from JSON"
  type = map(object({
    resource_group_key = string
    name               = string
    cidr               = string
    subnets = map(object({
      name = string
      cidr = string
    }))
  }))
  default = {}
}

variable "security_groups" {
  description = "Security groups configuration from JSON"
  type = map(object({
    resource_group_key = string
    name               = string
    rules = list(object({
      name        = string
      port        = number
      protocol    = optional(string, "Tcp")
      source      = optional(string, "*")
      priority    = number
      description = optional(string, "")
    }))
  }))
  default = {}
}

variable "virtual_machines" {
  description = "Virtual machines configuration from JSON"
  type = map(object({
    resource_group_key = string
    network_key        = string
    subnet_key         = string
    security_group_key = string
    name               = string
    size               = string
    admin_username     = string
    ssh_key_path       = string
    create_public_ip   = optional(bool, true)
    public_ip_sku      = optional(string, "Basic")
  }))
  default = {}
}

variable "enable_existing_resources" {
  description = "Enable support for existing resources lookup"
  type        = bool
  default     = false
}

# Optional override variables for backward compatibility
variable "resource_group_override" {
  description = "Override resource group configuration"
  type = object({
    name          = optional(string)
    location      = optional(string)
    existing_name = optional(string)
  })
  default = null
}

variable "network_override" {
  description = "Override network configuration"
  type = object({
    vnet_name               = optional(string)
    vnet_cidr               = optional(string)
    subnet_name             = optional(string)
    subnet_cidr             = optional(string)
    existing_vnet_name      = optional(string)
    existing_subnet_name    = optional(string)
    existing_resource_group = optional(string)
  })
  default = null
}

variable "vm_override" {
  description = "Override VM configuration"
  type = object({
    name             = optional(string)
    size             = optional(string)
    admin_username   = optional(string)
    ssh_key_path     = optional(string)
    create_public_ip = optional(bool)
    public_ip_sku    = optional(string)
  })
  default = null
}

variable "security_override" {
  description = "Override security configuration"
  type = object({
    rules = optional(list(object({
      name        = string
      port        = number
      protocol    = optional(string, "Tcp")
      source      = optional(string, "*")
      priority    = number
      description = optional(string, "")
    })))
    existing_nsg_name           = optional(string)
    existing_nsg_resource_group = optional(string)
  })
  default = null
}

variable "resource_group"   { type = any }
variable "network"          { type = any }
variable "vm"               { type = any }
variable "security"         { type = any }