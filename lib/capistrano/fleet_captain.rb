require "capistrano"
require "mkmf"
require 'rake'
require 'timeout'

if Rake::Task.tasks.include?("deploy")
  Rake::Task["deploy"].clear_actions
end

require "capistrano/scm"

load File.expand_path("../tasks/deploy.rake", __FILE__)
load File.expand_path("../tasks/docker.rake", __FILE__)

module Capistrano
  class FleetCaptain < Capistrano::SCM

    def container(*args, &block)
      docker_client.send(*args, &block)
    end

    def cluster(*args, &block)
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

      def local_services
        @local_services  ||= ::FleetCaptain.services
      end

      def remote_services
        @remote_services ||= cluster(:list)
      end

      def identical_services
        local_services & remote_services
      end

      def changed_locally
        (local_services - remote_services).select { |service|
          remote_service_names.include? service.name
        }
      end

      def new_locally
        local_services - remote_services
      end

      def removed_locally
        remote_services - local_services
      end

      def all_services
        local_services + remote_services
      end
      
      def provision(&block)
        cloud(:provision!, &block)
      end

      def verify
        container(:verify)
      end

      def rollback_tag(production_tag, rollback_tag)
        images = container(:images)

        production_image = images.select { |i| i.info['RepoTags'] == production_tag }
        production_image.tag(rollback_tag)
      end

      def tag(image_id, tag)
        container(:tag, image_id, tag)
      end

      def update
        container(:build, repo_tag)
      end

      def release
        container(:push, repo_tag)
      end

      def register(service)
        cluster(:submit, service)
      end

      def loaded?(service)
        cluster(:loaded?, service)
      end

      def start(service)
        if cluster(:loaded?, service)
          cluster(:start, service)
        else
          raise ::FleetCaptain::ServiceNotRegistered, 
            "Service #{service.name} is not registered in the cluster"
        end
      end

      private

      def remote_service_names
        @remote_services_names ||= remote_services.map(&:name)
      end

    end
  end
end
