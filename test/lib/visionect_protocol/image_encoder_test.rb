# frozen_string_literal: true

require "test_helper"

class VisionectProtocol::ImageEncoderTest < Minitest::Test
  def test_encode_png_returns_array_of_compressed_strips
    png = generate_test_png(1600, 1200)
    strips = VisionectProtocol::ImageEncoder.encode_png(png)

    assert_equal 200, strips.length
    strips.each { |s| assert_kind_of String, s }
  end

  def test_png_to_4bpp_returns_correct_size
    png = generate_test_png(1600, 1200)
    raw = VisionectProtocol::ImageEncoder.png_to_4bpp(png)

    assert_equal 960_000, raw.bytesize
    assert_equal Encoding::BINARY, raw.encoding
  end

  def test_png_to_4bpp_resizes_to_native_dimensions
    # Smaller input should be resized to 1600x1200 then rotated
    png = generate_test_png(800, 600)
    raw = VisionectProtocol::ImageEncoder.png_to_4bpp(png)

    assert_equal 960_000, raw.bytesize
  end

  def test_png_to_4bpp_pixel_values_in_4bit_range
    png = generate_test_png(1600, 1200)
    raw = VisionectProtocol::ImageEncoder.png_to_4bpp(png)

    raw.bytes.each_with_index do |byte, i|
      high = (byte >> 4) & 0x0F
      low = byte & 0x0F
      assert high <= 15, "High nibble at #{i} = #{high}"
      assert low <= 15, "Low nibble at #{i} = #{low}"
    end
  end

  def test_compress_strips_produces_200_strips
    raw = "\xff".b * 960_000
    strips = VisionectProtocol::ImageEncoder.compress_strips(raw)

    assert_equal 200, strips.length
  end

  def test_compress_strips_roundtrips_correctly
    raw = ("\x00\xff\x0f\xf0".b * 240_000)
    strips = VisionectProtocol::ImageEncoder.compress_strips(raw)

    # Strips 0-198 carry actual pixel data, strip 199 is 80B of 0xFF (VSS convention)
    reconstructed = "".b
    strips[0...-1].each do |compressed|
      reconstructed << LZ4.raw_decode(compressed, 4800)
    end

    last = LZ4.raw_decode(strips.last, VisionectProtocol::ImageEncoder::LAST_STRIP_SIZE)
    assert_equal VisionectProtocol::ImageEncoder::LAST_STRIP_SIZE, last.bytesize
    assert_equal raw[0, reconstructed.bytesize], reconstructed
  end

  def test_test_pattern_returns_200_strips
    strips = VisionectProtocol::ImageEncoder.test_pattern

    assert_equal 200, strips.length
    strips[0...-1].each do |s|
      decompressed = LZ4.raw_decode(s, 4800)
      assert_equal 4800, decompressed.bytesize
    end
    # Last strip is 80B of 0xFF (VSS convention)
    last = LZ4.raw_decode(strips.last, VisionectProtocol::ImageEncoder::LAST_STRIP_SIZE)
    assert_equal VisionectProtocol::ImageEncoder::LAST_STRIP_SIZE, last.bytesize
  end

  def test_png_to_4bpp_white_image_is_uniform
    png = generate_test_png(1600, 1200, color: "white")
    raw = VisionectProtocol::ImageEncoder.png_to_4bpp(png)

    # All bytes should be the same for a uniform color input
    unique_bytes = raw.bytes.uniq
    assert_equal 1, unique_bytes.length, "White image should produce uniform output, got #{unique_bytes.length} unique values"
  end

  def test_png_to_4bpp_black_image_is_uniform
    png = generate_test_png(1600, 1200, color: "black")
    raw = VisionectProtocol::ImageEncoder.png_to_4bpp(png)

    unique_bytes = raw.bytes.uniq
    assert_equal 1, unique_bytes.length, "Black image should produce uniform output, got #{unique_bytes.length} unique values"
  end

  private

  def generate_test_png(width, height, color: "gray50")
    require "mini_magick"
    img = MiniMagick::Image.create(".png") do |f|
      MiniMagick.convert do |c|
        c.size "#{width}x#{height}"
        c << "xc:#{color}"
        c << f.path
      end
    end
    img.to_blob
  end
end
