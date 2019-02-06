terraform{
  backend "s3"{
    bucket="terraform-ch3"
    key="~/terraform/ch3/global/s3/terraform.tfstate"
    region="us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state"{
  bucket = "terraform-ch3"
  versioning {enabled = true}
  lifecycle {prevent_destroy = true}
}
