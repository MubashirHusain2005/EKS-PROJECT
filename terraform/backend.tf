terraform {
  backend "s3" {

    bucket  = "mubashir-tf-state"
    key     = "global/s3/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
}
