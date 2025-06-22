resource "aws_vpc" "my_vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_support = true
    #map_public_ip_on_launch = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.prefix_name}-vpc"
    }
}

resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "${var.prefix_name}-igw"
    }
}

resource "aws_nat_gateway" "my_ngw" {
    #count = length(var.public_subnet_cidr)
    #subnet_id = aws_subnet.public_subnet[count.index].id
    subnet_id = aws_subnet.public_subnet[0].id
    allocation_id = aws_eip.my_eip.id
    tags = {
        Name = "${var.prefix_name}-ngw"
    }
    depends_on = [aws_internet_gateway.my_igw]
}

resource "aws_eip" "my_eip" {
    domain = "vpc"
}

resource "aws_subnet" "public_subnet" {
    count = length(var.public_subnet_cidr)
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = var.public_subnet_cidr[count.index]
    availability_zone = element(var.azs, count.index)
    tags = {
        Name = "${var.prefix_name}-public-subnet-${count.index + 1}"
    }   
}

resource "aws_subnet" "private_subnet" {
    count = length(var.private_subnet_cidr)
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = var.private_subnet_cidr[count.index]
    availability_zone = element(var.azs, count.index)
    tags = {
        Name = "${var.prefix_name}-private-subnet-${count.index + 1}"
    }
}


resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "${var.prefix_name}-public-rt"
    }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}


resource "aws_route_table_association" "public_rta" {
    count = length(var.public_subnet_cidr)
    subnet_id = aws_subnet.public_subnet[count.index].id
    route_table_id = aws_route_table.public_rt.id
    depends_on = [aws_internet_gateway.my_igw, aws_subnet.public_subnet]
}

resource "aws_route_table" "private_rt" {
    #count  = length(var.private_subnet_ids)
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "${var.prefix_name}-private-rt"
    }
}

resource "aws_route" "private_internet_access" {
  #count = length(var.public_subnet_cidr)  
  #route_table_id         = aws_route_table.private_rt[count.index].id
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.my_ngw.id
}

resource "aws_route_table_association" "private_rta" {
    count = length(var.private_subnet_cidr)
    subnet_id = aws_subnet.private_subnet[count.index].id
    #route_table_id = aws_route_table.private_rt[count.index].id
    route_table_id = aws_route_table.private_rt.id
    depends_on = [aws_nat_gateway.my_ngw, aws_subnet.private_subnet]
}


