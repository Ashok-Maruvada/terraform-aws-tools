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

# module "nexus" {
#   source  = "terraform-aws-modules/ec2-instance/aws"

#   name = "nexus"

#   instance_type          = "t3.small"
#   vpc_security_group_ids = ["sg-0f10b4b0d09399166"]
#   # convert StringList to list and get first element
#   subnet_id = "subnet-01d795f2252cb194a"
#   ami = data.aws_ami.nexus_ami_info.id
#   tags = {
#     Name = "nexus"
#   }
# }

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