# AWS and Azure VPN

### This is a solution for creating VPN server for AWS and Azure (fast and easy).

---
## AWS

A CloudFormation template for adding an EC2 instance with a fully automated bootstrap script to create a VPN that automatically creates SSL certificates and allows easy management of users.


<details><summary> Description</summary>
<p>

##### Resources created:
- CloudFormation template
  - Ec2 instance 
  - Vpc Selection
  - Subnet selection
  - Security group
  - IAM Profile
  - Role 
  - Policy
  - S3 Bucket
  - SES
  - FlowLog 
  - ENI 
  - EIP 
- VPN bootstrap script for installing and running OpenVPN 

![SCR-20230704-jajh](https://github.com/valconsee/VPN/assets/114985182/5242034b-94bf-4f55-87be-ae89b665af3a)

---

#### Running CloudFormation template

1. Log in to the AWS account
2. Open CloudFormation and create a stack with new resources
3. Load the template and fill in the parameters
4. Connect to the EC2 instance and use scripts to manage users.
- The bootstrap script can run for up to 30 minutes because of the key encryption process.

Navigate to the /root folder and use:
- Create user:
```Bash
./create_vpn_user firstname-lastname
```
- Remove user:
```Bash
./revoke_vpn_user firstname-lastname
```
- Fix network issues:
```Bash
./repair-net
```
- Check who is connected to the VPN
```Bash
cat /var/log/openvpn/openvpn-status.log | sed '/ROUTING/q' | head -n -1
```
- Check out the list of created users
```Bash
ll /root/pki/issued/
```
5. After the user is created send the one-time link to the user

![vpn_user](https://user-images.githubusercontent.com/114985182/205260315-e6a0e8bc-d8aa-4e4a-871e-515950048ce1.png)

![file_io](https://user-images.githubusercontent.com/114985182/205260343-087d725c-6448-475d-97e1-278543676ab2.png)

### Create OpenVPN users through a list

To streamline and simplify the process of creating a larger number of users requiring access, you can utilize a GitHub Action found in the repository. One prerequisite for its usage is that during the deployment of the CloudFormation template, you have provided a verified email address for SES.

Here's a step-by-step guide:

1. Create a new private repository and add secrets for actions to establish a connection with AWS.

2. Create an action to synchronize the user list with OpenVPN.

3. Generate a new user list in the email address format, with each user listed on a separate line. Save the file as:

   ./users/vpn_user_list
   ```Bash
   mail1@example.com
   mail2@example.com
   mail3@example.com
   ```


4. Once the changes are pushed to GitHub, your OpenVPN will create new users and send them an email containing the configuration file. Please note that the configuration file will expire within 24 hours of receiving the email.

By following these steps, you can efficiently generate OpenVPN users and automate the process using GitHub Actions.


</p>
</details>

<details><summary> Video </summary>

https://user-images.githubusercontent.com/114985182/205624165-ba77b327-11bd-40ed-a912-92f6dcecf084.mp4

</details>

---

## Azure

ARM template for adding VM with a fully automated bootstrap script to create a VPN that automatically creates SSL certificates and allows easy management of users.

<details><summary> Description</summary>
<p>

### Resources creation for VPN:
- Resource group
- Virtual network
- Network Interface
- Network security group
- Virtual machine
- Public IP address
- Disk

![Pasted image 20221121004547](https://user-images.githubusercontent.com/114985182/205259764-1d4098b4-e250-49fd-a03e-f9d7ebaef954.png)

---

#### Running ARM temp from Azure CLI

1. Log in to Azure
   ```Bash
   az login
   ```

2. Set the right subscription
   ```Bash
   az account set --subscription "your subscription id"
   ```

3. Create the Resource group
   ```Bash
   az account list-locations
   az group create --name "resource-group" --location "your location"
   ```

4. Deploy the ARM template
   ```Bash
   az group deployment create --name "name of your deployment" --resource-group "resource-group" --template-file "./azuredeploy.json"
   ```

5. In Azure CLI fill in "Linux OS Password" parameter
-   At least 12 characters
-   A mixture of both uppercase and lowercase letters
-   A mixture of letters and numbers

6. Create or remove a VPN user
Connect with SSH to the VM and use scripts to manage users.
- The bootstrap script can run for up to 30 minutes because of the key encryption process.

Navigate to the /root folder and use:
- Create user:
```Bash
./create_vpn_user firstname-lastname
```
- Remove user:
```Bash
./revoke_vpn_user firstname-lastname
```
- Fix network issues:
```Bash
./repair-net
```
- Check who is connected to the VPN
```Bash
cat /var/log/openvpn/openvpn-status.log | sed '/ROUTING/q' | head -n -1
```
- Check out the list of created users
```Bash
ll /root/pki/issued/
```
7. After the user is created send the one-time link to the user

![vpn_user](https://user-images.githubusercontent.com/114985182/205260315-e6a0e8bc-d8aa-4e4a-871e-515950048ce1.png)

![file_io](https://user-images.githubusercontent.com/114985182/205260343-087d725c-6448-475d-97e1-278543676ab2.png)

</p>
</details>

<details><summary> Video </summary>

https://user-images.githubusercontent.com/114985182/205856683-904c2135-0f39-41a8-9bc5-2a493897ed84.mp4

</details>

---


<details><summary>Repository info</summary>
<p>

#### ⚠️  This is a Valcon private repository and it needs a personal access token to be cloned.  ⚠️

The maintainer for the repository: senad.dizdarevic@valcon.com
If you are cloning this repository and creating a new one make sure to change the git clone command in the user-data section of the template.

</p>
</details>
