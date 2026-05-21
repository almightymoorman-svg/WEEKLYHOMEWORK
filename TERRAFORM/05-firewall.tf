resource "google_compute_firewall" "allow_http" {
  name    = "${local.prefix}-allow-http"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.http_tag]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${local.prefix}-allow-ssh"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.ssh_tag]
}

# health check probes come from these GCP ranges, instances need to allow them
resource "google_compute_firewall" "allow_hc" {
  name    = "${local.prefix}-allow-hc"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = [local.http_tag]
}
