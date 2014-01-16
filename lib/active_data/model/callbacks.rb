module ActiveData
  module Model

    # == Callbacks for ActiveData::Model lifecycle
    #
    # Provides ActiveModel callbacks support for lifecycle
    # actions.
    #
    #   class Book
    #     include ActiveData::Model
    #     include ActiveData::Model::Callbacks
    #
    #     attribute :id, type: Integer
    #     attribute :title, type: String
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
        include ActiveData::Model::Lifecycle
        extend ActiveModel::Callbacks

        define_model_callbacks :initialize, only: :after
        define_model_callbacks :save, :create, :update, :destroy

      private
        def initialize *_
          super
          run_callbacks :initialize
        end

        def save_object
          run_callbacks(:save) { super }
        end

        def create_object
          run_callbacks(:create) { super }
        end

        def update_object
          run_callbacks(:update) { super }
        end

        def destroy_object
          run_callbacks(:destroy) { super }
        end
      end
    end
  end
end
