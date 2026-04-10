# frozen_string_literal: true

module Users
  class MagicLinksController < Devise::MagicLinksController
    skip_before_action :auto_sign_in_default_user!, raise: false

    def show
      self.resource = warden.authenticate!(auth_options)

      if resource.magic_link_nonce.blank? ||
          !ActiveSupport::SecurityUtils.secure_compare(
            session[:magic_link_nonce].to_s,
            resource.magic_link_nonce
          )
        sign_out(resource)
        set_flash_message!(:alert, :magic_link_invalid)
        redirect_to new_user_session_path
        return
      end

      resource.update_column(:magic_link_nonce, nil)
      session.delete(:magic_link_nonce)

      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      redirect_to after_sign_in_path_for(resource)
    end
  end
end
