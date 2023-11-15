resource "aws_security_group" "additional" {
  name_prefix = "sp-eks-${var.ENV}-sg"
  vpc_id      = var.VPC_ID

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "10.1.0.0/20",
      "192.168.0.0/20",
    ]
  }

  tags = {
    Environment = var.ENV
    Application = "eks"
    Terraform   = "true"
    Name        = "sp-eks-${var.ENV}-sg"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.CLUSTER_NAME
  cluster_version = var.EKS_VERSION

  cluster_endpoint_private_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  vpc_id                   = var.VPC_ID
  subnet_ids               = var.SUBNETS_IDS
  control_plane_subnet_ids = var.SUBNETS_IDS

  cloudwatch_log_group_retention_in_days = 30
  cluster_security_group_name = "${var.CLUSTER_NAME}-sg"
  iam_role_name = "${var.CLUSTER_NAME}-role"

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
    
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }


    
  eks_managed_node_groups = {

    sp-eks-dev-ng-spot = {
      
      use_custom_launch_template = false
      attach_cluster_primary_security_group = true
      vpc_security_group_ids                = [aws_security_group.additional.id]
      Name = "sp-eks-${var.ENV}-ng-spot"
      min_size     = 1
      max_size     = 10
      desired_size = 1
      disk_size    = 50
      remote_access = {
        ec2_ssh_key    = var.SSH_KEY
      }
      tags={
        Name        = "sp-eks-${var.ENV}-spot"
      }

    labels = {
        Name = "sp-eks-${var.ENV}-ng-spot"
        role = "sp-eks-${var.ENV}-spot"
        Application = var.ENV
      }

      instance_types = var.SPOT_INSTANCE_TYPE
      capacity_type  = "SPOT"
    }
  }
  tags = {
    Environment = var.ENV
    Application = "eks"
    Terraform   = "true"
    Name        = "sp-eks-${var.ENV}"
  }
}