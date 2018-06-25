// PROJECT Variables
variable "my_gcp_project" {
  default = "Your_Project_ID"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "credentials_file_path" {
  description = "Path to the JSON file used to describe your account credentials"
  default     = "/GCP/k8s-lab/djs-gcp-2018-creds.json"
}

variable "gce_ssh_user" {
  description = " ssh user that is used in the public key"
  default = "dspears@SJCMAC3024G8WL"
  }

variable "gce_ssh_pub_key" {
  description = " ssh key in the format:  ssh-rsa <key> username "
  default = "ssh-rsa LM4L63uRouhKaV7VyU/W2skcItmsdlyBIec/vqdHpjqOicOZUo7XFxBc86sCfHB4IcKQ0B dspears@SJCMAC3024G8WL"}

//The rest of the variables do not need to be modified for the K8s Lab
// VM-Series Firewall Variables 

variable "firewall_name" {
  default = "firewall"
}

variable "image_fw" {
  default = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-bundle1-810"
}

variable "machine_type_fw" {
  default = "n1-standard-4"
}

variable "bootstrap_bucket_fw" {
  default = "gcp-2018-djs"
}

variable "interface_0_name" {
  default = "management"
}

variable "interface_1_name" {
  default = "untrust"
}

variable "interface_2_name" {
  default = "trust"
}

variable "scopes_fw" {
  default = ["https://www.googleapis.com/auth/cloud.useraccounts.readonly",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
  ]
}
