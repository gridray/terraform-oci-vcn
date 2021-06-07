locals {
  anywhere      = "0.0.0.0/0"
  ipv6_anywhere = "::/0"

  all_anywhere = var.ipv6_enabled ? [local.anywhere, local.ipv6_anywhere] : [local.anywhere]
}

# VCN
resource "oci_core_vcn" "vcn" {
  count          = module.this.enabled ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = module.this.name
  freeform_tags  = module.this.tags

  cidr_block     = ""
  cidr_blocks    = var.cidr_blocks
  dns_label      = module.this.name
  is_ipv6enabled = var.ipv6_enabled
}

# VCN default Security List Lockdown
resource "oci_core_default_security_list" "lockdown" {
  count = module.this.enabled && var.lockdown_default_seclist ? 1 : 0

  // If variable is true, removes all rules from default security list
  manage_default_resource_id = oci_core_vcn.vcn[0].default_security_list_id

}

resource "oci_core_default_security_list" "restore_default" {
  count = module.this.enabled && !var.lockdown_default_seclist ? 1 : 0

  // If variable is false, restore all default rules to default security list
  manage_default_resource_id = oci_core_vcn.vcn[0].default_security_list_id

  dynamic "egress_security_rules" {
    for_each = local.all_anywhere

    content {
      // allow all egress traffic
      destination = egress_security_rules.value
      protocol    = "all"
    }
  }

  dynamic "ingress_security_rules" {
    for_each = local.all_anywhere
    content {
      // allow all SSH
      protocol = "6"
      source   = ingress_security_rules.value
      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = local.all_anywhere
    content {
      // allow ICMP for all type 3 code 4
      protocol = "1"
      source   = ingress_security_rules.value

      icmp_options {
        type = "3"
        code = "4"
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.cidr_blocks
    content {
      //allow all ICMP from VCN
      protocol = "1"
      source   = ingress_security_rules.value

      icmp_options {
        type = "3"
      }
    }
  }

}

# Internet Gateway
resource "oci_core_internet_gateway" "ig" {
  count = module.this.enabled && var.internet_gateway_enabled ? 1 : 0

  compartment_id = var.compartment_id

  display_name = "${module.this.name}-internet-gateway"

  freeform_tags = module.this.tags

  vcn_id = oci_core_vcn.vcn[0].id
}

resource "oci_core_route_table" "ig" {
  count = module.this.enabled && var.internet_gateway_enabled == true ? 1 : 0

  compartment_id = var.compartment_id

  display_name = "${module.this.name}-internet-gateway"

  freeform_tags = module.this.tags

  dynamic "route_rules" {
    # default routes to internet
    for_each = local.all_anywhere
    # * With this route table, Internet Gateway is always declared as the default gateway
    content {
      destination       = route_rules.value
      network_entity_id = oci_core_internet_gateway.ig[0].id
      description       = "Terraformed - Auto-generated at Internet Gateway creation: Internet Gateway as default gateway"
    }
  }

  dynamic "route_rules" {
    # * filter var.internet_gateway_route_rules for routes with "drg" as destination
    # * and steer traffic to the module created DRG
    for_each = var.internet_gateway_route_rules != null ? { for k, v in var.internet_gateway_route_rules : k => v
    if v.network_entity_id == "drg" } : {}

    content {
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = oci_core_drg.drg[0].id
      description       = route_rules.value.description
    }
  }

  dynamic "route_rules" {
    # * filter var.internet_gateway_route_rules for routes with "internet_gateway" as destination
    # * and steer traffic to the module created Internet Gateway
    for_each = var.internet_gateway_route_rules != null ? { for k, v in var.internet_gateway_route_rules : k => v
    if v.network_entity_id == "internet_gateway" } : {}

    content {
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = oci_core_internet_gateway.ig[0].id
      description       = route_rules.value.description
    }
  }

  dynamic "route_rules" {
    # * filter var.internet_gateway_route_rules for generic routes
    # * can take any Named Value : String, Input Variable, Local Value, Data Source, Resource, Module Output ...
    # * useful for gateways that are not managed by the module
    for_each = var.internet_gateway_route_rules != null ? { for k, v in var.internet_gateway_route_rules : k => v
    if contains(["drg", "internet_gateway"], v.network_entity_id) == false } : {}

    content {
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity_id
      description       = route_rules.value.description
    }
  }

  vcn_id = oci_core_vcn.vcn[0].id
}

# Service Gateway
data "oci_core_services" "all_oci_services" {
  count = module.this.enabled && var.service_gateway_enabled == true ? 1 : 0
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }

}

resource "oci_core_service_gateway" "service_gateway" {
  count = module.this.enabled && var.service_gateway_enabled == true ? 1 : 0

  compartment_id = var.compartment_id

  display_name = "${module.this.name}-service-gateway"

  freeform_tags = module.this.tags

  dynamic "services" {
    for_each = data.oci_core_services.all_oci_services[0].services
    content {
      service_id = services.value.id
    }
  }

  vcn_id = oci_core_vcn.vcn[0].id
}

# NAT Gateway
resource "oci_core_nat_gateway" "nat_gateway" {
  count = module.this.enabled && var.nat_gateway_enabled == true ? 1 : 0

  compartment_id = var.compartment_id

  display_name = "${module.this.name}-nat-gateway"

  freeform_tags = module.this.tags

  vcn_id = oci_core_vcn.vcn[0].id
}

resource "oci_core_route_table" "nat" {
  count = module.this.enabled && var.nat_gateway_enabled == true ? 1 : 0

  compartment_id = var.compartment_id

  display_name = "${module.this.name}-nat-gateway"

  freeform_tags = module.this.tags

  dynamic "route_rules" {
    for_each = local.all_anywhere
    # * With this route table, NAT Gateway is always declared as the default gateway
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_nat_gateway.nat_gateway[0].id
      description       = "Terraformed - Auto-generated at NAT Gateway creation: NAT Gateway as default gateway"
    }
  }

  dynamic "route_rules" {
    # * If Service Gateway is created with the module, automatically creates a rule to handle traffic for "all services" through Service Gateway
    for_each = var.service_gateway_enabled == true ? [1] : []

    content {
      destination       = lookup(data.oci_core_services.all_oci_services[0].services[0], "cidr_block")
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = oci_core_service_gateway.service_gateway[0].id
      description       = "Terraformed - Auto-generated at Service Gateway creation: All Services in region to Service Gateway"
    }
  }

  dynamic "route_rules" {
    # * filter var.nat_gateway_route_rules for routes with "drg" as destination
    # * and steer traffic to the module created DRG
    for_each = var.nat_gateway_route_rules != null ? { for k, v in var.nat_gateway_route_rules : k => v
    if v.network_entity_id == "drg" } : {}

    content {
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = oci_core_drg.drg[0].id
      description       = route_rules.value.description
    }
  }

  dynamic "route_rules" {
    # * filter var.nat_gateway_route_rules for routes with "nat_gateway" as destination
    # * and steer traffic to the module created NAT Gateway
    for_each = var.nat_gateway_route_rules != null ? { for k, v in var.nat_gateway_route_rules : k => v
    if v.network_entity_id == "nat_gateway" } : {}

    content {
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = oci_core_nat_gateway.nat_gateway[0].id
      description       = route_rules.value.description
    }
  }

  dynamic "route_rules" {
    # * filter var.internet_gateway_route_rules for generic routes
    # * can take any Named Value : String, Input Variable, Local Value, Data Source, Resource, Module Output ...
    # * useful for gateways that are not managed by the module
    for_each = var.nat_gateway_route_rules != null ? { for k, v in var.nat_gateway_route_rules : k => v
    if contains(["drg", "nat_gateway"], v.network_entity_id) == false } : {}

    content {
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
      network_entity_id = route_rules.value.network_entity_id
      description       = route_rules.value.description
    }
  }

  vcn_id = oci_core_vcn.vcn[0].id
}

# Dynamic Route Gateway
resource "oci_core_drg" "drg" {
  count          = module.this.enabled && var.drg_enabled == true ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = "${module.this.name}-drg"

  freeform_tags = module.this.tags
}

resource "oci_core_drg_attachment" "drg" {
  count = module.this.enabled && var.drg_enabled == true ? 1 : 0

  drg_id = oci_core_drg.drg[0].id
  vcn_id = oci_core_vcn.vcn[0].id
}