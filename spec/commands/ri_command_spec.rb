require_relative '../helper'
describe "ri" do
  it "prints an error message without an argument" do
    expect(debunker_eval("ri")).to include("Please provide a class, module, or method name (e.g: ri Array#push)")
  end
end
