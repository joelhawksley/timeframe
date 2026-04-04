# frozen_string_literal: true

module Users
  class SessionsController < Devise::Passwordless::SessionsController
    before_action :redirect_if_signed_in!, only: [:new, :create]

    def create
      self.resource = resource_class.find_or_create_by!(email: create_params[:email])
      send_magic_link(resource)
      set_flash_message!(:notice, :magic_link_sent)
      redirect_to after_magic_link_sent_path_for(resource)
    end

    protected

    def send_magic_link(resource)
      nonce = SecureRandom.hex(16)
      resource.update_column(:magic_link_nonce, nonce)
      session[:magic_link_nonce] = nonce
      super
    end

    private

    def redirect_if_signed_in!
      redirect_to root_path if warden.authenticated?(:user)
    end

    def create_params
      resource_params.permit(:email, :remember_me)
    end
  end
end
