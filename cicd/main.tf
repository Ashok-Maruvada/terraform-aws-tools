module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-Master"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-0b79601d86b17db45"] #default VPC SG and give same in below for agent and nexus
  subnet_id = "subnet-01d795f2252cb194a" #any default Subnet ID 
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins.sh")
  tags = {
    Name = "jenkins-Master"
  }
}

module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type          = "t3.micro"
  vpc_security_group_ids = ["sg-0b79601d86b17db45"]
  # convert StringList to list and get first element
  subnet_id = "subnet-01d795f2252cb194a"
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins-agent.sh")
  tags = {
    Name = "jenkins-agent"
  }
}
# keeping public key in server and login with private key
resource "aws_key_pair" "tools" {
  key_name = "tools"
  # you can paste the public key directly like this
  #public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILXDe5ueCdCaBhf3s1CQN2sIrNjrzLvvykPE6II6odX6 ashok@INBook_X1"
  public_key = file("C:/D-AWS/Devops/Key/tools.pub")
  # ~ means windows home directory
}

module "nexus" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "nexus"

  instance_type          = "t3.medium"
  vpc_security_group_ids = ["sg-0b79601d86b17db45"]
  # convert StringList to list and get first element
  subnet_id = "subnet-01d795f2252cb194a"
  ami = data.aws_ami.nexus_ami_info.id
  key_name = aws_key_pair.tools.key_name
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30
    }
  ]
  tags = {
    Name = "nexus"
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins.public_ip
      ]
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins_agent.private_ip
      ]
    },
    {
      name    = "nexus"
      type    = "A"
      ttl     = 1
      records = [
        module.nexus.private_ip
      ]
    }
  ]

}