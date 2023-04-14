terraform {
  backend "s3" {
    bucket = "dev-finalproj-group1"            // Bucket where to SAVE Terraform State
    key    = "dev/webserver/terraform.tfstate" // Object name in the bucket to SAVE Terraform State
    region = "us-east-1"                       // Region where bucket is created
  }
}