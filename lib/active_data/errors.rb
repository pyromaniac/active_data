module ActiveData
  class ActiveDataError < StandardError
  end

  class NotFound < ActiveDataError
  end

  # Backported from active_model 5
  class ValidationError < ActiveDataError
    attr_reader :model

    def initialize(model)
      @model = model
      errors = @model.errors.full_messages.join(", ")
      super(I18n.t(:"#{@model.class.i18n_scope}.errors.messages.model_invalid", errors: errors, default: :'errors.messages.model_invalid'))
    end
  end

  class ObjectNotFound < ActiveDataError
  end

  class UnsavableObject < ActiveDataError
  end

  class UndestroyableObject < ActiveDataError
  end

  class ObjectNotSaved < ActiveDataError
  end

  class ObjectNotDestroyed < ActiveDataError
  end

  class AssociationNotSaved < ActiveDataError
  end

  class AssociationTypeMismatch < ActiveDataError
    def initialize expected, got
      super "Expected `#{expected}` (##{expected.object_id}), but got `#{got}` (##{got.object_id})"
    end
  end

  class TooManyObjects < ActiveDataError
  end

  class NormalizerMissing < NoMethodError
    def initialize name
      super <<-EOS
Could not find normalizer `:#{name}`
You can define it with:

  ActiveData.normalizer(:#{name}) do |value, options|
    # do some staff with value and options
  end
      EOS
    end
  end
end
