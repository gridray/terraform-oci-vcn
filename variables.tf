variable "region" {
  type        = string
  description = "OCI Region"
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  type        = string
  description = "Compartment id where vcn should be created"
}

variable "cidr_blocks" {
  type        = list(string)
  description = "list of cidr blocks to be provisioned in vcn"
}

variable "drg_enabled" {
  type        = bool
  description = "should Dynamic Route Gateway be enabled in VCN"
  default     = true
}

variable "internet_gateway_enabled" {
  type        = bool
  description = "should Internet Gateway be enabled in VCN"
  default     = true
}

variable "internet_gateway_route_rules" {
  description = "(Updatable) List of routing rules to add to Internet Gateway Route Table"
  type = list(object({
    destination       = string
    destination_type  = string
    network_entity_id = string
    description       = string
  }))
  default = null
}


variable "ipv6_enabled" {
  type        = bool
  description = "Is IPV6 to be enabled in the vcn"
  default     = true
}

variable "lockdown_default_seclist" {
  description = "whether to remove all default security rules from the VCN Default Security List"
  default     = true
  type        = bool
}

variable "nat_gateway_enabled" {
  type        = bool
  description = "should NAT Gateway be enabled in VCN"
  default     = true
}

variable "nat_gateway_route_rules" {
  description = "(Updatable) List of routing rules to add to NAT Gateway Route Table"
  type = list(object({
    destination       = string
    destination_type  = string
    network_entity_id = string
    description       = string
  }))
  default = null
}

variable "service_gateway_enabled" {
  type        = bool
  description = "should Service Gateway be enabled in VCN"
  default     = true
}