  class HomeController < ApplicationController
  def index
  end

  def display
    authenticate_user!

  end
end
