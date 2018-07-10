
### Prerequisities:  

1) AWS CLI installed and configured  
2) Terraform installed  
3) SSH Key for access to EC2 resources configured in AWS account, and available on local machine  
4) If using Windows, Putty installed to set up SSH connections  

### Terraform setup:  

Navigate to the terraform repository folder in a terminal, then:  

`terraform init`  
`terraform plan`  
`terraform apply`  

If you need to remove the resources for a config change ...
`terraform destory`  

Additionally, you can run `terraform apply` repeatedly to make changes to resources if necessary.

### Post-Terraform Setup:

The AWS Infrastructure implements a VPC, within which there are public and private subnets. The Redshift cluster is deployed into the private subnet, and as such it is not directly accessible outside the VPC. On the other hand, EC2 instances are deployed into the public subnet. So, we can use the EC2 machines as proxy servers for connecting to Redshift.   
The steps below describe the necessary setup:

1) Navigate to the EC2 section of the AWS console  
2) Write down the public IP / DNS name of the *analytics* instance  
3) Navigate to the Redshift section of the AWS console  
4) Write down the Redshift cluster endpoint address  
5) SSH to *analytics* via a terminal (use Putty on Windows)  
6) Run `sudo nano /etc/haproxy/haproxy.cfg`  
7) Make sure that the settings in `haproxy-configs.txt` are copied into the `haproxy.cfg` file within the public-facing EC2 instance.  Replace the Redshift endpoint placeholder with the actual Redshift endpoint from step 4 above  
8) Restart haproxy: `sudo service haproxy restart`  
9) Test connecting to the dw from within the EC2 instance: `psql -h <redshift-endpoint> -U <username> -d <database> -p <port>`  
10) Test connecting to the dw from a client, but replace the specific redshift endpoint with the DNS of the public-facing EC2 machine. HAproxy should route traffic on port 5439 to the database if everything is set up correctly.