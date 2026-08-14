variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "ami_id" {
  type    = string
  default = "ami-035827357e3c7e810"
}

variable "project_name" {
  type    = string
  default = "sunil"
}
