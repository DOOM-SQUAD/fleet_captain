require "capistrano"
require "mkmf"
require 'rake'

if Rake::Task.tasks.include?("deploy")
  Rake::Task["deploy"].clear_actions
end

require "capistrano/scm"

load File.expand_path("../tasks/deploy.rake", __FILE__)
load File.expand_path("../tasks/docker.rake", __FILE__)

module Capistrano
  class FleetCaptain < Capistrano::SCM
    def docker(*args, &block)
      docker_client.send(*args, &block)
    end

    def fleet(*args, &block)
      fleet_client.send(*args, &block)
    end
    
    def cloud(*args, &block)
      cloud_client.send(*args, &block)
    end

    module DefaultStrategy
      attr_accessor :fleet_client, :docker_client, :cloud_client

      def fleet_client
        @fleet_client ||= ::FleetCaptain::FleetClient.new(context.fetch(:fleet_endpoint))
      end

      def docker_client
        @docker_client ||= ::FleetCaptain::DockerClient.local
      end

      def cloud_client
        @cloud_client ||= ::FleetCaptain::AWSClient.new(context.fetch(:name), 
                                                        context.fetch(:tags))
      end

      def load_fleetfile
        ::FleetCaptain.fleetfile
      end

      def new_services
        # FleetCaptain.services not in fleet(:list)
        services - fleet(:list)
      end

      def changed_services
        # FleetCaptain.services changed from fleet(:list)
        services - fleet(:list)
      end

      def stale_services
        # fleet(:list) not in FleetCaptain.services
        services - fleet(:list)
      end

      def all_services
        fleet(:list) | services
      end
      
      def services
        ::FleetCaptain.services
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
