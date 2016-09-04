module ActiveData
  module Model
    module Validations
      extend ActiveSupport::Concern
      include ActiveModel::Validations

      included do
        extend HelperMethods
        include HelperMethods

        alias_method :validate, :valid?
      end

      def validate!(context = nil)
        valid?(context) || raise_validation_error
      end

    protected

      def raise_validation_error
        raise ActiveData::ValidationError, self
      end
    end
  end
end

Dir[File.dirname(__FILE__) + '/validations/*.rb'].each { |file| require file }
