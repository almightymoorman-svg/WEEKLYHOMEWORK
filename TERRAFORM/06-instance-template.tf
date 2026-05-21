resource "google_compute_instance_template" "web" {
  name_prefix  = "${local.prefix}-tpl-"
  machine_type = var.machine_type
  project      = var.project_id
  region       = var.region

  tags = [local.http_tag, local.ssh_tag]

  disk {
    source_image = var.disk_image
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {}
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      apt-get update -y
      apt-get install -y nginx
      systemctl enable nginx
      systemctl start nginx
      INSTANCE=$(curl -sf -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/instance/name" || echo "unknown")
      echo "<h1>served by: $INSTANCE</h1>" > /var/www/html/index.html
    EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}
