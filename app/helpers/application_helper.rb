# frozen_string_literal: true

module ApplicationHelper
  def flash_class(level)
    case level
    when :success then 'alert alert-success'
    when :error then 'alert alert-error'
    when :alert then 'alert alert-error'
    else 'alert alert-info'
    end
  end
end
