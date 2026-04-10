# frozen_string_literal: true

class AccountsController < ApplicationController
  def create
    account = Account.new(name: params[:account][:name])

    if account.save
      current_user.accounts << account
      redirect_to root_path, notice: "Account \"#{account.name}\" created."
    else
      redirect_to root_path, alert: account.errors.full_messages.join(", ")
    end
  end

  def destroy
    account = current_user.accounts.find(params[:id])

    if params[:name_confirmation].to_s.downcase.strip == account.name.downcase.strip
      if account.locations.any?
        redirect_to root_path, alert: "Delete all locations before deleting this account."
      else
        account.destroy
        redirect_to root_path, notice: "Account \"#{account.name}\" deleted."
      end
    else
      redirect_to root_path, alert: "Account name did not match."
    end
  end
end
