require 'docker'

module FleetCaptain
  class DockerClient
    class << self
      def reset
        @local_docker = nil
      end

      def local
        return @local_docker if @local_docker
        if ENV['DOCKER_HOST']
          @local_docker = remote(ENV['DOCKER_HOST'], ENV['DOCKER_CERT_PATH'])
        else
          @local_docker = new
        end

        @local_docker.verify

        @local_docker
      rescue StandardError
        raise FleetCaptain::DockerError, "couldn't connect to local docker"
      end
      
      def remote(host, cert_path)
        new(local_remote_connection(host, cert_path))
      end

      private

      def local_remote_connection(host, cert_path)
        Docker::Connection.new(host, 
          client_cert: File.join(cert_path, 'cert.pem'),
          client_key: File.join(cert_path, 'key.pem'),
          ssl_ca_file: File.join(cert_path, 'ca.pem'),
          scheme: 'https')
      end
    end

    attr_reader :connection, :authentication

    def initialize(connection = Docker.connection)
      @connection = connection
      begin
        verify
      rescue Excon::Errors::SocketError 
        raise FleetCaptain::DockerError, "docker not present or could not connect to daemon"
      end
    end

    def verify
      Docker.info(connection) and true
    end

    def authenticate!(**options)
      result = JSON.parse(connection.post('/auth', {}, body: options.to_json))
      if result['Status'] == 'Login Succeeded'
        @authentication = options
      else
        raise FleetCaptain::DockerError, result['Status']
      end
    end

    def authentication
      return @authentication if @authentication
      raise FleetCaptain::DockerError, "Authentication required"
    end

    def images
      Docker::Image.all({}, connection)
    end

    def image(tag)
      Docker::Image.get(tag, {}, connection)
    end

    def tag(old_tag, new_tag)
      repo, new_tag = new_tag.split(':')

      unless repo && new_tag
        raise FleetCaptain::DockerError, "new tag must be in repo:tag format"
      end

      Docker::Image.get(old_tag, {}, connection).tag(repo: repo, tag: new_tag)
    end

    def build(path_to_docker_file, tag, **options, &block)
      unless File.exist?(path_to_docker_file) && Dir.entries(path_to_docker_file).include?("Dockerfile")
        raise FleetCaptain::DockerError, "No Dockerfile in #{path_to_docker_file}"
      end

      options.merge!(t: tag)

      Docker::Image.build_from_dir(path_to_docker_file, options, connection) do |stream|
         parse_build_stream_output(stream, &block) unless block.nil?
      end
    end

    def push(tag, &block)
      image(tag).push(authentication, repo_tag: tag) do |stream|
         parse_push_output(stream, &block) unless block.nil?
      end
    end

    private

    def parse_push_output(stream)
      stream.lines.each do |line|
        lines = line.split(/(?<=})(?={)/)
        lines.each do |split_line|
          yield JSON.parse(split_line)
        end
      end
    end

    def parse_build_stream_output(stream)
      stream.lines.each do |line|
        yield JSON.parse(line).fetch('stream').chomp
      end
    end
  end
end
