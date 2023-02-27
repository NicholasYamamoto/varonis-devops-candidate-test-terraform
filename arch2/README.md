# `arch`

These Terraform scripts create and configure all of the resources needed for this assignment:

`create_eks.tf`:
- Creates IAM roles with necessary IAM policies for the EKS Cluster and Node Group
- Uses a module to create the EKS cluster
- Creates and configures an OpenID Connect Provider for EKS to use

`create_ingress.tf`:
- Creates the Kubernetes Namespace
- Creates a Kubernetes Service Account (KSA) to interact with the AWS Load Balancer Controller
- Creates an IAM role for the EKS Service Account
- Deploys an AWS Load Balancer Controller using a Helm chart

`create_ecr.tf`:
- Creates the AWS Elastic Container Registry (ECR) repository to store the web application container to deploy to the cluster