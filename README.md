# opstest

(The hello_app_java was replaced with hello_app_ruby)

## Prerequisites

1) Tools

    ```bash
    brew install ansible terraform terraform-inventory jq ruby
    ```

2) Variables

    * `TF_VAR_aws_access_key` - Amazon AWS token (with relevant EC2 policy)
    * `TF_VAR_aws_secret_key` - Amazon AWS secret (with relevant EC2 policy)
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

## 🎉Terrampiler DSL + Terraform + Ansible 🎉

The fun part. 
Terrampiler (literally Terraform + compiler) is a nano DSL and compiler to Terraform's format. 
Terrampiler able you to describe EC2 + ALB + Route53 with nano DSL. After "compilation" you will get big boring Terraform script.    

```bash
cd terrampiler
```

Start from describing EC2 instances in `schema.rb` you want to create:

```ruby
require './compiler'

Terraform.configure do |c|
  # Define instances by AZ
  c.ec2 us_west_1a: 0
  c.ec2 us_west_1b: 1

  c.ec2 us_west_1c: 1

  c.ec2 us_west_2a: 1
  c.ec2 us_west_2b: 1
  c.ec2 us_west_2c: 1

  # It helps ansible find our instances (in environment_staging group)
  c.ec2_tag environment: :staging

  # How to build LBs
  c.alb source_port: 80, target_port: 8080

  # Optional. You can skip this if you wouldn't use multi-region configuration.
  # Don'f forget delegate zone to Google
  # TF_VAR_aws_access_key and TF_VAR_aws_secret_key should have permissions for Route53
  c.route53 zone: 'opstestzone.tk'
end

puts Terraform.build!
```

Full list of availibale AZs:
```
ap_northeast_1a, ap_northeast_1c,
ap_northeast_2a, ap_northeast_2c,

ap_south_1a, ap_south_1b,

ap_southeast_1a, ap_southeast_1b,
ap_southeast_2a, ap_southeast_2b, ap_southeast_2c,

ca_central_1a, ca_central_1b

eu_central_1a, eu_central_1b, eu_central_1c,

eu_west_1a, eu_west_1b, eu_west_1c,
eu_west_2a, eu_west_2b,

sa_east_1a, sa_east_1c,

us_east_1b, us_east_1c, us_east_1d, us_east_1e,
us_east_2a, us_east_2b, us_east_2c,

us_west_1a, us_west_1b, us_west_1c,
us_west_2a, us_west_2b, us_west_2c
```

Then generate `main.tf` with `ruby schema.rb` 

```bash
ruby schema.rb > main.tf
```

Then use Terraform and Ansible as usual

```bash
terraform init
terraform apply

cd ../ansible
APP_ENV=staging
APP_COMMIT=6bcf933400740eaef8d4ae4a81c6cb1304fdf289
ansible-playbook -i inventory_terrampiler tasks/deploy/hello_app.yml
```

After deploy you will get multi-region multi-az distributed system (with little strange behavior of Route53's Weighted Records).

![](https://user-images.githubusercontent.com/418868/49621324-d1eb2900-f9d5-11e8-8523-2e590fe179ed.png)
