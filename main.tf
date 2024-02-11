locals {
  project_id = "groovy-groove-413911"
  region     = "europe-west9"
  zone       = "europe-west9-a"
}

resource "google_service_account" "pal-server-sac" {
  project      = local.project_id
  account_id   = "pal-server-sa"
  display_name = "Custom SA for Server VM"
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = "pal-server-storage"
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.pal-server-sac.email}"
}

resource "google_compute_instance" "pal-server" {
  project      = local.project_id
  name         = "pal-server"
  machine_type = "e2-standard-2"
  zone         = local.zone
  tags         = ["pal-server"]

  metadata =  {
    ssh-keys = "${var.user}:${var.publickeypath}"
  }
  boot_disk {
    initialize_params {
      size  = 20
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.public-server-ip.address
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.pal-server-sac.email
    scopes = ["cloud-platform"]
  }

  # metadata_startup_script = file("${path.module}/creation_script.sh")

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.user
      host        = google_compute_instance.pal-server.network_interface[0].access_config[0].nat_ip
      private_key = file(var.privatekeypath)
    }
    script = "${path.module}/creation_script.sh"

  }

}

resource "google_compute_address" "public-server-ip" {
  project = local.project_id
  region  = local.region
  name    = "pal-server-ip"
}

resource "google_compute_firewall" "pal-server-traffic" {
  project = local.project_id
  name    = "allow-pal-server-traffic"

  allow {
    protocol = "icmp"
  }

  allow {
    ports    = ["8211", "25575"]
    protocol = "tcp"
  }
  allow {
    ports    = ["8211", "25575"]
    protocol = "udp"
  }

  direction     = "INGRESS"
  network       = "default"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["pal-server"]
}