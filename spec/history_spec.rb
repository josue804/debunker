require_relative 'helper'
require 'tempfile'

describe Debunker do
  before do
    Debunker.history.clear

    @saved_history = "1\n2\n3\n"

    Debunker.history.loader = proc do |&blk|
      @saved_history.lines.each { |l| blk.call(l) }
    end

    Debunker.load_history
  end

  after do
    Debunker.history.clear
    Debunker.history.restore_default_behavior
    Debunker.history.instance_variable_set(:@original_lines, 0)
  end

  describe '#push' do
    it "does not record duplicated lines" do
      Debunker.history << '3'
      Debunker.history << '_ += 1'
      Debunker.history << '_ += 1'
      expect(Debunker.history.to_a.grep('_ += 1').count).to eq 1
    end

    it "does not record empty lines" do
      c = Debunker.history.to_a.count
      Debunker.history << ''
      expect(Debunker.history.to_a.count).to eq c
    end
  end

  describe "#clear" do
    before do
      @old_file = Debunker.config.history.file
      @hist_file_path = File.expand_path('spec/fixtures/debunker_history')
      Debunker.config.history.file = @hist_file_path
      Debunker.history.clear
      Debunker.history.restore_default_behavior
      Debunker.load_history
    end

    after do
      Debunker.config.history.file = @old_file
    end

    it "clears this session's history" do
      expect(Debunker.history.to_a.size).to be > 0
      Debunker.history.clear
      expect(Debunker.history.to_a.size).to eq 0
      expect(Debunker.history.original_lines).to eq 0
    end

    it "doesn't affect the contents of the history file" do
      expect(Debunker.history.to_a.size).to eq 3
      Debunker.history.clear

      File.open(@hist_file_path, 'r') { |fh|
        file = fh.to_a

        expect(file.length).to eq 3
        expect(file.any? { |a| a =~ /athos/ }).to eq true
      }
    end
  end

  describe "#history_line_count" do
    it "counts entries in history" do
      Debunker.history.clear
      saved_history = "olgierd\ngustlik\njanek\ngrzes\ntomek\n"
      Debunker.history.loader = proc do |&blk|
        saved_history.lines.each { |l| blk.call(l) }
      end
      Debunker.load_history

      expect(Debunker.history.history_line_count).to eq 5
    end
  end

  describe "#restore_default_behavior" do
    it "restores loader" do
      Debunker.history.loader = proc {}
      Debunker.history.restore_default_behavior
      expect(Debunker.history.loader.class).to eq Method
      expect(Debunker.history.loader.name.to_sym).to eq :read_from_file
    end

    it "restores saver" do
      Debunker.history.saver = proc {}
      Debunker.history.restore_default_behavior
      expect(Debunker.history.saver.class).to eq Method
      expect(Debunker.history.saver.name.to_sym).to eq :save_to_file
    end

    it "restores pusher" do
      Debunker.history.pusher = proc {}
      Debunker.history.restore_default_behavior
      expect(Debunker.history.pusher.class).to eq Method
      expect(Debunker.history.pusher.name.to_sym).to eq :push_to_readline
    end

    it "restores clearer" do
      Debunker.history.clearer = proc {}
      Debunker.history.restore_default_behavior
      expect(Debunker.history.clearer.class).to eq Method
      expect(Debunker.history.clearer.name.to_sym).to eq :clear_readline
    end
  end

  describe "#session_line_count" do
    it "returns the number of lines in history from just this session" do
      Debunker.history << 'you?'
      Debunker.history << 'you are so precious'
      expect(Debunker.history.session_line_count).to eq 2
    end
  end

  describe ".load_history" do
    it "reads the contents of the file" do
      expect(Debunker.history.to_a[-2..-1]).to eq %w(2 3)
    end
  end

  describe "saving to a file" do
    before do
      @histfile = Tempfile.new(["debunkerhistory", "txt"])
      @history = Debunker::History.new(:file_path => @histfile.path)
      Debunker.config.history.should_save = true
      @history.pusher = proc{ }
    end

    after do
      @histfile.close(true)
      Debunker.config.history.should_save = false
    end

    it "saves lines to a file as they are written" do
      @history.push "5"
      expect(File.read(@histfile.path)).to eq "5\n"
    end

    it "interleaves lines from many places" do
      @history.push "5"
      File.open(@histfile.path, 'a'){ |f| f.puts "6" }
      @history.push "7"

      expect(File.read(@histfile.path)).to eq "5\n6\n7\n"
    end
  end

  describe "expanding the history file path" do
    before { Debunker.config.history.should_save = true  }
    after  { Debunker.config.history.should_save = false }

    it "recognizes ~ (#1262)" do
      # This is a pretty dumb way of testing this, but at least it shouldn't
      # succeed spuriously.
      history = Debunker::History.new(file_path: '~/test_history')
      error = Class.new(RuntimeError)

      expect(File).to receive(:open).
        with(File.join(ENV['HOME'].to_s, "/test_history"), 'a', 0600).
        and_raise(error)

      expect { history.push 'a line' }.to raise_error error
    end
  end
end
