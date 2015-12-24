require 'debunker/commands/ls/interrogatable'
require 'debunker/commands/ls/methods_helper'

class Debunker
  class Command::Ls < Debunker::ClassCommand
    class SelfMethods < Debunker::Command::Ls::Formatter
      include Debunker::Command::Ls::Interrogatable
      include Debunker::Command::Ls::MethodsHelper

      def initialize(interrogatee, no_user_opts, opts, _debunker_)
        super(_debunker_)
        @interrogatee = interrogatee
        @no_user_opts = no_user_opts
        @ppp_switch = opts[:ppp]
        @jruby_switch = opts['all-java']
      end

      def output_self
        methods = all_methods(true).select do |m|
          m.owner == @interrogatee && grep.regexp[m.name]
        end
        heading = "#{ Debunker::WrappedModule.new(@interrogatee).method_prefix }methods"
        output_section(heading, format(methods))
      end

      private

      def correct_opts?
        @no_user_opts && interrogating_a_module?
      end

    end
  end
end
