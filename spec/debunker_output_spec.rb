require_relative 'helper'

describe Debunker do
  describe "output failsafe" do
    after do
      Debunker.config.print = Debunker::DEFAULT_PRINT
    end

    it "should catch serialization exceptions" do
      Debunker.config.print = lambda { |*a| raise "catch-22" }

      expect { mock_debunker("1") }.to_not raise_error
    end

    it "should display serialization exceptions" do
      Debunker.config.print = lambda { |*a| raise "catch-22" }

      expect(mock_debunker("1")).to match(/\(debunker\) output error: #<RuntimeError: catch-22>/)
    end

    it "should catch errors serializing exceptions" do
      Debunker.config.print = lambda do |*a|
        raise Exception.new("catch-22").tap{ |e| class << e; def inspect; raise e; end; end }
      end

      expect(mock_debunker("1")).to match(/\(debunker\) output error: failed to show result/)
    end
  end

  describe "DEFAULT_PRINT" do
    it "should output the right thing" do
      expect(mock_debunker("[1]")).to match(/^=> \[1\]/)
    end

    it "should include the =>" do
      debunker = Debunker.new
      accumulator = StringIO.new
      debunker.config.output = accumulator
      debunker.config.print.call(accumulator, [1], debunker)
      expect(accumulator.string).to eq("=> \[1\]\n")
    end

    it "should not be phased by un-inspectable things" do
      expect(mock_debunker("class NastyClass; undef pretty_inspect; end", "NastyClass.new")).to match(/#<.*NastyClass:0x.*?>/)
    end

    it "doesn't leak colour for object literals" do
      expect(mock_debunker("Object.new")).to match(/=> #<Object:0x[a-z0-9]+>\n/)
    end
  end

  describe "output_prefix" do
    it "should be able to change output_prefix" do
      debunker = Debunker.new
      accumulator = StringIO.new
      debunker.config.output = accumulator
      debunker.config.output_prefix = "-> "
      debunker.config.print.call(accumulator, [1], debunker)
      expect(accumulator.string).to eq("-> \[1\]\n")
    end
  end

  describe "color" do
    before do
      Debunker.config.color = true
    end

    after do
      Debunker.config.color = false
    end

    it "should colorize strings as though they were ruby" do
      debunker = Debunker.new
      accumulator = StringIO.new
      colorized   = CodeRay.scan("[1]", :ruby).term
      debunker.config.output = accumulator
      debunker.config.print.call(accumulator, [1], debunker)
      expect(accumulator.string).to eq("=> #{colorized}\n")
    end

    it "should not colorize strings that already include color" do
      debunker = Debunker.new
      f = Object.new
      def f.inspect
        "\e[1;31mFoo\e[0m"
      end
      accumulator = StringIO.new
      debunker.config.output = accumulator
      debunker.config.print.call(accumulator, f, debunker)
      # We add an extra \e[0m to prevent color leak
      expect(accumulator.string).to eq("=> \e[1;31mFoo\e[0m\e[0m\n")
    end
  end

  describe "output suppression" do
    before do
      @t = debunker_tester
    end
    it "should normally output the result" do
      expect(mock_debunker("1 + 2")).to eq("=> 3\n")
    end

    it "should not output anything if the input ends with a semicolon" do
      expect(mock_debunker("1 + 2;")).to eq("")
    end

    it "should output something if the input ends with a comment" do
      expect(mock_debunker("1 + 2 # basic addition")).to eq("=> 3\n")
    end

    it "should not output something if the input is only a comment" do
      expect(mock_debunker("# basic addition")).to eq("")
    end
  end

  describe "custom non-IO object as $stdout" do
    it "does not crash debunker" do
      old_stdout = $stdout
      custom_io = Class.new { def write(*) end }.new
      debunker_eval = DebunkerTester.new(binding)
      expect(debunker_eval.eval("$stdout = custom_io", ":ok")).to eq(:ok)
      $stdout = old_stdout
    end
  end
end
