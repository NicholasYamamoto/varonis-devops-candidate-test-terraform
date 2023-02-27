# Create the namespace to use for the resources
resource "kubernetes_namespace" "eks-namespace" {
  metadata {
    name = var.k8s_namespace
  }
}

# Create and configure the EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.10.0"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id = var.vpc_id

  subnet_ids = [
    var.subnet_private_a_1a,
    var.subnet_private_b_1b,
    var.subnet_private_c_1a
  ]

  enable_irsa = true

  # Disable creation of unnecessary default resources to make the cluster "simpler"
  create_cloudwatch_log_group = false
  create_kms_key              = false
  cluster_encryption_config   = {}

  eks_managed_node_group_defaults = {
    # TODO: Might need to add create_iam_role = false and that stuff here!
    disk_size = 10
  }

  eks_managed_node_groups = {
    primary = {
      desired_size = 1
      min_size     = 1
      max_size     = 3

      labels = {
        role = "primary"
      }

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
    }
  }

  # node_security_group_additional_rules = {
  #   ingress_allow_access_from_control_plane = {
  #     type                          = "ingress"
  #     protocol                      = "tcp"
  #     from_port                     = 9443
  #     to_port                       = 9443
  #     source_cluster_security_group = true
  #     description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
  #   }
  # }
}
