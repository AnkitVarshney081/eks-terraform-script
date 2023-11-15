terraform {
    required_providers {
       aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.00"
    }
    } 
  required_version = ">= 1.4.0"
}
# terraform {
#   backend "s3" {
#     bucket         = "sp-terraform-state-bucket"
#     key            = "dev/eks/terraform.tfstate"
#     region         = "ap-south-1"

#   }
# }

provider "aws" {
  profile = "poc"
  region = "us-west-1"
}
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}


# data "aws_eks_cluster_auth" "default" {
#   name = module.eks.cluster_name
# }

# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.default.token
# }
