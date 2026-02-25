terraform {
  backend "s3" {
    bucket = "my-ecs-tfstate-bucket" # Change this to your bucket name
    key    = "ecs/v1/terraform.tfstate"
    region = "ap-south-1"
  }
}
