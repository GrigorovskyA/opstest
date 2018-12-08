require './compiler'

Terraform.configure do |c|
  # Define instances by AZ
  c.ec2 us_east_1a: 0
  c.ec2 us_east_1b: 1
  c.ec2 us_east_1c: 1
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
