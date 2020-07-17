variable "environment" {
  type        = string
  description = "Environment name"
}

variable "name" {
  type        = string
  description = "GKE cluster name"
}

variable "region" {
  type        = string
  description = "GCP region within cluster is deployed."
}

variable "location" {
  type        = string
  description = "Cluster location (can be regional or zonal)"
}

variable "vpc_network" {
  type        = string
  description = "VPC network name or self-link"
}

variable "subnetwork_range" {
  type        = string
  description = "GKE subnetwork CIDR range"
}

variable "subnetwork_pods_range" {
  type        = string
  description = "Subnetwork secondary CIDR range for pods."
}

variable "subnetwork_services_range" {
  type        = string
  description = "Subnetwork secondary CIDR range for services."
}

variable "daily_maintenance_window_start_time" {
  type        = string
  description = "Daily maintenance window start time in UTC"
  default     = "03:00"
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Wheter master should use internal address as cluster endpoint"
  default     = false
}

variable "enable_private_nodes" {
  type        = bool
  description = "Whether nodes have internal IP addresses only."
  default     = true
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "CIDR block for master subnet. Required if nodes are private."
  default     = "172.16.0.16/28"
}

variable "master_authorized_networks" {
  type = set(object({
    cidr_block   = string
    display_name = string
  }))
  default     = []
  description = <<EOF
    CIDR ranges for master authorized networks. Authorized networks are used
    to limit the access when cluster has public endpoint enabled.
  EOF
}

variable "node_pools" {
  description = <<EOF
    Node pools definition. Each node pool should include:

    General:
    --------
    name - node pool name
    initial_node_count - initial nodes number

    Autoscaling:
    ------------
    min_node_count - minimum node number in pool
    max_node_count - maximum node number in pool

    Machine parameters:
    -------------------
    machine_type - node machine type (e.g. n1-standard-1)
    disk_size - size of the disk attached to node (in GB)
    disk_type - type of the disk attached to node (e.g. pg-standard, pd-ssd)

    NOTE: if cluster is regional the node pools will be replicated in each
    zone.
  EOF

  type = set(object({
    name               = string
    initial_node_count = number
    min_node_count     = number
    max_node_count     = number
    machine_type       = string
    disk_size          = number
    disk_type          = string
  }))

  default = []
}
