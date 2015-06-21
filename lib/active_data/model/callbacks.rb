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
        extend ActiveModel::Callbacks

        include ActiveModel::Validations::Callbacks
        include Lifecycle

        define_model_callbacks :initialize, only: :after
        define_model_callbacks :save, :create, :update, :destroy

        alias_method_chain :initialize, :callbacks
        alias_method_chain :save_object, :callbacks
        alias_method_chain :create_object, :callbacks
        alias_method_chain :update_object, :callbacks
        alias_method_chain :destroy_object, :callbacks
      end

    private

      def initialize_with_callbacks *_
        initialize_without_callbacks(*_)
        run_callbacks :initialize
      end

      def save_object_with_callbacks &block
        run_callbacks(:save) { save_object_without_callbacks(&block) }
      end

      def create_object_with_callbacks &block
        run_callbacks(:create) { create_object_without_callbacks(&block) }
      end

      def update_object_with_callbacks &block
        run_callbacks(:update) { update_object_without_callbacks(&block) }
      end

      def destroy_object_with_callbacks &block
        run_callbacks(:destroy) { destroy_object_without_callbacks(&block) }
      end
    end
  end
end
