output "region" {
  value = var.region
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_registry" {
  value = split("/", aws_ecr_repository.app["minipoll-backend"].repository_url)[0]
}

output "rds_address" {
  value = aws_db_instance.pg.address
}

output "github_role_arn" {
  value = aws_iam_role.github.arn
}

output "lb_controller_role_arn" {
  value = module.lb_controller_irsa.iam_role_arn
}

output "name_servers" {
  value = aws_route53_zone.zone.name_servers
}
