terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "my-context"
}


