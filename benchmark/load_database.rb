# frozen_string_literal: true

require 'sqlite3'
require_relative '../wiki_parser/wiki_parser'

module Benchmark
  class LoadDatabase
    def initialize(data_path:)
      @data_path = data_path
    end

    def call
      @db_connection = SQLite3::Database.open(data_path)

      create_schema
      parse_wiki
    end

    private

    attr_reader :data_path, :db_connection

    def create_schema
      @db_connection.execute <<~SQL
        CREATE TABLE IF NOT EXISTS wiki_articles(
          title VARCHAR(255),
          content TEXT
        );
      SQL

      @db_connection.execute <<~SQL
        DELETE FROM wiki_articles;
      SQL
    end

    def parse_wiki
      count = 0
      parser = WikiParser.new(path: 'wikipedia.xml')

      loop do
        page = parser.get_next_page
        break unless page

        count += 1

        insert_article(page.title, page.article)
        puts "Processed #{count} documents" if (count % 100).zero?
      end
    end

    def insert_article(title, content)
      sql = <<~SQL
        INSERT INTO wiki_articles (title, content)
        VALUES (?, ?)
      SQL

      @db_connection.execute sql, title, content
    end
  end
end

Benchmark::LoadDatabase.new(data_path: 'benchmark/wiki.db').call
