# frozen_string_literal: true

require "simplecov"
SimpleCov.start
SimpleCov.minimum_coverage 100

ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "minitest/autorun"
require "minitest/unit"
require "active_support/testing/time_helpers"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
end
