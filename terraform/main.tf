 ###VPC Networking

resource "aws_vpc" "eks-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = var.enable_host
  enable_dns_support   = var.enable_support

  tags = {
    Name = "Main-VPC"
  }
}

resource "aws_internet_gateway" "igw" { 
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    Name                                        = "IGW"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  depends_on = [aws_vpc.eks-vpc]
}

resource "aws_subnet" "public-subnet-2a" {
  vpc_id                  = aws_vpc.eks-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "Public-subnet-2a"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                    = 1
  }

  depends_on = [aws_vpc.eks-vpc]
}

resource "aws_subnet" "public-subnet-2b" {
  vpc_id                  = aws_vpc.eks-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "Publicsubnet-2b"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                    = 1
  }

  depends_on = [aws_vpc.eks-vpc]
}


resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"  }

  depends_on = [aws_vpc.eks-vpc, aws_internet_gateway.igw]
}



resource "aws_route_table_association" "pub-route-association-2a" {

  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-subnet-2a.id

}

resource "aws_route_table_association" "pub-route-association-2b" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-subnet-2b.id
}



resource "aws_subnet" "private-subnet-2a" {
  vpc_id                  = aws_vpc.eks-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "Private-subnet-2a"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = 1
  }

  depends_on = [aws_vpc.eks-vpc]
}

resource "aws_subnet" "private-subnet-2b" {
  vpc_id                  = aws_vpc.eks-vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "Private-subnet-2a"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = 1
  }

  depends_on = [aws_vpc.eks-vpc]
}



resource "aws_eip" "ngw-eip" {
  domain = "vpc"

  tags = {
    Name = "eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.public-subnet-2b.id
  allocation_id = aws_eip.ngw-eip.id

  tags = {
    Name = "igw-nat"
  }

  depends_on = [aws_internet_gateway.igw, aws_eip.ngw-eip]
}



resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.eks-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "private-rt"

  }

}

resource "aws_route_table_association" "private-route-association-2a" {

  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-subnet-2a.id

  depends_on = [aws_vpc.eks-vpc, aws_subnet.private-subnet-2a, aws_route_table.private-rt]
}

resource "aws_route_table_association" "private-route-association-2b" {

  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-subnet-2b.id

  depends_on = [aws_vpc.eks-vpc, aws_subnet.private-subnet-2b, aws_route_table.private-rt]
}


####IAM Roles and Policies

#IAM Role for the cluster
resource "aws_iam_role" "cluster" {
  name = "eks-cluster"
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

#IAM policies for the cluster
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}



resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSBlockStoragePolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
}


resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSLoadBalancingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}





#IAM role for nodes
resource "aws_iam_role" "nodes" {
  name = "eks-node-group"

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

#IAM policies for the nodes
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}



#EKS

resource "aws_eks_cluster" "eks-cluster" {
  name    = "eks-cluster"
  version = "1.30"

  role_arn = aws_iam_role.cluster.arn

  # Controls how Kubernetes API authentication works
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Tells EKS which subnets to use for control-plane ENIs
  vpc_config {
      security_group_ids = [aws_security_group.eks_cluster.id]
      subnet_ids = [
      aws_subnet.private-subnet-2a.id,
      aws_subnet.private-subnet-2b.id
    ]

    endpoint_private_access = true
    endpoint_public_access  = false

  }

  tags = {
    Environment = "labs"
    Project     = "eks-assignment"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSBlockStoragePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSLoadBalancingPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}


resource "aws_eks_node_group" "private-nodes" {
  cluster_name  = aws_eks_cluster.eks-cluster.name
  node_role_arn = aws_iam_role.nodes.arn

  subnet_ids = [
    aws_subnet.private-subnet-2a.id,
    aws_subnet.private-subnet-2b.id
]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.large"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Environment = "labs"
    Project     = "eks-assignment"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]

}

#Security Group for the Cluster

resource "aws_security_group" "eks_cluster" {
  name        =  "eks-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.eks-vpc.id

  tags = {
    Name = "EKS-project"
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  to_port                  = 443
  type                     = "ingress"
  cidr_blocks               = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  to_port                  = 65535
  type                     = "egress"
  cidr_blocks              =  ["0.0.0.0/0"]
}