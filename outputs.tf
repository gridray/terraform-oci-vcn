output "vcn_id" {
  description = "id of vcn that is created"
  value       = join(",", oci_core_vcn.vcn[*].id)
}

output "drg_id" {
  description = "id of drg if it is created"
  value       = join(",", oci_core_drg.drg[*].id)
}

output "nat_gateway_id" {
  description = "id of nat gateway if it is created"
  value       = join(",", oci_core_nat_gateway.nat_gateway[*].id)
}

output "internet_gateway_id" {
  description = "id of internet gateway if it is created"
  value       = join(",", oci_core_internet_gateway.ig[*].id)
}

output "service_gateway_id" {
  description = "id of service gateway if it is created"
  value       = join(",", oci_core_service_gateway.service_gateway[*].id)
}

output "ig_route_id" {
  description = "id of internet gateway route table"
  value       = join(",", oci_core_route_table.ig[*].id)
}

output "nat_route_id" {
  description = "id of VCN NAT gateway route table"
  value       = join(",", oci_core_route_table.nat[*].id)
}


# All attributes

output "drg_all_attributes" {
  description = "all attributes of created drg"
  value       = length(oci_core_drg.drg) == 1?{ for k, v in oci_core_drg.drg[0] : k => v }: null
}

output "drg_attachment_all_attributes" {
  description = "all attributes related to drg attachment"
  value       = length(oci_core_drg_attachment.drg) == 1?{ for k, v in oci_core_drg_attachment.drg[0] : k => v }: null
}

output "internet_gateway_all_attributes" {
  description = "all attributes of created internet gateway"
  value       = length(oci_core_internet_gateway.ig) == 1?{ for k, v in oci_core_internet_gateway.ig[0] : k => v }: null
}

output "ig_route_all_attributes" {
  description = "all attributes of created ig route table"
  value       = length(oci_core_route_table.ig) == 1?{ for k, v in oci_core_route_table.ig[0] : k => v }: null
}

output "nat_gateway_all_attributes" {
  description = "all attributes of created nat gateway"
  value       = length(oci_core_nat_gateway.nat_gateway) == 1?{ for k, v in oci_core_nat_gateway.nat_gateway[0] : k => v }: null
}

output "nat_route_all_attributes" {
  description = "all attributes of created nat gateway route table"
  value       = length(oci_core_route_table.nat) == 1?{ for k, v in oci_core_route_table.nat[0] : k => v }: null
}

output "service_gateway_all_attributes" {
  description = "all attributes of created service gateway"
  value       = length(oci_core_service_gateway.service_gateway) == 1?{ for k, v in oci_core_service_gateway.service_gateway[0] : k => v }: null
}

output "vcn_all_attributes" {
  description = "all attributes of created vcn"
  value       = length(oci_core_vcn.vcn) == 1?{ for k, v in oci_core_vcn.vcn[0] : k => v }: null
}