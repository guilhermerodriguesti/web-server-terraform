# Specify the provider and access details
provider "aws" {
  region = var.aws_region
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = var.vpc_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.default_ig_id
}

resource "aws_elb" "web" {
  name = "terraform-example-elb"

  subnets         = [var.default_subnet_id]
  security_groups = [var.elb_sg_id]
  instances       = [aws_instance.web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_instance" "web" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    host = self.public_ip
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = lookup(var.aws_amis, var.aws_region)

  # The name of our SSH keypair we created above.
  key_name = var.key_id

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [var.default_sg_id]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = var.default_subnet_id

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
  }
}
