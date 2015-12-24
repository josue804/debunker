require_relative '../helper'

describe "reload_code" do
  describe "reload_current_file" do
    it 'raises an error source code not found' do
      expect do
        eval <<-RUBY, TOPLEVEL_BINDING, 'does_not_exist.rb', 1
          debunker_eval(binding, "reload-code")
        RUBY
      end.to raise_error(Debunker::CommandError)
    end

    it 'raises an error when class not found' do
      expect do
        debunker_eval(
          "cd Class.new(Class.new{ def goo; end; public :goo })",
          "reload-code")
      end.to raise_error(Debunker::CommandError)
    end

    it 'reloads debunker commmand' do
      expect(debunker_eval("reload-code reload-code")).to match(/reload-code was reloaded!/)
    end

    it 'raises an error when debunker command not found' do
      expect do
        debunker_eval(
          "reload-code not-a-real-command")
      end.to raise_error(Debunker::CommandError, /Cannot locate not-a-real-command!/)
    end
  end
end
