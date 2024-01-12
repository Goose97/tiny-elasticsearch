# frozen_string_literal: true

require 'fileutils'
require_relative './segment_counter'
require_relative '../merge/background_worker'

$document_id = -1

module Index
  class Indexer
    DATA_PATH = '.data'
    DICTIONARY_PATH = "#{DATA_PATH}/term_dictionary".freeze

    def initialize(tokenizer:)
      @tokenizer = tokenizer
      @merge_worker = Thread.new do
        Merge::BackgroundWorker.new(data_path: DATA_PATH).call
      end
    end

    def add_document(document)
      $document_id += 1
      segment_id = Index::SegmentCounter.instance.next_segment

      tokens = @tokenizer.tokenize(document[:text])
      tokens.uniq!

      term_dictionary, document_storage = init_dependencies(segment_id)
      term_dictionary.add_terms(tokens, $document_id)
      term_dictionary.persist
      document_storage.add_document(document, $document_id)
    end

    def shutdown
      @merge_worker.exit
    end

    private

    attr_reader :tokenizer, :thread

    def init_dependencies(segment_id)
      data_path = data_path(segment_id)
      posting_list_storage = Index::PostingListStorage.new(data_path:)
      term_dictionary = Index::TermDictionary.new(data_path:, posting_list_storage:)
      document_storage = Index::DocumentStorage.new(data_path:)

      [term_dictionary, document_storage]
    end

    def data_path(segment_id)
      "#{DATA_PATH}/segment_#{segment_id}"
    end
  end
end
