provider "aws" {
  region = "us-east-1"
}

# Resource Block - EC2 instance
resource "aws_instance" "jenkins_pipeline" {
  ami             = "ami-0c7217cdde317cfec" # Ubuntu 22.04
  instance_type   = "t2.micro"
  key_name        = "tfproject" # Key pair
  user_data       = file("./install_jenkins_script.sh")
  security_groups = [aws_security_group.jenkins_sg.name]

  tags = {
    Name = "jenkins-instance"
  }
}

# Resource Block - Security Group 
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allows ssh connection and web traffic for jenkins-instance"
  vpc_id      = "vpc-0fb73703b42911725" # Your default VPC id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["73.95.123.72/32"] # Your IP address
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All ports
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

# Resource Block - Random provider resource
resource "random_id" "bucket" {
  byte_length = 8
}

# Resource Block - s3 Bucket
resource "aws_s3_bucket" "jenkins_artifacts_bucket" {
  bucket = "jenkins-artifacts-bucket-${random_id.bucket.hex}"
}
# Create a configuration for S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "jenkins_artifacts_bucket" {
  bucket = aws_s3_bucket.jenkins_artifacts_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
# Create a configuration for managing the ACL and set to "private"
resource "aws_s3_bucket_acl" "jenkins_artifacts_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.jenkins_artifacts_bucket]

  bucket = aws_s3_bucket.jenkins_artifacts_bucket.id
  acl    = "private"
}