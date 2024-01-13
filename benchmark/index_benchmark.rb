# frozen_string_literal: true

require 'sqlite3'
require 'get_process_mem'
require_relative '../index/tokenizer'
require_relative '../index/indexer'

module Benchmark
  class IndexBenchmark
    def initialize(db_path:, max_documents: nil)
      @db_path = db_path
      @max_documents = max_documents
      @thread = Thread.new { measure_speed }

      @indexed_payload = 0
      @indexed_documents = 0

      @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @max_memory_usage = 0
    end

    def call
      @db_connection = SQLite3::Database.new(@db_path)

      indexer = init_indexer

      catch :halt do
        loop do
          articles = fetch_articles
          break if articles.empty?

          articles.each do |article|
            title, content = article
            indexer.add_document({ text: content, title: })

            @indexed_payload += content.bytesize
            @indexed_documents += 1

            throw :halt if @max_documents && @indexed_documents >= @max_documents
          end
        end
      end

      indexer.shutdown
      @end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      report_stats

      @thread.exit
      FileUtils.rm_rf('tmp')
    end

    private

    attr_reader :db_path, :max_documents, :db_connection, :indexed_payload, :thread, :start_time, :end_time

    def fetch_articles
      sql = <<-SQL
        SELECT * FROM wiki_articles LIMIT 500 OFFSET ?
      SQL

      @db_connection.execute sql, @indexed_documents
    end

    def init_indexer
      FileUtils.rm_rf('tmp/benchmark')
      FileUtils.mkdir_p('tmp/benchmark')
      tokenizer = Index::Tokenizer.new

      Index::Indexer.new(tokenizer:, data_path: 'tmp/benchmark', buffer_size: 1)
    end

    def report_stats
      payload_in_mb = @indexed_payload / 1024 / 1024
      total_time = @end_time - @start_time

      puts <<~TEXT
        ----- FINISH INDEXING -----
        - Total documents: #{@indexed_documents}
        - Total payload: #{payload_in_mb} MB
        - Total time: #{total_time} seconds
        - Average speed: #{payload_in_mb / total_time} MB/sec
        - Peak memory usage: #{@max_memory_usage} MB
        - Index disk size: #{index_disk_size} MB
      TEXT
    end

    def index_disk_size
      size = Dir['tmp/benchmark/**/*'].select { |f| File.file?(f) }.sum { |f| File.size(f) }

      size / 1024 / 1024
    end

    def measure_speed
      time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      indexed_payload_start = @indexed_payload

      loop do
        sleep 5
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        diff = (@indexed_payload - indexed_payload_start) / (now - time)

        mem = GetProcessMem.new
        puts <<~TEXT
          Speed: #{diff / 1024} KB/sec
          Memory: #{mem.mb.round(2)} MB
        TEXT

        @max_memory_usage = mem.mb if mem.mb > @max_memory_usage

        indexed_payload_start = @indexed_payload
        time = now
      end
    end
  end
end

Benchmark::IndexBenchmark.new(db_path: 'benchmark/wiki.db').call
