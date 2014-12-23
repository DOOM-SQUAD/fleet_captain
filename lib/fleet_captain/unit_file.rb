module FleetCaptain
  module UnitFile
    extend self
    def parse(text)
      text.each_line.with_object(FleetCaptain::Service.new('Unnamed')) do |line, service|
        directive, command = line.split('=')
        if FleetCaptain.available_directives.include? directive
          service.send("#{directive.underscore}=",command.chomp)
        end
      end
    end
  end
end
