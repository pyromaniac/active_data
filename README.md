[![Build Status](https://travis-ci.org/pyromaniac/active_data.png?branch=master)](https://travis-ci.org/pyromaniac/active_data)
[![Code Climate](https://codeclimate.com/github/pyromaniac/active_data.png)](https://codeclimate.com/github/pyromaniac/active_data)

# ActiveData

ActiveData is a ActiveModel-based frontend for your data. You might need to use it in the following cases:

* When you need a form objects pattern.

```ruby
class ProfileForm
  include ActiveData::Model

  attribute 'first_name', type: String
  attribute 'last_name', type: String
  attribute 'birth_date', type: Date

  def full_name
    [first_name, last_name].reject(&:blank).join(' ')
  end

  def full_name= value
    self.first_name, self.last_name = value.split(' ', 2).map(&:strip)
  end
end

class ProfileController < ApplicationController
  def edit
    @form = ProfileForm.new current_user.attributes.slice(*%w(full_name birth_date))
  end
  def update
    result = ProfileForm.new(params[:profile_form]).save do |form|
      current_user.update_attributes(form.attributes.slice(*%w(full_name birth_date)))
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

  attribute :airline, type: String
  attribute :number, type: String
  attribute :departure, type: Time
  attribute :arrival, type: Time

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

  attribute :question_id, type: Integer
  attribute :content, type: String

  validates :question_id, :content, presence: true
end

class Quiz < ActiveRecord::Base
  embeds_many :answers

  validates :user_id, presence: true
  validates :answers, associated: true
end

q = Quis.new
q.answers.build(question_id: 42, content: 'blabla')
q.save
```

## Installation

Add this line to your application's Gemfile:

    gem 'active_data'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_data

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
