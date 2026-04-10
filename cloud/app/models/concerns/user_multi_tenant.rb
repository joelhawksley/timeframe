# frozen_string_literal: true

# Extends core User with Devise authentication for multi-tenant mode
module UserMultiTenant
  extend ActiveSupport::Concern

  included do
    devise :magic_link_authenticatable, :rememberable

    encrypts :magic_link_nonce
    encrypts :remember_token

    has_many :audit_logs, dependent: :destroy
  end
end

User.include(UserMultiTenant)
