output "cluster_name" {
  value = aws_eks_cluster.my_eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.my_eks.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.my_eks.arn
}

output "cluster_role_arn" {
  value = aws_iam_role.cluster.arn
}

output "oidc_provider_url" {
  value = aws_eks_cluster.my_eks.identity[0].oidc[0].issuer
}

output "node_group_role_arn" {
  value = aws_iam_role.node_group.arn
}






