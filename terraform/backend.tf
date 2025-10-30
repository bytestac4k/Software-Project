terraform {
  backend "s3" {
    bucket         = "software-project-terraform-state"   # ← change to your bucket
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "software-project-tf-locks"          # ← change to your table
    encrypt        = true
  }
}
