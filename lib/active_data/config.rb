module ActiveData
  class Config
    include ::Singleton

    attr_accessor :include_root_in_json, :i18n_scope

    def initialize
      @include_root_in_json = false
      @i18n_scope = :active_data
    end
  end
end
