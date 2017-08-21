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
    #     attribute :id, Integer
    #     attribute :title, String
    #
    #     define_save do # executes in the instance scope
    #       REDIS.set(id, attributes.to_json)
    #     end
    #
    #     define_destroy do
    #       REDIS.del(id)
    #     end
    #   end
    #
    #   class Author
    #     include ActiveData::Model
    #     include ActiveData::Model::Lifecycle
    #
    #     attribute :id, Integer
    #     attribute :name, String
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
    # If performers was not defined in model, they cat be passed as
    # blocks to `save`, `update` and `destroy` methods:
    #
    #   authos.save { REDIS.set(id, attributes.to_json) }
    #   authos.update { REDIS.set(id, attributes.to_json) }
    #   authos.destroy { REDIS.del(id) }
    #
    # Save and destroy processes acts almost the save way as
    # ActiveRecord's (with +persisted?+ and +destroyed?+ methods
    # affecting).
    #
    module Lifecycle
      extend ActiveSupport::Concern

      included do
        include Persistence

        class_attribute(*%i[save create update destroy].map { |action| "_#{action}_performer" })
        private(*%i[save create update destroy].map { |action| "_#{action}_performer=" })
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
        %i[save create update destroy].each do |action|
          define_method "define_#{action}" do |&block|
            send("_#{action}_performer=", block)
          end
        end

        # Initializes new instance with attributes passed and calls +save+
        # on it. Returns instance in any case.
        #
        def create(*args)
          new(*args).tap(&:save)
        end

        # Initializes new instance with attributes passed and calls +save!+
        # on it. Returns instance in case of success and raises ActiveData::ValidationError
        # or ActiveData::ObjectNotSaved in case of validation or saving fail respectively.
        #
        def create!(*args)
          new(*args).tap(&:save!)
        end
      end

      # <tt>define_<action></tt> on instance level works the same
      # way as class <tt>define_<action></tt> methods, but defines
      # performers for instance only
      #
      #   user.define_save do
      #     REDIS.set(id, attributes.to_json)
      #   end
      #   user.save! # => will use instance-level performer
      #
      %i[save create update destroy].each do |action|
        define_method "define_#{action}" do |&block|
          send("_#{action}_performer=", block)
        end
      end

      # Assigns passed attributes and calls +save+
      # Returns true or false in case of successful or unsuccessful
      # saving respectively.
      #
      #   author.update(name: 'Donald')
      #
      # If update performer is not defined with `define_update`
      # or `define_save`, it raises ActiveData::UnsavableObject.
      # Also save performer block might be passed instead of in-class
      # performer definition:
      #
      #   author.update(name: 'Donald') { REDIS.set(id, attributes.to_json) }
      #
      def update(attributes, &block)
        assign_attributes(attributes) && save(&block)
      end
      alias_method :update_attributes, :update

      # Assigns passed attributes and calls +save!+
      # Returns true in case of success and raises ActiveData::ValidationError
      # or ActiveData::ObjectNotSaved in case of validation or
      # saving fail respectively.
      #
      #   author.update!(name: 'Donald')
      #
      # If update performer is not defined with `define_update`
      # or `define_save`, it raises ActiveData::UnsavableObject.
      # Also save performer block might be passed instead of in-class
      # performer definition:
      #
      #   author.update!(name: 'Donald') { REDIS.set(id, attributes.to_json) }
      #
      def update!(attributes, &block)
        assign_attributes(attributes) && save!(&block)
      end
      alias_method :update_attributes!, :update!

      # # Saves object by calling save performer defined with +define_save+,
      # +define_create+ or +define_update+ methods.
      # Returns true or false in case of successful
      # or unsuccessful saving respectively. Changes +persisted?+ to true
      #
      #   author.save
      #
      # If save performer is not defined with `define_update` or
      # `define_create` or `define_save`, it raises ActiveData::UnsavableObject.
      # Also save performer block might be passed instead of in-class
      # performer definition:
      #
      #   author.save { REDIS.set(id, attributes.to_json) }
      #
      def save(_options = {}, &block)
        raise ActiveData::UnsavableObject unless block || savable?
        valid? && save_object(&block)
      end

      # Saves object by calling save performer defined with +define_save+,
      # +define_create+ or +define_update+ methods.
      # Returns true in case of success and raises ActiveData::ValidationError
      # or ActiveData::ObjectNotSaved in case of validation or
      # saving fail respectively. Changes +persisted?+ to true
      #
      #   author.save!
      #
      # If save performer is not defined with `define_update` or
      # `define_create` or `define_save`, it raises ActiveData::UnsavableObject.
      # Also save performer block might be passed instead of in-class
      # performer definition:
      #
      #   author.save! { REDIS.set(id, attributes.to_json) }
      #
      def save!(_options = {}, &block)
        raise ActiveData::UnsavableObject unless block || savable?
        validate!
        save_object(&block) or raise ActiveData::ObjectNotSaved
      end

      # Destroys object by calling the destroy performer.
      # Returns instance in any case. Changes +persisted?+
      # to false and +destroyed?+ to true in case of success.
      #
      #   author.destroy
      #
      # If destroy performer is not defined with `define_destroy`,
      # it raises ActiveData::UndestroyableObject.
      # Also destroy performer block might be passed instead of in-class
      # performer definition:
      #
      #   author.destroy { REDIS.del(id) }
      #
      def destroy(&block)
        raise ActiveData::UndestroyableObject unless block || destroyable?
        destroy_object(&block)
        self
      end

      # Destroys object by calling the destroy performer.
      # In case of success returns instance and changes +persisted?+
      # to false and +destroyed?+ to true.
      # Raises ActiveData::ObjectNotDestroyed in case of fail.
      #
      #   author.destroy!
      #
      # If destroy performer is not defined with `define_destroy`,
      # it raises ActiveData::UndestroyableObject.
      # Also destroy performer block might be passed instead of in-class
      # performer definition:
      #
      #   author.destroy! { REDIS.del(id) }
      #
      def destroy!(&block)
        raise ActiveData::UndestroyableObject unless block || destroyable?
        destroy_object(&block) or raise ActiveData::ObjectNotDestroyed
        self
      end

    private

      def savable?
        !!((persisted? ? _update_performer : _create_performer) || _save_performer)
      end

      def save_object(&block)
        apply_association_changes! if respond_to?(:apply_association_changes!)
        result = persisted? ? update_object(&block) : create_object(&block)
        mark_persisted! if result
        result
      end

      def create_object(&block)
        performer = block || _create_performer || _save_performer
        !!performer_exec(&performer)
      end

      def update_object(&block)
        performer = block || _update_performer || _save_performer
        !!performer_exec(&performer)
      end

      def destroyable?
        !!_destroy_performer
      end

      def destroy_object(&block)
        performer = block || _destroy_performer
        result = !!performer_exec(&performer)
        mark_destroyed! if result
        result
      end

      def performer_exec(&block)
        if block.arity == 1
          yield(self)
        else
          instance_exec(&block)
        end
      end
    end
  end
end
