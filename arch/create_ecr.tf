# Create an AWS ECR repository to store my web application 
resource "aws_ecr_repository" "nick-container-registry" {
  name                 = "nick-ecr"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}