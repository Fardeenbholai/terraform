variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnets_cidr_private" {
  type    = "list"
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "subnets_cidr_public" {
  type    = "list"
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "azs" {
  type    = "list"
  default = ["us-east-1a", "us-east-1b"]
} 
