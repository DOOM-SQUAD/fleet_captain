require 'fleet_captain/commands/hash_options'

module FleetCaptain
  module Commands
    class Docker
      attr_reader :container

      def initialize(container)
        @container = container
      end

      def to_command(command)
        parse(command) do |parsed_command|
          if parsed_command.action.inquiry.run?
            run_command(parsed_command)
          else
            other_command(parsed_command)
          end
        end
      end

      def run_command(parsed_command)
        [ "/usr/bin/docker",
          parsed_command.action,
          "--name #{container.container_name}",
          parsed_command.params,
          container.container,
          parsed_command.commands ].join(" ").squish
      end

      def other_command(parsed_command)
        [ "/usr/bin/docker",
          parsed_command.action,
          parsed_command.params,
          container.container_name ].join(" ").squish
      end

      def parse(command)
        case command
        when String, Symbol
          [ yield(HashOptions.new(command.to_s)) ]
        when Hash
          command.map { |k, args| 
            yield HashOptions.create(k => args)
            # Array wrap implicitly converts hashes to arrays.  not what we
            # want so do it by hand.
          }
        end
      end

    end
  end
end
