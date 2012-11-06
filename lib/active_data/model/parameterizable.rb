module ActiveData
  module Model
    module Parameterizable
      extend ActiveSupport::Concern

      def to_params options = nil
        hash = serializable_hash options

        self.class.association_names.each do |association_name|
          if self.class.nested_attributes? association_name
            records = send(association_name)
            hash["#{association_name}_attributes"] = if records.is_a?(Enumerable)
              attributes = {}
              records.each_with_index do |a, i|
                key = a.has_attribute?(:id) && a.id? ? a.id : i
                attributes[key.to_s] = a.serializable_hash
              end
              attributes
            else
              records.serializable_hash
            end
          end
        end

        hash
      end
    end
  end
end