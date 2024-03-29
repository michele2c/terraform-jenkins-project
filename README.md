# terraform-jenkins-project

Hello, there! This project is my journey into cloud computing as a Cloud DevOps Engineer.
In this project, we will use Terraform to create infrastructure automation to provision and manage AWS resources and deploy Jenkins CI/CD pipeline.

# Deploying Jenkins using Terraform
*Automate your infrastructure*

## Use Case

Your team would like to start using Jenkins as their CI/CD tool to create pipelines for DevOps projects. They need you to create the Jenkins server using Terraform so that it can be used in other environments and so that changes to the environment are better tracked.


## What do you need?

To ensure a successful start for this guide, you may need the following:

- AWS Console Management account
- Knowledge of Cloud9 and AWS resources
- AWS Key pair

My environment setup: For this project, I am using a Cloud9 environment with Terraform installed.

If you need guidance to install Terraform, please refer to this documentation: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform.

---
## Objectives

**Foundational**

✔ Deploy an AWS EC2 instance in the default VPC.

✔ Bootstrap the EC2 instance with a script that will install and start Jenkins.

✔ Create and assign a Security Group to the Jenkins Security Group that allows traffic on port 22 from your IP and allows traffic from port 8080.

✔ Create a S3 bucket for the Jenkins Artifacts that is not open to the public.

✔ Verify that Jenkins is reachable via port 8080 in your browser.

## Let’s get started!
### 1. Deploy an AWS EC2 instance in the default VPC

To start our project, open the Cloud9 environment if you haven’t yet and check if Terraform is installed with terraform version command.

Let’s create a folder to stay organized and two files “terraform.tf” and “main.tf”.

    mkdir terraform-jenkins-project && cd terraform-jenkins-project

    touch main.tf terraform.tf

As we will be launching our infrastructure on AWS, we need to configure the provider block for AWS in the “terraform.tf” file.
```
# Provider block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.36.0"
    }
  }
}
```
In the “main.tf” file, we will begin coding the Jenkins instance by creating our first resource block. Also, I am configuring the infrastructure to be deployed in the us-east-1 region, although you are free to select a region closer to you.
    provider "aws" {
      region = "us-east-1"
    }
    
    # Resource Block - EC2 instance
    resource "aws_instance" "jenkins_pipeline" {
      ami             = "ami-0c7217cdde317cfec" # Ubuntu 22.04
      instance_type   = "t2.micro"
      key_name        = "tfproject" # Key pair
    
      tags = {
        Name = "jenkins-instance"
      }
    }
    
Let’s go over this code snippet.

`provider “aws” {region = “us-east-1”}` ⇒ This line indicates that we are using AWS provider and we want to deploy our resources in the “us-east-1” region.

`resource "aws_instance" "jenkins_pipeline" {}` ⇒ Here we opened a resource block, specifying the type of resource "aws_instance" and its name "jenkins_pipeline" . Together those two form a unique ID for this resource block.

`ami` ⇒ The AMI of the instance.

`instance_type` ⇒ The size of the instance.

`key_name` ⇒ Key pair we will use to do an SSH connection.

*Note: If you haven’t yet, make sure you create key pair.*

`tags = {Name = "jenkins-instance"}` ⇒ The name of the instance.

### 2. Bootstrap the EC2 instance with a script that will install and start Jenkins

For this step, I wrote a shell script file that installs Jenkins and sets the necessary configuration for our instance. Then, I saved it as “install_jenkins_script.sh” in the project folder.

Create the script by copying and pasting the code below.
    
    #!/bin/bash
    sudo apt-get update -y
    # install java
    sudo apt install fontconfig openjdk-17-jre -y
    # install jenkins
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install jenkins -y
    sudo systemctl enable jenkins

Let’s map it in our code, adding the `user_data` argument and the Terraform function called `file()`, it should look like this `user_data = file("./install_jenkins_script.sh")`.
```
provider "aws" {
  region = "us-east-1"
}

# Resource Block - EC2 instance
resource "aws_instance" "jenkins_pipeline" {
  ami             = "ami-0c7217cdde317cfec" # Ubuntu 22.04
  instance_type   = "t2.micro"
  key_name        = "tfproject" # Key pair
  user_data       = file("./install_jenkins_script.sh")
  tags = {
    Name = "jenkins-instance"
  }
}
```

