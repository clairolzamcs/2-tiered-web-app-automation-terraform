# Final Project: Two-Tier web application automation with Terraform

## Deployment Steps
> **IMPORTANT:** Repeat these steps for each environment.

> **NOTE:** Update `<environment>` to ***dev, staging or prod***.

### S3 Bucket Setup
Create S3 buckets for each environment with below names:

| Environment | S3 Bucket Name |
| ----------- | ----------- |
| dev | dev-finalproj-group1 |
| staging | staging-finalproj-group1 |
| prod | prod-finalproj-group1 |
### Terminal Setup
```
alias tf=terraform
```
### Deployment of Network Infrastructure
1. Go to `~/terraform/environments/<environment>/network/` directory.
    ```
    cd ~/terraform/environments/<environment>/network/
    ```
2. Deploy the **VPC, Public and Private Subnets, Internet Gateway, NAT Gateway, Elastic IP and Route Tables**.
    ```
    tf init
    tf fmt && tf validate
    tf plan
    tf apply -auto-approve
    ```
### SSH Keys Setup
1. Go to `~/terraform/environments/<environment>/webserver/` directory.
    ```
    cd ~/terraform/environments/<environment>/webserver/
    ```
2. Generate SSH keys:
    ```
    ssh-keygen -t rsa -f group1-<environment>
    ```
3. Change permission level of the keys to 400.
    ```
    chmod 400 group1-<environment>
    ```
### Deployment of Webservers
> **NOTE:** Replace both `my_private_ip` and `my_public_ip` in `~/terraform/environments/<environment>/webservers/variables.tf` with your Cloud9 instance's IPs.

Deploy the **Security Groups, Application Load Balancer, Launch Configuration, Bastion and Auto Scaling Group**. It also creates images within the S3 Bucket and uplaods the images from images folder.
```
tf init
tf fmt && tf validate
tf plan
tf apply -auto-approve
```
### Access the Webpage via Load Balancer's DNS Name
1. After deploying the webserver, there will be an output called `website` in the terminal or in `AWS Console > Load Balancers under EC2`.
2. Copy and paste it to the web browser.

> **IMPORTANT:** Repeat these steps for each environment.

> **NOTE:** Update `<environment>` to **dev, staging** or **prod**.
1. Destroy the `webservers` first.
    ```
    cd ~/terraform/environments/<environment>/webserver/
    tf destroy -auto-approve
    ```
2. Then `network`.
    ```
    cd ~/terraform/environments/<environment>/network/
    tf destroy -auto-approve
    ```

[![tfsec](https://github.com/Project-GroupOne/final-project/actions/workflows/tfsec.yml/badge.svg)](https://github.com/Project-GroupOne/final-project/actions/workflows/tfsec.yml)

[![build](https://github.com/Project-GroupOne/final-project/actions/workflows/trivy.yml/badge.svg)](https://github.com/Project-GroupOne/final-project/actions/workflows/trivy.yml)
