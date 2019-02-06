#put this state in s3
terraform{
  backend "s3"{
    bucket="terraform-ch3"
    key="~/terraform/ch3/stage/data-stores/mysql/terraform.tfstate"
    region="us-east-2"
		encrypt="true"
  }
}

provider "aws" {
	region = "us-east-2"
}

#create db resource
resource "aws_db_instance" "example"{
	engine = "mysql"
	allocated_storage = 10
	instance_class = "db.t2.micro"
	name = "exampledb"
	username = "admin"
	password = "${var.db_password}"
}
