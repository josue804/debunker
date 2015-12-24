require_relative 'helper'

describe "Debunker.config.exception_whitelist" do
  before do
    @str_output = StringIO.new
  end

  it 'should rescue all exceptions NOT specified on whitelist' do
    expect(Debunker.config.exception_whitelist.include?(NameError)).to eq false
    expect { Debunker.start(self, :input => StringIO.new("raise NameError\nexit"), :output => @str_output) }.not_to raise_error
  end

  it 'should NOT rescue exceptions specified on whitelist' do
    old_whitelist = Debunker.config.exception_whitelist
    Debunker.config.exception_whitelist = [NameError]
    expect { Debunker.start(self, :input => StringIO.new("raise NameError"), :output => @str_output) }.to raise_error NameError
    Debunker.config.exception_whitelist = old_whitelist
  end
end


