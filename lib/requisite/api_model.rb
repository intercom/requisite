require 'json'

module Requisite
  class ApiModel < BoundaryObject
    attr_reader :model
    
    def initialize(model={})
      @model = model.kind_of?(Hash) ? Hash[model.map{ |k, v| [k.to_sym, v] }] : model
    end
    
    def convert(name)
      attribute_from_model(name)
    end
    
    def convert!(name)
      attribute_from_model(name) || (raise NotImplementedError.new("'#{name}' not found on model"))
    end

    def attribute_from_model(name)
      if @model.kind_of?(Hash)
        @model[name]
      else
        @model.send(name) if @model.respond_to?(name)
      end
    end

    def merge_attribute_if_exists!(to_merge, attribute_name)
      attribute_from_model(attribute_name) ? to_merge.merge!(attribute_from_model(attribute_name)) : to_merge
    end

    def to_hash
      preprocess_model
      {}.tap do |result|
        self.class.attribute_keys.each do |meth|
          value = self.send(meth)
          result.merge!({meth => value}) unless value.nil?
        end
      end
    end
    
    def to_json
      to_hash.to_json
    end
    
    def parse_typed_hash(name, hash)
      {}.tap do |result|
        passed_hash = attribute_from_model(name)
        hash.each do |key, value|
          next unless passed_hash && passed_hash[key]
          raise_bad_type_if_type_mismatch(passed_hash[key], value)
          result[key] = passed_hash[key]
        end
      end
    end
    
    def parse_scalar_hash(name)
      {}.tap do |result|
        passed_hash = attribute_from_model(name) || {}
        passed_hash.each do |key, value|
          raise BadTypeError.new(value, 'Numeric, String or Boolean') unless (value.kind_of?(Numeric) || value.kind_of?(String) || value.kind_of?(TrueClass) || value.kind_of?(FalseClass))
          result[key] = value
        end
      end
    end
    
    def parse_typed_array(name, type)
      [].tap do |result|
        passed_array = attribute_from_model(name) || []
        passed_array.each do |value|
          raise_bad_type_if_type_mismatch(value, type)
          result << value
        end
      end
    end
    
    def with_type!(desired_type)
      yield.tap do |value|
        raise_bad_type_if_type_mismatch(value, desired_type) if value
      end
    end
    
    def first_attribute_from_model(*attributes)
      attributes.each do |attribute|
        value = attribute_from_model(attribute)
        if value && !(value.kind_of?(Hash) && value.empty?)
          return value
        end
      end
      nil
    end
    
    private

    def preprocess_model
      # noop
    end
  end
end
