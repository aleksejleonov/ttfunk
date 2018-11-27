module TTFunk
  class Table
    class Cff < TTFunk::Table
      class Encoding < TTFunk::SubTable
        include Enumerable

        STANDARD_ENCODING_ID = 0
        EXPERT_ENCODING_ID = 1

        DEFAULT_ENCODING_ID = STANDARD_ENCODING_ID

        class << self
          def codes_for_encoding_id(encoding_id)
            case encoding_id
            when STANDARD_ENCODING_ID
              Encodings::STANDARD
            when EXPERT_ENCODING_ID
              Encodings::EXPERT
            end
          end
        end

        attr_reader :top_dict, :format, :count, :offset_or_id

        def initialize(top_dict, file, offset_or_id = nil, length = nil)
          @top_dict = top_dict
          @offset_or_id = offset_or_id || DEFAULT_ENCODING_ID

          if offset
            super(file, offset, length)
          else
            @count = self.class.codes_for_encoding_id(offset_or_id).size
          end
        end

        def each
          return to_enum(__method__) unless block_given?
          # +1 adjusts for the implicit .notdef glyph
          (count + 1).times { |i| yield self[i] }
        end

        def [](glyph_id)
          return 0 if glyph_id == 0
          return code_for(glyph_id) if offset
          self.class.codes_for_encoding_id(offset_or_id)[glyph_id - 1]
        end

        def offset
          # Numbers from 0..1 mean encoding IDs instead of offsets. IDs are
          # pre-defined, generic encodings that define the characters present
          # in the font.
          #
          # In the case of an offset, add the CFF table's offset since the
          # charset offset is relative to the start of the CFF table. Otherwise
          # return nil (no offset).
          if offset_or_id > 1
            offset_or_id + top_dict.cff_offset
          end
        end

        # mapping is new -> old glyph ids
        def encode(mapping)
          # no offset means no encoding was specified (i.e. we're supposed to
          # use a predefined encoding) so there's nothing to encode
          return '' unless offset

          codes = mapping.keys.sort.map { |new_gid| code_for(mapping[new_gid]) }
          ranges = TTFunk::BinUtils.rangify(codes)

          # calculate whether storing the charset as a series of ranges is
          # more efficient (i.e. takes up less space) vs storing it as an
          # array of SID values
          total_range_size = (2 * ranges.size) +
            (element_width(:range_format) * ranges.size)

          total_array_size = codes.size * element_width(:array_format)

          [].tap do |result|
            if total_array_size <= total_range_size
              fmt = element_format(:array_format)
              result << [format_int(:array_format), codes.size].pack('CC')
              result << codes.pack("#{fmt}*")
            else
              fmt = element_format(:range_format)
              result << [format_int(:range_format), ranges.size].pack('CC')

              ranges.each do |range|
                code, num_left = range
                result << [code, num_left].pack(fmt)
              end
            end
          end.join
        end

        private

        def code_for(glyph_id)
          return 0 if glyph_id == 0

          # rather than validating the glyph as part of one of the predefined
          # encodings, just pass it through
          return glyph_id unless offset

          case format_sym
          when :array_format
            # zero is always .notdef, so adjust with - 1
            @entries[glyph_id - 1]

          when :range_format
            remaining = glyph_id

            @entries.each do |range|
              if range.size >= remaining
                return (range.first + remaining) - 1
              end

              remaining -= range.size
            end

            0
          end
        end

        def parse!
          @format, entry_count = read(2, 'C*')
          @length = entry_count * element_width

          case format_sym
          when :array_format
            @count = entry_count
            @entries = read(length, 'C*')

          when :range_format
            @entries = []
            @count = 0

            entry_count.times do
              code, num_left = read(element_width, element_format)
              @entries << (code..(code + num_left))
              @count += num_left + 1
            end
          end
        end

        # @TODO: handle supplemental encoding (necessary?)
        def element_format(fmt = format_sym)
          case fmt
          when :array_format then 'C'
          when :range_format then 'CC'
          end
        end

        # @TODO: handle supplemental encoding (necessary?)
        def element_width(fmt = format_sym)
          case fmt
          when :array_format then 1
          when :range_format then 2
          else
            raise "'#{fmt}' is an unsupported encoding format"
          end
        end

        # @TODO: handle supplemental encoding (necessary?)
        def format_sym(fmt = @format)
          case fmt
          when 0 then :array_format
          when 1 then :range_format
          else
            raise "unsupported charset format '#{fmt}'"
          end
        end

        def format_int(sym = format_sym)
          case sym
          when :array_format then 0
          when :range_format then 1
          else
            raise "unsupported charset format '#{sym}'"
          end
        end
      end
    end
  end
end