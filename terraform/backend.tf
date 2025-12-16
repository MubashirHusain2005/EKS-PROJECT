resource "aws_s3_bucket" "terraform_state" {
  bucket = "mubashir-tf-state"
  region = "eu-west-2"

  lifecycle {
    prevent_destroy = false
  }

}

resource "aws_dynamodb_table" "dynamodb" {
  name           = "test-table-name"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "Attribute1"

  attribute {
    name = "Attribute1"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table"
    Environment = "production"
  }
}


terraform {
  backend "s3" {

    bucket  = "mubashir-tf-state"
    key     = "global/s3/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
}
