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
    disk_size_gb = 100
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {}
  }

   metadata_startup_script = <<-EOT
    #!/bin/bash
    dnf update -y
    dnf install -y httpd

    systemctl enable httpd
    systemctl start httpd

    echo "<h1>Week 9 Terraform Web Server</h1>" > /var/www/html/index.html
  EOT
}
