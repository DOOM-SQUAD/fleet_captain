require 'active_support/core_ext/string'

module FleetCaptain
  module Commands
    class HashOptions
      attr_accessor :action, :params, :command

      def self.create(**from)
        self.new(from.keys.first.to_s, args: [from.values.first].flatten)
      end

      def initialize(action = '', params = [], command = [], args: [])
        @action   = action
        @params   = params
        @commands = command
        parse_args(args)

      end

      def to_s
        [action, params, commands].join(' ').squish
      end

      def params=(args)
        args.each { |k,v| add_param(k,v) }
        @params
      end

      def add_param(k, v)
        @params << (if v == true
          key_to_option(k)
        else
          "#{key_to_option(k)} #{v}"
        end)
      end

      def params
        @params.join(' ').squish
      end

      def commands
        @commands.join(' ').squish
      end

      def commands=(args)
        @commands << Array(args).map(&:to_s)
      end

      def parse_args(args)
        args.each do |arg|
          case arg
          when String, Symbol then self.commands = arg
          when Hash then self.params = arg
          end
        end
      end

      private

      def key_to_option(key)
        option = key.to_s.gsub('_','-') # legal ruby symbols to dashed options
        prefix = option.length > 1 ? '--' : '-' #multicharacter options have two dashes
        "#{prefix}#{option}" #the actual option name
      end
    end
  end
end
