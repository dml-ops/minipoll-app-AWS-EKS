variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "project_name" {
  type    = string
  default = "minipoll"
}

variable "kubernetes_version" {
  description = "Newest version in standard support (see the command above)"
  type        = string
}

variable "node_instance_type" {
  type    = string
  default = "m7i-flex.large" # 2 vCPUs, 8 GiB
}

variable "db_username" {
  type    = string
  default = "minipolladmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  type = string
}

variable "domain_name" {
  type    = string
  default = "dmldev.site"
}

variable "github_repo" {
  description = "owner/repo allowed to deploy"
  type        = string
  default     = "dml-ops@267247411/minipoll-app-AWS-EKS@1441956777"
}

variable "alb_dns_name" {
  description = "DNS name of the load balancer, filled in during Part 7"
  type        = string
  default     = ""
}
