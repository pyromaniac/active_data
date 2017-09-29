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
      errors = @model.errors.full_messages.join(', ')
      super(I18n.t(:"#{@model.class.i18n_scope}.errors.messages.model_invalid", errors: errors, default: :'errors.messages.model_invalid'))
    end
  end

  class UnsavableObject < ActiveDataError
  end

  class UndestroyableObject < ActiveDataError
  end

  class ObjectNotSaved < ActiveDataError
  end

  class ObjectNotDestroyed < ActiveDataError
  end

  class AssociationChangesNotApplied < ActiveDataError
  end

  class AssociationTypeMismatch < ActiveDataError
    def initialize(expected, got)
      super "Expected `#{expected}` (##{expected.object_id}), but got `#{got}` (##{got.object_id})"
    end
  end

  class ObjectNotFound < ActiveDataError
    def initialize(object, association_name, record_id)
      message = "Couldn't find #{object.class.reflect_on_association(association_name).klass.name}" \
        "with #{object.respond_to?(:_primary_name) ? object._primary_name : 'id'} = #{record_id} for #{object.inspect}"
      super message
    end
  end

  class TooManyObjects < ActiveDataError
    def initialize(limit, actual_size)
      super "Maximum #{limit} objects are allowed. Got #{actual_size} objects instead."
    end
  end

  class UndefinedPrimaryAttribute < ActiveDataError
    def initialize(klass, association_name)
      super <<-MESSAGE
Undefined primary attribute for `#{association_name}` in #{klass}.
It is required for embeds_many nested attributes proper operation.
You can define this association as:

  embeds_many :#{association_name} do
    primary :attribute_name
  end
      MESSAGE
    end
  end

  class NormalizerMissing < NoMethodError
    def initialize(name)
      super <<-MESSAGE
Could not find normalizer `:#{name}`
You can define it with:

  ActiveData.normalizer(:#{name}) do |value, options|
    # do some staff with value and options
  end
      MESSAGE
    end
  end

  class TypecasterMissing < NoMethodError
    def initialize(*classes)
      classes = classes.flatten
      super <<-MESSAGE
Could not find typecaster for #{classes}
You can define it with:

  ActiveData.typecaster('#{classes.first}') do |value|
    # do some staff with value and options
  end
      MESSAGE
    end
  end

  class PersistenceAdapterMissing < NoMethodError
    def initialize(data_source)
      super <<-MESSAGE
Could not find persistence adapter for #{data_source}
You can define it with:

  class #{data_source}
    def self.active_data_persistence_adapter
      #{data_source}ActiveDataPersistenceAdapter
    end
  end
      MESSAGE
    end
  end
end
