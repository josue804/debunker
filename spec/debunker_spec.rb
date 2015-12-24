require_relative 'helper'

describe Debunker do
  before do
    @str_output = StringIO.new
  end

  describe "Exotic object support" do
    # regression test for exotic object support
    it "Should not error when return value is a BasicObject instance" do
      ReplTester.start do
        input('BasicObject.new').should =~ /^=> #<BasicObject:/
      end
    end
  end

  describe 'DISABLE_PRY' do
    before do
      ENV['DISABLE_PRY'] = 'true'
    end

    after do
      ENV.delete 'DISABLE_PRY'
    end

    it 'should not binding.debunker' do
      expect(binding.debunker).to eq nil
    end

    it 'should not Debunker.start' do
      expect(Debunker.start).to eq nil
    end
  end

  describe "Debunker.critical_section" do
    it "should prevent Debunker being called" do
      output = StringIO.new
      Debunker.config.output = output
      Debunker.critical_section do
        Debunker.start
      end
      expect(output.string).to match(/Debunker started inside Debunker/)
    end
  end

  describe "Debunker.binding_for" do

    # regression test for burg's bug (see git history)
    it "Should not error when object doesn't have a valid == method" do
      o = Object.new
      def o.==(other)
        raise
      end

      expect { Debunker.binding_for(o) }.to_not raise_error
    end

    it "should not leak local variables" do
      [Object.new, Array, 3].each do |obj|
        expect(Debunker.binding_for(obj).eval("local_variables")).to be_empty
      end
    end

    it "should work on frozen objects" do
      a = "hello".freeze
      expect(Debunker.binding_for(a).eval("self")).to equal(a)
    end
  end

  describe "#last_exception=" do
    before do
      @debunker = Debunker.new binding: binding
      @e = mock_exception "foo.rb:1"
    end

    it "returns an instance of Debunker::LastException" do
      @debunker.last_exception = @e
      expect(@debunker.last_exception.wrapped_exception).to eq @e
    end

    it "returns a frozen exception" do
      @debunker.last_exception = @e.freeze
      expect(@debunker.last_exception).to be_frozen
    end

    it "returns an object who mirrors itself as the wrapped exception" do
      @debunker.last_exception = @e.freeze
      expect(@debunker.last_exception).to be_an_instance_of StandardError
    end
  end

  describe "open a Debunker session on an object" do
    describe "rep" do
      before do
        class Hello
        end
      end

      after do
        Object.send(:remove_const, :Hello)
      end

      # bug fix for https://github.com/debunker/debunker/issues/93
      it 'should not leak debunker constants into Object namespace' do
        expect { debunker_eval(Object.new, "Command") }.to raise_error NameError
      end

      it 'should be able to operate inside the BasicObject class' do
        debunker_eval(BasicObject, ":foo", "Pad.obj = _")
        expect(Pad.obj).to eq :foo
      end

      it 'should set an ivar on an object' do
        o = Object.new
        debunker_eval(o, "@x = 10")
        expect(o.instance_variable_get(:@x)).to eq 10
      end

      it 'should display error if Debunker instance runs out of input' do
        redirect_debunker_io(StringIO.new, @str_output) do
          Debunker.start
        end
        expect(@str_output.string).to match(/Error: Debunker ran out of things to read/)
      end

      it 'should make self evaluate to the receiver of the rep session' do
        o = :john
        expect(debunker_eval(o, "self")).to eq o
      end

      it 'should define a nested class under Hello and not on top-level or Debunker' do
        mock_debunker(Debunker.binding_for(Hello), "class Nested", "end")
        expect(Hello.const_defined?(:Nested)).to eq true
      end

      it 'should suppress output if input ends in a ";" and is an Exception object (single line)' do
        expect(mock_debunker("Exception.new;")).to eq ""
      end

      it 'should suppress output if input ends in a ";" (single line)' do
        expect(mock_debunker("x = 5;")).to eq ""
      end

      it 'should be able to evaluate exceptions normally' do
        was_called = false
        mock_debunker("RuntimeError.new", :exception_handler => proc{ was_called = true })
        expect(was_called).to eq false
      end

      it 'should notice when exceptions are raised' do
        was_called = false
        mock_debunker("raise RuntimeError", :exception_handler => proc{ was_called = true })
        expect(was_called).to eq true
      end

      it 'should not try to catch intended exceptions' do
        expect { mock_debunker("raise SystemExit") }.to raise_error SystemExit
        # SIGTERM
        expect { mock_debunker("raise SignalException.new(15)") }.to raise_error SignalException
      end

      describe "multi-line input" do
        it "works" do
          expect(mock_debunker('x = ', '1 + 4')).to match(/5/)
        end

        it 'should suppress output if input ends in a ";" (multi-line)' do
          expect(mock_debunker('def self.blah', ':test', 'end;')).to eq ''
        end

        describe "newline stripping from an empty string" do
          it "with double quotes" do
            expect(mock_debunker('"', '"')).to match(%r|"\\n"|)
            expect(mock_debunker('"', "\n", "\n", "\n", '"')).to match(%r|"\\n\\n\\n\\n"|)
          end

          it "with single quotes" do
            expect(mock_debunker("'", "'")).to match(%r|"\\n"|)
            expect(mock_debunker("'", "\n", "\n", "\n", "'")).to match(%r|"\\n\\n\\n\\n"|)
          end

          it "with fancy delimiters" do
            expect(mock_debunker('%(', ')')).to match(%r|"\\n"|)
            expect(mock_debunker('%|', "\n", "\n", '|')).to match(%r|"\\n\\n\\n"|)
            expect(mock_debunker('%q[', "\n", "\n", ']')).to match(%r|"\\n\\n\\n"|)
          end
        end

        describe "newline stripping from an empty regexp" do
          it "with regular regexp delimiters" do
            expect(mock_debunker('/', '/')).to match(%r{/\n/})
          end

          it "with fancy delimiters" do
            expect(mock_debunker('%r{', "\n", "\n", '}')).to match(%r{/\n\n\n/})
            expect(mock_debunker('%r<', "\n", '>')).to match(%r{/\n\n/})
          end
        end

        describe "newline from an empty heredoc" do
          it "works" do
            expect(mock_debunker('<<HERE', 'HERE')).to match(%r|""|)
            expect(mock_debunker("<<'HERE'", "\n", 'HERE')).to match(%r|"\\n"|)
            expect(mock_debunker("<<-'HERE'", "\n", "\n", 'HERE')).to match(%r|"\\n\\n"|)
          end
        end
      end
    end

    describe "repl" do
      describe "basic functionality" do
        it 'should set an ivar on an object and exit the repl' do
          input_strings = ["@x = 10", "exit-all"]
          input = InputTester.new(*input_strings)

          o = Object.new

          Debunker.start(o, :input => input, :output => StringIO.new)

          expect(o.instance_variable_get(:@x)).to eq 10
        end
      end

      describe "complete_expression?" do
        it "should not mutate the input!" do
          clean = "puts <<-FOO\nhi\nFOO\n"
          a = clean.dup
          Debunker::Code.complete_expression?(a)
          expect(a).to eq clean
        end
      end

      describe "history arrays" do
        it 'sets _ to the last result' do
          t = debunker_tester
          t.eval ":foo"
          expect(t.eval("_")).to eq :foo
          t.eval "42"
          expect(t.eval("_")).to eq 42
        end

        it 'sets out to an array with the result' do
          t = debunker_tester
          t.eval ":foo"
          t.eval "42"
          res = t.eval "_out_"

          expect(res).to be_a_kind_of Debunker::HistoryArray
          expect(res[1..2]).to eq [:foo, 42]
        end

        it 'sets _in_ to an array with the entered lines' do
          t = debunker_tester
          t.eval ":foo"
          t.eval "42"
          res = t.eval "_in_"

          expect(res).to be_a_kind_of Debunker::HistoryArray
          expect(res[1..2]).to eq [":foo\n", "42\n"]
        end

        it 'uses 100 as the size of _in_ and _out_' do
          expect(debunker_tester.eval("[_in_.max_size, _out_.max_size]")).to eq [100, 100]
        end

        it 'can change the size of the history arrays' do
          expect(debunker_tester(:memory_size => 1000).eval("[_out_, _in_].map(&:max_size)")).to eq [1000, 1000]
        end

        it 'store exceptions' do
          mock_debunker("foo!", "Pad.in = _in_[-1]; Pad.out = _out_[-1]")

          expect(Pad.in).to eq "foo!\n"
          expect(Pad.out).to be_a_kind_of NoMethodError
        end
      end

      describe "last_result" do
        it "should be set to the most recent value" do
          expect(debunker_eval("2", "_ + 82")).to eq 84
        end

        # This test needs mock_debunker because the command retvals work by
        # replacing the eval_string, so _ won't be modified without Debunker doing
        # a REPL loop.
        it "should be set to the result of a command with :keep_retval" do
          Debunker::Commands.block_command '++', '', :keep_retval => true do |a|
            a.to_i + 1
          end

          expect(mock_debunker('++ 86', '++ #{_}')).to match(/88/)
        end

        it "should be preserved over an empty line" do
          expect(debunker_eval("2 + 2", " ", "\t",  " ", "_ + 92")).to eq 96
        end

        it "should be preserved when evalling a  command without :keep_retval" do
          expect(debunker_eval("2 + 2", "ls -l", "_ + 96")).to eq 100
        end
      end

      describe "nesting" do
        after do
          Debunker.reset_defaults
          Debunker.config.color = false
        end

        it 'should nest properly' do
          Debunker.config.input = InputTester.new("cd 1", "cd 2", "cd 3", "\"nest:\#\{(_debunker_.binding_stack.size - 1)\}\"", "exit-all")

          Debunker.config.output = @str_output

          o = Object.new
          o.debunker

          expect(@str_output.string).to match(/nest:3/)
        end
      end

      describe "defining methods" do
        it 'should define a method on the singleton class of an object when performing "def meth;end" inside the object' do
          [Object.new, {}, []].each do |val|
            debunker_eval(val, 'def hello; end')
            expect(val.methods(false).map(&:to_sym).include?(:hello)).to eq true
          end
        end

        it 'should define an instance method on the module when performing "def meth;end" inside the module' do
          hello = Module.new
          debunker_eval(hello, "def hello; end")
          expect(hello.instance_methods(false).map(&:to_sym).include?(:hello)).to eq true
        end

        it 'should define an instance method on the class when performing "def meth;end" inside the class' do
          hello = Class.new
          debunker_eval(hello, "def hello; end")
          expect(hello.instance_methods(false).map(&:to_sym).include?(:hello)).to eq true
        end

        it 'should define a method on the class of an object when performing "def meth;end" inside an immediate value or Numeric' do
          [:test, 0, true, false, nil,
              (0.0 unless Debunker::Helpers::BaseHelpers.jruby?)].each do |val|
            debunker_eval(val, "def hello; end");
            expect(val.class.instance_methods(false).map(&:to_sym).include?(:hello)).to eq true
          end
        end
      end

      describe "Object#debunker" do

        after do
          Debunker.reset_defaults
          Debunker.config.color = false
        end

        it "should start a debunker session on the receiver (first form)" do
          Debunker.config.input = InputTester.new("self", "exit-all")

          str_output = StringIO.new
          Debunker.config.output = str_output

          20.debunker

          expect(str_output.string).to match(/20/)
        end

        it "should start a debunker session on the receiver (second form)" do
          Debunker.config.input = InputTester.new("self", "exit-all")

          str_output = StringIO.new
          Debunker.config.output = str_output

          debunker 20

          expect(str_output.string).to match(/20/)
        end

        it "should raise if more than two arguments are passed to Object#debunker" do
          expect { debunker(20, :quiet, :input => Readline) }.to raise_error ArgumentError
        end
      end

      describe "Debunker.binding_for" do
        it 'should return TOPLEVEL_BINDING if parameter self is main' do
          _main_ = lambda { TOPLEVEL_BINDING.eval('self') }
          expect(Debunker.binding_for(_main_.call).is_a?(Binding)).to eq true
          expect(Debunker.binding_for(_main_.call)).to eq TOPLEVEL_BINDING
          expect(Debunker.binding_for(_main_.call)).to eq Debunker.binding_for(_main_.call)
        end
      end
    end
  end

  describe 'setting custom options' do
    it 'does not raise for unrecognized options' do
      expect { Debunker.new(:custom_option => 'custom value') }.to_not raise_error
    end

    it 'correctly handles the :quiet option (#1261)' do
      instance = Debunker.new(:quiet => true)
      expect(instance.quiet?).to eq true
    end
  end

  describe "a fresh instance" do
    it "should use `caller` as its backtrace" do
      location  = "#{__FILE__}:#{__LINE__ + 1}"[1..-1] # omit leading .
      backtrace = Debunker.new.backtrace

      expect(backtrace).not_to equal nil
      expect(backtrace.any? { |l| l.include?(location) }).to equal true
    end
  end
end
