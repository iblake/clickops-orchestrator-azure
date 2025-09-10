# OCI modular orchestration pattern - consolidated dependency injection
# Allows external modules to override local JSON configurations
# Enables composition: parent modules can inject computed resources as dependencies
variable "module_dependencies" {
  type = object({
    resource_groups = optional(any, null)
    networks        = optional(any, null)
    security_groups = optional(any, null)
  })
  default     = {}
  description = "Optional dependencies from parent modules (overrides JSON configs)"
}

# Resource Configuration Patterns:
# - resource_id: null = create new resource, non-null = use existing resource by ID
# - optional fields with defaults reduce JSON configuration verbosity  
# - *_key fields reference keys from respective resource variables


variable "resource_groups" {
  type = map(object({
    name        = string
    location    = string
    resource_id = optional(string)
  }))
  default = {}
}

variable "networks" {
  type = map(object({
    resource_group_key = optional(string)
    resource_id        = optional(string)
    name               = string
    cidr               = optional(string)
    subnets = map(object({
      name        = string
      cidr        = optional(string)
      resource_id = optional(string)
    }))
  }))
  default = {}
}

variable "security_groups" {
  type = map(object({
    resource_group_key = optional(string)
    resource_id        = optional(string)
    name               = string
    rules = optional(list(object({
      name        = string
      port        = number
      protocol    = optional(string, "Tcp")
      source      = optional(string, "*")
      priority    = number
      description = optional(string, "")
    })), [])
  }))
  default = {}
}

variable "virtual_machines" {
  type = map(object({
    resource_group_key = string
    network_key        = string
    subnet_key         = string
    security_group_key = string
    name               = string
    size               = string
    admin_username     = string
    ssh_key_path       = optional(string, "~/.ssh/azure_vm_key.pub")
    create_public_ip   = optional(bool, true)
    public_ip_sku      = optional(string, "Basic")
  }))
  default = {}

  # Free Tier Compliance: Validation rules reference centralized constants from validations.tf
  # This pattern enables shared validation logic across multiple resource types
  validation {
    condition     = alltrue([for vm in var.virtual_machines : contains(local.validation_config.valid_vm_sizes, vm.size)])
    error_message = local.validation_config.vm_size_error_template
  }

  validation {
    condition     = alltrue([for vm in var.virtual_machines : contains(local.validation_config.valid_public_ip_skus, vm.public_ip_sku)])
    error_message = local.validation_config.public_ip_sku_error_template
  }
}