[![Build Status](https://travis-ci.org/pyromaniac/active_data.png?branch=master)](https://travis-ci.org/pyromaniac/active_data)
[![Code Climate](https://codeclimate.com/github/pyromaniac/active_data.png)](https://codeclimate.com/github/pyromaniac/active_data)

# ActiveData

ActiveData is a ActiveModel-based front-end for your data. You might need to use it in the following cases:

* When you need a form objects pattern.

```ruby
class ProfileForm
  include ActiveData::Model

  attribute 'first_name', String
  attribute 'last_name', String
  attribute 'birth_date', Date

  def full_name
    [first_name, last_name].reject(&:blank).join(' ')
  end

  def full_name= value
    self.first_name, self.last_name = value.split(' ', 2).map(&:strip)
  end
end

class ProfileController < ApplicationController
  def edit
    @form = ProfileForm.new current_user.attributes
  end

  def update
    result = ProfileForm.new(params[:profile_form]).save do |form|
      current_user.update_attributes(form.attributes)
    end

    if result
      redirect_to ...
    else
      render 'edit'
    end
  end
end
```

* When you need to work with data-storage in ActiveRecord style with

```ruby
class Flight
  include ActiveData::Model

  attribute :airline, String
  attribute :number, String
  attribute :departure, Time
  attribute :arrival, Time

  validates :airline, :number, presence: true

  def id
    [airline, number].join('-')
  end

  def self.find id
    source = REDIS.get(id)
    instantiate(JSON.parse(source)) if source.present?
  end

  define_save do
    REDIS.set(id, attributes.to_json)
  end

  define_destroy do
    REDIS.del(id)
  end
end
```

* When you need to implement embedded objects for ActiveRecord models

```ruby
class Answer
  include ActiveData::Model

  attribute :question_id, Integer
  attribute :content, String

  validates :question_id, :content, presence: true
end

class Quiz < ActiveRecord::Base
  embeds_many :answers

  validates :user_id, presence: true
  validates :answers, associated: true
end

q = Quiz.new
q.answers.build(question_id: 42, content: 'blabla')
q.save
```

## Why?

ActiveData is an ActiveModel-based library that provides the following abilities:

  * Standard form objects building toolkit: attributes with typecasting, validations, etc.
  * High-level universal ORM/ODM library using any data source (DB, http, redis, text files).
  * Embedding objects into your ActiveRecord entities. Quite useful with PG JSON capabilities.

Key features:

  * Complete objects lifecycle support: saving, updating, destroying.
  * Embedded and referenced associations.
  * Backend-agnostic named scopes functionality.
  * Callbacks, validations and dirty attributes inside.

## Installation

Add this line to your application's Gemfile:

    gem 'active_data'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_data

## Usage

ActiveData has modular architecture, so it is required to include modules to obtain additional features. By default ActiveData supports attributes definition and validations.

### Attributes

ActiveData provides several types of attributes and typecasts each attribute to its defined type upon initialization.

```ruby
class Book
  include ActiveData::Model

  attribute :title, String
  collection :author_ids, Integer
end
```

#### Attribute

```ruby
attribute :full_name, String, default: 'John Talbot'
```

By default, if type for attribute is not set, it is defined with `Object` type, so it would be a great idea to specify type for every attribute explicitly.

Type is necessary for attribute typecasting. Here is the list of pre-defined basic typecasters:

```irb
[1] pry(main)> ActiveData._typecasters.keys
=> ["Object", "String", "Array", "Hash", "Date", "DateTime", "Time", "ActiveSupport::TimeZone", "BigDecimal", "Float", "Integer", "Boolean", "ActiveData::UUID"]
```

In addition, you can provide any class type when defining the attribute, but in that case you will be able to only assign instances of that specific class or value nil:

```ruby
attribute :template, MyCustomTemplateType
```

##### Defaults

It is possible to provide default values for attributes and they will act in the same way as AR or Mongoid default values:

```ruby
attribute :check, Boolean, default: false # Simply false by default
attribute :today, Date, default: ->{ Time.zone.now.to_date } # Dynamic default value
attribute :today_wday, Integer, default: ->{ today.wday } # Default is evaluated in instance context
attribute :today_wday, Integer, default: ->(instance) { instance.today.wday } # The same as previous, but instance provided explicitly
```

##### Enums

Enums restrict the scope of possible values for attribute. If assigned value is not included in provided list - then it turns to nil:

```ruby
attribute :direction, String, enum: %w[north south east west]
```

##### Normalizers

Normalizers are applied last, modifying typecast value. It is possible to provide a list of normalizers, they will be applied in the order. It is possible to pre-define normalizers to DRY code:

```ruby
ActiveData.normalizer(:trim) do |value, options, _attribute|
  value.first(options[:length] || 2)
end

attribute :title, String, normalizers: [->(value) { value.strip }, trim: {length: 80}]
```

##### Readonly

```ruby
attribute :name, String, readonly: true # Readonly forever
attribute :name, String, readonly: ->{ true } # Conditionally readonly
attribute :name, String, readonly: ->(instance) { instance.subject.present? } # Explicit instance
```

#### Collection

Collection is simply an array of equally-typed values:

```ruby
class Panda
  include ActiveData::Model

  collection :ids, Integer
end
```

Collection typecasts each value to specified type and also no matter what are you going to pass - it will be an array.

```irb
[1] pry(main)> Panda.new
=> #<Panda ids: []>
[2] pry(main)> Panda.new(ids: 42)
=> #<Panda ids: [42]>
[3] pry(main)> Panda.new(ids: [42, '33'])
=> #<Panda ids: [42, 33]>
```

Default and enum modifiers are applied to every value, normalizer will be applied to the whole array.

#### Dictionary

Dictionary field is a hash of specified type values with string keys:

```ruby
class Foo
  include ActiveData::Model

  dictionary :ordering, String
end
```

```irb
[1] pry(main)> Foo.new
=> #<Foo ordering: {}>
[2] pry(main)> Foo.new(ordering: {name: :desc})
=> #<Foo ordering: {"name"=>"desc"}>
```

Keys list might be restricted with `:keys` option, defaults and enums are applied to every value, normalizers are applied to the whole hash.

#### Localized

Localized is similar to how Globalize 3 attributes work.

```ruby
localized :title, String
```

#### Represents

Represents provides an easy way to expose model attributes through an interface.
It will automatically set passed value to the represented object **before validation**.
You can use any ActiveRecord, ActiveModel or ActiveData object as a target of representation.
A type of an attribute will be taken from it.
If there is no type, it will be `Object` by default. You can set the type explicitly by passing the `type: TypeClass` option.
Represents will also add automatic validation of the target object.

```ruby
class Person
  include ActiveData::Model

  attribute :name, String
end

class Doctor
  include ActiveData::Model
  include ActiveData::Model::Representation

  attribute :person, Object
  represents :name, of: :person
end

person = Person.new(name: 'Walter Bishop')
# => #<Person name: "Walter Bishop">
Doctor.new(person: person).name
# => "Walter Bishop"
Doctor.new(person: person, name: 'Dr. Walter Bishop').name
# => "Dr. Walter Bishop"
person.name
# => "Dr. Walter Bishop"
```

### Associations

ActiveData provides a set of associations. There are two types of them: referenced and embedded. The closest example of referenced association is AR `belongs_to` and as for embedded ones - Mongoid's embedded. Also these associations support `accepts_nested_attributes` call.

#### EmbedsOne

```ruby
embeds_one :profile
```

Defines singular embedded object. Might be defined inline:

```ruby
embeds_one :profile do
  attribute :first_name, String
  attribute :last_name, String
end
```

Possible options:

* `:class_name` - association class name
* `:validate` - true or false
* `:default` - default value for association: attributes hash or instance of defined class

#### EmbedsMany

```ruby
embeds_many :tags
```

Defines collection of embedded objects. Might be defined inline:

```ruby
embeds_many :tags do
  attribute :identifier, String
end
```

* `:class_name` - association class name
* `:validate` - true or false
* `:default` - default value for association: attributes hash collection or instances of defined class

#### ReferencesOne

```ruby
references_one :user
```

This will provide several methods to the object: `#user`, `#user=`, `#user_id` and `#user_id=`, just as would occur with an ActiveRecord association.

Possible options:

* `:class_name` - association class name
* `:primary_key` - associated object primary key (`:id` by default):

  ```ruby
  references_one :user, primary_key: :name
  ```

  This will create the following methods: `#user`, `#user=`, `#user_name` and `#user_name=`

* `:reference_key` - redefines `#user_id` and `#user_id=` method names completely.
* `:validate` - true or false
* `:default` - default value for association: reference or object itself

#### ReferencesMany

```ruby
references_many :users
```

This will provide several methods to the object: `#users`, `#users=`, `#user_ids` and `#user_ids=` just as an ActiveRecord relation does.

Possible options:

* `:class_name` - association class name
* `:primary_key` - associated object primary key (`:id` by default):

  ```ruby
  references_many :users, primary_key: :name
  ```

  This will create the following methods: `#users`, `#users=`, `#user_names` and `#user_names=`

* `:reference_key` - redefines `#user_ids` and `#user_ids=` method names completely.
* `:validate` - true or false
* `:default` - default value for association: reference collection or objects themselves

#### Interacting with ActiveRecord

### Persistence Adapters

Adapter definition syntax:
```ruby
class Mongoid::Document
  # anything that have similar interface to
  # ActiveData::Model::Associations::PersistenceAdapters::Base
  def self.active_data_persistence_adapter
    MongoidAdapter
  end
end
```
Where
`ClassName` - name of model class or one of ancestors
`data_source` - name of data source class
`primary_key` - key to search data
`scope_proc` - additional proc for filtering

All required interface for adapters described in `ActiveData::Model::Associations::PersistenceAdapters::Base`.

Adapter for ActiveRecord is `ActiveData::Model::Associations::PersistenceAdapters::ActiveRecord`. So, all AR models will use `PersistenceAdapters::ActiveRecord` by default.

### Primary

### Persistence

### Lifecycle

### Callbacks

### Dirty

### Validations

### Scopes

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
