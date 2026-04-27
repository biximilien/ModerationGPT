require_relative "../plugin"
require_relative "../../environment"

module ModerationGPT
  module Plugins
    class PostgresPlugin < Plugin
      def boot(**)
        database_connection
      end

      def database_connection
        @database_connection ||= begin
          database_url = Environment.database_url
          raise "DATABASE_URL is required when postgres plugin is enabled" if database_url.nil? || database_url.strip.empty?

          require "pg"
          PG.connect(database_url)
        end
      end

      alias connection database_connection
    end
  end
end
