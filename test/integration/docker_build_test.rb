# frozen_string_literal: true

require "test_helper"

class DockerBuildTest < ActiveSupport::TestCase
  test "Dockerfile builds successfully" do
    result = system("docker build -q -t timeframe-build-test #{Rails.root}", out: File::NULL, err: File::NULL)

    assert result, "Docker build failed. Run 'docker build .' from the project root to see the error."
  end
end
