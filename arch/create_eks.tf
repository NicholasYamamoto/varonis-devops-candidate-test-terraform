# Create an IAM role for the EKS Cluster
resource "aws_iam_role" "eks-cluster-role" {
  name = "NickEKSClusterRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# Attach the AWS EKS Cluster policy to the role
resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

# Enable Security Groups for pods to additionally secure deployed web app at L3 (Network layer)
resource "aws_iam_role_policy_attachment" "eks-vpc-resource-controller-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-role.name
}

# Create an IAM role for the EKS Node Group
resource "aws_iam_role" "eks-node-group-role" {
  name = "NickEKSNodeGroupRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# Attach the EKS Worker Node IAM policy to the role
resource "aws_iam_role_policy_attachment" "nodes-eks-worker-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-group-role.name
}

# Attach the EKS CNI policy to the role
resource "aws_iam_role_policy_attachment" "nodes-eks-cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-group-role.name
}

# Attach the EKS Worker Node IAM policy to the role
resource "aws_iam_role_policy_attachment" "nodes-ec2-container-registry-read-only-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-group-role.name
}

# Create and configure the EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.10.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.25"

  subnet_ids = [
    var.subnet_private_a_1a,
    var.subnet_private_b_1b,
    var.subnet_private_c_1a
  ]
  # Disable access to the cluster from outside the VPC
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true
  vpc_id                          = var.vpc_id

  # Assign the IAM role created above rather than making a new one for the cluster
  create_iam_role = false
  iam_role_arn    = aws_iam_role.eks-cluster-role.arn

  # Create and configure an OpenID Connect Provider (OIDC) for EKS to use
  enable_irsa              = true
  custom_oidc_thumbprints  = [module.eks.cluster_tls_certificate_sha1_fingerprint]
  openid_connect_audiences = ["sts.amazonaws.com"]

  # Disable creation of unnecessary default resources to make the cluster "simpler"
  create_cloudwatch_log_group = false
  create_kms_key              = false
  cluster_encryption_config   = {}

  eks_managed_node_group_defaults = {
    create_iam_role = false
    iam_role_name   = aws_iam_role.eks-node-group-role.name
    iam_role_arn    = aws_iam_role.eks-node-group-role.arn
  }
  eks_managed_node_groups = {
    main = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1

      instance_type = "t3.small"
      capacity_type = "SPOT"
    }
  }

  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow the Kubernetes Control Plane to access webhook port of the AWS Load Balancer Controller"
    }
  }
}
