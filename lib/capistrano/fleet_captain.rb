require "capistrano"
require "mkmf"

if Rake::Task.tasks.include?("deploy")
  Rake::Task["deploy"].clear_actions
end

require "capistrano/scm"

load File.expand_path("../tasks/deploy.rake", __FILE__)
load File.expand_path("../tasks/docker.rake", __FILE__)

module Capistrano
  class FleetCaptain < Capistrano::SCM
    attr_writer :aws_region

    def docker(*args)
      @docker_client ||= FleetCaptain::DockerClient.local
      @docker_client.send(*args)
    end

    def fleet(*args)
      @fleet_client.send(*args, &block)
    end
    
    def cloud(*args, &block)
      @cloud.send(*args, &block)
    end

    module DefaultStrategy
      def fleet_setup(fleet_endpoint)
        @fleet_client = FleetCaptain::FleetClient.new(actual, fleet_endpoint, public_key)
      end

      def aws_setup(name, tags)
        @cloud = FleetCaptain::AWSClient.new(name, tags)
      end

      def load_fleetfile
        FleetCaptain.fleetfile
      end

      def list_services
        FleetCaptain.services
      end

      def new_services
        FleetCaptain.services not in fleet(:list)
      end

      def changed_services
        FleetCaptain.services changed from fleet(:list)
      end

      def stale_services
        fleet(:list) not in FleetCaptain.services
      end
      
      def services
        FleetCaptain.services
      end

      def provision(&block)
        cloud(:provision!, &block)
      end

      def verify
        docker :verify
      end

      def rollback_tag(production_tag, rollback_tag)
        images = docker :images

        production_image = images.select { |i| i.info['RepoTags'] == production_tag }
        production_image.tag(rollback_tag)
      end


      def tag(image_id, tag)
        docker :tag, image_id, tag
      end

      def update
        docker :build, repo_tag
      end

      def release
        docker :push, repo_tag
      end
    end
  end
end
