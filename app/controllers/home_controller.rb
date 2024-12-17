# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    render :index, layout: false
  end
end
