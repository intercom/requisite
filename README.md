# Requisite

Requisite is an elegant way of strongly defining request and response models for serialization. How nice would it be if you could do:

```ruby
def create
  api_user = ApiRequestUser.new(params)
  user = User.create(api_user.to_hash)
  render json: ApiResponseUser.new(user).to_json
end
```

Without worrying about strong parameters, type safety and keeping a consistent API?

## Usage

```ruby
require 'requisite'
```

## ApiModel

ApiModels are the primary way of using Requisite, they represent a model defined as part of an API. Attributes can be listed within a `serialized_attributes` block, with the format `<attribute-type> <attribute-name> <options>`.

|   method   |                                                                                                               behaviour                                                                                                               |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| attribute  | The attribute with the given name will be looked up on the model, nil if not found. If a method with the same name exists on the UserResponse object it will be called for a value instead. Can take several options. Aliased to `a`. |
| attribute! | as attribute, but raises an error if not found on model. Aliased to `a!`.                                                                                                                                                             |

ApiModels can be constructed from other objects, or from Hashes (like those you might find in _params_). The helper method `attribute_from_model(:attribute_name)` gives access that will work with either.

These objects have methods to access, and can be serialized back to a Hash (post-transformation; with non-listed parameters removed), or directly to json.

```ruby
class UserApiModel < Requisite::ApiModel
  serialized_attributes do
    attribute! :id
    attribute! :username
    attribute :real_name
  end

  # method with the name of of an attribute will be called to calculate the mapped value
  def real_name
    "#{attribute_from_model(:first_name)} #{attribute_from_model(:last_name)}"
  end
end

current_user = User.new(:id => 5, :first_name => 'Jamie', :last_name => 'Osler', :username => 'josler')
user = UserApiModel.new(current_user)
user.username
# => 'josler'
user.real_name
# => 'Jamie Osler'
user.to_hash
# => { :id => 5, :real_name => 'Jamie Osler', :username => 'josler' }
user.to_json
# => "{\"id\":5,\"real_name\":\"Jamie Osler\",\"username\":\"josler\"}"
```

`nil` values are not returned in the response, unless `to_hash(show_nil: true)` or `to_json(show_nil: true)` are requested.

Errors are thrown when a required attribute is not present:

```ruby
UserApiModel.new({:id => 5, :first_name => 'Jamie', :last_name => 'Osler'}).to_hash
# => Requisite::NotImplementedError: 'username' not found on model
```

#### Options

There are several options that can be used with ApiModel attributes:

|    option   |                                                               behaviour                                                               |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| default     | `value` will be used as a default if the attribute is not found. Not available for `attribute!`                                       |
| stringify   | `.to_s` will be called on `value`                                                                                                     |
| rename      | The returned value will be sourced from the model's `value` attribute                                                                 |
| type        | Raises error if value does not match given type. Works on the model's value prior to stringification and renaming. Nils are excluded. |
| scalar_hash | Attribute is a hash with only scalar values permitted - Numeric, String, TrueClass and FalseClass types.                                                                               |
| typed_hash  | Attribute is a typed hash, with `value` a hash specifying a mapping of sub-attribute to types.                                        |
| typed_array | Attribute is a typed array, with `value` specifying the type of elements within the array                                             |

They can also be combined.

Example:

```ruby
class UserApiModel < Requisite::ApiModel
  serialized_attributes do
    attribute :id, stringify: true
    attribute :custom_attributes, rename: :custom_data
    attribute :is_awesome, default: true
    attribute :awesome_score, rename: :score, stringify: true, default: 9001
    attribute :age, type: Integer,
    attribute :tired, type: Requisite::Boolean
  end
end

current_user = User.new(:id => 5, :custom_data => [ {:number_events => 4} ], :age => 26)
UserApiModel.new(current_user).to_json
# => "{\"id\":\"5\",\"custom_attributes\":[{\"number_events\":4}],\"is_awesome\":true,\"awesome_score\":\"9001\",\"age\":26}"
```

