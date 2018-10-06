require "colorize"
require "./lime/modules"

struct Colorize::Object
  getter fore, back
end

module Lime
  extend self

  @@empty_buffer = Array(Char | Colorize::Object(Char)).new(Window.width*Window.height) { ' ' }
  @@buffer : Array(Char | Colorize::Object(Char)) = @@empty_buffer.dup

  # Waits until a key has been pressed and returns it.
  def get_key_raw : String
    STDIN.raw do |io|
      buffer = Bytes.new(3)
      String.new(buffer[0, io.read(buffer)])
    end
  end

  private KEYS = {
    {:enter, "enter"},
    {:up, "up arrow"}, {:down, "down arrow"},
    {:left, "left arrow"}, {:right, "right arrow"},
    {:tab, "tab"},
    {:backspace, "backspace"},
    {:escape, "escape"},
    {:ctrl_c, "Ctrl+C"},
  }

  private KEY_BODY = <<-KEY_BODY
    when "\\r", "\\n"
      :enter
    when "\\e[A"
      :up
    when "\\e[B"
      :down
    when "\\e[C"
      :right
    when "\\e[D"
      :left
    when "\t"
      :tab
    when "\\u{7f}", "\\b"
      :backspace
    when "\\e"
      :escape
    when "\\u{3}"
      :ctrl_c
    else
      key
    end
  KEY_BODY

  {% begin %}
    # Waits until a key has been pressed and returns
    {% for value in KEYS %}
    # - `{{value[0]}}` if {{value[1].id}} has been pressed.
    {% end %}
    #
    # If none of the above keys are pressed, the key is returned as is.
    def get_key : Symbol | String
      case key = get_key_raw
      {{KEY_BODY.id}}
    end

    # Checks if a key is pressed, if it is, returns
    {% for value in KEYS %}
    # - `{{value[0]}}` if {{value[1].id}} has been pressed.
    {% end %}
    #
    # If none of the above keys are pressed, the key is returned as is.
    #
    # If no key is pressed, returns `nil`.
    def check_key : String?
      case key = check_key_raw
      {{KEY_BODY.id}}
    end
  {% end %}

  # Checks if a key is pressed, if it is, returns it, otherwise returns `nil`.
  def check_key_raw : String?
    STDIN.raw do |io|
      io.read_timeout = 0.1
      buffer = Bytes.new(3)
      String.new(buffer[0, io.read(buffer)])
    end
  rescue IO::Timeout
  end

  # Inserts *char* into the buffer at *x*, *y*.
  def print(char : Char | Colorize::Object(Char), x, y)
    @@buffer[x + Window.width * y] = char
  end

  # Inserts *string* into the buffer at *x*, *y*.
  def print(string : String, x, y)
    string.each_char_with_index do |char, i|
      @@buffer[x + i + Window.width * y] = char
    end
  end

  # :ditto:
  def print(string : Colorize::Object(String), x, y)
    fore = string.fore
    back = string.back
    string = string.to_s
    if fore == Colorize::ColorANSI::Default && back == Colorize::ColorANSI::Default
      Lime.print(string, x, y)
    else
      string = string[string.index('m').not_nil! + 1..string.rindex('\e').not_nil! - 1]
      string.each_char_with_index do |char, i|
        @@buffer[x + i + (y*Window.width)] = char.colorize.fore(fore).back(back)
      end
    end
  end

  # Inserts *string* formatted into the buffer at *x*, *y*.
  #
  # This method properly handles newlines in the string unlike `print`:
  # ```
  # Lime.printf("hello\nworld", 2, 2)
  # ```
  # ```text
  #
  #
  #     hello
  #     world
  # ```
  def printf(string : String, x, y)
    i = 0
    string.each_line do |line|
      Lime.print(line, x, y + i)
      i += 1
    end
  end

  # :ditto:
  def printf(string : Colorize::Object(String), x, y)
    fore = string.fore
    back = string.back
    string = string.to_s

    if fore == Colorize::ColorANSI::Default && back == Colorize::ColorANSI::Default
      Lime.printf(string, x, y)
    else
      string = string[string.index('m').not_nil! + 1..string.rindex('\e').not_nil! - 1]
      i = 0
      string.each_line do |line|
        Lime.print(line.colorize.fore(fore).back(back), x, y + i)
        i += 1
      end
    end
  end

  # Clears the buffer.
  def clear
    # Instead of rebuilding the whole buffer every time again, copy the empty buffer
    @@buffer = @@empty_buffer.dup
  end

  # Returns the buffer as a string.
  def buffer : String
    String.build do |io|
      @@buffer.each do |char|
        io << char
      end
    end
  end

  # Returns the buffer as an array of characters.
  def raw_buffer : Array(Char | Colorize::Object(Char))
    @@buffer
  end

  # Draws the buffer to the screen.
  def draw
    print(Lime.buffer)
  end

  # Like a game loop.
  # The order is as follows:
  #
  # **1.** Execute the given block.
  #
  # **2.** Draw the buffer to the screen.
  #
  # **3.** Clear the buffer.
  def loop
    ::loop do
      yield
      Lime.draw
      Lime.clear
    end
  end

  # Inserts a block (`▀`) at *x*, *y* with *color* into the buffefr.
  def pixel(x, y, color : Colorize::Color = Colorize::ColorANSI::Default)
    position = x + (y/2)*Window.width

    if color == Colorize::ColorANSI::Default
      default_pixel(position, y)
      return
    end

    @@buffer[position] = (if y.even?
      if @@buffer[position].to_s.includes?('▄')
        if char = @@buffer[position].as?(Colorize::Object(Char))
          char.back(color)
        else
          @@buffer[position].as(Char).colorize.back(color)
        end
      else
        if char = @@buffer[position].as?(Colorize::Object(Char))
          '▀'.colorize(color).back(char.back)
        else
          '▀'.colorize(color)
        end
      end
    else
      if @@buffer[position].to_s.includes?('▀')
        if char = @@buffer[position].as?(Colorize::Object(Char))
          char.back(color)
        else
          @@buffer[position].as(Char).colorize.back(color)
        end
      else
        if char = @@buffer[position].as?(Colorize::Object(Char))
          '▄'.colorize(color).back(char.back)
        else
          '▄'.colorize(color)
        end
      end
    end)
  end

  private def default_pixel(position, y)
    @@buffer[position] = (if y.even?
      if @@buffer[position].to_s.includes?('▄')
        if char = @@buffer[position].as?(Colorize::Object(Char))
          '▀'.colorize.back(char.fore)
        else
          '█'
        end
      elsif @@buffer[position].to_s.includes?('█')
        if char = @@buffer[position].as?(Colorize::Object(Char))
          '▄'.colorize.back(char.fore)
        else
          '█'
        end
      else
        if char = @@buffer[position].as?(Colorize::Object(Char))
          '▀'.colorize.back(char.back)
        else
          '▀'
        end
      end
    else
      if @@buffer[position].to_s.includes?('▀')
        if char = @@buffer[position].as?(Colorize::Object(Char))
          '▄'.colorize.back(char.fore)
        else
          '█'
        end
      elsif @@buffer[position].to_s.includes?('█')
        if char = @@buffer[position].as?(Colorize::Object(Char))
          '▄'.colorize.back(char.fore)
        else
          '█'
        end
      else
        if char = @@buffer[position].as?(Colorize::Object(Char))
          '▄'.colorize.back(char.back)
        else
          '▄'
        end
      end
    end)
  end

  # Inserts a line from *x0*, *y0* to *x1*, *y1* with *color* into the buffer.
  #
  # This method uses [Bresenham's line algorithm](https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm).
  def line(x0, y0, x1, y1, color : Colorize::Color = Colorize::ColorANSI::Default)
    if (y1 - y0).abs < (x1 - x0).abs
      if x1 > x1
        Lime.line_low(x1, y1, x0, y0, color)
      else
        Lime.line_low(x0, y0, x1, y1, color)
      end
    else
      if y0 > y1
        Lime.line_high(x1, y1, x0, y0, color)
      else
        Lime.line_high(x0, y0, x1, y1, color)
      end
    end
  end

  # :nodoc:
  def line_low(x0, y0, x1, y1, color)
    dx = x1 - x0
    dy = y1 - y0
    yi = 1
    if dy < 0
      yi = -1
      dy = -dy
    end
    d = 2*dy - dx
    y = y0

    (x0..x1).each do |x|
      Lime.pixel(x, y, color)
      if d > 0
        y = y + yi
        d = d - 2*dx
      end
      d = d + 2*dy
    end
  end

  # :nodoc:
  def line_high(x0, y0, x1, y1, color)
    dx = x1 - x0
    dy = y1 - y0
    xi = 1
    if dx < 0
      xi = -1
      dx = -dx
    end
    d = 2*dx - dy
    x = x0

    (y0..y1).each do |y|
      Lime.pixel(x, y, color)
      if d > 0
        x = x + xi
        d = d - 2*dy
      end
      d = d + 2*dx
    end
  end
end

require "../lime/drawables"
include Lime::Drawables
Rectangle
