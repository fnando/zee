# frozen_string_literal: true

require "sqlite3"

module Zee
  module CacheStore
    class SQLite3 < Base
      # @api private
      INSERT_QUERY = <<~SQL
        insert or replace into cache_store (key, content, expires_at)
        values (:key, :content, :expires_at)
        returning 1
      SQL

      # @api private
      EXISTS_QUERY = <<~SQL
        select 1 from cache_store where key = :key and
        (
          expires_at is null or
          expires_at >= :now
        )
        limit 1
      SQL

      # @api private
      READ_QUERY = <<~SQL
        select content from cache_store where key = :key and
        (
          expires_at is null or
          expires_at >= :now
        )
        limit 1
      SQL

      # @api private
      DELETE_QUERY = "delete from cache_store where key = :key returning 1"

      # @api private
      CLEAR_QUERY = "delete from cache_store"

      # @api private
      INCREMENT_QUERY = <<~SQL
        insert into cache_store (key, content, expires_at)
        values (:key, :amount, :expires_at)
        on conflict(key) do update set
        content = case
                  when expires_at is null or expires_at < current_timestamp
                  then content + :amount
                  else :amount
                  end,
        expires_at = :expires_at
        returning content
      SQL

      # @api private
      DECREMENT_QUERY = <<~SQL
        insert into cache_store (key, content, expires_at)
        values (:key, -:amount, :expires_at)
        on conflict(key) do update set
        content = case
                  when expires_at is null or expires_at < current_timestamp
                  then content - :amount
                  else -:amount
                  end,
        expires_at = :expires_at
        returning content
      SQL

      # @return [String] the connection string for the SQLite3 database.
      attr_reader :url

      def initialize(url:, **)
        super(**)

        uri = URI(url)
        @db = ::SQLite3::Database.new(uri.opaque || uri.path)
        setup_database
      end

      def setup_database
        @db.execute_batch <<~SQL
          create table if not exists cache_store (
            key varchar(255) primary key not null,
            content blob not null,
            expires_at real
          );

          create index if not exists index_cache_store_expires_at on cache_store(expires_at);
        SQL

        result = @db.execute <<~SQL
          select name
          from sqlite_master
          where type='table' and name='cache_store';
        SQL

        return if result.flatten.include?("cache_store")

        # :nocov:
        raise "Couldn't find the `cache_store` table"
        # :nocov:
      end

      # @param key [String, Symbol] The key to write to.
      # @param value [Object] The value to write.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Boolean] Whether the write was successful.
      def write(key, value, expires_in: nil)
        expires_at = (Time.now.utc + expires_in).to_f if expires_in

        result = @db.execute(
          INSERT_QUERY,
          key: normalize_key(key),
          content: dump(value),
          expires_at:
        )

        result.flatten.include?(1)
      rescue StandardError
        false
      end

      # @param key [String, Symbol] The key to check to.
      # @return [Boolean] Whether the write was successful.
      def exist?(key)
        result = @db.execute(
          EXISTS_QUERY,
          key: normalize_key(key),
          now: Time.now.to_f
        )
        result.flatten.include?(1)
      rescue StandardError
        nil
      end

      # @param key [String, Symbol] The key to read from.
      # @return [Boolean] Whether the write was successful.
      def read(key)
        content, _ =
          *@db.execute(
            READ_QUERY,
            key: normalize_key(key),
            now: Time.now.to_f
          ).flatten

        load(content)
      rescue StandardError
        nil
      end

      # @param key [String, Symbol] The key to delete.
      # @return [Boolean] Whether the write was successful.
      def delete(key)
        @db.execute(DELETE_QUERY, key: normalize_key(key)).any?
      rescue StandardError
        false
      end

      # @param key [String, Symbol] The key to read/write from/to.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Object] The resolved value.
      def fetch(key, expires_in: nil, &)
        value = read(key)

        unless value
          value = yield(key, self)
          return value unless write(key, value, expires_in:)
        end

        value
      end

      # @param key [String, Symbol] The key to increment.
      # @param amount [Integer] The amount to increment the value by.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Integer] the new value.
      def increment(key, amount = 1, expires_in: nil)
        expires_at = expires_in ? (Time.now.utc + expires_in).to_f : nil

        @db.execute(
          INCREMENT_QUERY,
          key: normalize_key(key),
          amount:,
          expires_at:
        ).flatten.first
      rescue StandardError
        false
      end

      # @param key [String, Symbol] The key to decrement.
      # @param amount [Integer] The amount to decrement the value by.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Integer] the new value.
      def decrement(key, amount = 1, expires_in: nil)
        expires_at = expires_in ? (Time.now.utc + expires_in).to_f : nil

        @db.execute(
          DECREMENT_QUERY,
          key: normalize_key(key),
          amount:,
          expires_at:
        ).flatten.first
      rescue StandardError
        false
      end

      # @param data [Hash{String => Object}] The data to write.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Boolean] Whether the write was successful.
      def write_multi(data, expires_in: nil)
        data.map {|key, value| write(key, value, expires_in:) }.all?
      end

      # @param keys [Array<String, Symbol>] The keys to read from.
      # @return [Hash{String => Object}] The resolved values.
      def read_multi(*keys)
        placeholders = Array.new(keys.size, "?").join(",")
        query = <<~SQL
          select key, content
          from cache_store
          where key in(#{placeholders})
            and (expires_at is null or expires_at >= current_timestamp)
        SQL
        result = @db.execute(query, keys.map(&:to_s))
        hash = result.empty? ? keys.zip(result).to_h : result.to_h
        hash.transform_values { load(_1) }
      rescue StandardError
        keys.zip(Array.new(keys.size)).to_h
      end

      # @param keys [Array<String, Symbol>] The keys to delete.
      # @return [Integer] The number of keys deleted.
      def delete_multi(*keys)
        placeholders = Array.new(keys.size, "?").join(",")
        query = "delete from cache_store where key in(#{placeholders})"
        @db.execute(query, keys)
        @db.changes
      rescue StandardError
        0
      end

      # @param keys [Array<String, Symbol>] The keys to read/write from/to.
      # @param expires_in [Integer] The number of seconds to expire the key in.
      # @return [Hash{String => Object}] The resolved values.
      # @yieldparam key [Array<String, Hash>] The key that was not found, plus
      #                                       the options.
      def fetch_multi(*keys, expires_in: nil, &)
        expires_at = (Time.now.utc + expires_in).to_f if expires_in
        placeholders = Array.new(keys.size, "?").join(",")
        query = <<~SQL
          select key, content
          from cache_store
          where key in(#{placeholders})
            and (expires_at is null or expires_at >= current_timestamp)
        SQL

        normalized_keys = keys.map { normalize_key(_1) }
        result = @db.execute(query, normalized_keys).to_h

        result = keys.each_with_object({}) do |key, buffer|
          key = key.to_s
          value = result[normalize_key(key)]
          value = load(value) if value
          value = yield(key, self) if value.nil?

          buffer[key] = value
        end

        result.each do |key, value|
          @db.execute(
            INSERT_QUERY,
            key: normalize_key(key),
            content: dump(value),
            expires_at:
          )
        end

        result
      rescue StandardError
        (result || keys.zip(Array.new(keys)).to_h)
          .transform_values {|key| yield(key, self) }
      end

      # Clears the storage.
      # @return [Boolean] Whether the clear was successful.
      def clear(**)
        @db.execute(CLEAR_QUERY)
        true
      rescue StandardError
        false
      end
    end
  end
end
