require 'active_support/concern'

module FleetCaptain
  class Service
    module Attributes
      extend ActiveSupport::Concern

      module ClassMethods
        def define_attributes(methods)
          methods.each do |directive|
            method_name = directive.underscore
            define_attribute_methods(method_name)
          end
        end
      end
      
      def attribute(attr)
        if attribute_multiple?(attr)
          instance_variable_get("@#{attr}") || instance_variable_set("@#{attr}", [])
        else
          instance_variable_get "@#{attr}"
        end
      end

      def attribute_concat(attr, *values, failable: false)
        send("#{attr}_will_change!") unless values.empty?

        if send("#{attr}_multiple?")
          send(attr).concat(to_command(values, failable))
        else
          send("#{attr}=", values.first)
        end
      end

      def attribute=(attr, value, failable: false)
        new_value = to_command(value, failable)
        unless [new_value, nil].include?(send(attr))
          send("#{attr}_will_change!")
        end

        if attribute_multiple?(attr)
          instance_variable_set "@#{attr}", Array.wrap(new_value)
        else
          instance_variable_set "@#{attr}", new_value
        end
      end

      def failable_attribute=(attr, value)
        send('attribute=',attr, value, failable: true)
      end

      def failable_attribute_concat(attr, *values)
        attribute_concat(attr, *values, failable: true)
      end

      def attribute_multiple?(attr)
        FleetCaptain.multi_value_directives.include?(attr)
      end

      def attributes
        non_directive_attributes = { 'name' => @name }
        FleetCaptain
          .available_methods
          .each.with_object(non_directive_attributes) { |method, memo|
            memo[method] = send(method)
        }.delete_if { |_, v| v.blank? }
      end

      def attributes=(hash)
        hash.each_pair do |attribute, value|
          send("#{attribute}=", value) 
        end
      end
    end
  end
end
