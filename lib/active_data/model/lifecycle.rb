module ActiveData
  module Model

    # == Lifecycle methods for ActiveData::Model
    #
    # Provides methods +save+ and +destroy+ and its bang variants.
    # Also, patches +create+ and +update_attributes+ methods by adding
    # save at the end.
    #
    # You can define save or destroy performers with <tt>define_<action></tt>
    # methods. Create and update performers might be defined instead of
    # save performer:
    #
    #   class Book
    #     include ActiveData::Model
    #     include ActiveData::Model::Lifecycle
    #
    #     attribute :id, type: Integer
    #     attribute :title, type: String
    #
    #     define_save do # executes in the instance scope
    #       REDIS.set(id, attributes.to_json)
    #     end
    #
    #     define_destroy do
    #       REDIS.del(instance.id)
    #     end
    #   end
    #
    #   class Author
    #     include ActiveData::Model
    #     include ActiveData::Model::Lifecycle
    #
    #     attribute :id, type: Integer
    #     attribute :name, type: String
    #
    #     define_create do # will be called on create only
    #       REDIS.sadd('author_ids', id)
    #       REDIS.set(id, attributes.to_json)
    #     end
    #
    #     define_update do # will be called on update only
    #       REDIS.set(id, attributes.to_json)
    #     end
    #   end
    #
    # In case of undefined performer ActiveData::UnsavableObject
    # or ActiveData::UndestroyableObject will be raised respectively.
    #
    # Save and destroy processes acts almost the save way as
    # ActiveRecord's (with +persisted?+ and +destroyed?+ methods
    # affecting). But without callbacks by default. To add callbacks
    # you need simply include ActiveData::Model::Callbacks.
    #
    module Lifecycle
      extend ActiveSupport::Concern

      included do
        class_attribute *[:save, :create, :update, :destroy].map { |action| "_#{action}_performer" }, instance_writer: false
      end

      module ClassMethods

        # <tt>define_<action></tt> methods define performers for lifecycle
        # actions. Every action block must return boolean result, which
        # would mean the action success. If action performed unsuccessfully
        # ActiveData::ObjectNotSaved or ActiveData::ObjectNotDestroyed will
        # be raised respectively in case of bang methods using.
        #
        #   class Author
        #     define_create { true }
        #   end
        #
        #   Author.new.save # => true
        #   Author.new.save! # => true
        #
        #   class Author
        #     define_create { false }
        #   end
        #
        #   Author.new.save # => false
        #   Author.new.save! # => ActiveData::ObjectNotSaved
        #
        # Also performers blocks are executed in the instance context, but
        # instance also passed as argument
        #
        #   define_update do |instance|
        #      instance.attributes.to_json
        #   end
        #
        # +define_create+ and +define_update+ performers has higher priority
        # than +define_save+.
        #
        #   class Author
        #     define_update { ... }
        #     define_save { ... }
        #   end
        #
        #   author = Author.create # using define_save performer
        #   author.update_attributes(...) # using define_update performer
        #
        [:save, :create, :update, :destroy].each do |action|
          define_method "define_#{action}" do |&block|
            self.send("_#{action}_performer=", block)
          end
        end

        # Initializes new instance with attributes passed and calls +save+
        # on it. Returns instance in any case.
        #
        def create attributes = {}
          new(attributes).tap(&:save)
        end

        # Initializes new instance with attributes passed and calls +save!+
        # on it. Returns instance in case of success and raises ActiveData::ValidationError
        # or ActiveData::ObjectNotSaved in case of validation or saving fail respectively.
        #
        def create! attributes = {}
          new(attributes).tap(&:save!)
        end
      end

      # Assigns passed attributes and calls +save+
      # Returns true or false in case of successful or unsuccessful
      # saving respectively.
      #
      def update_attributes attributes
        assign_attributes(attributes) && save
      end

      # Assigns passed attributes and calls +save!+
      # Returns true in case of success and raises ActiveData::ValidationError
      # or ActiveData::ObjectNotSaved in case of validation or
      # saving fail respectively.
      #
      def update_attributes! attributes
        assign_attributes(attributes) && save!
      end

      # # Saves object by calling save performer defined with +define_save+,
      # +define_create+ or +define_update+ methods.
      # Returns true or false in case of successful
      # or unsuccessful saving respectively. Changes +persisted?+ to true
      #
      def save options = {}
        raise ActiveData::UnsavableObject unless savable?
        valid? && save_object
      end

      # Saves object by calling save performer defined with +define_save+,
      # +define_create+ or +define_update+ methods.
      # Returns true in case of success and raises ActiveData::ValidationError
      # or ActiveData::ObjectNotSaved in case of validation or
      # saving fail respectively. Changes +persisted?+ to true
      #
      def save! options = {}
        raise ActiveData::UnsavableObject unless savable?
        raise ActiveData::ValidationError unless valid?
        save_object or raise ActiveData::ObjectNotSaved
      end

      # Destroys object by calling the destroy performer.
      # Returns instance in any case. Changes +persisted?+
      # to false and +destroyed?+ to true in case of success.
      #
      def destroy
        raise ActiveData::UndestroyableObject unless destroyable?
        destroy_object
        self
      end

      # Destroys object by calling the destroy performer.
      # In case of success returns instance and changes +persisted?+
      # to false and +destroyed?+ to true.
      # Raises ActiveData::ObjectNotDestroyed in case of fail.
      #
      def destroy!
        raise ActiveData::UndestroyableObject unless destroyable?
        destroy_object or raise ActiveData::ObjectNotDestroyed
        self
      end

    private

      def savable?
        !!((persisted? ? _update_performer : _create_performer) || _save_performer)
      end

      def save_object
        result = persisted? ? update_object : create_object
        @persisted = true if result
        result
      end

      def create_object
        performer = _create_performer || _save_performer
        instance_exec(self, &performer)
      end

      def update_object
        performer = _update_performer || _save_performer
        instance_exec(self, &performer)
      end

      def destroyable?
        !!_destroy_performer
      end

      def destroy_object
        result = instance_exec(self, &_destroy_performer)
        if result
          @persisted = false
          @destroyed = true
        end
        result
      end
    end
  end
end
