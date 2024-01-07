# frozen_string_literal: true

require 'fileutils'

$document_id = -1

module Index
  class Indexer
    DATA_PATH = '.data'
    DICTIONARY_PATH = "#{DATA_PATH}/term_dictionary".freeze

    def initialize(tokenizer:, term_dictionary:, document_storage:)
      @tokenizer = tokenizer
      @term_dictionary = term_dictionary
      @document_storage = document_storage
      @thread = dictionary_background_writer
    end

    def add_document(document)
      $document_id += 1

      tokens = @tokenizer.tokenize(document[:text])

      @term_dictionary.add_terms(tokens, $document_id)
      @document_storage.add_document(document, $document_id)
    end

    def shutdown
      @thread.kill
    end

    private

    attr_reader :tokenizer, :term_dictionary, :thread

    def dictionary_background_writer
      Thread.new do
        loop do
          @term_dictionary.persist
          sleep 3
        end
      end
    end
  end
end
