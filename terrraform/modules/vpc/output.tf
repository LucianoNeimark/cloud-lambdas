output "subnet_ids" {
  value = [for subnet in aws_subnet.this : subnet.id]
}

output "vpc_id" {
  value = aws_vpc.this.id
}
