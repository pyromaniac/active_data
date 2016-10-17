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

#### EmbedsOne
#### EmbedsMany
#### ReferencesOne
#### ReferencesMany
#### Interacting with ActiveRecord

### Persistence Adapters

Adapter definition syntax:
```ruby
ActiveData.persistence_adapter('ClassName') do |data_source, primary_key, scope_proc|
  CustomAdapter.new(data_source, primary_key, scope_proc) # or anything that have similar interface to ActiveData::Model::Associations::PersistenceAdapters::Base
end
```
Where  
`ClassName` - name of model class or one of ancestors  
`data_source` - name of data source class  
`primary_key` - key to search data  
`scope_proc` - additional proc for filtering  

All required interface for adapters described in `ActiveData::Model::Associations::PersistenceAdapters::Base`.

Adapter for ActiveRecord is `ActiveData::Model::Associations::PersistenceAdapters::ActiveRecord`.
```ruby
ActiveData.persistence_adapter('ActiveRecord::Base') do |data_source, primary_key, scope_proc|
  PersistenceAdapters::ActiveRecord.new(data_source, primary_key, scope_proc)
end
```
So, all AR models will use `PersistenceAdapters::ActiveRecord` by default.

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
