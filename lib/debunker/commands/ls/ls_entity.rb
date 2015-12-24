require 'debunker/commands/ls/grep'
require 'debunker/commands/ls/formatter'
require 'debunker/commands/ls/globals'
require 'debunker/commands/ls/constants'
require 'debunker/commands/ls/methods'
require 'debunker/commands/ls/self_methods'
require 'debunker/commands/ls/instance_vars'
require 'debunker/commands/ls/local_names'
require 'debunker/commands/ls/local_vars'

class Debunker
  class Command::Ls < Debunker::ClassCommand

    class LsEntity
      attr_reader :_debunker_

      def initialize(opts)
        @interrogatee = opts[:interrogatee]
        @no_user_opts = opts[:no_user_opts]
        @opts = opts[:opts]
        @args = opts[:args]
        @grep = Grep.new(Regexp.new(opts[:opts][:G] || '.'))
        @_debunker_ = opts.delete(:_debunker_)
      end

      def entities_table
        entities.map(&:write_out).reject { |o| !o }.join('')
      end

      private

      def grep(entity)
        entity.tap { |o| o.grep = @grep }
      end

      def globals
        grep Globals.new(@opts, _debunker_)
      end

      def constants
        grep Constants.new(@interrogatee, @no_user_opts, @opts, _debunker_)
      end

      def methods
        grep(Methods.new(@interrogatee, @no_user_opts, @opts, _debunker_))
      end

      def self_methods
        grep SelfMethods.new(@interrogatee, @no_user_opts, @opts, _debunker_)
      end

      def instance_vars
        grep InstanceVars.new(@interrogatee, @no_user_opts, @opts, _debunker_)
      end

      def local_names
        grep LocalNames.new(@no_user_opts, @args, _debunker_)
      end

      def local_vars
        LocalVars.new(@opts, _debunker_)
      end

      def entities
        [globals, constants, methods, self_methods, instance_vars, local_names,
          local_vars]
      end
    end
  end
end
