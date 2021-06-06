variable "region" {
  type        = string
  description = "OCI region"
}

variable "compartment_id" {
  type = string
}

variable "cidr_blocks" {
  type = list(string)
}