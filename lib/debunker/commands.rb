# Default commands used by Debunker.
Debunker::Commands = Debunker::CommandSet.new

Dir[File.expand_path('../commands', __FILE__) << '/*.rb'].each do |file|
  require file
end
