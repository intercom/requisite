require 'test_helper'

# Example Object
class ApiUser < Requisite::ApiModel
  serialized_attributes do
    attribute :id, type: String
    attribute :user_id
    attribute :email, type: String
    attribute :name, type: String
    attribute :created_at, type: Fixnum
    attribute :last_seen_user_agent, type: String
    attribute :last_request_at, type: Fixnum
    attribute :unsubscribed_from_emails, type: Requisite::Boolean
    attribute :update_last_request_at, type: Requisite::Boolean
    attribute :new_session, type: Requisite::Boolean
    attribute :custom_data, scalar_hash: true, rename: :custom_attributes
    attribute :company
    attribute :companies
  end
  
  # Ensure that at least one identifier is passed
  def preprocess_model
    identifier = attribute_from_model(:id)
    identifier ||= attribute_from_model(:user_id)
    identifier ||= attribute_from_model(:email)
    raise StandardError unless identifier
  end
  
  # We want to accept someone sending `created_at` or `created` as parameters
  def created_at
    with_type!(Fixnum) { attribute_from_model(:created_at) || attribute_from_model(:created) }
  end
end

module Requisite
  describe ApiUser do
    it 'accepts a user' do
      user_request_params = {
        :user_id => 'abcdef',
        :name => 'Bob',
        :created => 1414173164,
        :new_session => true,
        :custom_attributes => {
          :is_cool => true,
          :logins => 77
        },
        :junk => 'data'
      }
      user = ApiUser.new(user_request_params)
      user.to_hash.must_equal({
        :user_id => 'abcdef',
        :name => 'Bob',
        :created_at => 1414173164,
        :new_session => true,
        :custom_data => {
          :is_cool => true,
          :logins => 77
        }
      })
      user.name.must_equal('Bob')
    end
    
    it 'raises an error without an identifier' do
      user_request_params = { :name => 'Bob' }
      user = ApiUser.new(user_request_params)
      proc { user.to_hash }.must_raise(StandardError)
    end
    
    it 'raises an error when created or created_at is not of the right type' do
      user_request_params = { :user_id => 'abcdef', :created => 'Thursday' }
      user = ApiUser.new(user_request_params)
      proc { user.to_hash }.must_raise(Requisite::BadTypeError)
    end
  end
end
