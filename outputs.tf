output "vpc_id" {
  value = aws_vpc.main.id
}
output "public_subnets" {
  value = aws_subnet.subnets[*].id
}
output "private_subnets" {
  value = var.tiered ? aws_subnet.private_subnets[*].id : aws_subnet.subnets[*].id
}
