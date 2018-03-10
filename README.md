# TerraVPN

This is a [Terraform](https://www.terraform.io/) project to build and start an [OpenVPN](https://openvpn.net/) server running within AWS EC2 instance of any region or size. In a single command, start up a new personal OpenVPN server in any region in AWS in less than a minute.

Disclaimer: This is very much a work-in-progress and an experiment.

### Setup

1. Setup AWS

   Create/Use an IAM Setting in your AWS configuration that can at a minimum manage EC2 and Security Groups. Set the configuration in your shell.

   ```sh
   export AWS_ACCESS_KEY_ID="<access id>"
   export AWS_SECRET_ACCESS_KEY="<access secret>"
   ```

2. Install [Terraform](https://www.terraform.io/).
3. Checkout this Repository.
4. Run `terraform init` in the projects directory.
5. Run `terraform plan` to validate the project on your machine.

### Run

To create your own OpenVPN server: run `terraform apply` in the directory of this project, that's it.

This will do a few things:

1. Creates a fresh SSH Key pair in the `keys` directory for this instance only.
2. Creates a new Security Group and EC2 Instance in AWS.
3. Installs and configures OpenVPN on new instance.
4. Creates a client configuration file for your device. You will be presented with a download command on success to run via `scp`.

### Options

To run your new setup in a separate region, pass `-var "region=ca-central-1"`  or equivalent to `terraform plan` and `terraform apply`.
To use a different instance size, pass `-var "instance_size=t2.micro"` or equivalent to `terraform plan` and `terraform apply`.

### Destroy

To take down your already created VPN: run `terraform destroy` in the project directory.

### Notes

Read more about setting up OpenVPN on Ubuntu with [Digital Ocean's setup](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-16-04).
