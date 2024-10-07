# Todoey on the Cloud

### By Leon Chen & Glen Garcia


We are developing a versatile, and user-friendly to-do list web application named To-doey. This application operates on three foundational Docker containers, each handling a specific task. The frontend container enables users to interact with the application, using React + Vite, such as creating to-do tasks. The backend container, built with Node.js and Express.js, manages the REST API. Lastly, the PostgreSQL database container stores user information and task data in a structured schema.

### Application Architecture
The application is structured:

* Frontend: Uses React + Vite to display the user interface of Todoey
* Backend: Uses Node.js and Express.js for the API calls.
* RDS Database: Stores user, task data in a structured schema.
* SNS Service: Emails the user during account creation, and when a task is created.

Required Dependencies:

- Vagrant
- AWS Account

## Manual deployment:

`git clone` the repository to a directory, and `cd COSC349-A2` to move into the repository.



Open a terminal at the repository directory, and run 
```
vagrant up
```
After completion of the vagrant VM, run
```
vagrant ssh
```

Now you need to have a .pem file obtained from AWS. If you do not have one, create one, and ensure it is called "`cosc349-2024.pem`" as the terraform provisioning expects a .pem file with the name "`cosc349-2024`"

Place the .pem file in the root directory of the repository, as it is a synced folder between your machine and vagrant VM.

Then in vagrant SSH, run the command: 
```
sudo cp /vagrant/cosc349-2024.pem /home/vagrant
```
To copy the .pem file, from the shared folder, into the VM for usage in Terraform.
Now give it r/w privileges by running
```
sudo chmod 600 /home/vagrant/cosc349-2024.pem
```

Now you will need to copy your credentials from AWS CLI to /.aws/credentials. You can do this by running

```
cd ~
```
to ensure, you're in the correct directory, then 

```
nano .aws/credentials
```
and paste your details obtained from AWS CLI there and save.






Now go to the shared folder directory by running

```
cd /vagrant/
```

Run `terraform init` then `terraform plan` and finally `terraform apply` typing yes.


### Permission Denied Error

If you come across a permission denied error, regarding the "cosc349-2024.pem" file, in vagrant ssh, you need to run 
```
sudo chown vagrant:vagrant /home/vagrant/cosc349-2024.pem
```

To change the ownership to the user "vagrant" in the vagrant VM

### Cleaning up

To clean up and destroy all instances, and security groups in AWS provisioned by Terraform, redirect to the vagrant shared folder.

```
cd /vagrant/
```
then
```
terraform destroy
```
and type "yes" to the prompts to destroy.

## Redeployment steps when AWS lab session stops or timer ends:

The steps for redeploying the frontend and backend EC2 instances after the lab session ends, or when the EC2 instances are shut down are as follows:

1) You will need to access the EC2 instance via ssh or by AWS' EC2 instance connect.
2) After successful connection to the EC2 instances, run the commands:
```
cd frontend
```
or 
```
cd backend
```
depending on which EC2 instance you are in. 

In the backend folder contains a credentials file that is copied to the EC2 instances during terraform provisioning. You may also have to replace its content with new AWS CLI details, depending on how long before the old credentials expire. Use the command
```
nano ./credentials
```
To access credentials and replace the content with new AWS CLI credentials. (The credentials is used for aws-sdk for SNS to work)

Then run the "`redeploy.sh`" script to build and run the docker containers. Do this for both instances.
```
sudo ./redeploy.sh
```

Note: This will only work if the current instances are using Elastic IP Address (EIP), otherwise you will have to update backend and frontend's .env files in the EC2 instance SSH or instance connect, to match the newly generated IPv4s.
