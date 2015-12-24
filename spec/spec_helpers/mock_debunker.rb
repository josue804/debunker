def mock_debunker(*args)
  args.flatten!
  binding = args.first.is_a?(Binding) ? args.shift : binding()
  options = args.last.is_a?(Hash) ? args.pop : {}

  input = InputTester.new(*args)
  output = StringIO.new

  redirect_debunker_io(input, output) do
    binding.debunker(options)
  end

  output.string
end

# Set I/O streams. Out defaults to an anonymous StringIO.
def redirect_debunker_io(new_in, new_out = StringIO.new)
  old_in = Debunker.config.input
  old_out = Debunker.config.output

  Debunker.config.input = new_in
  Debunker.config.output = new_out
  begin
    yield
  ensure
    Debunker.config.input = old_in
    Debunker.config.output = old_out
  end
end

class InputTester
  def initialize(*actions)
    @orig_actions = actions.dup
    @actions = actions
  end

  def readline(*)
    @actions.shift
  end

  def rewind
    @actions = @orig_actions.dup
  end
end
