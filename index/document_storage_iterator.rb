# frozen_string_literal: true

module Index
  class DocumentStorageIterator
    def initialize(document_storage)
      @document_storage = document_storage
      @total_documents = document_storage.total_documents
      @offset = 0
    end

    def next
      return if @offset >= @total_documents

      document_id, document_offset = document_storage.get_document_by_index(offset)
      @offset += 1

      [document_id, document_offset]
    end

    private

    attr_reader :document_storage, :offset, :total_documents
  end
end
