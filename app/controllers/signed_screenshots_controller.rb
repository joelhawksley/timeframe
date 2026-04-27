# frozen_string_literal: true

require_dependency TimeframeCore::Engine.root.join("app", "controllers", "signed_screenshots_controller")

class SignedScreenshotsController
  skip_before_action :auto_sign_in_default_user!
end
