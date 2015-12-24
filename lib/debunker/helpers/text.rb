class Debunker
  module Helpers
    # The methods defined on {Text} are available to custom commands via {Debunker::Command#text}.
    module Text
      extend self
      COLORS =
      {
        "black"   => 0,
        "red"     => 1,
        "green"   => 2,
        "yellow"  => 3,
        "blue"    => 4,
        "purple"  => 5,
        "magenta" => 5,
        "cyan"    => 6,
        "white"   => 7
      }

      COLORS.each_pair do |color, value|
        define_method color do |text|
          "\001\033[0;#{30+value}m\002#{text}\001\033[0m\002"
        end

        define_method "bright_#{color}" do |text|
          "\001\033[1;#{30+value}m\002#{text}\001\033[0m\002"
        end
      end

      # Remove any color codes from _text_.
      #
      # @param  [String, #to_s] text
      # @return [String] _text_ stripped of any color codes.
      def strip_color(text)
        text.to_s.gsub(/(\001)?\e\[.*?(\d)+m(\002)?/ , '')
      end

      # Returns _text_ as bold text for use on a terminal.
      #
      # @param [String, #to_s] text
      # @return [String] _text_
      def bold(text)
        "\e[1m#{text}\e[0m"
      end

      # Returns `text` in the default foreground colour.
      # Use this instead of "black" or "white" when you mean absence of colour.
      #
      # @param [String, #to_s] text
      # @return [String]
      def default(text)
        text.to_s
      end
      alias_method :bright_default, :bold

      # Executes the block with `Debunker.config.color` set to false.
      # @yield
      # @return [void]
      def no_color(&block)
        boolean = Debunker.config.color
        Debunker.config.color = false
        yield
      ensure
        Debunker.config.color = boolean
      end

      # Executes the block with `Debunker.config.pager` set to false.
      # @yield
      # @return [void]
      def no_pager(&block)
        boolean = Debunker.config.pager
        Debunker.config.pager = false
        yield
      ensure
        Debunker.config.pager = boolean
      end

      # Returns _text_ in a numbered list, beginning at _offset_.
      #
      # @param  [#each_line] text
      # @param  [Fixnum] offset
      # @return [String]
      def with_line_numbers(text, offset, color=:blue)
        lines = text.each_line.to_a
        max_width = (offset + lines.count).to_s.length
        lines.each_with_index.map do |line, index|
          adjusted_index = (index + offset).to_s.rjust(max_width)
          "#{self.send(color, adjusted_index)}: #{line}"
        end.join
      end

      # Returns _text_ indented by _chars_ spaces.
      #
      # @param [String] text
      # @param [Fixnum] chars
      def indent(text, chars)
        text.lines.map { |l| "#{' ' * chars}#{l}" }.join
      end
    end
  end
end