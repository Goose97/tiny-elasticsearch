# frozen_string_literal: true

require 'fileutils'

$document_id = -1
$segment_id = -1

module Index
  class Indexer
    DATA_PATH = '.data'
    DICTIONARY_PATH = "#{DATA_PATH}/term_dictionary".freeze

    def initialize(tokenizer:)
      @tokenizer = tokenizer
    end

    def add_document(document)
      $document_id += 1
      $segment_id += 1

      tokens = @tokenizer.tokenize(document[:text])
      tokens.uniq!

      term_dictionary, document_storage = init_dependencies
      term_dictionary.add_terms(tokens, $document_id)
      term_dictionary.persist
      document_storage.add_document(document, $document_id)
    end

    private

    attr_reader :tokenizer, :thread

    def init_dependencies
      posting_list_storage = Index::PostingListStorage.new(data_path:)
      term_dictionary = Index::TermDictionary.new(data_path:, posting_list_storage:)
      document_storage = Index::DocumentStorage.new(data_path:, document_id_offset: $document_id)

      [term_dictionary, document_storage]
    end

    def data_path
      "#{DATA_PATH}/segment_#{$segment_id}"
    end
  end
end
