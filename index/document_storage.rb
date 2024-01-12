# frozen_string_literal: true

require 'json'
require_relative './document_storage_iterator'

module Index
  # DocumentStorage is responsible for storing documents
  # It consists of two files:
  # - documents - stores the documents
  # - documents_index - stores the offset of the documents in the documents file. It stores pairs
  # of document_id and offset
  class DocumentStorage
    def self.documents_file(data_path:)
      "#{data_path}/documents"
    end

    def self.documents_index_file(data_path:)
      "#{data_path}/documents_index"
    end

    def initialize(data_path:)
      @path = DocumentStorage.documents_file(data_path:)
      @index_path = DocumentStorage.documents_index_file(data_path:)
      @offset = 0

      open_file_handler
      open_index_file_handler
    end

    # Persist document and return its offset in the file
    def add_document(document, document_id)
      payload = JSON.generate(document)

      # Prefix with the payload length - 8 bytes
      @file_handler << [payload.bytesize].pack('Q>')
      @file_handler << payload
      @file_handler.flush

      # Store the offset of the document in the index file
      @index_file_handler << [document_id, @offset].pack('Q>*')
      @index_file_handler.flush

      @offset += payload.bytesize + 8
    end

    def get_document(document_id)
      _, offset = binary_search(document_id)
      raise 'Document not found' if offset.nil?

      @file_handler.seek(offset)
      payload_length = @file_handler.read(8).unpack1('Q>')
      payload = @file_handler.read(payload_length)

      JSON.parse(payload)
    end

    def total_documents
      File.size(@index_path) / 16
    end

    def into_iterator
      Iterator.new(self)
    end

    def get_document_by_index(index)
      @index_file_handler.seek(index * 16)

      @index_file_handler.read(16).unpack('Q>Q>')
    end

    private

    attr_reader :path, :offset, :file_handler, :index_file_handler

    def open_file_handler
      FileUtils.mkdir_p(File.dirname(@path))

      fd = IO.sysopen(@path, 'a+b')
      io = IO.new(fd)

      @file_handler = io
    end

    def open_index_file_handler
      File.new(@index_path, 'w') unless File.exist?(@index_path)

      fd = IO.sysopen(@index_path, 'a+b')
      io = IO.new(fd)

      @index_file_handler = io
    end

    def binary_search(document_id)
      lo = 0
      hi = total_documents - 1

      while lo <= hi
        mid = lo + (hi - lo) / 2
        mid_value, mid_offset = get_document_by_index(mid)

        if mid_value == document_id
          return mid, mid_offset
        elsif mid_value < document_id
          lo = mid + 1
        else
          hi = mid - 1
        end
      end
    end
  end
end
