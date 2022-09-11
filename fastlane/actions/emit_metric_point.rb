require 'rubygems'
require 'dogapi'

module Fastlane
  module Actions
    module SharedValues
      DATADOG_API_KEY = :DATADOG_API_KEY
    end

    class EmitMetricPointAction < Action
      def self.run(params)
        dog = Dogapi::Client.new(params[:api_key])
        dog.emit_point(params[:metric], params[:point], :tags => params[:tags])
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_name: "DATADOG_API_KEY",
                                       description: "API Key for EmitMetricPointAction", 
                                       verify_block: 
                                          proc do |value|
                                            UI.user_error!("No API key for EmitMetricPointAction given, pass using `api_key: 'key'`") unless (value and not value.empty?)
                                          end
                                      ),
          FastlaneCore::ConfigItem.new(key: :point,
                                       env_name: "FL_EMIT_METRIC_POINT_POINT",
                                       description: "Point relating to a metric",
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :metric,
                                       env_name: "FL_EMIT_METRIC_POINT_METRIC",
                                       description: "The name of the timeseries",
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :tags,
                                      env_name: "FL_EMIT_METRIC_POINT_TAGS",
                                      description: "A list of tags associated with the metric",
                                      is_string: false)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
