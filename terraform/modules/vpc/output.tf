output "subnet_ids" {
  value = [for subnet in aws_subnet.this : subnet.id]
}

output "vpc_id" {
  value = aws_vpc.this.id
}


output "private_route_table_id" {
  value = aws_route_table.private.id
}

