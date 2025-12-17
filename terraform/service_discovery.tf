# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.app_name}.local"
  description = "Private DNS namespace for ${var.app_name}"
  vpc         = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-namespace"
  }
}

# Service Discovery Service for Backend
resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name = "${var.app_name}-backend-discovery"
  }
}