class Debunker
  class Command::Edit
    class ExceptionPatcher
      attr_accessor :_debunker_
      attr_accessor :state
      attr_accessor :file_and_line

      def initialize(_debunker_, state, exception_file_and_line)
        @_debunker_ = _debunker_
        @state = state
        @file_and_line = exception_file_and_line
      end

      # perform the patch
      def perform_patch
        file_name, _ = file_and_line
        lines = state.dynamical_ex_file || File.read(file_name)

        source = Debunker::Editor.new(_debunker_).edit_tempfile_with_content(lines)
        _debunker_.evaluate_ruby source
        state.dynamical_ex_file = source.split("\n")
      end
    end
  end
end
