# terraform-jenkins-project
    Hello, there! This project is my journey into cloud computing as a Cloud DevOps Engineer.

# Deploying Jenkins using Terraform
/*Automate your infrastructure*/

In this project, we will use Terraform to create infrastructure automation to provision and manage AWS resources and deploy Jenkins CI/CD pipeline.

## Use Case

Your team would like to start using Jenkins as their CI/CD tool to create pipelines for DevOps projects. They need you to create the Jenkins server using Terraform so that it can be used in other environments and so that changes to the environment are better tracked.

## What do you need?

To ensure a successful start for this guide, you may need the following:

    - AWS Console Management account
    - Knowledge of Cloud9 and AWS resources
    - AWS Key pair

My environment setup: For this project, I am using a Cloud9 environment with Terraform installed.

If you need guidance to install Terraform, please refer to this documentation: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform.

## Objectives

*Foundational*

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
