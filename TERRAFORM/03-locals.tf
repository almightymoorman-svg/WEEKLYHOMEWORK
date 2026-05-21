locals {
  prefix = "${var.app}-${var.env}"

  vpc_name    = "${local.prefix}-vpc"
  subnet_name = "${local.prefix}-subnet"

  http_tag = "${local.prefix}-http"
  ssh_tag  = "${local.prefix}-ssh"
}
