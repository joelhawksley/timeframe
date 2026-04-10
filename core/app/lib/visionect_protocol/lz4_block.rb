# frozen_string_literal: true

module VisionectProtocol
  # Minimal LZ4 block encoder/decoder compatible with the standard LZ4 block format.
  # Produces output identical to Python's lz4.block.compress(store_size=False).
  module LZ4Block
    HASH_LOG = 12
    HASH_SIZE = 1 << HASH_LOG
    MIN_MATCH = 4
    # Last 5 bytes must be literals (LZ4 spec safety margin)
    LAST_LITERALS = 5

    class << self
      def compress(input)
        input = input.b if input.encoding != Encoding::BINARY
        src = input.bytes
        src_len = src.length
        return encode_literals(src, 0, src_len) if src_len < 13

        output = []
        hash_table = Array.new(HASH_SIZE, -1)
        anchor = 0
        pos = 1 # Start from 1 so there's always at least 1 literal first
        limit = src_len - LAST_LITERALS

        # Seed hash for position 0
        hash_table[hash4(src, 0)] = 0

        while pos < limit
          h = hash4(src, pos)
          ref = hash_table[h]
          hash_table[h] = pos

          if ref >= 0 && ref < pos && pos - ref <= 65535 &&
              src[ref] == src[pos] && src[ref + 1] == src[pos + 1] &&
              src[ref + 2] == src[pos + 2] && src[ref + 3] == src[pos + 3]

            # Extend match forward
            match_len = 4
            max_fwd = src_len - LAST_LITERALS - pos
            while match_len < max_fwd && src[ref + match_len] == src[pos + match_len]
              match_len += 1
            end

            lit_len = pos - anchor
            emit_sequence(output, src, anchor, lit_len, pos - ref, match_len)

            anchor = pos + match_len
            pos = anchor
          else
            pos += 1
          end
        end

        remaining = src_len - anchor
        emit_last_literals(output, src, anchor, remaining)

        output.pack("C*")
      end

      def decompress(input, uncompressed_size)
        input = input.b if input.encoding != Encoding::BINARY
        src = input.bytes
        src_len = src.length
        output = []
        si = 0

        while si < src_len
          token = src[si]
          si += 1

          # Literal length
          lit_len = (token >> 4) & 0x0F
          if lit_len == 15
            loop do
              extra = src[si]
              si += 1
              lit_len += extra
              break if extra != 255
            end
          end

          # Copy literals
          output.concat(src[si, lit_len])
          si += lit_len

          # Check if we've consumed all input (last sequence has no match)
          break if si >= src_len

          # Match offset (LE)
          offset = src[si] | (src[si + 1] << 8)
          si += 2

          # Match length
          match_len = (token & 0x0F) + MIN_MATCH
          if (token & 0x0F) == 15
            loop do
              extra = src[si]
              si += 1
              match_len += extra
              break if extra != 255
            end
          end

          # Copy match (byte-by-byte for overlapping copies)
          match_pos = output.length - offset
          match_len.times do |i|
            output << output[match_pos + i]
          end
        end

        output.pack("C*")
      end

      private

      def hash4(src, pos)
        v = src[pos] | (src[pos + 1] << 8) | (src[pos + 2] << 16) | (src[pos + 3] << 24)
        ((v * 2654435761) >> (32 - HASH_LOG)) & (HASH_SIZE - 1)
      end

      def emit_sequence(output, src, lit_start, lit_len, offset, match_len)
        ml = match_len - MIN_MATCH
        token = [((lit_len < 15) ? lit_len : 15), ((ml < 15) ? ml : 15)]
        output << ((token[0] << 4) | token[1])

        # Extended literal length
        if lit_len >= 15
          remaining = lit_len - 15
          while remaining >= 255
            output << 255
            remaining -= 255
          end
          output << remaining
        end

        # Literals
        lit_len.times { |i| output << src[lit_start + i] }

        # Match offset (LE)
        output << (offset & 0xFF)
        output << ((offset >> 8) & 0xFF)

        # Extended match length
        if ml >= 15
          remaining = ml - 15
          while remaining >= 255
            output << 255
            remaining -= 255
          end
          output << remaining
        end
      end

      def emit_last_literals(output, src, start, count)
        token_lit = (count < 15) ? count : 15
        output << (token_lit << 4)

        if count >= 15
          remaining = count - 15
          while remaining >= 255
            output << 255
            remaining -= 255
          end
          output << remaining
        end

        count.times { |i| output << src[start + i] }
      end

      def encode_literals(src, start, count)
        output = []
        emit_last_literals(output, src, start, count)
        output.pack("C*")
      end
    end
  end
end
