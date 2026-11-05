resource "aws_ecr_repository" "app" {
  for_each     = toset(["minipoll-backend", "minipoll-frontend"])
  name         = each.key
  force_delete = true # lets terraform destroy remove repos that still hold images

  image_scanning_configuration {
    scan_on_push = true
  }
}