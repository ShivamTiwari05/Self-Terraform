data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
    cluster_name = "eks-${random_string.suffix.result}"
}

module "vpc" {
    source = "../modules/VPC_module"
    

    #name = "for-eks"

    vpc_cidr_block = "10.0.0.0/16"
    azs = slice(data.aws_availability_zones.available.names, 0, 3)

    private_subnet_cidr = [
        "10.0.1.0/24",
        "10.0.2.0/24",
        "10.0.3.0/24"
    ]
    public_subnet_cidr = [
        "10.0.4.0/24",
        "10.0.5.0/24",
        "10.0.6.0/24"
    ]

    #public_subnet_tags = {
    #"kubernetes.io/role/elb" = 1
  #}

  #private_subnet_tags = {
  #  "kubernetes.io/role/internal-elb" = 1
  #}
}



module "eks" {
  source = "../modules/EKS_module"
  
  cluster_name = local.cluster_name
  cluster_version = "1.32"


  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true


  # Automatically adds the cluster creator (the IAM identity running Terraform) to the Kubernetes aws-auth ConfigMap as an admin (cluster administrator).
  #This means the creator will have full cluster-admin permissions in Kubernetes via kubectl

  enable_cluster_creator_admin = true


  #cluster_add_ons = {
   # aws_ebs_csi_driver = {
  #    service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
   # }
  #}

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  eks_managed_node_group_default = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
  cluster_iam_role_additional_policies = []
  
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider_url
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}



