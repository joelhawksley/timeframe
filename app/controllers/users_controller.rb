# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!

  def update
    current_user.update(user_params)

    redirect_to(root_path, flash: {notice: "Updated"})
  end

  private

  def user_params
    params.require(:user).permit(:latitude, :longitude)
  end
end
