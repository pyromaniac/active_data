module ActiveData
  class Config
    include Singleton

    attr_accessor :include_root_in_json, :i18n_scope, :_normalizers

    def initialize
      @include_root_in_json = false
      @i18n_scope = :active_data
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
