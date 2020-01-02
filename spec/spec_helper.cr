require "spec"

class String
  class Builder < IO
    def clear
      @buffer = GC.malloc_atomic(capacity.to_u32).as(UInt8*)
      @bytesize = 0
      @finished = false
    end
  end

  # Cuts `self` down to multiple pieces of size *size* and returns them as an array.
  #
  # ```
  # "hello world".pieces(2) # => ["he", "ll", "o ", "wo", "rl", "d"]
  # ```
  def pieces(of size)
    pieces = [] of String
    io = String::Builder.new
    i = 0
    self.each_char do |char|
      if i == size
        pieces << io.to_s
        io.clear
        i = 0
      end
      io << char
      i += 1
    end
    pieces << io.to_s if !io.empty?
    pieces
  end
end

def buffer
  string = String.build do |io|
    Lime.buffer.each do |char|
      io << char
    end
  end

  buffer = string.pieces(Window.width_cells)
  Lime.clear

  skip = true
  buffer.compact_map do |line|
    line = line.rstrip(' ')
    skip = false if !line.empty?
    next line if skip || !line.empty?
  end.join('\n')
end
