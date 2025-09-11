# Azure Landing Zones Orchestrator

An Azure infrastructure orchestrator implementing the **OCI pattern** for creating free-tier Azure infrastructure using Terraform and modular JSON configurations. Supports both creating new resources and using existing infrastructure seamlessly.

## Architecture Overview

This orchestrator implements a hybrid resource management system with:

- **Resource-based JSON files** organized by resource types (Resource Groups, Networks, Security, Compute)
- **Key-based references** for automatic dependency resolution
- **Hybrid resource discovery**: automatically detects whether to create new resources or use existing ones
- **Azure Verified Modules** for all infrastructure components
- **Free tier compliance** built-in validations

## How It Works

### Resource Detection

The orchestrator automatically determines whether to create or reference resources based on JSON configuration:

#### New Resources (Created by Terraform)
When no `resource_id` is provided, Terraform creates the resource using Azure Verified Modules.

```json
{
  "resource_groups": {
    "rg-demo": {
      "name": "rg-free-demo",
      "location": "eastus"
    }
  }
}
```

#### Existing Resources (Discovered via Data Sources) 
When `resource_id` is provided, Terraform discovers and references the existing Azure resource.

```json
{
  "resource_groups": {
    "rg-existing": {
      "name": "existing-resource-group", 
      "location": "eastus",
      "resource_id": "/subscriptions/.../resourceGroups/existing-resource-group"
    }
  }
}
```

### Key-Based Reference System

Resources reference each other using descriptive keys, automatically resolved by the orchestrator:

```json
{
  "virtual_machines": {
    "vm-web": {
      "resource_group_key": "rg-demo",     // → resolves to "rg-demo"
      "network_key": "vnet-demo",          // → resolves to VNet resource ID
      "subnet_key": "subnet-public",       // → resolves to subnet resource ID
      "security_group_key": "nsg-web",     // → resolves to NSG resource ID
      "name": "vm-web-server",
      "size": "Standard_B1s",
      "admin_username": "azureuser",
      "ssh_key_path": "~/.ssh/azure_vm_key.pub"
    }
  }
}
```

## Usage Scenarios

### Prerequisites

**For GitHub Actions Deployment (Highly Recommended):**
- GitHub repository with the azure-terraform.yaml workflow configured
- Self-hosted runner in OCI (Instance Principal) with Azure and OCI credentials (backet for terraform state) configured
- SSH key pair available at `~/.ssh/azure_vm_key.pub` on the runner

**For Local Development/Testing (Optional):**
```bash
# Generate SSH key pair for VM access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key -N ""

# Azure authentication (choose one)
az login  # Option 1: Azure CLI
# OR set environment variables for Service Principal (Option 2)
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret" 
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
```

### Scenario 1: Create Complete New Infrastructure

Deploy everything from scratch - Resource Group, VNet, NSG, and VMs.

**Via GitHub Actions (Recommended):**
1. Configure your JSON files in the `config/` directory
2. Create a Pull Request with your changes
3. GitHub Actions automatically runs `terraform plan` and posts results as PR comment
4. Merge the PR to trigger automatic deployment via GitHub Actions

**Via Local Terraform (Development/Testing):**
```bash
terraform init

# Deploy complete infrastructure with explicit var-files
terraform apply \
  -var-file=config/resource-groups.json \
  -var-file=config/networks.json \
  -var-file=config/security-groups.json \
  -var-file=config/virtual-machines.json
```

**Result**: Creates ~18 Azure resources (RG + VNet + Subnets + NSG + VM + Public IP + NIC + Disk)

### Scenario 2: Deploy VMs on Existing Infrastructure

Use existing network infrastructure and deploy only virtual machines.

**Step 1**: Modify your JSON configs to reference existing resources by adding `resource_id`:

> **Important**: For existing networks, subnets are automatically treated as existing. Only specify the subnet name - do not add individual `resource_id` fields for subnets.

```json
// config/resource-groups.json
{
  "resource_groups": {
    "rg-existing": {
      "name": "my-existing-rg",
      "location": "eastus", 
      "resource_id": "/subscriptions/your-sub-id/resourceGroups/my-existing-rg"
    }
  }
}

// config/networks.json  
{
  "networks": {
    "vnet-existing": {
      "resource_group_key": "rg-existing",
      "name": "my-existing-vnet",
      "resource_id": "/subscriptions/your-sub-id/resourceGroups/my-existing-rg/providers/Microsoft.Network/virtualNetworks/my-existing-vnet",
      "subnets": {
        "subnet-existing": {
          "name": "my-existing-subnet"
        }
      }
    }
  }
}
```

