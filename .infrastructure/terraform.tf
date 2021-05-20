# CONFIG
# ==========================

terraform {
  backend "s3" {
    bucket = "cpcwood-ecs-circleci-tf-state"
    key = "state.tfstate"
    region = "eu-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  shared_credentials_file = "$HOME/.aws/credentials"
  profile = "ecs-tf"
  region = var.aws_region
}

variable "aws_region" {
  description = "The AWS region things are created in"
  default = "eu-west-2"
}


# NETWORK
# ==========================

# vpc for ecs
resource "aws_vpc" "ecs-circleci-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "ecs-circleci-vpc"
  }
}

# vpc subnet - public
resource "aws_subnet" "ecs-circleci-subnet-public" {
  vpc_id = aws_vpc.ecs-circleci-vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-circleci-subnet-public"
  }
}

# connect vpc to internet
resource "aws_internet_gateway" "ecs-circleci-ig" {
  vpc_id = aws_vpc.ecs-circleci-vpc.id

  tags = {
    Name = "ecs-circleci-ig"
  }
}

# route traffic from vpc to internet gateway
resource "aws_route_table" "ecs-circleci-rt-public" {
  vpc_id = aws_vpc.ecs-circleci-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs-circleci-ig.id
  }
}

# add route table to subnet
resource "aws_route_table_association" "ecs-circleci-rt-to-public-subnet" {
  subnet_id = aws_subnet.ecs-circleci-subnet-public.id
  route_table_id = aws_route_table.ecs-circleci-rt-public.id
}

# add security group for vpc
resource "aws_security_group" "ecs-circleci-sg" {
  vpc_id = aws_vpc.ecs-circleci-vpc.id

  ingress {
    from_port = 80
    to_port = 8180
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ECR
# ==========================

# ecr repository
resource "aws_ecr_repository" "ecs-circleci-ecr" {
  name = "cpcwood-ecs-circleci"
}

# output ecr repo endpoint
output "ecs-circleci-ecr-endpoint" {
  value = aws_ecr_repository.ecs-circleci-ecr.repository_url
}


# ECS
# ==========================

resource "aws_ecs_cluster" "ecs-circleci-cluster" {
  name = "cpcwood-ecs-circleci"
}

# resource "aws_ecs_task_definition" "ecs-circleci-cluster-td" {
#   family = "worker"
#   container_definitions = data.template_file.task_definition_template.rendered
# }

# resource "aws_ecs_service" "worker" {
#   name = "worker"
#   cluster = aws_ecs_cluster.ecs-circleci-cluster.id
#   task_definition = aws_ecs_task_definition.ecs-circleci-cluster-td.arn
#   desired_count = 2
# }

