module FleetCaptain
  module UnitFile
    extend self
    def parse(text)
      text.each_line.with_object(FleetCaptain::Service.new('Unnamed')) do |line, service|
        directive, value = line.split('=')
        if FleetCaptain.available_directives.include? directive
          if service.send(directive.underscore).present?
            service.send("#{directive.underscore}_concat", value)
          else
            service.send("#{directive.underscore}=", value)
          end
        end
      end
    end
  end
end
