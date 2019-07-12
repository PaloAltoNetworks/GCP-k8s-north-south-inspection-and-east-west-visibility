// Configure the Google Cloud provider
provider "google" {
  credentials = "${file(var.credentials_file_path)}"
  project     = "${var.my_gcp_project}"
  region      = "${var.region}"
}

// Adding SSH Public Key Project Wide
resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "${var.gce_ssh_user}:${var.gce_ssh_pub_key}"
}


// Adding VPC Networks to Project  MANAGEMENT
resource "google_compute_subnetwork" "management-sub" {
  name          = "management-sub"
  ip_cidr_range = "10.5.0.0/24"
  network       = "${google_compute_network.management.self_link}"
  region        = "${var.region}"
}

resource "google_compute_network" "management" {
  name                    = "${var.interface_0_name}"
  auto_create_subnetworks = "false"
}

// Adding VPC Networks to Project  UNTRUST
resource "google_compute_subnetwork" "untrust-sub" {
  name          = "untrust-sub"
  ip_cidr_range = "10.5.1.0/24"
  network       = "${google_compute_network.untrust.self_link}"
  region        = "${var.region}"
}

resource "google_compute_network" "untrust" {
  name                    = "${var.interface_1_name}"
  auto_create_subnetworks = "false"
}

// Adding VPC Networks to Project  TRUST
resource "google_compute_subnetwork" "trust-sub" {
  name          = "trust-sub"
  ip_cidr_range = "10.5.2.0/24"
  network       = "${google_compute_network.trust.self_link}"
  region        = "${var.region}"
}

resource "google_compute_network" "trust" {
  name                    = "${var.interface_2_name}"
  auto_create_subnetworks = "false"
}

// Adding GCP Route to TRUST Interface
resource "google_compute_route" "trust" {
  name                   = "trust-route"
  dest_range             = "0.0.0.0/0"
  network                = "${google_compute_network.trust.self_link}"
  next_hop_instance      = "${element(google_compute_instance.firewall.*.name,count.index)}"
  next_hop_instance_zone = "${var.zone}"
  priority               = 1001

  depends_on = ["google_compute_instance.firewall",
    "google_compute_network.trust",
    "google_compute_network.untrust",
    "google_compute_network.management",
  ]
}

// Adding GCP Firewall Rules for MANGEMENT
resource "google_compute_firewall" "allow-mgmt" {
  name    = "allow-mgmt"
  network = "${google_compute_network.management.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["443", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Adding GCP Firewall Rules for INBOUND
resource "google_compute_firewall" "allow-inbound" {
  name    = "allow-inbound"
  network = "${google_compute_network.untrust.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Adding GCP Firewall Rules for OUTBOUND
resource "google_compute_firewall" "allow-outbound" {
  name    = "allow-outbound"
  network = "${google_compute_network.trust.self_link}"

  allow {
    protocol = "all"

    # ports    = ["all"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Create a new Palo Alto Networks NGFW VM-Series GCE instance
resource "google_compute_instance" "firewall" {
  name                      = "${var.firewall_name}-${count.index + 1}"
  machine_type              = "${var.machine_type_fw}"
  zone                      = "${var.zone}"
  can_ip_forward            = true
  allow_stopping_for_update = true
  count                     = 1

  // Adding METADATA Key Value pairs to VM-Series GCE instance
  metadata {
    vmseries-bootstrap-gce-storagebucket = "${var.bootstrap_bucket_fw}"
    serial-port-enable = true
    #sshKeys                              = "${var.public_key}"
  }

  service_account {
    scopes = "${var.scopes_fw}"
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.management-sub.self_link}"
    network_ip       = "10.5.0.4"
    access_config = {}
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.untrust-sub.self_link}"
    network_ip       = "10.5.1.4"
    access_config = {}
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.trust-sub.self_link}"
    network_ip    = "10.5.2.4"
  }

  boot_disk {
    initialize_params {
      image = "${var.image_fw}"
    }
  }
  depends_on = [
    "google_container_cluster.cluster",
    "google_compute_network.trust",
    "google_compute_subnetwork.trust-sub"
  ]
}
//Create a K8s cluster
resource "google_container_cluster" "cluster" {
  name               = "cluster-1"
  zone               = "${var.zone}"
  min_master_version = "1.12.8-gke.10"
  initial_node_count = 2

  logging_service    = "none"
  monitoring_service = "none"
  network = "${google_compute_network.trust.self_link}"
  subnetwork = "${google_compute_subnetwork.trust-sub.self_link}"

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  addons_config {
    http_load_balancing {
      disabled = true
    }
  }

  node_config {
    disk_size_gb = "32"
    image_type   = "ubuntu"
    machine_type = "n1-standard-1"
    preemptible  = false
    oauth_scopes = ["monitoring"]
    labels {
      pool    = "default-pool"
      cluster = "the-cluster"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    "google_compute_network.trust",
    "google_compute_subnetwork.trust-sub"
  ]
}

// Create VPC route for cluster outbound access - bypass firewall
resource "google_compute_route" "apiserver-outbound" {
  name                   = "apiserver-outbound"
  dest_range             = "${google_container_cluster.cluster.endpoint}/32"
  network                = "${google_compute_network.trust.self_link}"
  next_hop_gateway       = "default-internet-gateway"
  priority               = 1001

  depends_on = ["google_container_cluster.cluster"]
}
output "pan-tf-trust-ip" {
  value = "${google_compute_instance.firewall.*.network_interface.2.address}"
}

output "pan-tf-name" {
  value = "${google_compute_instance.firewall.*.name}"
}

output "k8s-cluster-name" {
  value = "${google_container_cluster.cluster.*.name}"
}

output "k8s-cluster-endpoint" {
  value = "${google_container_cluster.cluster.endpoint}"
}