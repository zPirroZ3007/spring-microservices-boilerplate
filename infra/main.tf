terraform {
  backend "s3" {
    bucket = "terraform-s44r95vw"
    region = "eu-south-1"
  }
}

provider "aws" {
  region = "eu-south-1"
}

variable "prefix" {
  default = ""
  type    = string
}

variable "git_user" {
  default = ""
  type    = string
}

variable "git_token" {
  default = ""
  type    = string
}

variable "image_version" {
  default = ""
  type    = string
}

data aws_ecs_cluster "cluster" {
  cluster_name = ""
}

# Nome del bucket S3 già esistente dove caricare l'env file
variable "env_bucket_name" {
  default = "terraform-s44r95vw"
  type    = string
}

variable "rule_priority" {
  default = 0
  type    = number
}

data "aws_vpc" "vpc" {
  default = true
}

data "aws_secretsmanager_secret" "ghcr_credentials" {
  name = "ghcr2"
}