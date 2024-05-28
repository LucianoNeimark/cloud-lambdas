variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "subnets" {
  type = list(object({
    name       = string
    cidr_block = string
  }))
}

variable "availability_zones" {
  type = list(string)
}
