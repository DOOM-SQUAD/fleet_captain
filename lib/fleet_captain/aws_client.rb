require 'aws-sdk'
require 'open-uri'
require 'active_support/configurable'
require 'active_support/inflector'
require 'json'

#AWSAccessKeyId=  AKIAJGBR5ACLN5VGUE7Q
#AWSSecretKey=    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

module FleetCaptain
  class AwsClient
    include ActiveSupport::Configurable

    config_accessor :template_url, instance_writer: false do
      "https://s3.amazonaws.com/coreos.com/dist/aws/coreos-stable-pv.template"
    end

    config_accessor :access_key_id
    config_accessor :secret_access_key
    config_accessor :region

    def self.template
      @template ||= JSON.parse(open(template_url).read)
    end

    attr_accessor :stack_name, :tags

    def initialize(name, **tags)
      @stack_name = name
      @tags = tags
      default_params!
      yield self if block_given?
    end

    def provision!
      client.create_stack(to_aws_params)
    end

    def to_aws_params
      {
        stack_name:    stack_name,
        template_url:  template_url,
        parameters:    parameters,
        tags:          tags.map { |k,v| { key: k.to_s, value: v.to_s } }
      }
    end

    def client
      @client ||= AWS::CloudFormation.new(
        access_key_id: config.access_key_id,
        secret_access_key: config.secret_access_key,
        region: config.region
      ).client
    end

    private

    def parameters
      parameter_keys.map do |parameter_key|
       { parameter_key: parameter_key, parameter_value: parameter_value(parameter_key) }
      end
    end

    #TODO Refactor me
    def default_params!
      template['Parameters'].each_pair do |key, spec|
        ruby_key = key.underscore

        define_singleton_method(ruby_key) do
          value = instance_variable_get("@#{ruby_key}") || template['Parameters'][key]['Default']
          if value.nil?
            raise ArgumentError, "Parameter #{ruby_key} is nil, but is required"
          end

          value
        end

        define_singleton_method("#{ruby_key}=") do |value|

          if !value.is_a?(Numeric) && spec['Type'] == 'Number'
            raise ArgumentError, "Value #{value} not allowed. Value is non-numeric." 
          end

          if spec['AllowedValues'] && !spec['AllowedValues'].include?(value)
            raise ArgumentError, "Value #{value} not allowed. Allowed Values are #{spec['AllowedValues']}" 
          end

          if spec['Type'] == 'Number'
            if value < spec['MinValue'].to_i || value > spec['MaxValue'].to_i
              raise ArgumentError, "Value #{value} not allowed. Value out of range." 
            end
          end

          instance_variable_set("@#{ruby_key}", value)
        end
      end
    end

    def parameter_keys
      return @parameter_keys if @parameter_keys
      @parameter_keys = template['Parameters'].keys
    end

    def parameter_value(key)
      send(key.underscore) 
    end

    def template
      self.class.template
    end

  end
end
