# frozen_string_literal: true

require_relative '../index/posting_list_storage'
require_relative '../index/term_dictionary'

module Merge
  class SegmentMerger
    class TermDictionaryMerger
      def initialize(data_path:, segment_a:, segment_b:, new_segment:)
        @segment_a = segment_a
        @segment_b = segment_b
        @new_segment = new_segment
        @data_path = data_path
      end

      def call
        merge_term_dictionaries
      end

      private

      attr_reader :segment_a, :segment_b, :new_segment, :data_path

      # Group by terms and merge their posting list
      # Since term dictionary is sorted by terms, we can walk two sorted lists by using two pointers
      def merge_term_dictionaries
        merged_posting_list = Index::PostingListStorage.new(data_path: "#{@data_path}/segment_#{@new_segment}")

        merged_term_dictionary = init_merged_term_dictionary_file

        # Walk two sorted lists of terms
        iterator_a = term_dictionary_iterator(segment_a)
        iterator_b = term_dictionary_iterator(segment_b)

        current_a = iterator_a.next
        current_b = iterator_b.next

        while current_a || current_b
          action = if current_a.nil?
                     :write_b
                   elsif current_b.nil?
                     :write_a
                   elsif current_a[0] > current_b[0]
                     :write_b
                   elsif current_a[0] < current_b[0]
                     :write_a
                   else
                     :merge
                   end

          case action
          when :write_a
            term, posting_list = current_a
            write_term_posting_list(merged_term_dictionary, term, posting_list, merged_posting_list)

            current_a = iterator_a.next
          when :write_b
            term, posting_list = current_b
            write_term_posting_list(merged_term_dictionary, term, posting_list, merged_posting_list)

            current_b = iterator_b.next
          when :merge
            term, posting_list_a = current_a
            _, posting_list_b = current_b
            posting_list = (posting_list_a + posting_list_b).sort
            write_term_posting_list(merged_term_dictionary, term, posting_list, merged_posting_list)

            current_a = iterator_a.next
            current_b = iterator_b.next
          end
        end

        merged_term_dictionary.flush
        merged_term_dictionary.close
      end

      def write_term_posting_list(fd, term, posting_list, posting_list_storage)
        # TODO: encapsulate this logic inside term dictionary
        offset = posting_list_storage.add_posting_list(posting_list)
        fd << [term.bytesize].pack('C')
        fd << term
        fd << [offset].pack('Q>')
      end

      def init_merged_term_dictionary_file
        merged_path = terms_dictionary_file_path(@new_segment)
        FileUtils.mkdir_p(File.dirname(merged_path))
        File.new(merged_path, 'w') unless File.exist?(merged_path)
        io = IO.sysopen(merged_path, 'ab')

        IO.new(io)
      end

      def terms_dictionary_file_path(segment)
        Index::TermDictionary.term_dictionary_file(data_path: "#{data_path}/segment_#{segment}")
      end

      def term_dictionary_iterator(segment)
        posting_list_storage = Index::PostingListStorage.new(data_path: "#{@data_path}/segment_#{segment}")
        term_dictionary = Index::TermDictionary.new(data_path: "#{@data_path}/segment_#{segment}",
                                                    posting_list_storage:)

        term_dictionary.into_iterator
      end
    end
  end
end
