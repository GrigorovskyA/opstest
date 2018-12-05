# opstest

## Prerequisites

1) Tools

    ```bash
    brew install ansible terraform terraform-inventory jq
    ```

2) Variables

    * `TF_VAR_aws_access_key` - Amazon AWS token (with at least the EC2FullAccess policy)
    * `TF_VAR_aws_secret_key` - Amazon AWS secret (with at least the EC2FullAccess policy)
    * `TF_VAR_aws_ssh_private_key` - path to private key
    * `TF_VAR_aws_ssh_public_key` - path to public key

## Terraform + Ansible

This will define EC2 + ALB in a classic way

1) Describe infrastructure in `terraform/main.tf`. Select environment name (staging, prod, etc) and 
the public port on every node instance (8080 for example) as a target for Application Load Balancer (ALB).
You can have more than one application on the same nodes.

2) Run Terraform

    ```bash
    cd terraform
    terraform init
    terraform apply # ansible/tasks/provision.yml will be call for each new node
    ```
   
3) Deploy (or redeploy) app to the intances. Define variables:
    
    * `APP_COMMIT` - commit hash in repo `https://github.com/a0s/opstest.git`
    * `APP_ENV` - name of environment, for example `staging`
    
4) and run Ansible

    ```bash
    cd ansible
    APP_ENV=staging
    APP_COMMIT=6bcf933400740eaef8d4ae4a81c6cb1304fdf289    
    ansible-playbook -i inventory_terraform tasks/deploy/hello_app.yml
    ```

## Terrampiler DSL + Terraform + Ansible

The fun part. Terrampiler able you to describe EC2 + ALB with nano DSL. After that Terrampiler converts your DSL description into Terraform's format.

```bash
cd terrampiler
```

Describe ec2 instances you want to create in `schema.rb` like this:

```ruby
require './compiler'

Terraform.configure do |c|
  c.ec2 us_west_2a: 1
  c.ec2 us_west_2b: 1
  c.ec2 us_west_2c: 1

  # it helps ansible to find our instances
  c.ec2_tag environment: :staging

  c.alb source_port: 80, target_port: 8080
end

puts Terraform.build!
```

Then generate `main.td` with `ruby schema.rb` 

```bash
ruby schema.rb > main.tf
```

After that use Terraform and Ansible as usual

```bash
terraform init
terraform apply
cd ../ansible
APP_ENV=staging
APP_COMMIT=6bcf933400740eaef8d4ae4a81c6cb1304fdf289
ansible-playbook -i inventory_terrampiler tasks/deploy/hello_app.yml
```
