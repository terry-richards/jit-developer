output "vpc_id" {
  value = aws_vpc.development_vpc.id
}

output "subnet_id" {
  value = aws_subnet.development_subnet.id
}