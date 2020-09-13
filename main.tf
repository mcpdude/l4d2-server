/*
Connect with friends via a shared digital space in l4d2.

This is a safe l4d2 server that won't break the bank. Game data is preserved across sessions.
Server is hosted on a permenant IP address. You need to start the VM each session, but it
will shutdown within 24 hours if you forget to turn it off.
Process is run in a sandboxed VM, so any server exploits cannot do any serious damage.

We are experimenting with providing support through a [google doc](https://docs.google.com/document/d/1TXyzHKqoKMS-jY9FSMrYNLEGathqSG8YuHdj0Z9GP34).
Help us make this simple for others to use by asking for help.


Features
- Runs [itzg/l4d2-server](https://hub.docker.com/r/itzg/l4d2-server/) Docker image
- Preemtible VM (cheapest), shuts down automatically within 24h if you forget to stop the VM
- Reserves a stable public IP, so the l4d2 clients do not need to be reconfigured
- Reserves the disk, so game data is remembered across sessions
- Restricted service account, VM has no ability to consume GCP resources beyond its instance and disk
- 2$ per month
  - Reserved IP address costs: $1.46 per month
  - Reserved 10Gb disk costs: $0.40
  - VM cost: $0.01 per hour, max session cost $0.24
*/

# We require a project to be provided upfront
# Create a project at https://cloud.google.com/
# Make note of the project ID
# We need a storage bucket created upfront too to store the terraform state
terraform {
  backend "gcs" {
    prefix = "l4d2/state"
    bucket = "l4d2"
  }
}

# You need to fill these locals out with the project, region and zone
# Then to boot it up, run:-
#   gcloud auth application-default login
#   terraform init
#   terraform apply
locals {
  # The Google Cloud Project ID that will host and pay for your l4d2 server
  project = "l4d2-287614"
  region  = "us-west2"
  zone    = "us-west2-a"
  # Allow members of an external Google group to turn on the server
  # through the Cloud Console mobile app or https://console.cloud.google.com
  # Create a group at https://groups.google.com/forum/#!creategroup
  # and invite members by their email address.
  # enable_switch_access_group = 1
  # l4d2_switch_access_group = "l4d2-switchers-lark@googlegroups.com"
}


provider "google" {
  project = local.project
  region  = local.region
}

# Create service account to run service with no permissions
resource "google_service_account" "l4d2" {
  account_id   = "leftfordead"
  display_name = "leftfordead"
}

# Permenant l4d2 disk, stays around when VM is off
resource "google_compute_disk" "l4d2" {
  name  = "l4d2"
  type  = "pd-standard"
  zone  = local.zone
  image = "cos-cloud/cos-stable"
  size  = 20
}

# Permenant IP address, stays around when VM is off
resource "google_compute_address" "l4d2" {
  name   = "l4d2-ip"
  region = local.region
}

# VM to run l4d2, we use preemptable which will shutdown within 24 hours
resource "google_compute_instance" "l4d2" {
  name         = "l4d2"
  machine_type = "c2-standard-4"
  zone         = local.zone
  tags         = ["l4d2"]

  # Run itzg/l4d2-server docker image on startup
  # The instructions of https://hub.docker.com/r/itzg/l4d2-server/ are applicable
  # For instance, Ssh into the instance and you can run
  #  docker logs mc
  #  docker exec -i mc rcon-cli
  # Once in rcon-cli you can "op <player_id>" to make someone an operator (admin)
  # Use 'sudo journalctl -u google-startup-scripts.service' to retrieve the startup script output
  metadata_startup_script = "docker run -p 27015:27015 -p 27015:27015/udp -p 27020:27020/udp -m 14G --name l4d2-server mcpdude/l4d2server"


  metadata = {
    enable-oslogin = "TRUE"
  }
      
  boot_disk {
    auto_delete = true 
    source      = google_compute_disk.l4d2.self_link

  }

  network_interface {
    network = google_compute_network.l4d2.name
    access_config {
      nat_ip = google_compute_address.l4d2.address
    }
  }

  service_account {
    email  = google_service_account.l4d2.email
    scopes = ["userinfo-email"]
  }

  scheduling {
    preemptible       = true # Closes within 24 hours (sometimes sooner)
    automatic_restart = false
  }
}

# Create a private network so the l4d2 instance cannot access
# any other resources.
resource "google_compute_network" "l4d2" {
  name = "l4d2"
}

# Open the firewall for l4d2 traffic
resource "google_compute_firewall" "l4d2" {
  name    = "l4d2"
  network = google_compute_network.l4d2.name
  # l4d2 client port
  allow {
    protocol = "tcp"
    ports    = ["27015"]
  }
  allow {
    protocol = "udp"
    ports    = ["27015"]
  }
  # ICMP (ping)
  allow {
    protocol = "icmp"
  }
  # SSH (for RCON-CLI access)
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["l4d2"]
}


