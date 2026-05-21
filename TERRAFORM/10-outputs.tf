output "lb_ip" {
  description = "external IP of the load balancer"
  value       = google_compute_global_address.lb.address
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "mig_name" {
  value = google_compute_instance_group_manager.web.name
}

# wait a few minutes after apply before testing, LB takes a bit to get healthy
output "test_command" {
  value = "curl http://${google_compute_global_address.lb.address}"
}
