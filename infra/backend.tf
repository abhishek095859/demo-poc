terraform {
  backend "s3" {
    bucket = "my-ecs-tfstate-bucket" # Change this to your bucket name
    key    = "ecs/terraform.tfstate"
    region = "us-east-1"
  }
}
