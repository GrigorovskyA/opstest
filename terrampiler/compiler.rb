module CrazyDash
  def _
    str = self
    sym = str.is_a?(Symbol)
    result = str.to_s.split('_').map { |s| s.split('-').join('_') }.join('-')
    sym ? result.to_sym : result
  end
end

class String
  include CrazyDash
end

class Symbol
  include CrazyDash
end

class Terraform
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def build!
      config.result
    end
  end

  class Configuration
    def initialize
      @ec2 = {}
      @ec2_tag = {}
    end

    def ec2(options = {})
      options.each do |az, count|
        fail("Count should be >= 0, got `{#{az.inspect}: #{count.inspect}}'") unless count.to_i >= 0
        fail("AZ should existing, got `{#{az.inspect}: #{count.inspect}}'") unless get_all_azs.include?(az)
        next unless count.to_i > 0

        region = get_region_by_az(az)
        @ec2[region] ||= {}
        @ec2[region][az] ||= 0
        @ec2[region][az] += count
      end
    end

    def ec2_tag(options = {})
      options.each do |key, value|
        @ec2_tag[key] = value
      end
    end

    def alb(source_port:, target_port:)
      @alb_source_port = source_port
      @alb_target_port = target_port
    end

    def route53(zone:)
      @route53_zone = zone
    end

    REGIONS_AZ = {
      ap_northeast_1: [:ap_northeast_1a, :ap_northeast_1c],
      ap_northeast_2: [:ap_northeast_2a, :ap_northeast_2c],
      ap_south_1: [:ap_south_1a, :ap_south_1b],
      ap_southeast_1: [:ap_southeast_1a, :ap_southeast_1b],
      ap_southeast_2: [:ap_southeast_2a, :ap_southeast_2b, :ap_southeast_2c],
      ca_central_1: [:ca_central_1a, :ca_central_1b],
      eu_central_1: [:eu_central_1a, :eu_central_1b, :eu_central_1c],
      eu_west_1: [:eu_west_1a, :eu_west_1b, :eu_west_1c],
      eu_west_2: [:eu_west_2a, :eu_west_2b],
      sa_east_1: [:sa_east_1a, :sa_east_1c],

      us_east_1: [:us_east_1b, :us_east_1c, :us_east_1d, :us_east_1e],
      us_east_2: [:us_east_2a, :us_east_2b, :us_east_2c],

      us_west_1: [:us_west_1a, :us_west_1b, :us_west_1c],
      us_west_2: [:us_west_2a, :us_west_2b, :us_west_2c],
    }

    def get_region_by_az(az)
      REGIONS_AZ.each do |region, azs|
        return region if azs.include?(az)
      end
      fail("Region not found for AZ `#{az}'")
    end

    def get_all_azs
      REGIONS_AZ.values.flatten
    end

    def get_number_cidr_by_az(az)
      numbers = { a: 1, b: 2, c: 3, d: 4, e: 5, f: 6 }
      region = get_region_by_az(az)
      az_letter = az.to_s.sub(region.to_s, '').to_sym
      fail("Unknown region letter for `#{az.inspect}'") unless numbers.key?(az_letter)
      numbers[az_letter]
    end

    def aws_providers
      result = []
      REGIONS_AZ.keys.each do |region|
        result << <<~EOS
          provider "aws" {
            alias = "#{region._}"
            region = "#{region._}"
            access_key = "${var.aws_access_key}"
            secret_key = "${var.aws_secret_key}"
          }
        EOS
      end
      result
    end

    def aws_input
      <<~EOS
        variable "aws_access_key" {
          default = ""
        }
        
        variable "aws_secret_key" {
          default = ""
        }
        
        variable "aws_ssh_public_key" {
          default = ""
        }
        
        variable "aws_ssh_private_key" {
          default = ""
        }
      EOS
    end

    def aws_ami
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          data "aws_ami" "aws_ami_ubuntu_#{region}" {
            provider = "aws.#{region._}"
            most_recent = true
          
            filter {
              name = "name"
              values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04*"]
            }
          
            filter {
              name = "virtualization-type"
              values = ["hvm"]
            }
          }
        EOS
      end
      result
    end

    def aws_security_group_ssh
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_security_group" "aws_security_group_ssh_#{region}" {
            provider = "aws.#{region._}"
            name = "allow_ssh"
            description = "Allow SSH traffic"
            vpc_id = "${aws_vpc.aws_vpc_#{region}.id}"

            ingress {
              from_port = 22
              to_port = 22
              protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
              ipv6_cidr_blocks = ["::/0"]
            }
          }
        EOS
      end
      result
    end

    def aws_security_group_internet_access
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_security_group" "aws_security_group_internet_access_#{region}" {
            provider = "aws.#{region._}"
            name = "allow_internet_access"
            description = "Allow access to internet"
            vpc_id = "${aws_vpc.aws_vpc_#{region}.id}"

            egress {
              from_port = 0
              to_port = 0
              protocol = "-1"
              cidr_blocks = ["0.0.0.0/0"]
              ipv6_cidr_blocks = ["::/0"]
            }
          }
        EOS
      end
      result
    end

    def aws_security_group_http_proxy
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_security_group" "aws_security_group_http_proxy_#{region}" {
            provider = "aws.#{region._}"
            name = "allow_http_proxy"
            description = "Allow HTTP 8080 traffic"
            vpc_id = "${aws_vpc.aws_vpc_#{region}.id}"

            ingress {
              from_port = 8080
              to_port = 8080
              protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
              ipv6_cidr_blocks = ["::/0"]
            }
          }
        EOS
      end
      result
    end

    def aws_security_group_default
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          data "aws_security_group" "aws_security_group_#{region}" {
            provider = "aws.#{region._}"
            name = "default"
            vpc_id = "${aws_vpc.aws_vpc_#{region}.id}"            
          }
        EOS
      end
      result
    end

    def aws_key_pair
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_key_pair" "aws_key_pair_#{region}" {
            provider = "aws.#{region._}"
            key_name = "server"
            public_key = "${file(var.aws_ssh_public_key)}"
          }
        EOS
      end
      result
    end

    def aws_vpc
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_vpc" "aws_vpc_#{region}" {
            provider = "aws.#{region._}"
            cidr_block = "10.0.0.0/16"
            enable_dns_hostnames = true
            enable_dns_support = true
          }
        EOS
      end
      result
    end

    def aws_internet_gateway
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_internet_gateway" "aws_internet_gateway_#{region}" {
            provider = "aws.#{region._}"
            vpc_id = "${aws_vpc.aws_vpc_#{region}.id}"
          }
        EOS
      end
      result
    end

    def aws_route_gateway
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_route" "aws_route_gateway_#{region}" {
            provider = "aws.#{region._}"
            route_table_id         = "${aws_vpc.aws_vpc_#{region}.main_route_table_id}"
            destination_cidr_block = "0.0.0.0/0"
            gateway_id             = "${aws_internet_gateway.aws_internet_gateway_#{region}.id}"
          }
        EOS
      end
      result
    end

    def aws_subnet
      result = []
      @ec2.each do |region, azs|
        azs.each do |az, _|
          result << <<~EOS
            resource "aws_subnet" "aws_subnet_#{az}" {
              provider = "aws.#{region._}"
              availability_zone = "#{az._}"
              vpc_id = "${aws_vpc.aws_vpc_#{region}.id}"
              map_public_ip_on_launch = true
              cidr_block = "10.0.#{get_number_cidr_by_az(az)}.0/24"                          
            }

            output "aws_subnet_#{az}_availability_zone" {
              value = "${aws_subnet.aws_subnet_#{az}.availability_zone}"
            }
          EOS
        end
      end
      result
    end

    def aws_instance
      result = []
      @ec2.each do |region, azs|
        azs.each do |az, count|
          result << <<~EOS
            resource "aws_instance" "aws_instance_#{az}" {
              provider = "aws.#{region._}"
              count = #{count}
              ami = "${data.aws_ami.aws_ami_ubuntu_#{region}.id}"
              instance_type = "t2.micro"
              key_name = "${aws_key_pair.aws_key_pair_#{region}.id}"
              vpc_security_group_ids = [
                "${aws_security_group.aws_security_group_ssh_#{region}.id}",
                "${aws_security_group.aws_security_group_http_proxy_#{region}.id}",
                "${aws_security_group.aws_security_group_internet_access_#{region}.id}",
                "${data.aws_security_group.aws_security_group_#{region}.id}"
              ]              
              availability_zone = "#{az._}"
              subnet_id = "${aws_subnet.aws_subnet_#{az}.id}"
              associate_public_ip_address = true
              
              root_block_device = {
                volume_size = 8
              }

              tags {
                #{@ec2_tag.map { |k, v| "#{k} = \"#{v}\"" }.join("\n")}
              }
            
              lifecycle {
                create_before_destroy = true
                ignore_changes = ["private_ip", "vpc_security_group_ids", "root_block_device"]
              }

              depends_on = ["aws_internet_gateway.aws_internet_gateway_#{region}"]
            }

            output "aws_instance_#{az}_public_ip" {
              value = "${aws_instance.aws_instance_#{az}.*.public_ip}"
            }

            output "aws_instance_#{az}_public_dns" {
              value = "${aws_instance.aws_instance_#{az}.*.public_dns}"
            }
          EOS
        end
      end
      result
    end

    def null_resource_provisioning
      result = []
      @ec2.each do |region, azs|
        azs.each do |az, instance_count|
          result << <<~EOS
            resource "null_resource" "null_resource_provisioning_#{az}" {
              count = "#{instance_count}"
            
              connection {
                timeout = "10m"
                user = "ubuntu"
                host = "${aws_instance.aws_instance_#{az}.*.public_ip[count.index]}"
                private_key = "${file(var.aws_ssh_private_key)}"
              }
            
              provisioner "remote-exec" {
                inline = [
                  "sudo -u root bash -c 'echo \\"${aws_instance.aws_instance_#{az}.*.availability_zone[count.index]}\\" > /etc/aws_availability_zone'",
                  "sudo -u root bash -c 'echo \\"${aws_instance.aws_instance_#{az}.*.public_dns[count.index]}\\" > /etc/aws_public_dns'",
                  "sudo -u root bash -c 'echo \\"${aws_instance.aws_instance_#{az}.*.private_dns[count.index]}\\" > /etc/aws_private_dns'"
                ]
              }
            
              provisioner "local-exec" {
                working_dir = "../ansible"
                command = <<EOT
                  ansible-playbook \
                  -u ubuntu \
                  --become \
                  -i '${aws_instance.aws_instance_#{az}.*.public_ip[count.index]},' \
                  --private-key ${var.aws_ssh_private_key} \
                  --ssh-common-args="-o StrictHostKeyChecking=no -o IdentitiesOnly=yes" \
                  tasks/provision.yml
                EOT
              }
            }
          EOS
        end
      end
      result
    end

    def aws_lb_target_group
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_lb_target_group" "aws_lb_target_group_#{region}" {
            provider = "aws.#{region._}"
            port = "#{@alb_target_port}"
            protocol = "HTTP"
            vpc_id = "${aws_vpc.aws_vpc_#{region}.id}"
            target_type = "instance"
          
            health_check {
              path = "/ping"
              port = "#{@alb_target_port}"
              timeout = 5
              interval = 10
            }
          }
        EOS
      end
      result
    end

    def aws_lb_target_group_attachment
      result = []
      @ec2.each do |region, azs|
        azs.each do |az, instance_count|
          result << <<~EOS
            resource "aws_lb_target_group_attachment" "aws_lb_target_group_attachment_#{az}" {
              provider = "aws.#{region._}"
              // Known bug here
              // count = "${length(aws_instance.aws_instance_#{az}.*.id)}"
              count = #{instance_count}
              port = "#{@alb_target_port}"
              target_group_arn = "${aws_lb_target_group.aws_lb_target_group_#{region}.arn}"
              target_id = "${element(aws_instance.aws_instance_#{az}.*.id, count.index)}"
            }
          EOS
        end
      end
      result
    end

    def aws_security_group_http
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_security_group" "aws_security_group_http_#{region}" {
            provider = "aws.#{region._}"
            name = "allow_http"
            description = "Allow HTTP traffic"
            vpc_id = "${aws_vpc.aws_vpc_#{region}.id}"

            ingress {
              from_port = 80
              to_port = 80
              protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
              ipv6_cidr_blocks = ["::/0"]
            }
          }
        EOS
      end
      result
    end

    def aws_lb
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_lb" "aws_lb_#{region}" {
            provider = "aws.#{region._}"
            name = "aws-lb-#{region._}"
            internal = false
            load_balancer_type = "application"
            security_groups = [
              "${aws_security_group.aws_security_group_http_#{region}.id}",
              "${data.aws_security_group.aws_security_group_#{region}.id}"
            ]
            subnets = [#{@ec2[region].map { |az, _| "\"${aws_subnet.aws_subnet_#{az}.id}\"" }.join(',')}]
          }

          output "aws_lb_#{region}_dns_name" {
            value = "${aws_lb.aws_lb_#{region}.dns_name}"
          }
        EOS
      end
      result
    end

    def aws_lb_listener
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_lb_listener" "aws_lb_listener_#{region}" {
            provider = "aws.#{region._}"
            load_balancer_arn = "${aws_lb.aws_lb_#{region}.arn}"
            port = "#{@alb_source_port}"
            protocol = "HTTP"
          
            default_action {
              type = "forward"
              target_group_arn = "${aws_lb_target_group.aws_lb_target_group_#{region}.arn}"
            }
          }
        EOS
      end
      result
    end

    def aws_route53_zone
      <<~EOS
        resource "aws_route53_zone" "aws_route53_zone" {
          provider = "aws.#{@ec2.keys.first._}"        
          name = "#{@route53_zone}"
        }
      EOS
    end

    def aws_route53_record
      result = []
      @ec2.each do |region, _|
        result << <<~EOS
          resource "aws_route53_record" "aws_route53_record_#{region}" {
            provider = "aws.#{region._}"
            zone_id = "${aws_route53_zone.aws_route53_zone.zone_id}"
            name = ""
            type = "A"
            set_identifier = "#{region}"

            alias {
              name = "${aws_lb.aws_lb_#{region}.dns_name}"
              zone_id = "${aws_lb.aws_lb_#{region}.zone_id}"
              evaluate_target_health = true
            }

            weighted_routing_policy {
              weight = 100
            }
          }
        EOS
      end
      result
    end

    def result
      result = []
      result << aws_input
      result << aws_providers
      result << aws_ami
      result << aws_security_group_ssh
      result << aws_security_group_internet_access
      result << aws_security_group_http_proxy
      result << aws_security_group_default
      result << aws_key_pair
      result << aws_vpc
      result << aws_internet_gateway
      result << aws_route_gateway
      result << aws_subnet
      result << aws_instance
      result << null_resource_provisioning
      result << aws_lb_target_group
      result << aws_lb_target_group_attachment
      result << aws_security_group_http
      result << aws_lb
      result << aws_lb_listener
      if @route53_zone
        result << aws_route53_zone
        result << aws_route53_record
      end
      result.flatten.map(&:strip).join("\n\n")
    end
  end
end
