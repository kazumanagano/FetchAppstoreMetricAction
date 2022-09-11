require "base64"
require "jwt"
require "open-uri"

module Fastlane
  module Actions
    class FetchAppstoreMetricAction < Action
      def self.run(params)
        private_key = OpenSSL::PKey.read(File.read(params[:private_key_path]))
        token = JWT.encode(
          {
            iss: params[:store_issuer_id],
            exp: Time.now.to_i + 20 * 60,
            aud: "appstoreconnect-v1"
          },
          private_key,
          "ES256",
          header_fields={ kid: params[:store_key_id] }
        )
        auth_headers = { "Authorization" => "Bearer #{token}" }

        preReleaseVersions_url = "https://api.appstoreconnect.apple.com/v1/preReleaseVersions?limit=10"
        preReleaseVersions_response = JSON.parse(URI.open(preReleaseVersions_url, auth_headers).read)

        # preReleaseVersions.id → builds.id → perfPowerMetricsと変換する
        perfPowerMetrics = preReleaseVersions_response["data"].lazy.map { |n|
          release_version_id = n["id"]
          builds_url = "https://api.appstoreconnect.apple.com/v1/builds?filter[preReleaseVersion]=#{release_version_id}&limit=1"
          builds_response = JSON.parse(URI.open(builds_url, auth_headers).read)

          perfPowerMetrics_url = builds_response["data"].first["relationships"]["perfPowerMetrics"]["links"]["related"]
          JSON.parse(URI.open(perfPowerMetrics_url, auth_headers).read)["productData"] rescue []
        }
        .reject(&:empty?)
        .map(&:first)
        .take(1)

        return perfPowerMetrics.first["metricCategories"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :store_issuer_id,
                                       env_name: "APP_STORE_CONNECT_API_KEY_ISSUER_ID",
                                       description: "API Key for APPSTORE_ISSUER_ID",
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :store_key_id,
                                       env_name: "APP_STORE_CONNECT_API_KEY_KEY_ID",
                                       description: "API Key for APPSTORE_KEY_ID",
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :private_key_path,
                                       env_name: "APP_STORE_CONNECT_API_KEY_KEY_FILEPATH",
                                       description: "Point relating to a APPSTORE_PRIVATE_KEY_PATH",
                                       is_string: true)
        ]
      end

      def self.output
        # Metric json
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
