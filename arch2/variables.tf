variable "region" {
  type        = string
  description = "The AWS region to deploy the cluster to"
}

variable "cluster_name" {
  type        = string
  description = "The name given to the cluster"
}

variable "cluster_version" {
  type        = string
  description = "The version to use for the EKS cluster"
}

variable "node_group_name" {
  type        = string
  description = "The name of the Node Group created in the cluster"
}

variable "k8s_namespace" {
  type        = string
  description = "The Kubernetes Namespace to create the resources in"
}

variable "subnet_private_a_1a" {
  type        = string
  description = "private-a subnet in AZ us-east-1a in the testVPC"
}

variable "subnet_private_b_1b" {
  type        = string
  description = "private-b subnet in AZ us-east-1b in the testVPC"
}

variable "subnet_private_c_1a" {
  type        = string
  description = "private-c subnet in the testVPC"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the testVPC"
}

variable "eks_ecr_image_repo" {
  type        = string
  description = "The ECR image repository required by EKS"
}
