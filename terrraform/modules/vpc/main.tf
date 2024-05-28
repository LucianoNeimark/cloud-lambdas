resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "this" {
  for_each = zipmap(range(length(var.subnets)), var.subnets) # Check if "zipmap" works properly
  #for_each = { for subnet in var.subnets : subnet.name => subnet }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = element(var.availability_zones, each.key)

  tags = {
    Name = each.value.name
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-private"
  }
}

resource "aws_route_table_association" "private_subnet" {
  for_each = aws_subnet.this

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

