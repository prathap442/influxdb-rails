require "influxdb/rails/middleware/subscriber"

module InfluxDB
  module Rails
    module Middleware
      # Subscriber acts as base class for different *Subscriber classes,
      # which are intended as ActiveSupport::Notifications.subscribe
      # consumers.
      class SimpleSubscriber < Subscriber
        attr_reader :series_name

        def initialize(configuration, series_name)
          super(configuration)
          @series_name = series_name
        end

        def call(_name, started, finished, _unique_id, payload)
          return unless enabled?

          begin
            InfluxDB::Rails.client.write_point series_name,
                                               values:    values(started, finished, payload),
                                               tags:      tags(payload),
                                               timestamp: timestamp(finished.utc)
          rescue StandardError => e
            log :error, "[InfluxDB::Rails] Unable to write points: #{e.message}"
          end
        end

        private

        def values(started, finished, _payload)
          { value: ((finished - started) * 1000).ceil }
        end

        def timestamp(finished)
          InfluxDB.convert_timestamp(finished.utc, configuration.time_precision)
        end

        def enabled?
          super && series_name.present?
        end
      end
    end
  end
end
