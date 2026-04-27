# frozen_string_literal: true

require_dependency TimeframeCore::Engine.root.join("app", "controllers", "devices_controller")

class DevicesController
  skip_before_action :auto_sign_in_default_user!, raise: false, only: [:confirmation_image]
end
