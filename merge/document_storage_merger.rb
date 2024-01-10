# frozen_string_literal: true

require_relative '../index/document_storage'
require_relative '../index/document_storage_iterator'

module Merge
  class SegmentMerger
    class DocumentStorageMerger
      def initialize(data_path:, segment_a:, segment_b:, new_segment:)
        @segment_a = segment_a
        @segment_b = segment_b
        @new_segment = new_segment
        @data_path = data_path
      end

      def call
        merge_documents_files
        merge_documents_index_files
      end

      private

      attr_reader :segment_a, :segment_b, :new_segment, :data_path

      # For the document files, we only need to concatenate them
      def merge_documents_files
        io = init_merged_documents_file

        IO.copy_stream(documents_file_path(@segment_a), io)
        IO.copy_stream(documents_file_path(@segment_b), io)

        io.flush
        io.close
      end

      def merge_documents_index_files
        iterator_a = Index::DocumentStorage.new(data_path: "#{data_path}/segment_#{segment_a}").into_iterator
        iterator_b = Index::DocumentStorage.new(data_path: "#{data_path}/segment_#{segment_b}").into_iterator

        segment_a_documents_size = File.size(documents_file_path(segment_a))

        merged_index = init_merged_documents_index_file

        # Walk through the two iterators and merge them, maintaining the sorted order
        # Also we need to bump the offset of the segment_b by the size of segment_a
        current_a = iterator_a.next
        current_b = iterator_b.next

        while current_a || current_b
          action = if current_a.nil?
                     :write_b
                   elsif current_b.nil?
                     :write_a
                   elsif current_a[0] < current_b[0]
                     :write_a
                   else
                     :write_b
                   end

          if action == :write_a
            merged_index << current_a.pack('Q>Q>')
            current_a = iterator_a.next
          elsif action == :write_b
            current_b[1] += segment_a_documents_size
            merged_index << current_b.pack('Q>Q>')
            current_b = iterator_b.next
          end
        end

        merged_index.flush
        merged_index.close
      end

      def init_merged_documents_file
        merged_path = documents_file_path(new_segment)
        FileUtils.mkdir_p(File.dirname(merged_path))
        File.new(merged_path, 'w') unless File.exist?(merged_path)
        io = IO.sysopen(merged_path, 'ab')

        IO.new(io)
      end

      def init_merged_documents_index_file
        merged_index_path = documents_file_index_path(new_segment)
        FileUtils.mkdir_p(File.dirname(merged_index_path))
        File.new(merged_index_path, 'w') unless File.exist?(merged_index_path)
        io = IO.sysopen(merged_index_path, 'ab')

        IO.new(io)
      end

      def documents_file_path(segment)
        Index::DocumentStorage.documents_file(data_path: "#{data_path}/segment_#{segment}")
      end

      def documents_file_index_path(segment)
        Index::DocumentStorage.documents_index_file(data_path: "#{data_path}/segment_#{segment}")
      end
    end
  end
end
