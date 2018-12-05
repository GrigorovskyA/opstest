# TODO Tags support

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
      @alb = {}
      @tag = {}
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

    def alb(*arg)
    end

    def tag(*arg)
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
      us_east_2: [:us_east_2a, :eu_east_2b, :eu_east_2c],
      us_west_1: [:us_west_1a, :us_west_1c],
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

    def providers
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

    def input
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

          output "aws_ami_ubuntu_#{region}_id" {
            value = "${data.aws_ami.aws_ami_ubuntu_#{region}.id}"
          }

          output "aws_ami_ubuntu_#{region}_name" {
            value = "${data.aws_ami.aws_ami_ubuntu_#{region}.name}"
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

          output "aws_security_group_ssh_#{region}_id" {
            value = "${aws_security_group.aws_security_group_ssh_#{region}.id}"
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

          output "aws_security_group_internet_access_#{region}_id" {
            value = "${aws_security_group.aws_security_group_internet_access_#{region}.id}"
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

          output "aws_key_pair_#{region}_id" {
            value = "${aws_key_pair.aws_key_pair_#{region}.id}"
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

          output "aws_vpc_#{region}_id" {
            value = "${aws_vpc.aws_vpc_#{region}.id}"
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

          output "aws_internet_gateway_#{region}_id" {
            value = "${aws_internet_gateway.aws_internet_gateway_#{region}.id}"
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

            output "aws_subnet_#{az}_id" {
              value = "${aws_subnet.aws_subnet_#{az}.id}"
            }

            output "aws_subnet_#{az}_availability_zone" {
              value = "${aws_subnet.aws_subnet_#{az}.availability_zone}"
            }

            output "aws_subnet_#{az}_cidr_block" {
              value = "${aws_subnet.aws_subnet_#{az}.cidr_block}"
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
                "${aws_security_group.aws_security_group_internet_access_#{region}.id}"
              ]              
              availability_zone = "#{az._}"
              subnet_id = "${aws_subnet.aws_subnet_#{az}.id}"
              associate_public_ip_address = true
              
              root_block_device = {
                volume_size = 8
              }
            
              lifecycle {
                create_before_destroy = true
                ignore_changes = ["private_ip", "vpc_security_group_ids", "root_block_device"]
              }

              depends_on = ["aws_internet_gateway.aws_internet_gateway_#{region}"]
            }

            output "aws_instance_#{az}_id" {
              value = "${aws_instance.aws_instance_#{az}.*.id}"
            }

            output "aws_instance_#{az}_id_public_ip" {
              value = "${aws_instance.aws_instance_#{az}.*.public_ip}"
            }

            output "aws_instance_#{az}_id_public_dns" {
              value = "${aws_instance.aws_instance_#{az}.*.public_dns}"
            }
          EOS
        end
      end
      result
    end

    def result
      result = []
      result << input
      result << providers
      result << aws_ami
      result << aws_security_group_ssh
      result << aws_security_group_internet_access
      result << aws_key_pair
      result << aws_vpc
      result << aws_internet_gateway
      result << aws_route_gateway
      result << aws_subnet
      result << aws_instance
      result.flatten.map(&:strip).join("\n\n")
    end
  end
end
