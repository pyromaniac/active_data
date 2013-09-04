module ActiveData
  class Config
    include Singleton

    attr_accessor :include_root_in_json

    def initialize
      @include_root_in_json = false
    end
  end
end
