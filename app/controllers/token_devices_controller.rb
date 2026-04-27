# frozen_string_literal: true

require_dependency TimeframeCore::Engine.root.join("app", "controllers", "token_devices_controller")

class TokenDevicesController
  skip_before_action :auto_sign_in_default_user!, raise: false
end
