require_relative '../helper'

describe "exit-program" do
  it 'should raise SystemExit' do
    expect { debunker_eval('exit-program') }.to raise_error SystemExit
  end

  it 'should exit the program with the provided value' do
    begin
      debunker_eval 'exit-program 66'
    rescue SystemExit => e
      expect(e.status).to eq(66)
    else
      raise "Failed to raise SystemExit"
    end
  end
end
