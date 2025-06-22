output "vpc_id" {
    description = "ID of the created VPC"
    value = aws_vpc.my_vpc.id
}

output "public_subnet_ids" {
    description = "List of IDs of the created public subnets"
    value = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
    description = "List of IDs of the created private subnets"
    value = aws_subnet.private_subnet[*].id
}

output "internet_gateway_id" {
    description = "ID of the created Internet Gateway"
    value = aws_internet_gateway.my_igw.id
    
}

output "nat_gateway_id" {
    description = "ID of the created NAT Gateway"
    value = aws_nat_gateway.my_ngw[*].id
}