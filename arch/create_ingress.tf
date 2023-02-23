# Create the namespace to use for the resources
resource "kubernetes_namespace" "eks-namespace" {
  metadata {
    name = var.k8s_namespace
  }
}

# Use a module to configure an IAM role for an AWS EKS Service Account to use a Load Balancer Controller
module "aws_eks_alb_role" {
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name                              = "NickClusterALBRole"
  role_description                       = "Allows an EKS cluster to access an AWS Load Balancer Controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.k8s_namespace}:aws-load-balancer-controller"]
    }
  }
}

# Create and configure a Kubernetes Service Account for the Load Balancer Controller
resource "kubernetes_service_account" "ksa-load-balancer-controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = var.k8s_namespace
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.aws_eks_alb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

# Create and configure an ALB for the cluster with a Helm chart
resource "helm_release" "eks-ingress" {
  name       = "nick-cluster-ingress"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = var.k8s_namespace
  version    = "1.4.7"
  depends_on = [
    kubernetes_service_account.ksa-load-balancer-controller
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.us-east-1.amazonaws.com"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}
