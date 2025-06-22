resource "aws_eks_cluster" "my_eks" {
    name = var.cluster_name

    access_config {
        authentication_mode = "API"
    }

    role_arn = aws_iam_role.cluster.arn
    version = var.cluster_version

    vpc_config {
        subnet_ids = var.subnet_ids

        endpoint_public_access  = var.cluster_endpoint_public_access
        endpoint_private_access = var.cluster_endpoint_private_access
    }

    depends_on = [
        aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
        #aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
        #aws_iam_role_policy_attachment.cluster_AmazonEKSWorkerNodePolicy,
        #aws_iam_role_policy_attachment.cluster_AmazonEC2ContainerRegistryReadOnly
    ]
}

resource "aws_eks_addon" "this" {
  for_each = var.cluster_add_ons

  cluster_name             = aws_eks_cluster.my_eks.name
  addon_name               = each.key
  addon_version            = each.value.addon_version
  resolve_conflicts        = each.value.resolve_conflicts
  service_account_role_arn = each.value.service_account_role_arn
}

resource "aws_eks_node_group" "this" {
  for_each = var.eks_managed_node_groups
  node_role_arn = aws_iam_role.node_group.arn
  subnet_ids = var.subnet_ids
  cluster_name = aws_eks_cluster.my_eks.name

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  instance_types = each.value.instance_types
}



resource "aws_iam_role" "cluster" {
    name = "eks-cluster-self"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "sts:AssumeRole",
                    "sts:TagSession"
                ]
                Effect = "Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
    role       = aws_iam_role.cluster.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


resource "aws_iam_role" "node_group" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"   # ✅ required for EC2 node groups
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}















terraform {
  required_version = ">= 1.3.0"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}


data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}


resource "kubectl_manifest" "nginx" {
  depends_on = [
    aws_eks_cluster.my_eks,
    aws_eks_node_group.this
  ]
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
      namespace: default
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
            - name: nginx
              image: nginx:1.23
              ports:
                - containerPort: 80
  YAML
}

############################################
# 7. Ad-hoc kubectl commands via null_resource #
############################################

resource "null_resource" "kubectl_commands" {
  depends_on = [aws_eks_cluster.my_eks, kubectl_manifest.nginx]

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = "~/.kube/config"   # or write out kubeconfig using local_file if you prefer
    }
    command = <<-EOC
      # wait for nodes
      kubectl wait --for=condition=Ready nodes --all --timeout=5m
      # get pods in default ns
      kubectl get pods -o wide
    EOC
  }
}