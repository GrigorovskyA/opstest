# Opstest

(The `hello_app_java` was replaced with `hello_app_ruby`)

## Prerequisites

1) Tools

    ```bash
    brew install ansible terraform terraform-inventory jq ruby git
    ```

2) Variables

    * `TF_VAR_aws_access_key` - Amazon AWS token (with relevant EC2 policy)
    * `TF_VAR_aws_secret_key` - Amazon AWS secret (with relevant EC2 policy)
    * `TF_VAR_aws_ssh_private_key` - path to private key
    * `TF_VAR_aws_ssh_public_key` - path to public key

## Terraform + Ansible

Using Terraform and Ansible to describe and use EC2 + ALB in a classic way.

Change to working dir:

```bash
cd terraform
```

Describe variables in `variables.tf`. Describe instances and ALB in `main.tf`. Select environment name (staging, prod, etc) and the public port on every node instance (8080 for example) as a target for Application Load Balancer (ALB).

Run Terraform

```bash
export AWS_ACCESS_KEY_ID=${TF_VAR_aws_access_key}
export AWS_SECRET_ACCESS_KEY=${TF_VAR_aws_secret_key}
terraform init
terraform apply # ansible/tasks/provision.yml will be call for each new node
```
   
Deploy (or redeploy) app to the intances. Define variables:
    
* `APP_COMMIT` - commit hash in repo `https://github.com/a0s/opstest.git`, default: last commit
* `APP_ENV` - name of environment, default: `staging`

Then run Ansible

```bash
cd ansible
ansible-playbook -i inventory_terraform tasks/deploy/hello_app.yml
```

After deploy you will get multi-az distributed system. See `lb_dns_name = xxx` for ALB's public dns.

## 🎉Terrampiler DSL🎉 + Terraform + Ansible

The fun part. 
Terrampiler (literally Terraform + compiler) is a nano DSL and compiler to Terraform's format. 
Terrampiler able you to describe EC2 + ALB + Route53 with nano DSL. After "compilation" you will get big boring Terraform script.    

Change to working dir:

```bash
cd terrampiler
```

Describe your EC2 instances in `schema.rb`:

```ruby
require './compiler'

Terraform.configure do |c|
  # Define instances by AZ
  # ALB in each region requires at least two different AZ
  c.ec2 us_east_1a: 0
  c.ec2 us_east_1b: 1
  c.ec2 us_east_1c: 1
  c.ec2 us_west_2a: 1
  c.ec2 us_west_2b: 1
  c.ec2 us_west_2c: 1

  # It helps ansible find our instances (in environment_staging group)
  c.ec2_tag environment: :staging

  # Describe ALB in each region
  c.alb source_port: 80, target_port: 8080

  # Optional. You can skip this if you wouldn't use multi-region configuration.
  # Don'f forget delegate zone to Google
  # TF_VAR_aws_access_key and TF_VAR_aws_secret_key should have permissions for Route53
  c.route53 zone: 'opstestzone.tk'
end

puts Terraform.build!
```

Then generate `main.tf` with `ruby schema.rb` 

```bash
ruby schema.rb > main.tf
```

Deploy instances and other infrastructure with Terraform:

```bash
terraform init
terraform apply
```

Then use Ansible to deploy `hello_app_ruby`. Define variables:
    
* `APP_COMMIT` - commit hash in repo `https://github.com/a0s/opstest.git`, default: last commit
* `APP_ENV` - name of environment, default: `staging`

Then run Ansible:

```bash
cd ansible
ansible-playbook -i inventory_terrampiler tasks/deploy/hello_app.yml
```

After deploy you will get multi-region multi-az distributed system (with little strange behavior of Route53's Weighted Records).

![](https://user-images.githubusercontent.com/418868/49621324-d1eb2900-f9d5-11e8-8523-2e590fe179ed.png)

List of available AZs:

```ruby
{
  ap_northeast_1: [:ap_northeast_1a, :ap_northeast_1c, :ap_northeast_1d],
  ap_northeast_2: [:ap_northeast_2a, :ap_northeast_2c],
  ap_south_1: [:ap_south_1a, :ap_south_1b],
  ap_southeast_1: [:ap_southeast_1a, :ap_southeast_1b, :ap_southeast_1c],
  ap_southeast_2: [:ap_southeast_2a, :ap_southeast_2b, :ap_southeast_2c],
  ca_central_1: [:ca_central_1a, :ca_central_1b],
  eu_central_1: [:eu_central_1a, :eu_central_1b, :eu_central_1c],
  eu_west_1: [:eu_west_1a, :eu_west_1b, :eu_west_1c],
  eu_west_2: [:eu_west_2a, :eu_west_2b, :eu_west_2c],
  eu_west_3: [:eu_west_3a, :eu_west_3b, :eu_west_3c],
  sa_east_1: [:sa_east_1a, :sa_east_1c],
  us_east_1: [:us_east_1a, :us_east_1b, :us_east_1c, :us_east_1d, :us_east_1e, :us_east_1f],
  us_east_2: [:us_east_2a, :us_east_2b, :us_east_2c],
  us_west_1: [:us_west_1b, :us_west_1c],
  us_west_2: [:us_west_2a, :us_west_2b, :us_west_2c]
}
```
