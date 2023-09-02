# VPN

**vpn** module is responsible for virtual private network in `dev` infrastructure on AWS.

## Table of contents

- [Structure](#structure)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Usage](#usage)
   - [VPN usage](#VPN)
- [Maintenance](#maintenance)
- [Documentation](#documentation)

## Structure

VPN is a Terraform module:

- `main.tf` - EC2 instance for running OpenVPN
- `iam.tf` - AWS IAM configuration for the VPN module
- `s3.tf` - AWS S3 bucket for storing the list of users
- `data.tf` - get access to the list of AWS resources
- `dev.tfvars` - manage variable assignments systematically in a file
- `network.tf` - configuration for VPC Flow Logs
- `providers.tf` - providers responsible for understanding API interactions
- `variables.tf` - customize aspects of Terraform module
- `userData.tmpl` - configuration file with user_data field

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) - Infrastructure as code tool
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - AWS Command Line Interface
- AWS VPC 
- AWS SES
- AWS S3 (tf.state)
- SSH key

## Configuration

1. Set up `dev` AWS profile


2. Set `AWS_PROFILE` environment variable:

   - MacOS/Linux: `export AWS_PROFILE=dev`
   - Windows: `set AWS_PROFILE=dev`
   - PowerShell: `$env:AWS_PROFILE = 'dev'`

## Usage

From the specific root module folder, e.g. `dev/vpn` edit `.tfvars` file for the environment you need and then run:

```shell
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

to initialize the module, preview changes and apply them.

   > The bootstrap script can run for up to 30 minutes because of the key encryption process. To check if the script is finished you can connect to the instance using SSM and run the command: `cat /var/log/cloud-init-output.log`

### VPN

1. For manual usage connect to the EC2 instance and follow next steps:

- Navigate to the /root folder and use.

- Create user:
   ```shell
   ./create_vpn_user firstname.lastname@example.com
   ```
- Remove user:
   ```shell
   ./revoke_vpn_user firstname.lastname@example.com
   ```
- Create users from the list:
   ```shell
   ./create_vpn_user_list
   ```
   Add users to /root/list_of_new_users.txt
- Fix network issues:
   ```shell
   ./repair-net
   ```
- Check out the list of created users
   ```shell
   ll /root/pki/issued/
   ```
- Check who is connected to the VPN
   ```shell
   cat /var/log/openvpn/openvpn-status.log | sed '/ROUTING/q' | head -n -1
   ```

2. For automated users management you can use GitHub action [manage_users.yml]()

Prerequisites:

- Validate AWS SES identity for sending configuration files
- Create folder and file: `mkdir ./users && touch ./users/users`
- Edit file `users` and place the list of users you want to have access to the VPN
   > The list of users must to be formatted as rows of email address

## Maintenance

- The `server certificate` is managed through a script that is automatically executed one day before its expiration. 

- The `client certificate` needs to be renewed before its expiration, and you will receive the exact certificate expiration date via notification or email.

- Within the document `/root/list_of_new_users.txt`, there is a list of users who currently have VPN access.

- The VPN server is configured to operate in `Split Tunneling mode`, where only traffic related to AWS VPC (private addresses) is routed through the VPN, while all other traffic continues to use the client's local connection.

## Documentation

- [Terraform](https://developer.hashicorp.com/terraform/docs)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