**Step 2**: Deploy the configuration:

**Via GitHub Actions (Recommended):**
1. Create a Pull Request with your modified JSON configurations
2. GitHub Actions runs `terraform plan` and shows what will be created
3. Review the plan in the PR comment
4. Merge the PR to trigger automatic deployment

**Via Local Terraform (Development/Testing):**
```bash
# Deploy VMs on existing infrastructure
terraform apply \
  -var-file=config/resource-groups.json \
  -var-file=config/networks.json \
  -var-file=config/security-groups.json \
  -var-file=config/virtual-machines.json
```

**Result**: Creates only VM and associated components (~7 Azure resources), uses existing network infrastructure

## CI/CD Integration

### Backend Configuration

The orchestrator uses **OCI Object Storage** as Terraform backend for state management:

- **`versions.tf.template`**: Template with OCI backend configuration using environment variables
- **`versions.tf`**: Generated file during workflow execution (git-ignored)
- **Runtime Generation**: Workflow uses `envsubst` to replace environment variables:
  ```bash
  envsubst < versions.tf.template > versions.tf
  ```

**Required Environment Variables** (set in `$HOME/.github-runner-env`):
```bash
# Azure Service Principal Credentials  
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret" 
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id"

# OCI Backend Configuration
export OCI_TF_STATE_BUCKET="terraform-state-bucket"
export OCI_TF_STATE_NAMESPACE="your-oci-namespace"
export OCI_REGION="eu-frankfurt-1"
```

### GitHub Actions Workflow

This repository uses the `azure-terraform.yaml` workflow for automated deployments:

#### Active Workflows

**Main Workflow: `azure-terraform.yaml`**
- **External Orchestrator Pattern**: Clones external repository for Terraform code
- **Runner-First Security**: All credentials stored on self-hosted runner (not GitHub)
- **Explicit Configuration**: Uses explicit var-file declarations for all JSON configurations
- **OCI Backend Support**: Terraform state stored in OCI Object Storage with Instance Principal auth  
- **SSH Key Management**: OCI Landing Zones pattern with file-based SSH key validation
- **PR Integration**: Detailed plan outputs posted as PR comments
- **Auto-Apply on Merge**: Infrastructure deployed automatically when PRs are merged
- **Secure Logging**: Azure login output hidden to prevent credential exposure

### Workflow Triggers

**Main Workflow (`azure-terraform.yaml`)**
- **Pull Requests**: Automatic `terraform plan` with detailed output posted as PR comment
- **PR Merge**: Automatic `terraform apply` when PR is merged to main
- **Manual Dispatch**: On-demand execution with environment selection (dev/staging/prod)

## Azure Free Tier Compliance

Built-in constraints ensure free tier compatibility:

- **VM Sizes**: 3 free tier options (750 hours/month each):
  - `Standard_B1s` (1 vCPU, 1GB RAM) - Most compatible
  - `Standard_B2pts_v2` (2 vCPU, 1GB RAM, ARM) - More efficient  
  - `Standard_B2ats_v2` (2 vCPU, 1GB RAM, AMD) - Higher performance
- **Storage**: `Standard_LRS` disk type, 30GB OS disk
- **Public IP**: `Basic` SKU only (1,500 hours/month free)
- **Authentication**: SSH keys only (no passwords)
- **OS**: Ubuntu 20.04 LTS

## Adding Resources

### Adding a Second VM

```json
{
  "virtual_machines": {
    "vm-web": { ... },
    "vm-app": {
      "resource_group_key": "rg-demo",
      "network_key": "vnet-demo",
      "subnet_key": "subnet-public", 
      "security_group_key": "nsg-web",
      "name": "vm-app-server",
      "size": "Standard_B2pts_v2",
      "admin_username": "azureuser",
      "ssh_key_path": "~/.ssh/azure_vm_key.pub",
      "create_public_ip": false
    }
  }
}
```

### Adding New Subnets

```json
{
  "networks": {
    "vnet-demo": {
      "resource_group_key": "rg-demo",
      "name": "vnet-free-demo", 
      "cidr": "10.0.0.0/16",
      "subnets": {
        "subnet-public": {
          "name": "subnet-public",
          "cidr": "10.0.1.0/24"
        },
        "subnet-private": {
          "name": "subnet-private", 
          "cidr": "10.0.2.0/24"
        }
      }
    }
  }
}
```
