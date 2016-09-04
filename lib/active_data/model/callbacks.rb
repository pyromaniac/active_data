module ActiveData
  module Model
    # == Callbacks for ActiveData::Model lifecycle
    #
    # Provides ActiveModel callbacks support for lifecycle
    # actions.
    #
    #   class Book
    #     include ActiveData::Model
    #
    #     attribute :id, Integer
    #     attribute :title, String
    #
    #     define_save do
    #       REDIS.set(id, attributes.to_json)
    #     end
    #
    #     define_destroy do
    #       REDIS.del(instance.id)
    #     end
    #
    #     after_initialize :setup_id
    #     before_save :do_something
    #     around_update do |&block|
    #       ...
    #       block.call
    #       ...
    #     end
    #     after_destroy { ... }
    #   end
    #
    module Callbacks
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Callbacks

        include ActiveModel::Validations::Callbacks
        include Lifecycle
        prepend PrependMethods

        define_model_callbacks :initialize, only: :after
        define_model_callbacks :save, :create, :update, :destroy
      end

      module PrependMethods
        def initialize(*_)
          super
          run_callbacks :initialize
        end

        def save_object(&block)
          run_callbacks(:save) { super(&block) }
        end

        def create_object(&block)
          run_callbacks(:create) { super(&block) }
        end

        def update_object(&block)
          run_callbacks(:update) { super(&block) }
        end

        def destroy_object(&block)
          run_callbacks(:destroy) { super(&block) }
        end
      end
    end
  end
end
