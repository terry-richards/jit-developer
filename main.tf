data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "developer" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id              = var.development_subnet_id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.key_pair.key_name

  user_data_base64 = data.template_cloudinit_config.config.rendered
  # Do not update instance if only user data changes - cloudinit runs _once_ anyway, 
  # so they can evolve without effecting the existing instances.
  lifecycle {
    ignore_changes = [user_data_base64]
  }

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name = local.developer_machine_name
  }
}

resource "aws_security_group" "sg" {
  name        = "${local.developer_user_name}-sg"
  description = "Security group for ${var.namespace}-${var.project}"

  vpc_id = var.development_vpc_id

  ingress {
    description = "SSH access from developer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configure cloud init to copy over bootstrap files and execute as 'ubuntu' user
locals {
  cloudinit_config = <<-EOF
#cloud-config
${jsonencode({
  write_files = [
    {
      path     = "/home/ubuntu/bootstrap-files/10-os-level.sh"
      encoding = "b64"
      content = base64encode(templatefile("./bootstrap-files/10-os-level.sh", {
        instance_name      = local.developer_machine_name
        developer_timezone = var.developer_timezone
      }))
      owner       = "ubuntu:ubuntu"
      permissions = "0755"
      defer       = true
    },
    {
      path        = "/home/ubuntu/bootstrap-files/20-desktop.sh"
      encoding    = "b64"
      content     = filebase64("./bootstrap-files/20-desktop.sh")
      owner       = "ubuntu:ubuntu"
      permissions = "0755"
      defer       = true
    },
    {
      path     = "/home/ubuntu/bootstrap-files/30-developer-tools.sh"
      encoding = "b64"
      content = base64encode(templatefile("./bootstrap-files/30-developer-tools.sh", {
        developer_email = var.developer_email
        developer_name  = var.developer_name
      }))
      owner       = "ubuntu:ubuntu"
      permissions = "0755"
      defer       = true
    },
    {
      path        = "/etc/cron.d/shutdown_cron"
      content     = "0 22 * * * /sbin/shutdown -h +10 'You development machine will shut down in 10 minutes. Save your work and go to sleep! Run \"shutdown -c\" to cancel.'\n"
      owner       = "root:root"
      permissions = "0644"
    }
  ],
  runcmd = [
    "chown -R ubuntu:ubuntu /home/ubuntu/bootstrap-files",
    "chmod -R 0755 /home/ubuntu/bootstrap-files",
    "su - ubuntu -c 'cd /home/ubuntu/bootstrap-files && ./10-os-level.sh'",
    "su - ubuntu -c 'cd /home/ubuntu/bootstrap-files && ./20-desktop.sh'",
    "su - ubuntu -c 'cd /home/ubuntu/bootstrap-files && ./30-developer-tools.sh'",
    "reboot"
  ]
})}
EOF
}

# Gzip ftw
data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = local.cloudinit_config
  }
}
