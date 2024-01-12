# frozen_string_literal: true

require 'pathname'
require_relative '../index/segment_counter'

module Merge
  class BackgroundWorker
    SEGMENT_MERGE_THRESHOLD = 2

    def initialize(data_path:)
      @data_path = data_path
    end

    def call
      loop do
        next unless mergeable_segments.size >= SEGMENT_MERGE_THRESHOLD

        # Merge two oldest segments
        SegmentMerger.new(data_path: @data_path,
                          segment_a: mergeable_segments[0],
                          segment_b: mergeable_segments[1],
                          new_segment: Index::SegmentCounter.instance.next_segment).call
      end
    end

    private

    attr_reader :data_path

    # Sorted from oldest to newest
    def mergeable_segments
      active_segment_id = Index::SegmentCounter.instance.active_segment

      return [] unless active_segment_id

      all_segments.sort.filter { _1 < active_segment_id }
    end

    def all_segments
      Pathname(@data_path).children.filter(&:directory?).map do |path|
        path.basename.to_s.split('_')[1].to_i
      end
    end
  end
end
