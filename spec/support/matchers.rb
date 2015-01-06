require 'timeout'

RSpec::Matchers.define :become do |first|
  match do |actual|
    @time ||= 1
    begin
      Timeout.timeout(@time) do
        if @not_nil
          loop { break if actual.call }
        else
          loop { break if first == actual.call } 
        end
      end
    rescue Timeout::Error
      return false
    end

    true
  end

  supports_block_expectations

  chain :within do |seconds|
    @time = seconds
  end

  chain :anything do
    @not_nil = true
  end

  failure_message do |actual|
    "Expected #{actual.call} to become #{@value} within #{@time} seconds"
  end
end

