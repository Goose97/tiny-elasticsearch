# frozen_string_literal: true

require_relative './document_storage_merger'
require_relative './term_dictionary_merger'
require_relative '../index/document_storage'

module Merge
  # Merge two segments into one
  # We need to merge:
  # - document_storage
  # - term_dictionary and posting_list_storage
  class SegmentMerger
    def initialize(data_path:, segment_a:, segment_b:, new_segment:)
      @segment_a = segment_a
      @segment_b = segment_b
      @new_segment = new_segment
      @data_path = data_path
    end

    def call
      DocumentStorageMerger.new(data_path: @data_path,
                                segment_a: @segment_a,
                                segment_b: @segment_b,
                                new_segment: @new_segment).call
      TermDictionaryMerger.new(data_path: @data_path,
                               segment_a: @segment_a,
                               segment_b: @segment_b,
                               new_segment: @new_segment).call
    end
  end
end
