module Requisite
  class BadTypeError < StandardError
    attr_accessor :message
    
    def initialize(value, desired_class)
      @message = "Value: #{value} not of type #{desired_class}"
    end
  end
end
