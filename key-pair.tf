# Generate a new key pair if the developer_public_key variable is null
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Only generate an aws_key_pair if the developer_public_key variable is null
resource "aws_key_pair" "key_pair" {
  key_name   = "${local.developer_user_name}-key-pair"
  public_key = tls_private_key.key_pair.public_key_openssh
}

# Save private key to a local file (to be provided to developer)
resource "local_file" "private_key" {
  filename        = "${trimsuffix(var.output_dir, "/")}/${aws_key_pair.key_pair.key_name}.pem"
  content         = tls_private_key.key_pair.private_key_pem
  file_permission = 0400
}
