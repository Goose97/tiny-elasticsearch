# frozen_string_literal: true

require_relative '../index/term_dictionary'
require_relative '../index/posting_list_storage'
require_relative '../index/document_storage'

module Query
  class Querier
    def initialize(data_path:)
      @data_path = data_path
    end

    def query(term)
      Dir["#{@data_path}/segment_*"].flat_map do |segment_path|
        query_segment(term, segment_path)
      end
    end

    private

    attr_reader :data_path

    def query_segment(term, segment_path)
      posting_list_storage = Index::PostingListStorage.new(data_path: segment_path)
      term_dictionary = Index::TermDictionary.new(data_path: segment_path, posting_list_storage:)
      document_storage = Index::DocumentStorage.new(data_path: segment_path)

      posting_list = term_dictionary.get_posting_list(term)

      return [] if posting_list.nil?

      posting_list.map do |document_id|
        document_storage.get_document(document_id)
      end
    end
  end
end
