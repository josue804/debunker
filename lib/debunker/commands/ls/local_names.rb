class Debunker
  class Command::Ls < Debunker::ClassCommand
    class LocalNames < Debunker::Command::Ls::Formatter

      def initialize(no_user_opts, args, _debunker_)
        super(_debunker_)
        @no_user_opts = no_user_opts
        @args = args
        @sticky_locals = _debunker_.sticky_locals
      end

      def correct_opts?
        super || (@no_user_opts && @args.empty?)
      end

      def output_self
        local_vars = grep.regexp[@target.eval('local_variables')]
        output_section('locals', format(local_vars))
      end

      private

      def format(locals)
        locals.sort_by(&:downcase).map do |name|
          if @sticky_locals.include?(name.to_sym)
            color(:debunker_var, name)
          else
            color(:local_var, name)
          end
        end
      end

    end
  end
end
