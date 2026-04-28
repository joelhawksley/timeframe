# frozen_string_literal: true

# :nocov:
class ScreenshotService
  VIEWPORT_WIDTH = 480
  VIEWPORT_HEIGHT = 800

  class << self
    def capture(url, width: VIEWPORT_WIDTH, height: VIEWPORT_HEIGHT, grayscale_depth: 2, rotate: true, raw: false, dither: true, grayscale_only: false)
      begin
        png_base64 = capture_screenshot(url, width: width, height: height)
      rescue Ferrum::DeadBrowserError, Ferrum::NoSuchPageError => e
        Rails.logger.warn "[ScreenshotService] Browser dead, resetting and retrying: #{e.message}"
        reset!
        png_base64 = capture_screenshot(url, width: width, height: height)
      end

      return png_base64 if raw

      if grayscale_only
        image = MiniMagick::Image.read(Base64.decode64(png_base64), ".png")
        image.rotate "90"
        image.combine_options do |c|
          c.colorspace "Gray"
          c.dither("None")
          c.colors 16
          c.depth 4
        end
        image.format "png"
        return Base64.strict_encode64(image.to_blob)
      end

      process_image(Base64.decode64(png_base64), grayscale_depth: grayscale_depth, rotate: rotate, dither: dither)
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

    def capture_screenshot(url, width:, height:)
      page = browser.create_page
      page.command("Emulation.setDeviceMetricsOverride",
        width: width,
        height: height,
        deviceScaleFactor: 1,
        mobile: false)
      page.go_to(url)
      png_base64 = page.screenshot(format: "png")
      page.close
      png_base64
    end

    def process_image(png_data, grayscale_depth: 2, rotate: true, dither: true)
      image = MiniMagick::Image.read(png_data, ".png")
      image.rotate "90" if rotate
      image.combine_options do |c|
        c.colorspace "Gray"
        c.dither("None") unless dither
        c.dither("FloydSteinberg") if dither
        c.posterize(2**grayscale_depth)
        c.depth grayscale_depth
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
