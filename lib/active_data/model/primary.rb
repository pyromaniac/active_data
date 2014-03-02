module ActiveData
  module Model
    module Primary
      extend ActiveSupport::Concern

      included do
        delegate :has_primary_attribute?, to: 'self.class'
      end

      module ClassMethods
        def primary_attribute options = {}
          attribute ActiveData.primary_attribute,
            options.reverse_merge(
              type: ActiveData::UUID,
              default: ->{ ActiveData::UUID.random_create }
            )
        end

        def has_primary_attribute?
          has_attribute? ActiveData.primary_attribute
        end
      end
    end
  end
end
