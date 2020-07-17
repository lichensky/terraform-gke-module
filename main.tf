# Local values
locals {
  name                = "${var.environment}-${var.name}"
  pods_range_name     = "${local.name}-pods"
  services_range_name = "${local.name}-services"
}

# GKE subnetwork
resource "google_compute_subnetwork" "cluster_subnetwork" {
  name          = local.name
  ip_cidr_range = var.subnetwork_range
  region        = var.region
  network       = var.vpc_network

  # Create secondary ranges for pods
  secondary_ip_range {
    range_name    = local.pods_range_name
    ip_cidr_range = var.subnetwork_pods_range
  }

  # Create secondary ranges for services
  secondary_ip_range {
    range_name    = local.services_range_name
    ip_cidr_range = var.subnetwork_services_range
  }
}

# GKE cluster
resource "google_container_cluster" "cluster" {
  location = var.region
  name     = local.name

  # Set maintenance policy. Start time is in UTC.
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.daily_maintenance_window_start_time
    }
  }

  # Private cluster config
  private_cluster_config {
    # Wheter master endpoint shoud be private
    enable_private_endpoint = var.enable_private_endpoint
    # Wheter nodes should have only private IP addresses
    enable_private_nodes    = var.enable_private_nodes
    # Specify master VPC CIDR block. Master VPC is managed by Google.
    # When nodes are private GCP creates peering between master and nodes VPC.
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # When the private endpoint is disabled the access can be limited to
  # authorized networks.
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Use calico to enable network policies
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  master_auth {
    # Set an empty username and password to explicitly disable basic auth
    username = ""
    password = ""

    # Whether client certificate authorization is enabled for this cluster.
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # The configuration for addons supported by GKE.
  addons_config {
    # Whether the network policy should be enabled for master.
    network_policy_config {
      disabled = false
    }
  }

  # Network settings
  network    = var.vpc_network
  subnetwork = google_compute_subnetwork.cluster_subnetwork.self_link

  # Configure IP aliases for VPC-native cluster.
  ip_allocation_policy {
    cluster_secondary_range_name  = local.pods_range_name
    services_secondary_range_name = local.services_range_name
  }

  # It is impossible to create cluster with custom node pools.
  # Remove default node pool after cluster creation.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Increase default timeout
  timeouts {
    update = "20m"
  }
}

# Cluster node pools
resource "google_container_node_pool" "node_pool" {
  for_each = { for pool in var.node_pools : pool.name => pool }

  # The cluster location
  location = google_container_cluster.cluster.location

  # Node pool name
  name = each.value.name

  # Cluster name
  cluster = google_container_cluster.cluster.name

  # Node scaling properties
  initial_node_count = each.value.initial_node_count
  autoscaling {
    # Minimum number of nodes in the node pool.
    min_node_count = each.value.min_node_count

    # Maximum number of nodes in the node pool
    max_node_count = each.value.max_node_count
  }

  # Node management configuration
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node parameters
  node_config {
    # Node machine type
    machine_type    = each.value.machine_type

    # Assign created service account to the nodes
    service_account = google_service_account.cluster.email

    # Size of the node persistent disk
    disk_size_gb = each.value.disk_size

    # Type of the node disk
    disk_type = each.value.disk_type

    # Set full platform access and limit persmissions by service account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  # Increase default timeout
  timeouts {
    update = "20m"
  }
}
