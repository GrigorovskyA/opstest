require './compiler'

Terraform.configure do |c|
  # Define instances count by AZ
  c.ec2 ap_northeast_1a: 0
  c.ec2 ap_northeast_1c: 0
  c.ec2 ap_northeast_2a: 0
  c.ec2 ap_northeast_2c: 0
  c.ec2 ap_south_1a: 0
  c.ec2 ap_south_1b: 0
  c.ec2 ap_southeast_1a: 0
  c.ec2 ap_southeast_1b: 0
  c.ec2 ap_southeast_2a: 0
  c.ec2 ap_southeast_2b: 0
  c.ec2 ap_southeast_2c: 0
  c.ec2 ca_central_1a: 0
  c.ec2 ca_central_1b: 0
  c.ec2 eu_central_1a: 0
  c.ec2 eu_central_1b: 0
  c.ec2 eu_central_1c: 0
  c.ec2 eu_east_2b: 0
  c.ec2 eu_east_2c: 0
  c.ec2 eu_west_1a: 0
  c.ec2 eu_west_1b: 0
  c.ec2 eu_west_1c: 0
  c.ec2 eu_west_2a: 0
  c.ec2 eu_west_2b: 0
  c.ec2 sa_east_1a: 0
  c.ec2 sa_east_1c: 0
  c.ec2 us_east_1b: 0
  c.ec2 us_east_1c: 0
  c.ec2 us_east_1d: 0
  c.ec2 us_east_1e: 0
  c.ec2 us_east_2a: 0
  c.ec2 us_west_1a: 0
  c.ec2 us_west_1c: 0
  c.ec2 us_west_2a: 1
  c.ec2 us_west_2b: 1
  c.ec2 us_west_2c: 0

  # It helps ansible to find our instances
  c.ec2_tag environment: :staging

  # How to build LBs
  c.alb source_port: 80, target_port: 8080
end

puts Terraform.build!
