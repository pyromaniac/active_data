module ActiveData
  class Railtie < Rails::Railtie
    initializer "active_data.active_record_patch" do |app|
      ActiveSupport.on_load :active_record do
        include ActiveData::ActiveRecord::Associations
        include ActiveData::ActiveRecord::NestedAttributes
      end
    end
  end
end
