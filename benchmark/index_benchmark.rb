# frozen_string_literal: true

require 'sqlite3'
require_relative '../index/tokenizer'
require_relative '../index/indexer'

module Benchmark
  class IndexBenchmark
    def initialize(db_path:)
      @db_path = db_path
      @count = 0
      @thread = measure_speed
    end

    def call
      @db_connection = SQLite3::Database.new(@db_path)

      indexer = init_indexer

      loop do
        articles.each do |article|
          @count += 1

          title, content = article
          indexer.add_document({ text: content, title: })
        end
      end

      @thread.exit
      FileUtils.rm_rf('tmp')
    end

    private

    attr_reader :db_path, :db_connection, :count, :thread

    def articles
      sql = <<-SQL
        SELECT * FROM wiki_articles LIMIT 500 OFFSET ?
      SQL

      @db_connection.execute sql, @count
    end

    def init_indexer
      FileUtils.rm_rf('tmp/benchmark')
      FileUtils.mkdir_p('tmp/benchmark')
      tokenizer = Index::Tokenizer.new

      Index::Indexer.new(tokenizer:, data_path: 'tmp/benchmark', buffer_size: 256)
    end

    def measure_speed
      Thread.new do
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        start_count = @count

        loop do
          sleep 5
          now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          speed = (count - start_count) / (now - time) / 5
          puts "Speed: #{speed} docs/sec"

          start_count = @count
          time = now
        end
      end
    end
  end
end

Benchmark::IndexBenchmark.new(db_path: 'benchmark/wiki.db').call
