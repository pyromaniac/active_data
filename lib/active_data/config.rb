module ActiveData
  class Config
    include Singleton

    attr_accessor :include_root_in_json, :i18n_scope, :primary_attribute, :_normalizers

    def self.delegated
      public_instance_methods - self.superclass.public_instance_methods - Singleton.public_instance_methods
    end

    def initialize
      @include_root_in_json = false
      @i18n_scope = :active_data
      @primary_attribute = :id
      @_normalizers = {}
    end

    def normalizer name, &block
      if block
        _normalizers[name.to_sym] = block
      else
        _normalizers[name.to_sym] or raise NormalizerMissing.new(name)
      end
    end
  end
end
