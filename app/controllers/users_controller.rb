# frozen_string_literal: true

class UsersController < ApplicationController
  def destroy
    if params[:email_confirmation].to_s.downcase.strip == current_user.email.downcase.strip
      sole_accounts = current_user.accounts.select { |a| a.users.count == 1 }
      if sole_accounts.any?
        names = sole_accounts.map(&:name).join(", ")
        redirect_to root_path, alert: "You are the only user on: #{names}. Delete the account(s) first."
      else
        current_user.destroy
        sign_out(current_user)
        redirect_to root_path, notice: "Your account has been deleted."
      end
    else
      redirect_to root_path, alert: "Email did not match."
    end
  end
end
