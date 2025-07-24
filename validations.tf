################################################################################
# SIMPLE VALIDATIONS - Free Tier Compliance
################################################################################

# Free-tier allowed resources
locals {
  allowed_vm_sizes = ["Standard_B1s", "Standard_B1ms"]
}

################################################################################
# VM Size Validation
################################################################################
resource "null_resource" "vm_size_validation" {
  lifecycle {
    precondition {
      condition     = contains(local.allowed_vm_sizes, var.vm.size)
      error_message = "VM size '${var.vm.size}' not allowed in free tier. Use: ${join(", ", local.allowed_vm_sizes)}"
    }
  }
}

################################################################################
# SSH Key Validation
################################################################################
resource "null_resource" "ssh_key_validation" {
  lifecycle {
    precondition {
      condition     = fileexists(abspath(pathexpand(var.vm.ssh_key_path)))
      error_message = "SSH key file '${var.vm.ssh_key_path}' not found. Generate with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key -N ''"
    }
  }
}

################################################################################
# Resource Group Configuration Validation
################################################################################
resource "null_resource" "rg_validation" {
  count = var.resource_group.existing_name != null || var.resource_group.name != null ? 1 : 0
  lifecycle {
    precondition {
      condition = (
        # Either use existing RG (name only required)
        var.resource_group.existing_name != null ||
        # Or create new RG (both name and location required)
        (var.resource_group.name != null && var.resource_group.location != null)
      )
      error_message = "Resource Group config: Either provide existing_name OR both name and location for new RG"
    }
  }
}

################################################################################
# Security Configuration Validation  
################################################################################
resource "null_resource" "security_validation" {
  count = var.security.existing_nsg_name != null || length(var.security.rules) > 0 ? 1 : 0
  lifecycle {
    precondition {
      condition = (
        # Either use existing NSG (both fields required)
        (var.security.existing_nsg_name != null && var.security.existing_nsg_resource_group != null) ||
        # Or create new NSG (rules can be empty list)
        var.security.existing_nsg_name == null
      )
      error_message = "Security config: For existing NSG provide both existing_nsg_name and existing_nsg_resource_group"
    }
  }
}

################################################################################
# Network Configuration Validation
################################################################################
resource "null_resource" "network_validation" {
  count = var.network.existing_vnet_name != null || var.network.vnet_name != null ? 1 : 0
  lifecycle {
    precondition {
      condition = (
        # Either use existing network (all 3 fields required)
        (var.network.existing_vnet_name != null &&
          var.network.existing_subnet_name != null &&
        var.network.existing_resource_group != null) ||
        # Or create new network (all 4 fields required)
        (var.network.vnet_name != null &&
          var.network.vnet_cidr != null &&
          var.network.subnet_name != null &&
        var.network.subnet_cidr != null)
      )
      error_message = "Network config: Either provide existing network (existing_vnet_name, existing_subnet_name, existing_resource_group) OR new network (vnet_name, vnet_cidr, subnet_name, subnet_cidr)"
    }

    precondition {
      condition = (
        var.network.existing_vnet_name != null ||
        (var.network.vnet_cidr != null && var.network.subnet_cidr != null && can(cidrhost(var.network.vnet_cidr, 0)) && can(cidrhost(var.network.subnet_cidr, 0)))
      )
      error_message = "Invalid CIDR format for new network. VNet: '${var.network.vnet_cidr != null ? var.network.vnet_cidr : "null"}', Subnet: '${var.network.subnet_cidr != null ? var.network.subnet_cidr : "null"}'"
    }
  }
}