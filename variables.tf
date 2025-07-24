# Simple variables for JSON inputs (no nested objects)
variable "resource_group" {
  description = "Resource group configuration"
  type = object({
    # For new resource group
    name     = optional(string)
    location = optional(string)

    # For existing resource group (simple name)
    existing_name = optional(string)
  })
  default = {
    name          = null
    location      = null
    existing_name = null
  }
}

variable "network" {
  description = "Network configuration"
  type = object({
    # For new network
    vnet_name   = optional(string)
    vnet_cidr   = optional(string)
    subnet_name = optional(string)
    subnet_cidr = optional(string)

    # For existing network (simple names, not IDs)
    existing_vnet_name      = optional(string)
    existing_subnet_name    = optional(string)
    existing_resource_group = optional(string)
  })
  default = {
    vnet_name               = null
    vnet_cidr               = null
    subnet_name             = null
    subnet_cidr             = null
    existing_vnet_name      = null
    existing_subnet_name    = null
    existing_resource_group = null
  }
}

variable "vm" {
  description = "VM configuration"
  type = object({
    name             = string
    size             = string
    admin_username   = string
    ssh_key_path     = string
    create_public_ip = optional(bool, true)
    public_ip_sku    = optional(string, "Basic")
  })
  default = {
    name             = "default-vm"
    size             = "Standard_B1s"
    admin_username   = "azureuser"
    ssh_key_path     = "~/.ssh/azure_vm_key.pub"
    create_public_ip = true
    public_ip_sku    = "Basic"
  }
}

variable "security" {
  description = "Security configuration"
  type = object({
    # For new NSG with rules
    rules = optional(list(object({
      name        = string
      port        = number
      protocol    = optional(string, "Tcp")
      source      = optional(string, "*")
      priority    = number
      description = optional(string, "")
    })), [])

    # For existing NSG (simple names)
    existing_nsg_name           = optional(string)
    existing_nsg_resource_group = optional(string)
  })
  default = {
    rules                       = []
    existing_nsg_name           = null
    existing_nsg_resource_group = null
  }
}