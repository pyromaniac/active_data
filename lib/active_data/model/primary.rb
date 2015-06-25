module ActiveData
  module Model
    module Primary
      extend ActiveSupport::Concern
      DEFAULT_PRIMARY_ATTRIBUTE_OPTIONS = -> { {
        type: ActiveData::UUID,
        default: -> { ActiveData::UUID.random_create }
      } }

      included do
        delegate :has_primary_attribute?, to: 'self.class'
        alias_method_chain :==, :primary
        alias_method :eql?, :==
      end

      module ClassMethods
        def primary_attribute options = {}
          attribute ActiveData.primary_attribute, options.presence || DEFAULT_PRIMARY_ATTRIBUTE_OPTIONS.call
        end

        def has_primary_attribute?
          has_attribute? ActiveData.primary_attribute
        end
      end

      def primary_attribute
        send(ActiveData.primary_attribute)
      end

      define_method :'=_with_primary=' do |other|
        other.instance_of?(self.class) &&
          has_primary_attribute? ?
            primary_attribute && primary_attribute == other.primary_attribute :
            send(:'=_without_primary=', other)
      end
    end
  end
end
