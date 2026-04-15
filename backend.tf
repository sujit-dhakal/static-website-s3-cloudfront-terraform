terraform {
  backend "s3" {
    bucket       = "static-website-terraform-state-sujit"
    key          = "terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}
