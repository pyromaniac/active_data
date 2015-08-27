module ActiveData
  module Model
    module Validations
      extend ActiveSupport::Concern
      include ActiveModel::Validations

      included do
        extend HelperMethods
        include HelperMethods
      end

      def validate! context = nil
        valid?(context) || raise_validation_error
      end

    protected

      def raise_validation_error
        raise ActiveData::ValidationError.new(self)
      end

    private

      # Move represent attribute errors to the top level:
      #
      #   {role: {:'user.email' => ['Some error']}}
      #
      # to:
      #
      #   {email: ['Some error']}
      #
      def run_validations! #:nodoc:
        super
        self.class.represents_attributes.each do |reference, attributes|
          reference_errors = errors.messages[reference.to_sym]
          next unless reference_errors

          attributes_hash = attributes.index_by(&:attribute)
          reference_errors.each do |key, messages|
            name = key.to_s.split(?.).last
            if attributes_hash.key?(name)
              reference_errors.delete(key)
              errors.messages[name.to_sym] ||= []
              errors.messages[name.to_sym].concat(messages)
            end
          end

          errors.messages.delete(reference.to_sym) if reference_errors.empty?
        end
        errors.empty?
      end
    end
  end
end

Dir[File.dirname(__FILE__) + "/validations/*.rb"].each { |file| require file }
