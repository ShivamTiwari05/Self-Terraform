variable "prefix_name" {
    description = "prefix for naming objects in the vpc module"
    type = string
    default = "my-vpc"
}

variable "vpc_cidr_block"{
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    description = "list of CIDR for public subnets"
    type = list(string)
}

variable "private_subnet_cidr" {
    description = "list of cidr for private subnets"
    type = list(string)
}

variable "azs" {
    description = "list of avaialbailty zone "
    type = list(string)
}




# Inside modules/VPC_module/variables.tf
variable "private_subnet_tags" {
  type = map(string)
  default = {}