The `Requisite::Boolean` type will match `TrueClass` and `FalseClass`.

#### Nested Structure Support

Nested structure support only applies one level deep; beyond that we recommend you use a nested ApiModel that's well structured.

##### Hashes

ApiModels support nested hashes in two forms; specifying that a Hash should contain only Scalar (Numeric, String and Boolean) values, or a nested hash of a typed attributes.

With scalar hashes, any scalar value is permitted:

```ruby
class UserApiModel < Requisite::ApiModel
  serialized_attributes do
    attribute :data, scalar_hash: true
  end
end

UserApiModel.new(:data => {:is_awesome => true, :score => 9001, :name => 'Jamie'}).to_hash
# => { :data => {:is_awesome => true, :score => 9001, :name => 'Jamie'} }
```

Non-scalar values will raise a `Requisite::BadTypeError`. Empty scalar hash attributes are returned as `{}`.

With typed hashes, only values specified with a type are permitted:

```ruby
class UserApiModel < Requisite::ApiModel
  serialized_attributes do
    attribute :data, typed_hash: { is_awesome: Requisite::Boolean, score: Integer, name: String  }
  end
end

UserApiModel.new(:data => {:is_awesome => true, :score => 9001, :name => 'Jamie'}).to_hash
# => { :data => {:is_awesome => true, :score => 9001, :name => 'Jamie'} }
```

Note that setting the type to the provided `Requisite::Boolean` permits `TrueClass` and `FalseClass` values.

Fields within a fixed hash that are not listed as permitted will be omitted (even with attribute! their presence will not raise an error).

Fields with the wrong data type will result in a `Requisite::BadTypeError` being raised. Empty typed hash attributes are returned as `{}`.

##### Arrays

Typed arrays are supported; arrays must be all of one type:

```ruby
class UserApiModel < Requisite::ApiModel
  serialized_attributes do
    attribute :ids, typed_array: String
  end
end

UserApiModel.new(:ids => ['x123D', 'u71d', '96yD']).to_hash
# => { :ids => ['x123D', 'u71d', '96yD'] }
```

Array values not corresponding to the correct type will raise a `Requisite::BadTypeError`. Empty Array attributes will be returned as `[]`.

#### Advanced Nested Structures

To work with advanced nested structures, we recommend you create a method with the attribute name that will be called, and use another ApiModel to perform validation, for example:

```ruby
class ApiUser < Requisite::ApiModel
  serialized_attributes do
    attribute :id, type: String
    attribute :company
  end

  # ApiCompany object handles its' own validation
  def company
    ApiCompany.new(attribute_from_model(:company)).to_hash
  end
end
```

#### Preprocess Request

A `preprocess_model` method can be defined to carry out any required steps before the model is processed, e.g.:

```ruby
class ApiUser < Requisite::ApiModel
  serialized_attributes do
    attribute :id, type: String
    attribute :email, type: String
  end

  # preprocess to check we have an identifier for the user
  def preprocess_model
    identifier = attribute_from_model(:id)
    identifier ||= attribute_from_model(:email)
    raise IdentifierNotFoundError unless identifier
  end
end
```

#### Around each attribute

An `around_each_attribute` method can be defined to wrap each attribute fetch in a block. This can be useful for instrumenting processing on a per attribute basis.

```ruby
class ApiUser < Requisite::ApiModel
  serialized_attributes do
    attribute :id, type: String
    attribute :email, type: String
  end

  def around_each_attribute(name, &block)
    start = Time.now
    yield
    end = Time.now
    puts "Fetching #{name} took #{end - start}"
  end
end
```

#### Thanks

Strongly inspired by the work done in the [mutations gem](https://github.com/cypriss/mutations), and with [restpack_serializer](https://github.com/RestPack/restpack_serializer), as well as some of the patterns laid out in Robert Martin's demonstrations of [clean architecture](http://blog.8thlight.com/uncle-bob/2012/08/13/the-clean-architecture.html).
