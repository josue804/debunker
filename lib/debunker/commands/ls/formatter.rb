class Debunker
  class Command::Ls < Debunker::ClassCommand
    class Formatter
      attr_writer :grep
      attr_reader :_debunker_

      def initialize(_debunker_)
        @_debunker_ = _debunker_
        @target = _debunker_.current_context
        @default_switch = nil
      end

      def write_out
        return false unless correct_opts?
        output_self
      end

      private

      def color(type, str)
        Debunker::Helpers::Text.send _debunker_.config.ls["#{type}_color"], str
      end

      # Add a new section to the output.
      # Outputs nothing if the section would be empty.
      def output_section(heading, body)
        return '' if body.compact.empty?
        fancy_heading = Debunker::Helpers::Text.bold(color(:heading, heading))
        Debunker::Helpers.tablify_or_one_line(fancy_heading, body)
      end

      def format_value(value)
        Debunker::ColorPrinter.pp(value, '')
      end

      def correct_opts?
        @default_switch
      end

      def output_self
        raise NotImplementedError
      end

      def grep
        @grep || proc { |x| x }
      end

    end
  end
end
