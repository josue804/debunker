class Debunker::Output
  attr_reader :_debunker_

  def initialize(_debunker_)
    @_debunker_ = _debunker_
    @boxed_io = _debunker_.config.output
  end

  def puts(*objs)
    return print "\n" if objs.empty?
    objs.each do |obj|
      if ary = Array.try_convert(obj)
        puts(*ary)
      else
        print "#{obj.to_s.chomp}\n"
      end
    end
    nil
  end

  def print(*objs)
    objs.each do |obj|
      @boxed_io.print decolorize_maybe(obj.to_s)
    end
    nil
  end
  alias << print
  alias write print

  def tty?
    @boxed_io.respond_to?(:tty?) and @boxed_io.tty?
  end

  def method_missing(name, *args, &block)
    @boxed_io.__send__(name, *args, &block)
  end

  def respond_to_missing?(*a)
    @boxed_io.respond_to?(*a)
  end

  def decolorize_maybe(str)
    if _debunker_.config.color
      str
    else
      Debunker::Helpers::Text.strip_color str
    end
  end
end
