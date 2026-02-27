APP_VERSION =
  if Rails.env.production?
    # :nocov:
    `git rev-parse HEAD 2>/dev/null`.to_s.strip
    # :nocov:
  else
    Rails.env
  end

DEPLOY_TIME = Time.now.to_i
