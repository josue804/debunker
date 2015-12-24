require_relative 'helper'

describe Debunker do
  describe 'loading rc files' do
    before do
      Debunker::HOME_RC_FILE.replace "spec/fixtures/testrc"
      Debunker::LOCAL_RC_FILE.replace "spec/fixtures/testrc/../testrc"
      Debunker.instance_variable_set(:@initial_session, true)
      Debunker.config.should_load_rc = true
      Debunker.config.should_load_local_rc = true
    end

    after do
      Debunker::HOME_RC_FILE.replace "~/.debunkerrc"
      Debunker::LOCAL_RC_FILE.replace "./.debunkerrc"
      Debunker.config.should_load_rc = false
      Object.remove_const(:TEST_RC) if defined?(TEST_RC)
    end

    it "should never run the rc file twice" do
      Debunker.start(self, :input => StringIO.new("exit-all\n"), :output => StringIO.new)
      expect(TEST_RC).to eq [0]

      Debunker.start(self, :input => StringIO.new("exit-all\n"), :output => StringIO.new)
      expect(TEST_RC).to eq [0]
    end

    # Resolving symlinks doesn't work on jruby 1.9 [jruby issue #538]
    unless Debunker::Helpers::BaseHelpers.jruby_19?
      it "should not load the rc file twice if it's symlinked differently" do
        Debunker::HOME_RC_FILE.replace "spec/fixtures/testrc"
        Debunker::LOCAL_RC_FILE.replace "spec/fixtures/testlinkrc"

        Debunker.start(self, :input => StringIO.new("exit-all\n"), :output => StringIO.new)

        expect(TEST_RC).to eq [0]
      end
    end

    it "should not load the debunkerrc if debunkerrc's directory permissions do not allow this" do
      Dir.mktmpdir do |dir|
        File.chmod 0000, dir
        Debunker::LOCAL_RC_FILE.replace File.join(dir, '.debunkerrc')
        Debunker.config.should_load_rc = true
        expect { Debunker.start(self, :input => StringIO.new("exit-all\n"), :output => StringIO.new) }.to_not raise_error
        File.chmod 0777, dir
      end
    end

    it "should not load the debunkerrc if it cannot expand ENV[HOME]" do
      old_home = ENV['HOME']
      ENV['HOME'] = nil
      Debunker.config.should_load_rc = true
      expect { Debunker.start(self, :input => StringIO.new("exit-all\n"), :output => StringIO.new) }.to_not raise_error

      ENV['HOME'] = old_home
    end

    it "should not run the rc file at all if Debunker.config.should_load_rc is false" do
      Debunker.config.should_load_rc = false
      Debunker.config.should_load_local_rc = false
      Debunker.start(self, :input => StringIO.new("exit-all\n"), :output => StringIO.new)
      expect(Object.const_defined?(:TEST_RC)).to eq false
    end

    describe "that raise exceptions" do
      before do
        Debunker::HOME_RC_FILE.replace "spec/fixtures/testrcbad"
        Debunker.config.should_load_local_rc = false

        putsed = nil

        # YUCK! horrible hack to get round the fact that output is not configured
        # at the point this message is printed.
        (class << Debunker; self; end).send(:define_method, :puts) { |str|
          putsed = str
        }

        @doing_it = lambda{
          Debunker.start(self, :input => StringIO.new("Object::TEST_AFTER_RAISE=1\nexit-all\n"), :output => StringIO.new)
          putsed
        }
      end

      after do
        Object.remove_const(:TEST_BEFORE_RAISE)
        Object.remove_const(:TEST_AFTER_RAISE)
        (class << Debunker; undef_method :puts; end)
      end

      it "should not raise exceptions" do
        expect(&@doing_it).to_not raise_error
      end

      it "should continue to run debunker" do
        @doing_it[]
        expect(Object.const_defined?(:TEST_BEFORE_RAISE)).to eq true
        expect(Object.const_defined?(:TEST_AFTER_RAISE)).to eq true
      end

      it "should output an error" do
        expect(@doing_it.call.split("\n").first).to match(
          %r{Error loading .*spec/fixtures/testrcbad: messin with ya}
        )
      end
    end
  end
end