### 3. Create and assign a Security Group to the Jenkins Security Group that allows traffic on port 22 from your IP and allows traffic from port 8080

To create a Security Group, we need to add another resource block. This block should contain arguments like “ingress” and “egress” rules for inbound and outbound traffic. These rules will allow traffic on port 22 and port 8080. Make sure to add the VPC id of your AWS Default VPC and your IP address when indicated.

    # Resource Block - Security Group 
    resource "aws_security_group" "jenkins_sg" {
      name        = "jenkins-sg"
      description = "Allows ssh connection and web traffic for jenkins-instance"
      vpc_id      = "<VPC-ID>" # Your default VPC id
    
      ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["<YOUR-IP-ADDRESS>"] # Your IP address
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

Now, add a new argument `security_groups = []` to our instance resource block. And pass the ID of the security group resource along with the name argument. As I said before, this ID is the combination of the resource type and the resource name, `aws_security_group.jenkins_sg` .

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

Awesome! We’re all set to launch our Jenkins instance. Let’s dive in with Terraform commands:

The first step to prepare Terraform for the work ahead is `terraform init` command. When we run `terraform init`, we’re essentially telling Terraform to set up its environment for our project.

    terraform init

Next, `terraform fmt` our friendly formatting assistant. When we run this command, Terraform looks into all .tf files and formats our code, making it organized and consistent, ensuring that all the code looks easy to read.

    terraform fmt

Now, let’s validate if the configuration is in order and there are no syntax errors or typos by running `terraform validate` command.

    terraform validate

Once we have our configuration validated, let’s run the `terraform plan` command to get a preview of our future infrastructure.
    terraform plan

This command prints out all the resources that will be created, modified, or destroyed based on our configuration. It’s incredibly handy!
And finally, let’s deploy our instance with `terraform apply` .
    terraform apply
    
    #the -auto-approve flag will execute the plan without prompting for your confiramtion
    terraform apply -auto-approve
Excellent! Terraform has successfully deployed our Jenkins instance.

### 4. Create a S3 bucket for the Jenkins Artifacts that is not open to the public

To set up an S3 bucket for Jenkins artifacts, we will add a new provider called “random”. This provider will assist us in generating a unique name for our bucket.

Let’s install this provider by copying and pasting the code below into our Terraform configuration file.
```
random = {
source = "hashicorp/random"
version = "3.6.0"
}
```
In the “main.tf, add a new resource block to create a random identifier with a length of 8 bytes.
```
# Resource Block - Random provider resource
resource "random_id" "bucket" {
  byte_length = 8
}
```
*Note: Using this provider is not a requirement for creating bucket names. It just helps to meet AWS requirements for a bucket name to be globally unique.*

Then, add three more resources block for the s3 bucket configuration.
```
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
```
Run the following commands:
```
# Download the random provider
terraform init

# Check the formatting
terraform fmt

# Validate configuration
terraform validate

# Visualize changes
terraform plan

# Execute the plan
terraform apply -auto-approve
```
### 5. Verify that Jenkins is reachable via port 8080 in your browser

After deploying our infrastructure, let’s connect to the Jenkins console and verify if it’s working as planned. First, we need to retrieve the password generated by Jenkins to unlock the console.

SSH into your instance run the following command in the terminal to verify if Jenkins was installed correctly and it’s running.

    sudo systemctl status jenkins

Then, retrieve the password.
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword

Browser to **http://<ec2-public-ip-address>:8080**. And follow the instructions to unlock Jenkins.

Mission accomplished! We’ve successfully used Terraform to automate a Jenkins CI/CD Pipeline Infrastructure using AWS resources.

---

**⚠ ️Important: Let's clean up!**
If you followed this guide for learning purposes and no longer need those resources, make sure to use `terraform destroy` command to clean up all of those resources.

---

## References
Terraform Providers - https://registry.terraform.io/browse/providers
AWS Provider documentation - https://registry.terraform.io/providers/hashicorp/aws/latest/docs
Random Provider documentation - https://registry.terraform.io/providers/hashicorp/random/latest/docs
Jenkins installation - https://www.jenkins.io/doc/book/installing/linux/
