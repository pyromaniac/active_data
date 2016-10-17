module ActiveData
  class Config
    include Singleton

    attr_accessor :include_root_in_json, :i18n_scope, :logger, :primary_attribute,
      :_normalizers, :_typecasters, :_persistence_adapters

    def self.delegated
      public_instance_methods - superclass.public_instance_methods - Singleton.public_instance_methods
    end

    def initialize
      @include_root_in_json = false
      @i18n_scope = :active_data
      @logger = Logger.new(STDERR)
      @primary_attribute = :id
      @_normalizers = {}
      @_typecasters = {}
      @_persistence_adapters = {}
    end

    def normalizer(name, &block)
      if block
        _normalizers[name.to_sym] = block
      else
        _normalizers[name.to_sym] or raise NormalizerMissing, name
      end
    end

    def persistence_adapter(klass, &block)
      klass_name = klass.to_s.camelize
      if block
        _persistence_adapters[klass_name] = block
      else
        klass_const = klass_name.constantize
        adapter = _persistence_adapters.values_at(*klass_const.ancestors.map(&:to_s)).compact.first
        raise PersistenceAdapterMissing, klass unless adapter
        adapter
      end
    end

    def typecaster(*classes, &block)
      classes = classes.flatten
      if block
        _typecasters[classes.first.to_s.camelize] = block
      else
        _typecasters[classes.detect do |klass|
          _typecasters[klass.to_s.camelize]
        end.to_s.camelize] or raise TypecasterMissing, classes
      end
    end
  end
end
