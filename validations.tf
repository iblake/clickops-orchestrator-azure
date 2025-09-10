# Azure Free Tier Compliance Validations
# This file centralizes all validation constants and helper functions for better maintainability

locals {
  # Free Tier Compliance Constants - Centralized configuration
  validation_config = {
    # VM Sizes allowed for Azure Free Tier (750 hours/month each)
    valid_vm_sizes = [
      "Standard_B1s",      # 1 vCPU, 1GB RAM - Intel x86
      "Standard_B2pts_v2", # 2 vCPU, 1GB RAM - ARM-based Ampere Altra  
      "Standard_B2ats_v2"  # 2 vCPU, 1GB RAM - AMD EPYC
    ]

    # Public IP SKUs allowed for Azure Free Tier 
    valid_public_ip_skus = [
      "Basic" # Only Basic SKU allowed (Azure free tier: 1,500 hours/month)
    ]

    # Error message templates
    vm_size_error_template       = "Only Azure free tier VM sizes are supported: Standard_B1s (1 vCPU, 1GB), Standard_B2pts_v2 (2 vCPU, 1GB ARM), Standard_B2ats_v2 (2 vCPU, 1GB AMD)"
    public_ip_sku_error_template = "Only Basic SKU public IPs are supported (Azure free tier includes 1,500 hours/month)"
  }
}