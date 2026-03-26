# frozen_string_literal: true

require "mini_magick"
require "extlz4"

module VisionectProtocol
  # Encodes a PNG image into the Visionect protocol image packet format.
  #
  # Image format: 4bpp grayscale (16 levels), LZ4-compressed strips.
  # Each strip covers 6 rows of the display at the native panel width.
  # The panel's native orientation is 1600×1200 (landscape);
  # the device applies rotation internally when mounted in portrait mode.
  #
  # Strip data layout within each strip's 4800 bytes:
  #   Sequential rows: row0[800B] + row1[800B] + ... + row5[800B]
  #   Each row: 800 bytes at 4bpp = 1600 pixels (2 pixels per byte, high nibble first)
  class ImageEncoder
    NATIVE_WIDTH = 1600
    NATIVE_HEIGHT = 1200
    BYTES_PER_ROW = NATIVE_WIDTH / 2 # 800 bytes at 4bpp
    ROWS_PER_STRIP = 6
    STRIP_SIZE = BYTES_PER_ROW * ROWS_PER_STRIP # 4800 bytes
    NUM_STRIPS = NATIVE_HEIGHT / ROWS_PER_STRIP # 200
    # VSS sends only 80 bytes (0xFF) for the last strip instead of 4800
    LAST_STRIP_SIZE = 80

    class << self
      # Encode a PNG (as binary string) into Visionect protocol image rectangles.
      # Returns an array of LZ4-compressed strip data strings.
      def encode_png(png_data)
        raw_pixels = png_to_4bpp(png_data)
        compress_strips(raw_pixels)
      end

      # Encode raw 4bpp pixel data (960,000 bytes for 1200×1600) into strips.
      # The last strip carries only LAST_STRIP_SIZE bytes (matching VSS behavior).
      def compress_strips(raw_4bpp)
        strips = []
        NUM_STRIPS.times do |i|
          if i == NUM_STRIPS - 1
            # Last strip: 80 bytes of 0xFF (matches VSS reference)
            strip_data = ("\xff" * LAST_STRIP_SIZE).b
          else
            offset = i * STRIP_SIZE
            strip_data = raw_4bpp[offset, STRIP_SIZE] || ("\xff" * STRIP_SIZE).b
          end
          strips << LZ4.raw_encode(strip_data)
        end
        strips
      end

      # Convert PNG binary data to raw 4bpp pixel data in native panel orientation.
      # Input PNG is portrait (1200×1600); we rotate 90° CW to get the panel's
      # native landscape layout (1600×1200) for the protocol.
      #
      # Uses PGM intermediate format for reliable 8bpp output regardless of
      # input depth, then packs pixel pairs into 4bpp bytes (high nibble first).
      def png_to_4bpp(png_data)
        image = MiniMagick::Image.read(png_data, ".png")

        # Resize to portrait, then rotate 90° CW to native panel landscape
        image.resize "#{NATIVE_HEIGHT}x#{NATIVE_WIDTH}!"
        image.rotate "90"

        # Convert to 16-level grayscale, output as PGM for reliable 8bpp
        image.combine_options do |c|
          c.colorspace "Gray"
          c.dither "FloydSteinberg"
          c.colors 16
          c.depth 8
        end
        image.format "pgm"

        pgm_blob = image.to_blob

        # Parse PGM P5 header: "P5\n<width> <height>\n<maxval>\n<data>"
        idx = 0
        3.times { idx = pgm_blob.index("\n", idx) + 1 }
        raw_8bpp = pgm_blob.byteslice(idx..)
        maxval = pgm_blob.byteslice(0, idx).split("\n")[2].to_i

        # Scale factor to map pixel values (0..maxval) to 4-bit range (0..15)
        scale = 15.0 / maxval

        # Pack pairs of 8-bit pixels into 4bpp bytes (high nibble first)
        expected_4bpp = NATIVE_WIDTH * NATIVE_HEIGHT / 2
        output = String.new(capacity: expected_4bpp, encoding: Encoding::BINARY)
        bytes = raw_8bpp.bytes
        i = 0
        while i < bytes.length - 1
          high = ((bytes[i] * scale) + 0.5).to_i.clamp(0, 15)
          low = ((bytes[i + 1] * scale) + 0.5).to_i.clamp(0, 15)
          output << ((high << 4) | low).chr
          i += 2
        end

        # :nocov:
        while output.bytesize < expected_4bpp
          output << "\xff"
        end
        # :nocov:

        output
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
    end
  end
end
