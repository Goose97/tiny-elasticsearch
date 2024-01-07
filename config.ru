# frozen_string_literal: true
#
require 'pp'

run do |env|
  path = env["PATH_INFO"]
  query_string = env["QUERY_STRING"]
  [200, {}, ["Hello World"]]
end
