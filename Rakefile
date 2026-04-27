# frozen_string_literal: true

require_relative "config/application"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList.new(ENV["TESTS"] || ["test/**/*_test.rb", "engine/test/**/*_test.rb"])
end

Rails.application.load_tasks

task default: :test
