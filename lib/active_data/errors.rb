module ActiveData
  class ActiveDataError < StandardError
  end

  class NotFound < ActiveDataError
  end

  class ValidationError < ActiveDataError
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

  class AssociationTypeMismatch < ActiveDataError
    def initialize expected, got
      super "Expected `#{expected}` (##{expected.object_id}), but got `#{got}` (##{got.object_id})"
    end
  end
end
