resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cluster_name = "${var.project_name}-eks"
  azs          = slice(data.aws_availability_zones.available.names, 0, 2)
}

# --- Network: public subnets (load balancer), private subnets (nodes), isolated database subnets ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"
  azs  = local.azs

  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24"]

  create_database_subnet_group = true

  enable_nat_gateway   = true
  single_nat_gateway   = true # one NAT keeps the bill lower
  enable_dns_hostnames = true

  # These tags let the load balancer controller find the right subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

# --- The EKS cluster ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true # you can run kubectl

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
      # makes Kubernetes NetworkPolicies actually enforced (same job Calico did on minikube)
      configuration_values = jsonencode({ enableNetworkPolicy = "true" })
    }
    metrics-server                  = {} # the autoscaler reads CPU from here
    amazon-cloudwatch-observability = {} # Container Insights, used in Part 7
  }

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      min_size       = 1
      max_size       = 2
      desired_size   = 2

      iam_role_additional_policies = {
        cloudwatch = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
    }
  }

  # Lets GitHub Actions run kubectl against the cluster
  access_entries = {
    github = {
      principal_arn = aws_iam_role.github.arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }
}

# --- Permission for the load balancer controller (installed in Part 6) ---
module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                              = "${var.project_name}-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}
