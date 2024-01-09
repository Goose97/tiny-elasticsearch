# frozen_string_literal: true

module Index
  class PostingListStorage
    def initialize(data_path:)
      @path = "#{data_path}/posting_list"
      @offset = 0

      open_file_handler
    end

    def get_posting_list(offset)
      @file_handler.seek(offset)
      payload_length = @file_handler.read(8).unpack1('Q>')
      @file_handler.read(payload_length).unpack('Q>*')
    end

    # Add a posting list to the data file and return the offset
    def add_posting_list(list)
      payload = list.pack('Q>*')

      # Prefix with the payload length - 8 bytes
      @file_handler << [payload.length].pack('Q>')
      @file_handler << payload
      @file_handler.flush

      offset = @offset
      @offset += payload.length + 8

      offset
    end

    private

    attr_reader :path, :offset, :file_handler

    def open_file_handler
      FileUtils.mkdir_p(File.dirname(@path))

      File.new(@path, 'w') unless File.exist?(@path)

      fd = IO.sysopen(@path, 'a+b')
      io = IO.new(fd)

      @file_handler = io
    end
  end
end
