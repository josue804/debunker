require_relative 'helper'

describe "Prompts" do
  describe "one-parameter prompt proc" do
    it 'should get full config object' do
      config = nil
      redirect_debunker_io(InputTester.new("exit-all")) do
        Debunker.start(self, :prompt => proc { |v| config = v })
      end
      expect(config.is_a?(Debunker::Config)).to eq true
    end

    it 'should get full config object, when using a proc array' do
      config1 = nil
      redirect_debunker_io(InputTester.new("exit-all")) do
        Debunker.start(self, :prompt => [proc { |v| config1 = v }, proc { |v| _config2 = v }])
      end
      expect(config1.is_a?(Debunker::Config)).to eq true
    end

    it 'should receive correct data in the config object' do
      config = nil
      redirect_debunker_io(InputTester.new("def hello", "exit-all")) do
        Debunker.start(self, :prompt => proc { |v| config = v })
      end

      expect(config.eval_string).to match(/def hello/)
      expect(config.nesting_level).to eq 0
      expect(config.expr_number).to eq 1
      expect(config.cont).to eq true
      expect(config._debunker_.is_a?(Debunker)).to eq true
      expect(config.object).to eq self
    end
  end

  describe "BACKWARDS COMPATIBILITY: 3 parameter prompt proc" do
    it 'should get 3 parameters' do
      o = n = p = nil
      redirect_debunker_io(InputTester.new("exit-all")) do
        Debunker.start(:test, :prompt => proc { |obj, nesting, _debunker_|
                    o, n, p = obj, nesting, _debunker_ })
      end
      expect(o).to eq :test
      expect(n).to eq 0
      expect(p.is_a?(Debunker)).to eq true
    end

    it 'should get 3 parameters, when using proc array' do
      o1 = n1 = p1 = nil
      redirect_debunker_io(InputTester.new("exit-all")) do
        Debunker.start(:test, :prompt => [proc { |obj, nesting, _debunker_|
                                       o1, n1, p1 = obj, nesting, _debunker_ },
                                     proc { |obj, nesting, _debunker_|
                                       _o2, _n2, _p2 = obj, nesting, _debunker_ }])
      end
      expect(o1).to eq :test
      expect(n1).to eq 0
      expect(p1.is_a?(Debunker)).to eq true
    end
  end
end
