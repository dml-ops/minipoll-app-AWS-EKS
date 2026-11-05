# Like a firewall: only the cluster may reach port 5432
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Postgres from the EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Postgres from the cluster"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      module.eks.node_security_group_id,
      module.eks.cluster_primary_security_group_id,
    ]
  }
}

resource "aws_db_instance" "pg" {
  identifier     = "${var.project_name}-pg-${random_string.suffix.result}"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "minipoll"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false # the "database is not public" proof

  # Lab settings so that terraform destroy is clean and cheap
  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
}
