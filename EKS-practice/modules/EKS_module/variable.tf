variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  default     = true
  description = "Whether the EKS cluster endpoint is publicly accessible"
}

variable "cluster_endpoint_private_access" {
  type        = bool
  default     = true
  description = "Whether the EKS cluster endpoint is publicly accessible"
}

variable "cluster_add_ons" {
  description = "Map of EKS add-ons to install"
  type        = map(object({
    addon_version            = optional(string)
    resolve_conflicts        = optional(string)
    service_account_role_arn = optional(string)
  }))
  default     = {}
}

# modules/eks/variables.tf
variable "vpc_id" {
  description = "The VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to launch the EKS cluster into"
  type        = list(string)
}


variable "eks_managed_node_group_default" {
  description = "Default config for EKS managed node groups"
  type        = map(any)
  default     = {}
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node groups"
  type = map(object({
    name                 = string
    desired_size         = number
    min_size             = number
    max_size             = number
    instance_types       = list(string)
    
  }))
  default = {}
}


