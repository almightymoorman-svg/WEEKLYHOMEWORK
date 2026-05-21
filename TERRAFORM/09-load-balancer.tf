resource "google_compute_global_address" "lb" {
  name    = "${local.prefix}-lb-ip"
  project = var.project_id
}

resource "google_compute_backend_service" "web" {
  name                  = "${local.prefix}-backend"
  project               = var.project_id
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.http.id]
  timeout_sec           = 30

  backend {
    group           = google_compute_instance_group_manager.web.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "web" {
  name            = "${local.prefix}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.web.id
}

resource "google_compute_target_http_proxy" "web" {
  name    = "${local.prefix}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.web.id
}

resource "google_compute_global_forwarding_rule" "web" {
  name                  = "${local.prefix}-fwd"
  project               = var.project_id
  target                = google_compute_target_http_proxy.web.id
  ip_address            = google_compute_global_address.lb.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
}
