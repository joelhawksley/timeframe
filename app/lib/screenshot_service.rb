# frozen_string_literal: true

# :nocov:
class ScreenshotService
  VIEWPORT_WIDTH = 480
  VIEWPORT_HEIGHT = 800

  class << self
    def capture(url)
      page = browser.create_page
      page.command("Emulation.setDeviceMetricsOverride",
        width: VIEWPORT_WIDTH,
        height: VIEWPORT_HEIGHT,
        deviceScaleFactor: 1,
        mobile: false)
      page.go_to(url)
      png_base64 = page.screenshot(format: "png")
      page.close

      process_image(Base64.decode64(png_base64))
    end

    def browser
      @browser ||= Ferrum::Browser.new(
        headless: "new",
        browser_path: find_browser_path,
        window_size: [VIEWPORT_WIDTH, VIEWPORT_HEIGHT],
        browser_options: {
          "no-sandbox" => nil,
          "disable-gpu" => nil,
          "disable-dev-shm-usage" => nil,
          "disable-software-rasterizer" => nil,
          "font-render-hinting" => "none",
          "disable-font-subpixel-positioning" => nil
        }
      )
    end

    def reset!
      @browser&.quit
      @browser = nil
    end

    private

    def process_image(png_data)
      image = MiniMagick::Image.read(png_data, ".png")
      image.rotate "90"
      image.combine_options do |c|
        c.colorspace "Gray"
        c.dither "FloydSteinberg"
        c.posterize 4
        c.depth 2
      end
      image.format "png"
      Base64.strict_encode64(image.to_blob)
    end

    def find_browser_path
      [
        "/usr/bin/chromium",
        "/usr/bin/chromium-browser",
        "/usr/bin/google-chrome",
        "/usr/bin/google-chrome-stable",
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
      ].find { |path| File.exist?(path) }
    end
  end
end
# :nocov:
