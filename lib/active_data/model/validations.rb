module ActiveData
  module Model
    module Validations
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Validations
        extend HelperMethods
        include HelperMethods
      end

      def validate! context = nil
        valid?(context) || raise_validation_error
      end

    protected

      def raise_validation_error
        raise(ActiveData::ValidationError.new(self))
      end
    end
  end
end

Dir[File.dirname(__FILE__) + "/validations/*.rb"].each { |file| require file }
