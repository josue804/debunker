require_relative 'helper'

describe "Sticky locals (_file_ and friends)" do
  it 'locals should all exist upon initialization' do
    expect { debunker_eval '_file_', '_dir_', '_ex_', '_debunker_', '_' }.to_not raise_error
  end

  it 'locals should still exist after cd-ing into a new context' do
    expect { debunker_eval 'cd 0', '_file_', '_dir_', '_ex_', '_debunker_', '_' }.to_not raise_error
  end

  it 'locals should keep value after cd-ing (_debunker_)' do
    debunker_tester.tap do |t|
      debunker = t.eval '_debunker_'
      t.eval 'cd 0'
      expect(t.eval('_debunker_')).to eq(debunker)
    end
  end

  describe '_ex_' do
    it 'returns the last exception without wrapping it in a LastException' do
      ReplTester.start do
        input  'raise "halp"'

        input  '_ex_.message == "halp"'
        output '=> true'

        input  'Kernel.instance_method(:class).bind(_ex_).call'
        output '=> RuntimeError'
      end
    end

    it 'keeps its value after cd-ing' do
      ReplTester.start do
        input  'error blah'
        input  '$x = _ex_'
        input  'cd 0'

        input  '_ex_ == $x'
        output '=> true'
      end
    end
  end

  it 'locals should keep value after cd-ing (_file_ and _dir_)' do
    Debunker.config.commands.command "file-and-dir-test" do
      set_file_and_dir_locals("/blah/ostrich.rb")
    end

    expect(debunker_eval('file-and-dir-test', 'cd 0', '_file_')).
      to match(/\/blah\/ostrich\.rb/)

    expect(debunker_eval('file-and-dir-test', 'cd 0', '_dir_')).
      to match(/\/blah/)

    Debunker.config.commands.delete "file-and-dir-test"
  end

  it 'locals should return last result (_)' do
    debunker_tester.tap do |t|
      lam = t.eval 'lambda { |_foo| }'
      expect(t.eval('_')).to eq(lam)
    end
  end

  it 'locals should return second last result (__)' do
    debunker_tester.tap do |t|
      lam = t.eval 'lambda { |_foo| }'
      t.eval 'num = 1'
      expect(t.eval('__')).to eq(lam)
    end
  end

  describe "User defined sticky locals" do
    describe "setting as Debunker.config option" do
      it 'should define a new sticky local for the session (normal value)' do
        Debunker.config.extra_sticky_locals[:test_local] = :john
        o = Object.new
        redirect_debunker_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Debunker.start(o)
        end
        expect(o.instance_variable_get(:@value)).to eq :john
        Debunker.config.extra_sticky_locals = {}
      end

      it 'should define a new sticky local for the session (proc)' do
        Debunker.config.extra_sticky_locals[:test_local] = proc { :john }

        o = Object.new
        redirect_debunker_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Debunker.start(o)
        end

        expect(o.instance_variable_get(:@value)).to eq :john
        Debunker.config.extra_sticky_locals = {}
      end

    end

    describe "passing in as hash option when creating debunker instance" do
      it 'should define a new sticky local for the session (normal value)' do
        o = Object.new
        redirect_debunker_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Debunker.start(o, :extra_sticky_locals => { :test_local => :john } )
        end

        expect(o.instance_variable_get(:@value)).to eq :john
      end

      it 'should define multiple sticky locals' do
        o = Object.new
        redirect_debunker_io(InputTester.new("@value1 = test_local1",
                                        "@value2 = test_local2",
                                        "exit-all")) do
          Debunker.start(o, :extra_sticky_locals => { :test_local1 => :john ,
                      :test_local2 => :carl} )
        end

        expect(o.instance_variable_get(:@value1)).to eq :john
        expect(o.instance_variable_get(:@value2)).to eq :carl
      end


      it 'should define a new sticky local for the session (as Proc)' do
        o = Object.new
        redirect_debunker_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Debunker.start(o, :extra_sticky_locals => { :test_local => proc { :john }} )
        end

        expect(o.instance_variable_get(:@value)).to eq :john
      end
    end

    describe "hash option value should override config value" do
      it 'should define a new sticky local for the session (normal value)' do
        Debunker.config.extra_sticky_locals[:test_local] = :john

        o = Object.new
        redirect_debunker_io(InputTester.new("@value = test_local",
                                        "exit-all")) do
          Debunker.start(o, :extra_sticky_locals => { :test_local => :carl })
        end

        expect(o.instance_variable_get(:@value)).to eq :carl
        Debunker.config.extra_sticky_locals = {}
      end
    end

    it 'should create a new sticky local' do
      t = debunker_tester
      t.eval "_debunker_.add_sticky_local(:test_local){ :test_value }"
      expect(t.eval("test_local")).to eq(:test_value)
    end

    it 'should still exist after cd-ing into new binding' do
      t = debunker_tester
      t.eval "_debunker_.add_sticky_local(:test_local){ :test_value }"
      t.eval "cd Object.new"
      expect(t.eval("test_local")).to eq(:test_value)
    end

    it 'should provide different values for successive block invocations' do
      debunker = Debunker.new
      debunker.push_binding binding
      debunker.add_sticky_local(:test_local) { rand }
      value1 = debunker.evaluate_ruby 'test_local'
      value2 = debunker.evaluate_ruby 'test_local'
      expect(value1).not_to eq(value2)
    end
  end

end
