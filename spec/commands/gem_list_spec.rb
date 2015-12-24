require_relative '../helper'

describe "gem-list" do
  it 'should not raise when invoked' do
    expect { debunker_eval(self, 'gem-list') }.to_not raise_error
  end

  it 'should work arglessly' do
    list = debunker_eval('gem-list')
    expect(list).to match(/rspec \(/)
  end

  it 'should find arg' do
    debunkerlist = debunker_eval('gem-list method_source')
    expect(debunkerlist).to match(/method_source \(/)
    expect(debunkerlist).not_to match(/rspec/)
  end

  it 'should return non-results as silence' do
    expect(debunker_eval('gem-list aoeuoueouaou')).to be_empty
  end
end
