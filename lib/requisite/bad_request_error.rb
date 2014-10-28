module Requisite
  class BadRequestError < StandardError
    attr_accessor :message
    
    def initialize(message = nil)
      @message = message || self.class.to_s
    end
  end
end
