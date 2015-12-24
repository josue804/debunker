require_relative 'basic_object'
class Debunker::Config < Debunker::BasicObject
  require_relative 'config/behavior'
  require_relative 'config/default'
  require_relative 'config/convenience'
  include Debunker::Config::Behavior

  def self.shortcuts
    Convenience::SHORTCUTS
  end
end
