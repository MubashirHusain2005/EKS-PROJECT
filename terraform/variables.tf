variable "vpc_cidr" {
  default = "10.0.0.0/16"
  type    = string
}

variable "enable_host" {
  default = true
  type    = bool
}

variable "enable_support" {
  default = true
  type    = bool
}

variable "vpc_id" {
  type    = string
  default = "aws_vpc.eks-vpc.id"
}

variable "cluster_name" {
  type = string
  default = "aws_eks_cluster.eks-cluster.name"
}

variable "nodes_name" {
  type = string
  default = "eks-nodes"
}