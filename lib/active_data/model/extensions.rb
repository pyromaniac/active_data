unless defined?(Boolean)
  class Boolean; end
end

unless defined?(Localized)
  class Localized; end
end

Dir["#{File.dirname(__FILE__)}/extensions/*.rb"].each { |f| require f }
