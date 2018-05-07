module ActiveData
  class Config
    include Singleton

    attr_accessor :include_root_in_json, :i18n_scope, :logger, :primary_attribute, :base_class, :base_concern,
      :_normalizers, :_typecasters

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
    end

    def normalizer(name, &block)
      if block
        _normalizers[name.to_sym] = block
      else
        _normalizers[name.to_sym] or raise NormalizerMissing, name
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
