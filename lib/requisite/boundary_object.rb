module Requisite
  class BoundaryObject
    class << self
      def attribute(name, options={})
        attribute_keys << name
        define_method(name) do
          resolved_name = options[:rename] || name
          result = self.send(:convert, resolved_name)
          result = self.send(:parse_typed_hash, resolved_name, options[:typed_hash]) if options[:typed_hash]
          result = self.send(:parse_scalar_hash, resolved_name) if options[:scalar_hash]
          result = self.send(:parse_typed_array, resolved_name, options[:typed_array]) if options[:typed_array]
          result = options[:default] if (options[:default] && empty_result?(result))
          raise_bad_type_if_type_mismatch(result, options[:type]) if options[:type] && result
          result = result.to_s if options[:stringify]
          result
        end
      end

      def attribute!(name, options={})
        attribute_keys << name
        define_method(name) do
          resolved_name = options[:rename] || name
          result = self.send(:convert!, resolved_name)
          result = self.send(:parse_typed_hash, resolved_name, options[:typed_hash]) if options[:typed_hash]
          result = self.send(:parse_scalar_hash, resolved_name) if options[:scalar_hash]
          result = self.send(:parse_typed_array, resolved_name, options[:typed_array]) if options[:typed_array]
          result = result.to_s if options[:stringify]
          raise_bad_type_if_type_mismatch(result, options[:type]) if options[:type]
          result
        end
      end

      def serialized_attributes(&block)
        @attribute_keys = []
        instance_eval(&block)
      end

      def attribute_keys
        @attribute_keys || []
      end

      def attribute_keys_with_inheritance
        superclass.respond_to?(:attribute_keys_with_inheritance) ? superclass.attribute_keys_with_inheritance.concat(attribute_keys) : attribute_keys || []
      end
    end

    private

    self.singleton_class.send(:alias_method, :a, :attribute)
    self.singleton_class.send(:alias_method, :a!, :attribute!)

    def raise_bad_type_if_type_mismatch(value, desired_type)
      raise BadTypeError.new(value, desired_type) unless (value.kind_of?(desired_type)) || ((value.kind_of?(TrueClass) || value.kind_of?(TrueClass)) && desired_type == Requisite::Boolean)
    end

    def raise_not_implemented_for_attribute(name)
      raise NotImplementedError.new("'#{name}' method not implemented")
    end

    def empty_result?(result)
      result.nil? || result == {}
    end
  end
end
