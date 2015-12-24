# These specs ensure that Debunker doesn't require readline until the first time a
# REPL is started.

require "helper"
require "shellwords"

describe "Readline" do
  before do
    @ruby    = RbConfig.ruby.shellescape
    @debunker_dir = File.expand_path(File.join(__FILE__, '../../../lib')).shellescape
  end

  it "is not loaded on requiring 'debunker'" do
    code = <<-RUBY
      require "debunker"
      p defined?(Readline)
    RUBY
    expect(`#@ruby -I #@debunker_dir -e '#{code}'`).to eq("nil\n")
  end

  it "is loaded on invoking 'debunker'" do
    code = <<-RUBY
      require "debunker"
      Debunker.start self, input: StringIO.new("exit-all"), output: StringIO.new
      puts defined?(Readline)
    RUBY
    expect(`#@ruby -I #@debunker_dir -e '#{code}'`.end_with?("constant\n")).to eq(true)
  end

  it "is not loaded on invoking 'debunker' if Debunker.input is set" do
    code = <<-RUBY
      require "debunker"
      Debunker.input = StringIO.new("exit-all")
      Debunker.start self, output: StringIO.new
      p defined?(Readline)
    RUBY
    expect(`#@ruby -I #@debunker_dir -e '#{code}'`.end_with?("nil\n")).to eq(true)
  end
end
