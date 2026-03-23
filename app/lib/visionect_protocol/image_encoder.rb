# frozen_string_literal: true

require "mini_magick"
require_relative "lz4_block"

module VisionectProtocol
  # Encodes a PNG image into the Visionect protocol image packet format.
  #
  # Image format: 4bpp grayscale (16 levels), LZ4-compressed strips.
  # Each strip covers 8 rows of the display at the native width.
  # The display native orientation is 1200×1600 (portrait);
  # the device applies rotation=1 (90° CW) for landscape display.
  #
  # Strip data layout within each strip's 4800 bytes:
  #   Sequential rows: row0[600B] + row1[600B] + ... + row7[600B]
  #   Each row: 600 bytes at 4bpp = 1200 pixels (2 pixels per byte, high nibble first)
  class ImageEncoder
    NATIVE_WIDTH = 1200
    NATIVE_HEIGHT = 1600
    BYTES_PER_ROW = NATIVE_WIDTH / 2 # 600 bytes at 4bpp
    ROWS_PER_STRIP = 8
    STRIP_SIZE = BYTES_PER_ROW * ROWS_PER_STRIP # 4800 bytes
    NUM_STRIPS = NATIVE_HEIGHT / ROWS_PER_STRIP # 200

    class << self
      # Encode a PNG (as binary string) into Visionect protocol image rectangles.
      # Returns an array of LZ4-compressed strip data strings.
      def encode_png(png_data)
        raw_pixels = png_to_4bpp(png_data)
        compress_strips(raw_pixels)
      end

      # Encode raw 4bpp pixel data (960,000 bytes for 1200×1600) into strips.
      def compress_strips(raw_4bpp)
        strips = []
        NUM_STRIPS.times do |i|
          offset = i * STRIP_SIZE
          strip_data = raw_4bpp[offset, STRIP_SIZE] || ("\xff" * STRIP_SIZE).b
          strips << LZ4Block.compress(strip_data)
        end
        strips
      end

      # Convert PNG binary data to raw 4bpp pixel data in native orientation.
      # The input PNG should be landscape (1600×1200). We rotate it -90°
      # to get the native portrait orientation (1200×1600) that the device expects.
      def png_to_4bpp(png_data)
        image = MiniMagick::Image.read(png_data, ".png")

        # Resize to display dimensions if needed
        image.resize "#{NATIVE_HEIGHT}x#{NATIVE_WIDTH}!" # 1600×1200 landscape

        # Rotate -90° to get native portrait orientation (1200 wide × 1600 tall)
        image.rotate "-90"

        # Convert to 16-level grayscale
        image.combine_options do |c|
          c.colorspace "Gray"
          c.dither "FloydSteinberg"
          c.colors 16
          c.depth 8
        end
        image.format "gray"

        # Read raw 8-bit grayscale pixels
        raw_8bit = image.to_blob
        expected_size = NATIVE_WIDTH * NATIVE_HEIGHT

        if raw_8bit.bytesize != expected_size
          # Pad or truncate to exact size
          if raw_8bit.bytesize < expected_size
            raw_8bit += ("\xff" * (expected_size - raw_8bit.bytesize)).b
          else
            raw_8bit = raw_8bit[0, expected_size]
          end
        end

        # Convert 8bpp to 4bpp (pack two pixels per byte)
        convert_8bpp_to_4bpp(raw_8bit)
      end

      # Generate a test pattern (gradient) for protocol testing.
      # Returns LZ4-compressed strips ready for packet building.
      def test_pattern
        raw = String.new(encoding: Encoding::BINARY)
        NATIVE_HEIGHT.times do |y|
          BYTES_PER_ROW.times do |x|
            # Horizontal gradient: left=black, right=white
            col = (x * 2 * 15) / NATIVE_WIDTH
            byte = (col << 4) | col
            raw << byte.chr
          end
        end
        compress_strips(raw)
      end

      private

      def convert_8bpp_to_4bpp(raw_8bit)
        bytes = raw_8bit.bytes
        output = String.new(capacity: bytes.length / 2, encoding: Encoding::BINARY)

        i = 0
        while i < bytes.length - 1
          # Quantize 8-bit (0-255) to 4-bit (0-15)
          high = (bytes[i] * 15 + 127) / 255
          low = (bytes[i + 1] * 15 + 127) / 255
          output << ((high << 4) | low).chr
          i += 2
        end

        # Pad to expected size if needed
        expected = NATIVE_WIDTH * NATIVE_HEIGHT / 2
        while output.bytesize < expected
          output << "\xff"
        end

        output
      end
    end
  end
end
