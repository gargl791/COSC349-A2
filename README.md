# COSC349-A1

### By Leon Chen & Glen Garcia


We are developing a versatile, and user-friendly to-do list web application named To-doey. This application operates on three foundational Docker containers, each handling a specific task. The frontend container enables users to interact with the application, using React + Vite, such as creating to-do tasks. The backend container, built with Node.js and Express.js, manages the REST API. Lastly, the PostgreSQL database container stores user information and task data in a structured schema.

Required Dependencies:

- Vagrant
- AWS Account

### Manual deployment:

`git clone` the repository to a directory, and `cd COSC349-A2` to move into the repository.



Open a terminal at the repository directory, and run 
```
vagrant up
```
After completion of the vagrant VM, run
```
vagrant ssh
```

now you need to have a .pem file obtained from AWS CLI, and name it "`cosc349-2024.pem`"

Place the .pem file in the root directory of the repository, as it is a synced folder between your machine and vagrant VM. In vagrant SSH, run the command: 
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
to ensure, you're isn the correct directory, then 

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