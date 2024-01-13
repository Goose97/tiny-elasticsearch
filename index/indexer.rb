# frozen_string_literal: true

require 'fileutils'
require_relative './segment_counter'
require_relative '../merge/background_worker'
require_relative './posting_list_storage'
require_relative './document_storage'
require_relative './term_dictionary'

$document_id = -1

module Index
  class Indexer
    def initialize(tokenizer:, data_path:, buffer_size:)
      @tokenizer = tokenizer
      @root_data_path = data_path
      @buffer = []
      @buffer_size = buffer_size
      @merge_worker = Thread.new do
        Merge::BackgroundWorker.new(data_path:).call
      end
    end

    def add_document(document)
      @buffer << document

      flush_buffer if @buffer.size >= @buffer_size
    end

    def shutdown
      @merge_worker.exit
    end

    private

    attr_reader :tokenizer, :root_data_path, :thread, :buffer, :buffer_size

    def init_dependencies(segment_id)
      data_path = data_path(segment_id)
      posting_list_storage = Index::PostingListStorage.new(data_path:)
      term_dictionary = Index::TermDictionary.new(data_path:, posting_list_storage:)
      document_storage = Index::DocumentStorage.new(data_path:)

      [term_dictionary, document_storage]
    end

    def data_path(segment_id)
      "#{@root_data_path}/segment_#{segment_id}"
    end

    def flush_buffer
      segment_id = Index::SegmentCounter.instance.next_segment

      documents = assign_document_id(@buffer)
      group_by_token = group_tokens(documents)

      term_dictionary, document_storage = init_dependencies(segment_id)

      term_dictionary.add_raw_entries(group_by_token.to_a)

      documents.each do |document, document_id|
        document_storage.add_document(document, document_id)
      end

      term_dictionary.persist

      @buffer = []
    end

    def group_tokens(documents)
      token_hash = {}

      documents.each do |document, document_id|
        @tokenizer.tokenize(document[:text]) do |token|
          token_hash[token] ||= []
          token_hash[token] << document_id
        end
      end

      token_hash
    end

    def assign_document_id(documents)
      documents.map do |document|
        $document_id += 1

        [document, $document_id]
      end
    end
  end
end
