class ApiResponseCleanupJob < ActiveJob::Base
  def perform
    ApiResponse.where("created_at < :time", {time: 7.days.ago}).destroy_all
  end
end
