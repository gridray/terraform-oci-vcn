provider "oci" {
  region = var.region
}

module "vcn" {

  source = "../../"

  name    = "testvcn1"
  context = module.this.context

  # general oci parameters
  compartment_id = var.compartment_id

  # vcn parameters
  drg_enabled              = false           # boolean: true or false
  internet_gateway_enabled = true            # boolean: true or false
  lockdown_default_seclist = false           # boolean: true or false
  nat_gateway_enabled      = true            # boolean: true or false
  service_gateway_enabled  = true            # boolean: true or false
  cidr_blocks              = var.cidr_blocks # VCN CIDR
}