terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}


# Configure the GitHub Provider
provider "github" {
    token = var.git-token
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

variable "git-name" {
  default = "HARUN-BULUT" # Please write your own git name
}

variable "git-token"{
    default = "XXXXXXXXXXXXXXXXXXXXXXXX" # please write your own token
}
 variable "key-name" {
   default = "firstkey" # please write your own key
 }

 resource "github_repository" "myrepo" {
  name        = "bookstore-api-repo"
  description = "My app"
  visibility = "private"
  auto_init = true
}

resource "github_branch_default" "default"{
  repository = github_repository.myrepo.name
  branch     = "main"
}

variable "files" {
  default = ["bookstore-api.py", "docker-compose.yml", "requirements.txt", "Dockerfile"]
}

resource "github_repository_file" "app-files" {
  for_each = toset(var.files)
  file                = each.value
  content             = file(each.value)
  repository          = github_repository.myrepo.name
  branch              = github_branch_default.default.branch
  commit_message      = "Managed by Terraform"
  commit_author       = "harun"
  commit_email        = "harunbulutus@gmail.com"
  overwrite_on_create = true #true yapmazsak degisiklik yaptigimizda dosyalar var olusturmaz hatasi aliriz
}

resource "aws_security_group" "tf-docker-sec-gr" {
  name = "docker-sec-gr-203"
  tags = {
    Name = "docker-sec-group-203"
  }
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "tf-docker-ec2" {
  ami = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  key_name = var.key-name
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  tags = {
    Name = "Web Server of Bookstore"
  }
  user_data = templatefile("user-data.sh", { user-data-git-token = var.git-token, user-data-git-name = var.git-name })
  depends_on = [ github_repository.myrepo, github_repository_file.app-files ]

}

output "website" {
  value = "http://${aws_instance.tf-docker-ec2.public_dns}"
}