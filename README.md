# opstest

## Prerequisites

```bash
brew install ansible terraform terraform-inventory jq
```

## Terraform

1) Define variables:

    * `TF_VAR_aws_access_key` - Amazon AWS token 
    * `TF_VAR_aws_secret_key` - Amazon AWS secret 
    * `TF_VAR_aws_key_path_priv` - path to private key, default is `~/.ssh/id_rsa`
    * `TF_VAR_aws_key_path_pub` - path to public key, default is `~/.ssh/id_rsa.pub`

2) Describe infrastructure in `terraform/main.tf`. Select environment name (staging, prod, etc) and 
public port on every node instance (8080 for example) as target for Application Load Balancer (ALB).
You can have more than one application on same nodes.

3) Run terraform

    ```bash
    cd terraform
    terraform apply
    # ansible/tasks/provision.yml will be call for each new node
    ```
    
## Deploy app with Ansible

1) Define variables:
    
    * `APP_COMMIT` - commit hash in `https://github.com/a0s/opstest.git` repo
    * `APP_ENV` - name of environment, for example `staging`
    
2) Deploy

    ```bash
    cd ansible
    ansible-playbook -i inventory tasks/deploy/hello_app.yml
    ```
