resource "google_compute_instance_group_manager" "web" {
  name               = "${local.prefix}-mig"
  zone               = var.zone
  project            = var.project_id
  base_instance_name = "${local.prefix}-vm"
  target_size        = var.mig_size

  version {
    instance_template = google_compute_instance_template.web.id
    name              = "primary"
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http.id
    initial_delay_sec = 120
  }
}
