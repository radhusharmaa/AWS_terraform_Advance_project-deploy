#created VPC 
resource "aws_vpc" "vpc_vnet_tf" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc tf"
  }
}
#created VPC Public subnet
resource "aws_subnet" "vpc_pubsub_tf" {
  vpc_id     = aws_vpc.vpc_vnet_tf.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "pub sub tf"
  }
}
#created VPC Private subnet
resource "aws_subnet" "vpc_pvtsub_tf" {
  vpc_id     = aws_vpc.vpc_vnet_tf.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "pvt sub tf"
  }
}
#created NSG for VPC
resource "aws_security_group" "allow_tls_sg_tf" {
  name        = "allow_tls_sg_tf"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc_vnet_tf.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "allow_tls_sg_tf"
  }
}
#created internet gateway for VNET
resource "aws_internet_gateway" "gw_tf" {
  vpc_id = aws_vpc.vpc_vnet_tf.id

  tags = {
    Name = "main_gw_tf"
  }
}

#created route table for settings rules b/w gateway & vnet
resource "aws_route_table" "pub_routetable_tf" {
  vpc_id = aws_vpc.vpc_vnet_tf.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_tf.id
  }

  tags = {
    Name = "pub RT"
  }
}

#created route table association for public subnet 
resource "aws_route_table_association" "pub_rt_a" {
  subnet_id      = aws_subnet.vpc_pubsub_tf.id
  route_table_id = aws_route_table.pub_routetable_tf.id
}

#created Vm instance
resource "aws_instance" "aws_vm_tf" {

  ami                    = "ami-05548f9cecf47b442"
  instance_type          = "t2.micro"
  key_name               = "kp_tf_vm"
  subnet_id              = aws_subnet.vpc_pubsub_tf.id
  vpc_security_group_ids = [aws_security_group.allow_tls_sg_tf.id]
  connection {

    type        = "ssh"
    host        = self.public_ip
    user        = admin
    private_key = file("./kp_tf_vm.pem")

  }
  tags = {
    Name = "firsrtfvm"
  }
}
#created Public IP
resource "aws_eip" "lb_eip_tf" {
  instance = aws_instance.aws_vm_tf.id
  domain   = "vpc"
}

#created Vm instance in private subnet

resource "aws_instance" "aws__db_vm_tf" {

  ami                    = "ami-05548f9cecf47b442"
  instance_type          = "t2.micro"
  key_name               = "kp_tf_vm"
  subnet_id              = aws_subnet.vpc_pvtsub_tf.id
  vpc_security_group_ids = [aws_security_group.allow_tls_sg_tf.id]
  connection {

    type = "ssh"
    #host        = self.public_ip
    user        = admin
    private_key = file("./kp_tf_vm.pem")

  }
  tags = {
    Name = "firsrtfvm_db"
  }
}
# pvt ip maybe for pvt server
resource "aws_eip" "lb_NAT_eip_tf" {

  domain = "vpc"
}
#created NAT gateway for Private subnet
resource "aws_nat_gateway" "lb_NAT_eip_tf" {
    allocation_id = aws_eip.lb_NAT_eip_tf.id
  subnet_id = aws_subnet.vpc_pubsub_tf.id

  tags = {
    Name = "gw NAT"
  }

}
#created route table for settings rules b/w gateway & vnet
resource "aws_route_table" "pvt_routetable_tf" {
  vpc_id = aws_vpc.vpc_vnet_tf.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.lb_NAT_eip_tf.id
  }

  tags = {
    Name = "pvt RT"
  }
}

#created route table association for public subnet 
resource "aws_route_table_association" "pvt_rt_a" {
  subnet_id      = aws_subnet.vpc_pvtsub_tf.id
  route_table_id = aws_route_table.pvt_routetable_tf.id
}
