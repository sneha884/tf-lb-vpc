resource "aws_vpc" "demo" {
  cidr_block       = var.vpc
  instance_tenancy = "default"
  tags             = merge(var.tags, { Name = format("%s-%s-%s", var.appname, var.env,"vpc" )})
}
/*-------------------public-subnet-----------------------*/
resource "aws_subnet" "public" {
  count                   = length(var.public_cidr_block)
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = var.public_cidr_block[count.index]
  map_public_ip_on_launch = "true"
   availability_zone    = element(var.availability_zones , count.index)
  tags                    = merge(var.tags, { Name = format("%s-%s-public-%s", var.appname, var.env, element(var.availability_zones , count.index)) })
}
/*-------------------public-subnet-----------------------*/
resource "aws_subnet" "private" {
  count             = length(var.private_cidr_block)
  vpc_id            = aws_vpc.demo.id
  cidr_block        = var.private_cidr_block[count.index]
  availability_zone = element(var.availability_zones , count.index)
  tags              = merge(var.tags, { Name = format("%s-%s-private-%s", var.appname, var.env, element(var.availability_zones , count.index)) })
}
/*-------------------internet gateway-----------------------*/
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.demo.id
  tags   = merge(var.tags, { Name = format("%s-%s-igw", var.appname, var.env, ) })
}/*------------------public Route table-----------------------*/
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.demo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, { Name = format("%s-%s-public", var.appname, var.env, ) })
}

/*-------------------private Route table-----------------------*/
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.demo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, { Name = format("%s-%s-private", var.appname, var.env, ) })
}
/*--------------------public-subnet-association-----------------------*/
resource "aws_route_table_association" "public" {
  count          = length(var.public_cidr_block)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public-rt.id
}
/*--------------------PRIVATE-subnet-association----------------------*/
resource "aws_route_table_association" "private" {
  count          = length(var.private_cidr_block)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private-rt.id
}
/*-------------------EIP-----------------------*/
resource "aws_eip" "eip" {
  vpc  = true
  tags = merge(var.tags, { Name = format("%s-%s-eip_nat", var.appname, var.env, ) })
}
/*------------------NAT-GATEWAY-----------------*/
resource "aws_nat_gateway" "nat_gtw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]
  tags          = merge(var.tags, { Name = format("%s-%s-nat_gtw", var.appname, var.env, ) })
}

#-----------Security-group-----------#
resource "aws_security_group" "task-sg" {
  name        = "demo-sg"
  description = "my-sg inbound traffic"
  vpc_id      = aws_vpc.demo.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "task-sg"
  }
}

