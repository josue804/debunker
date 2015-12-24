require_relative '../helper'

describe "exit" do
  before { @debunker = Debunker.new(:target => :outer, :output => StringIO.new) }

  it "should pop a binding" do
    @debunker.eval "cd :inner"
    expect(@debunker.evaluate_ruby("self")).to eq :inner
    @debunker.eval "exit"
    expect(@debunker.evaluate_ruby("self")).to eq :outer
  end

  it "should break out of the repl when binding_stack has only one binding" do
    expect(@debunker.eval("exit")).to equal false
    expect(@debunker.exit_value).to equal nil
  end

  it "should break out of the repl and return user-given value" do
    expect(@debunker.eval("exit :john")).to equal false
    expect(@debunker.exit_value).to eq :john
  end

  it "should break out of the repl even after an exception" do
    @debunker.eval "exit = 42"
    expect(@debunker.output.string).to match(/^SyntaxError/)
    expect(@debunker.eval("exit")).to equal false
  end
end
