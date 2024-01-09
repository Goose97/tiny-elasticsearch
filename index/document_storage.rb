# frozen_string_literal: true

require 'json'

module Index
  class DocumentStorage
    def initialize(data_path:, document_id_offset:)
      @path = "#{data_path}/documents"
      @index_path = "#{data_path}/documents_index"
      @document_id_offset = document_id_offset
      @offset = 0

      open_file_handler
      open_index_file_handler
    end

    # Persist document and return its offset in the file
    def add_document(document, document_id)
      payload = JSON.generate(document)

      # Prefix with the payload length - 8 bytes
      @file_handler << [payload.length].pack('Q>')
      @file_handler << payload
      @file_handler.flush

      # Store the offset of the document in the index file
      @index_file_handler.seek(segment_document_id(document_id) * 8)
      @index_file_handler << [@offset].pack('Q>')

      @offset += payload.length + 8
    end

    def get_document(document_id)
      @index_file_handler.seek(segment_document_id(document_id) * 8)
      offset = @index_file_handler.read(8).unpack1('Q>')

      @file_handler.seek(offset)
      payload_length = @file_handler.read(8).unpack1('Q>')
      payload = @file_handler.read(payload_length)

      JSON.parse(payload)
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

      fd = IO.sysopen(@index_path, 'r+b')
      io = IO.new(fd)

      @index_file_handler = io
    end

    def segment_document_id(document_id)
      document_id - @document_id_offset
    end
  end
end
