# frozen_string_literal: true

class HomeController < ApplicationController
  def logs
    render "logs", layout: false
  end
end
