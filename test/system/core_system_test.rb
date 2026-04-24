# frozen_string_literal: true

require_relative "../system_test_helper"

Dir[File.expand_path("../../../core/test/system/**/*_test.rb", __dir__)].each { |f| require f }
