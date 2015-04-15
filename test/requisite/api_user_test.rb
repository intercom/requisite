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

class InheritedApiUser < ApiUser
  serialized_attributes do
    attribute :new_attribute, type: String
    attribute :custom_data
  end
end

class UserModel
  attr_accessor :id, :user_id, :email, :name, :created_at, :created, :last_seen_user_agent, :last_request_at, :unsubscribed_from_emails
  attr_accessor :update_last_request_at, :new_session, :custom_attributes, :company, :companies
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

    it "can resolve an inherited set of attributes" do
      user_request_params = {
        :user_id => 'abcdef',
        :name => 'Bob',
        :created => 1414173164,
        :new_session => true,
        :custom_attributes => {
          :is_cool => true,
          :logins => 77
        },
        :custom_data => {
          :different => true
        },
        :new_attribute => 'hi',
        :junk => 'data'
      }
      user = InheritedApiUser.new(user_request_params)
      user.new_attribute.must_equal 'hi'
      user.name.must_equal 'Bob'
      user.custom_data.must_equal({ :different => true })
      InheritedApiUser.attribute_keys.must_equal([:new_attribute, :custom_data])
      user.to_hash.must_equal({
        :user_id => 'abcdef',
        :name => 'Bob',
        :created_at => 1414173164,
        :new_session => true,
        :custom_data => {
          :different => true
        },
        :new_attribute => 'hi'
      })
    end
    
    it 'accepts a user model' do
      user_model = UserModel.new
      user_model.user_id = 'abcdef'
      user_model.name = 'Bob'
      user = ApiUser.new(user_model)
      user.to_hash.must_equal({
        :user_id => 'abcdef',
        :name => 'Bob',
        :custom_data => {}
      })
      user.name.must_equal('Bob')
    end
    
    it 'accepts a user model and renders nils if asked' do
      user_model = UserModel.new
      user_model.user_id = 'abcdef'
      user_model.name = 'Bob'
      user = ApiUser.new(user_model)
      user.to_hash(show_nil: true).must_equal({
        :id => nil,
        :user_id => 'abcdef',
        :email => nil,
        :name => 'Bob',
        :created_at => nil,
        :last_seen_user_agent => nil,
        :last_request_at => nil,
        :unsubscribed_from_emails => nil,
        :update_last_request_at => nil,
        :new_session => nil,
        :custom_data => {},
        :company => nil,
        :companies => nil
      })
      user.name.must_equal('Bob')
    end
  end
end
