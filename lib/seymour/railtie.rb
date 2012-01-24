require "seymour"
require "seymour/config"
require "rails"
require "rails/seymour"

module Rails #:nodoc:
  module Mongoid #:nodoc:
    class Railtie < Rails::Railtie #:nodoc:

      # Exposes Seymour's configuration to the Rails application configuration.
      #
      # @example Set up configuration in the Rails app.
      #   module MyApplication
      #     class Application < Rails::Application
      #       config.seymour.activity_directory = 'app/activities'
      #     end
      #   end
      config.seymour = ::Seymour::Config

      # Due to all models not getting loaded and messing up inheritance queries
      # and indexing, we need to preload the models in order to address this.
      #
      # This will happen every request in development, once in ther other
      # environments.
      initializer "preload all activity models" do |app|
        config.to_prepare do
          puts "********************* Loading all Seymour activities"
          load_activities
        end
      end

      def load_activities
        puts "***** load_activities"
        if path = ::Seymour::Config.activity_directory
          Dir.glob("#{path}/**/*.rb").sort.each do |file|
            load_model(file.gsub(".rb", ""))
          end
        end
      end

      def load_model(file)
        puts "***** Loading file #{file}"
        require_dependency(file)
      end
    end
  end
end