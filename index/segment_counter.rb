# frozen_string_literal: true

module Index
  class SegmentCounter
    private_class_method :new

    @mutex = Mutex.new

    def initialize
      @segment_counter = -1
    end

    class << self
      attr_reader :mutex
    end

    def self.instance
      return @instance if @instance

      @mutex.synchronize do
        @instance ||= new
      end

      @instance
    end

    def next_segment
      Index::SegmentCounter.mutex.synchronize do
        @segment_counter += 1

        @segment_counter
      end
    end

    def active_segment
      return if @segment_counter == -1

      @segment_counter
    end

    private

    attr_reader :segment_counter
  end
end
