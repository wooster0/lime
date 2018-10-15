require "colorize"
require "./lime/modules"

struct Colorize::Object
  getter fore, back
end

# The main module of lime.
#
# All x, y arguments are zero-based.
#
# Sometimes you may come across the terms "cell" and "pixel":
# * A "cell" refers to one place of a character on the console: `█`.
# * A "pixel" **does not** refer to a pixel of a display.
#   It refers to the **half** of a "cell": `▀`, `▄`.
module Lime
  extend self

  @@empty_buffer = Array(Char | Colorize::Object(Char)).new(Window.width_cells*Window.height_cells) { ' ' }
  @@buffer : Array(Char | Colorize::Object(Char)) = @@empty_buffer.dup

  private KEYS = {
    {:up, "up arrow"}, {:down, "down arrow"},
    {:left, "left arrow"}, {:right, "right arrow"},
    {:enter, "enter"},
    {:tab, "tab"},
    {:backspace, "backspace"},
    {:escape, "escape"},
    {:ctrl_c, "Ctrl+C"},
  }

  private KEY_BODY = <<-KEY_BODY
    when "\\e[A"
      :up
    when "\\e[B"
      :down
    when "\\e[C"
      :right
    when "\\e[D"
      :left
    when "\\r", "\\n"
      :enter
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
    # Waits until a key has been pressed.
    # Returns
    {% for value in KEYS %}
    # - `{{value[0]}}` if {{value[1].id}} has been pressed.
    {% end %}
    #
    # If none of the above keys are pressed, the key is returned as is.
    #
    # NOTE: Ctrl+C is caught by this method and will not be handled by the system.
    def get_key : Symbol | String
      case key = get_key_raw
      {{KEY_BODY.id}}
    end

    # Checks if a key is pressed.
    # Returns
    {% for value in KEYS %}
    # - `{{value[0]}}` if {{value[1].id}} has been pressed.
    {% end %}
    #
    # If none of the above keys are pressed, the key is returned as is.
    #
    # If no key is pressed, returns `nil`.
    def check_key : Symbol | String | Nil
      case key = check_key_raw
      {{KEY_BODY.id}}
    end
  {% end %}

  # Waits until a key has been pressed and returns it.
  #
  # NOTE: Ctrl+C is caught by this method and will not be handled by the system.
  def get_key_raw : String
    STDIN.raw do |io|
      buffer = Bytes.new(3)
      String.new(buffer[0, io.read(buffer)])
    end
  end

  # Checks if a key is pressed, if it is, returns it, otherwise returns `nil`.
  def check_key_raw : String?
    STDIN.raw do |io|
      io.read_timeout = 0.01
      buffer = Bytes.new(3)
      String.new(buffer[0, io.read(buffer)])
    rescue IO::Timeout
    ensure
      io.read_timeout = nil
    end
  end

  # Inserts *char* into the buffer at *x*, *y*.
  def print(char : Char | Colorize::Object(Char), x : Int32, y : Int32)
    @@buffer[x + Window.width_cells * y] = char
  end

  # Inserts *string* into the buffer at *x*, *y*.
  def print(string : String, x : Int32, y : Int32)
    string.each_char_with_index do |char, i|
      @@buffer[x + i + Window.width_cells * y] = char
    end
  end

  # :ditto:
  def print(string : Colorize::Object(String), x : Int32, y : Int32)
    fore = string.fore
    back = string.back
    string = string.to_s
    if fore == Colorize::ColorANSI::Default && back == Colorize::ColorANSI::Default
      Lime.print(string, x, y)
    else
      string = string[string.index('m').not_nil! + 1..string.rindex('\e').not_nil! - 1]
      string.each_char_with_index do |char, i|
        @@buffer[x + i + (y*Window.width_cells)] = char.colorize.fore(fore).back(back)
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
  def printf(string : String, x : Int32, y : Int32)
    i = 0
    string.each_line do |line|
      Lime.print(line, x, y + i)
      i += 1
    end
  end

  # :ditto:
  def printf(string : Colorize::Object(String), x : Int32, y : Int32)
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
  # **1.** Executes the given block.
  #
  # **2.** Draws the buffer to the screen.
  #
  # **3.** Clears the buffer.
  def loop
    ::loop do
      yield
      Lime.draw
      Lime.clear
    end
  end

  # Inserts a pixel at *x*, *y* with *color* into the buffer.
  def pixel(x : Int32, y : Int32, color : Colorize::Color = Colorize::ColorANSI::Default)
    position = x + (y/2)*Window.width_cells

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

  # Inserts a line from *x1*, *y1* to *x2*, *y2* with *color* into the buffer.
  #
  # This method uses [Bresenham's line algorithm](https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm).
  def line(x1 : Int32, y1 : Int32,
           x2 : Int32, y2 : Int32, color : Colorize::Color = Colorize::ColorANSI::Default)
    if (y2 - y1).abs < (x2 - x1).abs
      if x2 > x2
        Lime.line_low(x2, y2, x1, y1, color)
      else
        Lime.line_low(x1, y1, x2, y2, color)
      end
    else
      if y1 > y2
        Lime.line_high(x2, y2, x1, y1, color)
      else
        Lime.line_high(x1, y1, x2, y2, color)
      end
    end
  end

  # :nodoc:
  def line_low(x1, y1, x2, y2, color)
    dx = x2 - x1
    dy = y2 - y1
    yi = 1
    if dy < 0
      yi = -1
      dy = -dy
    end
    d = 2*dy - dx
    y = y1

    (x1..x2).each do |x|
      Lime.pixel(x, y, color)
      if d > 0
        y = y + yi
        d = d - 2*dx
      end
      d = d + 2*dy
    end
  end

  # :nodoc:
  def line_high(x1, y1, x2, y2, color)
    dx = x2 - x1
    dy = y2 - y1
    xi = 1
    if dx < 0
      xi = -1
      dx = -dx
    end
    d = 2*dx - dy
    x = x1

    (y1..y2).each do |y|
      Lime.pixel(x, y, color)
      if d > 0
        x = x + xi
        d = d - 2*dy
      end
      d = d + 2*dx
    end
  end
end
