# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :auto_sign_in_default_user!
  skip_before_action :authenticate_user!, raise: false
end
