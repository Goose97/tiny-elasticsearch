# frozen_string_literal: true

require_relative './term_dictionary'

module Index
  class TermDictionary
    class Iterator
      def initialize(term_dictionary)
        @term_dictionary = term_dictionary
        @fd = init_file_handler
      end

      def next
        byte = @fd.read(1)
        unless byte
          @fd.close
          return
        end

        term_length = byte.unpack1('C')
        term = @fd.read(term_length)
        posting_list_offset = @fd.read(8).unpack1('Q>')

        posting_list = @term_dictionary.posting_list_storage.get_posting_list(posting_list_offset)
        [term, posting_list]
      end

      private

      attr_reader :term_dictionary, :fd

      def init_file_handler
        fd = IO.sysopen(@term_dictionary.path, 'rb')

        IO.new(fd)
      end
    end
  end
end
