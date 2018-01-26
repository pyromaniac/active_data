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



#### Attribute
#### Collection
#### Dictionary
#### Localized
#### Represents

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
