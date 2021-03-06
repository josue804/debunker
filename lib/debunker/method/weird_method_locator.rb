class Debunker
  class Method

    # This class is responsible for locating the *real* `Debunker::Method`
    # object captured by a binding.
    #
    # Given a `Binding` from inside a method and a 'seed' Debunker::Method object,
    # there are primarily two situations where the seed method doesn't match
    # the Binding:
    # 1. The Debunker::Method is from a subclass 2. The Debunker::Method represents a method of the same name
    # while the original was renamed to something else. For 1. we
    # search vertically up the inheritance chain,
    # and for 2. we search laterally along the object's method table.
    #
    # When we locate the method that matches the Binding we wrap it in
    # Debunker::Method and return it, or return nil if we fail.
    class WeirdMethodLocator
      class << self

        # Whether the given method object matches the associated binding.
        # If the method object does not match the binding, then it's
        # most likely not the method captured by the binding, and we
        # must commence a search.
        #
        # @param [Debunker::Method] method
        # @param [Binding] b
        # @return [Boolean]
        def normal_method?(method, b)
          method && (method.source_file && method.source_range rescue false) &&
          File.expand_path(method.source_file) == File.expand_path(b.eval('__FILE__')) &&
          method.source_range.include?(b.eval('__LINE__'))
        end

        def weird_method?(method, b)
          !normal_method?(method, b)
        end
      end

      attr_accessor :method
      attr_accessor :target

      # @param [Debunker::Method] method The seed method.
      # @param [Binding] target The Binding that captures the method
      #   we want to locate.
      def initialize(method, target)
        @method, @target = method, target
      end

      # @return [Debunker::Method, nil] The Debunker::Method that matches the
      #   given binding.
      def get_method
        find_method_in_superclass || find_renamed_method
      end

      # @return [Boolean] Whether the Debunker::Method is unrecoverable
      #   This usually happens when the method captured by the Binding
      #   has been subsequently deleted.
      def lost_method?
        !!(get_method.nil? && renamed_method_source_location)
      end

      private

      def normal_method?(method)
        self.class.normal_method?(method, target)
      end

      def target_self
        target.eval('self')
      end

      def target_file
        debunker_file? ? target.eval('__FILE__') : File.expand_path(target.eval('__FILE__'))
      end

      def target_line
        target.eval('__LINE__')
      end

      def debunker_file?
        Debunker.eval_path == target.eval('__FILE__')
      end

      # it's possible in some cases that the method we find by this approach is a sub-method of
      # the one we're currently in, consider:
      #
      # class A; def b; binding.debunker; end; end
      # class B < A; def b; super; end; end
      #
      # Given that we can normally find the source_range of methods, and that we know which
      # __FILE__ and __LINE__ the binding is at, we can hope to disambiguate these cases.
      #
      # This obviously won't work if the source is unavaiable for some reason, or if both
      # methods have the same __FILE__ and __LINE__, or if we're in rbx where b.eval('__LINE__')
      # is broken.
      #
      # @return [Debunker::Method, nil] The Debunker::Method representing the
      #   superclass method.
      def find_method_in_superclass
        guess = method

        while guess
          # needs rescue if this is a Disowned method or a C method or something...
          # TODO: Fix up the exception handling so we don't need a bare rescue
          if normal_method?(guess)
            return guess
          elsif guess != guess.super
            guess = guess.super
          else
            break
          end
        end

        # Uhoh... none of the methods in the chain had the right __FILE__ and __LINE__
        # This may be caused by rbx https://github.com/rubinius/rubinius/issues/953,
        # or other unknown circumstances (TODO: we should warn the user when this happens)
        nil
      end

      # This is the case where the name of a method has changed
      # (via alias_method) so we locate the Method object for the
      # renamed method.
      #
      # @return [Debunker::Method, nil] The Debunker::Method representing the
      #   renamed method
      def find_renamed_method
        return if !valid_file?(target_file)
        alias_name = all_methods_for(target_self).find do |v|
          expanded_source_location(target_self.method(v).source_location) == renamed_method_source_location
        end

        alias_name && Debunker::Method(target_self.method(alias_name))
      end

      def expanded_source_location(sl)
        return if !sl

        if debunker_file?
          sl
        else
          [File.expand_path(sl.first), sl.last]
        end
      end

      # Use static analysis to locate the start of the method definition.
      # We have the `__FILE__` and `__LINE__` from the binding and the
      # original name of the method so we search up until we find a
      # def/define_method, etc defining a method of the appropriate name.
      #
      # @return [Array<String, Fixnum>] The `source_location` of the
      #   renamed method
      def renamed_method_source_location
        return @original_method_source_location if defined?(@original_method_source_location)

        source_index = lines_for_file(target_file)[0..(target_line - 1)].rindex do |v|
          Debunker::Method.method_definition?(method.name, v)
        end

        @original_method_source_location = source_index &&
          [target_file, index_to_line_number(source_index)]
      end

      def index_to_line_number(index)
        # Debunker.line_buffer is 0-indexed
        debunker_file? ? index : index + 1
      end

      def valid_file?(file)
        (File.exist?(file) && !File.directory?(file)) || Debunker.eval_path == file
      end

      def lines_for_file(file)
        @lines_for_file ||= {}
        @lines_for_file[file] ||= if Debunker.eval_path == file
                                    Debunker.line_buffer
                                  else
                                    File.readlines(file)
                                  end
      end

      def all_methods_for(obj)
        obj.public_methods(false) +
          obj.private_methods(false) +
          obj.protected_methods(false)
      end
    end
  end
end
