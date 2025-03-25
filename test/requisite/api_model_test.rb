require 'test_helper'

module Requisite
  class DummyApiModel < Requisite::ApiModel
  end

  describe ApiModel do
    it 'creates methods from serialized_attributes block' do
      DummyApiModel.serialized_attributes { attribute :a; attribute :b }
      response = DummyApiModel.new
      def response.a; 'A'; end
      def response.b; 2; end
      _(response.to_hash).must_equal( :a => 'A', :b => 2 )
      _(response).must_respond_to :a
      _(response).must_respond_to :b
    end

    it 'attribute provides a default implementation of calling a hash model' do
      DummyApiModel.serialized_attributes { attribute :c }
      mock = {:c => 'C'}
      response = DummyApiModel.new(mock)
      _(response.to_hash).must_equal( :c => 'C' )
    end

    let(:params_hash) { {:c => 'C', :num => 12} }

    it 'attribute provides a default implementation of calling a model' do
      DummyApiModel.serialized_attributes { attribute :c }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal(:c => 'C')
    end

    it 'attribute can work with a default' do
      DummyApiModel.serialized_attributes { attribute :c, default: 'see' }
      response = DummyApiModel.new
      _(response.to_hash).must_equal(:c => 'see')
    end

    it 'ignores default if value given' do
      DummyApiModel.serialized_attributes { attribute :num, default: 0 }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal(:num => 12)
    end

    it 'can set a default value of true for a boolean attribute' do
      DummyApiModel.serialized_attributes { attribute :truthy_val, type: Requisite::Boolean, default: true }
      response = DummyApiModel.new
      _(response.to_hash).must_equal(:truthy_val => true)
    end

    it 'can set a default value of false for a boolean attribute' do
      DummyApiModel.serialized_attributes { attribute :truthy_val, type: Requisite::Boolean, default: false }
      response = DummyApiModel.new
      _(response.to_hash).must_equal(:truthy_val => false)
    end

    it 'attribute can be set to stringify fields' do
      DummyApiModel.serialized_attributes { attribute :num, stringify: true }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal(:num => '12')
    end

    it 'attribute can be set to rename fields' do
      DummyApiModel.serialized_attributes { attribute :my_num, rename: :num }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal(:my_num => 12)
    end

    it 'attribute can assert type of a field' do
      DummyApiModel.serialized_attributes { attribute :num, type: String }
      response = DummyApiModel.new(params_hash)
      _(proc { response.to_hash }).must_raise(BadTypeError)
    end

    it 'with_type! helper raises on mismatched type' do
      model = DummyApiModel.new()
      _(proc { model.send(:with_type!, String) { 1 + 2 }}).must_raise(Requisite::BadTypeError)
    end

    it 'first_attribute_from_model helper finds first matching attriubute' do
      model = DummyApiModel.new(:oh => 12, :a => nil, :b => 'B', :c => 'C')
      _(model.send(:first_attribute_from_model, :a, :b, :c)).must_equal('B')
    end

    it 'attribute can assert type of a boolean field' do
      DummyApiModel.serialized_attributes { attribute :truthy_val, type: Requisite::Boolean }
      response = DummyApiModel.new(:truthy_val => false)
      _(response.to_hash).must_equal(:truthy_val => false)
    end

    it 'attribute does not include values of nil' do
      DummyApiModel.serialized_attributes { attribute :num, type: String }
      response = DummyApiModel.new({:num => nil})
      _(response.to_hash).must_equal({})
    end

    it 'attribute includes values of nil if permitted' do
      DummyApiModel.serialized_attributes { attribute :num, type: String }
      response = DummyApiModel.new({:num => nil})
      _(response.to_hash(show_nil: true)).must_equal({:num => nil})
    end

    it 'attribute can be stringified and renamed with default fields' do
      DummyApiModel.serialized_attributes { attribute :my_num, rename: :num, stringify: true, default: 22 }
      response = DummyApiModel.new
      _(response.to_hash).must_equal(:my_num => '22')
    end

    it 'attribute can be stringified after type check' do
      DummyApiModel.serialized_attributes { attribute :num, stringify: true, type: Integer }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal(:num => '12')
    end

    it 'attribute type checks after rename' do
      DummyApiModel.serialized_attributes { attribute :my_num, rename: :num, type: String }
      response = DummyApiModel.new(params_hash)
      _(proc { response.to_hash }).must_raise(BadTypeError)
    end

    it 'attribute can be stringified, renamed, defaulted and have type checking on a field' do
      DummyApiModel.serialized_attributes { attribute :my_num, rename: :num, stringify: true, default: 22, type: String }
      response = DummyApiModel.new
      _(proc { response.to_hash }).must_raise(BadTypeError)
    end

    let(:invalid_params_hash) { {:d => nil} }

    it "attribute! raises an error if not found on model" do
      DummyApiModel.serialized_attributes { attribute! :d }
      response = DummyApiModel.new(invalid_params_hash)
      _(proc { response.to_hash }).must_raise(NotImplementedError, "'d' not found on model")
    end

    it 'attribute! does not raise an error if value on model is false' do
      params_hash = {:d => false}
      DummyApiModel.serialized_attributes { attribute! :d }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal({d: false})
    end

    it 'attribute! can be set to stringify fields' do
      DummyApiModel.serialized_attributes { attribute! :num, stringify: true }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal(:num => '12')
    end

    it 'attribute! can be set to rename fields' do
      DummyApiModel.serialized_attributes { attribute! :my_num, rename: :num }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal(:my_num => 12)
    end

    it 'sets the model from a hash' do
      DummyApiModel.serialized_attributes { }
      response = DummyApiModel.new(params_hash)
      _(response.model).must_equal(params_hash)
    end

    it 'sets the model from an object' do
      mc = MockClass.new
      mc.a = 'a'
      mc.b = 2
      DummyApiModel.serialized_attributes { attribute :a }
      response = DummyApiModel.new(mc)
      _(response.model).must_equal(mc)
      _(response.to_hash).must_equal(:a => 'a')
    end

    it 'has alias a for attribute' do
      DummyApiModel.serialized_attributes { a :num }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal(:num => 12)
    end

    it 'has alias a! for attribute!' do
      DummyApiModel.serialized_attributes { a! :num }
      response = DummyApiModel.new(params_hash)
      _(response.to_hash).must_equal(:num => 12)
    end

    it 'can convert to json' do
      DummyApiModel.serialized_attributes { a! :num }
      response = DummyApiModel.new(params_hash)
      _(response.to_json).must_equal("{\"num\":12}")
    end

    it 'drops non-listed parameters' do
      DummyApiModel.serialized_attributes { attribute :num }
      response = DummyApiModel.new({num: 12, other: 'value'})
      _(response.to_hash).must_equal(:num => 12)
    end

    it 'works with ActionController::Parameters' do
      DummyApiModel.serialized_attributes { attribute :num }
      params = ActionController::Parameters.new(num: 12)
      response = DummyApiModel.new(params)
      _(response.to_hash).must_equal(:num => 12)
    end

    describe 'with nested structures' do

      describe 'with typed arrays' do
        it 'allows arrays of one type' do
          DummyApiModel.serialized_attributes { attribute :ids, typed_array: Integer }
          response = DummyApiModel.new({ids: [1, 2, 3]})
          _(response.to_hash).must_equal(:ids => [1, 2, 3])
        end

        it 'raises errors when array has a wrongly typed value' do
          DummyApiModel.serialized_attributes { attribute :ids, typed_array: Requisite::Boolean }
          response = DummyApiModel.new({ids: [true, 'value', false]})
          _(Proc.new {response.to_hash}).must_raise(BadTypeError)
        end
      end

      describe 'with typed nested hashes' do
        it 'drops non listed parameters in nested hashes' do
          DummyApiModel.serialized_attributes { attribute :data, typed_hash: { num: Numeric, bool: Requisite::Boolean } }
          response = DummyApiModel.new({data: { num: 12, value: 'x', bool: true }})
          _(response.to_hash).must_equal(:data => { :num => 12, :bool => true })
        end

        it 'can stringify nested hashes' do
          DummyApiModel.serialized_attributes { attribute :data, typed_hash: { num: Numeric }, stringify: true }
          response = DummyApiModel.new({data: { num: 12, value: 'x' }})
          _(response.to_hash).must_equal(:data => "{:num=>12}")
        end

        it 'raises an error when nested hash values of the wrong type' do
          DummyApiModel.serialized_attributes { attribute :data, typed_hash: { num: Numeric } }
          _(Proc.new {DummyApiModel.new({data: { num: '12'}}).to_hash}).must_raise(BadTypeError)
        end

        it 'can rename param and work with nested hashes' do
          DummyApiModel.serialized_attributes { attribute :my_data, typed_hash: { num: Numeric }, rename: :data }
          response = DummyApiModel.new({data: { num: 12, value: 'x' }})
          _(response.to_hash).must_equal(:my_data => { :num => 12 })
        end

        it 'can set a default value for a nested hash' do
          DummyApiModel.serialized_attributes { attribute :data, typed_hash: { num: Numeric }, default: { num: 4 } }
          response = DummyApiModel.new({data: { value: 'x' }})
          _(response.to_hash).must_equal(:data => { :num => 4 })
        end

        it 'drops non listed fields with attribute!' do
          DummyApiModel.serialized_attributes { attribute! :data, typed_hash: { num: Numeric } }
          response = DummyApiModel.new({data: { num: 12, value: 'x' }})
          _(response.to_hash).must_equal(:data => { :num => 12 })
        end

        it 'attribute! does not raise an error with missing values in hash' do
          DummyApiModel.serialized_attributes { attribute! :data, typed_hash: { num: Numeric } }
          response = DummyApiModel.new({data: { value: 'x' }})
          _(response.to_hash).must_equal(:data => { })
        end
      end

      describe 'with scalar only nested hashes' do
        it 'should parse scalar hashes permitting anything scalar' do
          DummyApiModel.serialized_attributes { attribute :data, scalar_hash: true }
          response = DummyApiModel.new({data: { num: 12, value: 'x', :truthy => false }})
          _(response.to_hash).must_equal(:data => { :num => 12, :value => 'x', :truthy => false })
        end

        it 'should parse a renamed scalar hash' do
          DummyApiModel.serialized_attributes { attribute :my_data, scalar_hash: true, rename: :data }
          response = DummyApiModel.new({data: { num: 12, value: 'x' }})
          _(response.to_hash).must_equal(:my_data => { :num => 12, :value => 'x' })
        end

        it 'should stringify a scalar hash' do
          DummyApiModel.serialized_attributes { attribute :data, scalar_hash: true, stringify: true }
          response = DummyApiModel.new({data: { num: 12, value: 'x' }})
          _(response.to_hash).must_equal(:data => "{:num=>12, :value=>\"x\"}")
        end

        it 'should parse scalar hashes permitting anything scalar with object' do
          mc = MockClass.new
          mc.a = 'a'
          mc.b = { num: 12, value: 'x' }
          DummyApiModel.serialized_attributes { attribute :b, scalar_hash: true }
          response = DummyApiModel.new(mc)
          _(response.to_hash).must_equal(:b => { :num => 12, :value => 'x' })
        end

        it 'should fail to parse scalar hashes when non scalar values present' do
          DummyApiModel.serialized_attributes { attribute :data, scalar_hash: true }
          _(Proc.new { DummyApiModel.new({data: { num: 12, value: { nested: 'value' } }}).to_hash}).must_raise(BadTypeError)
          _(Proc.new { DummyApiModel.new({data: { num: 12, value: ['array value'] }}).to_hash}).must_raise(BadTypeError)
        end

        it 'should fail to parse scalar hashes permitting anything scalar with object' do
          mc = MockClass.new
          mc.a = 'a'
          mc.b = { value: { nested: 'value' } }
          DummyApiModel.serialized_attributes { attribute :b, scalar_hash: true }
          response = DummyApiModel.new(mc)
          _(Proc.new { response.to_hash }).must_raise(BadTypeError)
        end

        it 'can set a default value for a scalar hash' do
          DummyApiModel.serialized_attributes { attribute :data, scalar_hash: true, default: { num: 9, value: 'y' } }
          response = DummyApiModel.new({data: { }})
          _(response.to_hash).must_equal(:data => { :num => 9, :value => 'y' })
        end

        it 'doesnt raise with attribute! when an empty hash passed' do
          DummyApiModel.serialized_attributes { attribute! :data, scalar_hash: true }
          response = DummyApiModel.new({data: {}})
          _(response.to_hash).must_equal(:data => {})
        end

        it 'raises with attribute! when nil is passed' do
          DummyApiModel.serialized_attributes { attribute! :data, scalar_hash: true }
          response = DummyApiModel.new({data: nil})
          _(Proc.new {response.to_hash}).must_raise(NotImplementedError)
        end
      end
    end
  end
end

class MockClass
  attr_accessor :a, :b
end
