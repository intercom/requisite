require 'test_helper'

## Example Object
class ApiEvent < Requisite::ApiModel
  serialized_attributes do
    attribute! :event_name, type: String
    attribute :id, type: String
    attribute :user_id, type: String
    attribute :email, type: String
    attribute :metadata, scalar_hash: true
  end
end

module Requisite
  describe ApiEvent do
    it 'accepts an event' do
      event_request_params = {
        :event_name => 'bought',
        :user_id => 'abcdef',
        :metadata => {
          :item => 'CD',
          :price => 20.01
        },
        :junk => 'data'
      }
      event = ApiEvent.new(event_request_params)
      event.to_hash.must_equal({
        :event_name => 'bought',
        :user_id => 'abcdef',
        :metadata => {
          :item => 'CD',
          :price => 20.01
        }
      })
    end
  end
end
