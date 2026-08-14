locals {
  project_name   = "web-app"
  instance_count = 3
  common_tags = {
    Project = "web-app"
    Owner   = "sunil"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # Mumbai Region
}
# 1. KEY PAIR (Added Component)
resource "aws_key_pair" "deployer" {
  key_name   = "sunil-deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..." 
}
# 2. SECURITY GROUP (Allow SSH + HTTP)
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# ==========================================
# 3. EC2 INSTANCES (Looping 3 times)
# ==========================================
resource "aws_instance" "web" {
  count                  = local.instance_count # Uses local variable for consistency
  ami                    = "ami-0f5ee92e2d63afc18" # Amazon Linux 2 in ap-south-1
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name # Linked Key Pair here
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  # Fixed syntax: Using raw variable formatting ($ instead of Terraform interpolations inside EOF string)
  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              echo "<h1>This is Server ${count.index + 1}</h1>" > /var/www/html/index.html
              EOF

  user_data_replace_on_change = false

  tags = merge(
    local.common_tags,
    {
      Name = "web-server-${count.index + 1}"
    }
  )
}

# 4. EBS VOLUMES (Looping 3 times - Added Component)

resource "aws_ebs_volume" "extra_storage" {
  count             = local.instance_count
  availability_zone = aws_instance.web[count.index].availability_zone # Matches exact server zone
  size              = 10
  type              = "gp3"

  tags = merge(
    local.common_tags,
    {
      Name = "ebs-volume-${count.index + 1}"
    }
  }
# 5. VOLUME ATTACHMENTS (Looping 3 times)
resource "aws_volume_attachment" "ebs_att" {
  count       = local.instance_count
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.extra_storage[count.index].id
  instance_id = aws_instance.web[count.index].id
}


