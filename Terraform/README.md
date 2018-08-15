
### Prerequisities:  

1) AWS CLI installed and configured  
2) Terraform installed  
3) SSH Key for access to EC2 resources configured in AWS account, and available on local machine  
4) If using Windows, Putty installed to set up SSH connections  

### Terraform setup:  

Navigate to the terraform repository folder in a terminal, then:  

`terraform init`  

The Redshift username and password are not specified directly in the .tf files to keep them secure. Add a file called `terraform.tfvars` to your repository - Terraform will automatically read this file when it tries to launch resources on AWS. The file needs to contain the following variables for the configs in this repo to work correctly:

* redshift_master_username
* redshift_master_password

Once you create those variables:  
 
* Check for errors: `terraform plan`  
* Launch resources: `terraform apply`  

If you need to remove the resources for a config change ...
`terraform destory`  

Additionally, you can run `terraform apply` repeatedly to make changes to resources if necessary.

### Post-Terraform Setup:

The AWS Infrastructure implements a VPC with a public and private subnet. The Redshift cluster is deployed into the private subnet, and as such it is not directly accessible outside the VPC. An EC2 instance is deployed into the public subnet and configured as a bastion host to access the database.
   
The steps below describe the necessary setup:

1) Navigate to the EC2 section of the AWS console  
2) Write down the public IP / DNS name of the *analytics* instance  
3) Navigate to the Redshift section of the AWS console  
4) Write down the Redshift cluster endpoint address  
5) SSH to *analytics* via a terminal (use Putty on Windows)  
6) Run `sudo nano /etc/sysctl.conf`  
Modify the setting on line 8 to read `net.ipv4.ip_forward = 1` instead of `net.ipv4.ip_forward = 0`   

7) Run `sudo nano /etc/haproxy/haproxy.cfg`  
8) Make sure that the settings in `haproxy-configs.txt` are copied into the `haproxy.cfg` file within the public-facing EC2 instance.  Replace the Redshift endpoint placeholder with the actual Redshift endpoint from step 4 above  
9) Restart haproxy: `sudo service haproxy restart`  
10) Test connecting to the dw from within the EC2 instance: `psql -h <redshift-endpoint> -U <username> -d <database> -p <port>`  
11) Test connecting to the dw from a client, but replace the specific redshift endpoint with the DNS of the public-facing EC2 bastion host. HAproxy should forward traffic on port 5439 from the bastion host to the database if everything is set up correctly.