require "colorize"
require "./lime/drawables"
require "./lime/modules"

struct Colorize::Object
  getter fore, back
end

# The main module of lime.
#
# All `x` and `y` arguments are zero-based.
#
# An `IndexError` will be raised if:
# * An `x` argument is greater than `Window.width`.
# * An `x` argument is lower than `-Window.width_cells`.
# * A `y` argument is greater than `Window.height`.
# * A `y` argument is lower than `-Window.height_cells`.
#
# NOTE: Sometimes you might come across the terms "cell" and "pixel":
# * A "cell" refers to one place of a character on the console: `█`.
# * A "pixel" **does not** refer to a pixel of a display.
#   It refers to the **half** of a "cell": `▀`, `▄` (also called a "half block").
module Lime
  extend self

  @@buffer = Array(Char | Colorize::Object(Char)).new(Window.width_cells*Window.height_cells) { ' ' }

  # Sets the height of the buffer to *height*.
  def bufferHeight=(height)
    count = Window.width_cells*height
    if height > @@buffer.size/Window.width_cells
      count.times do
        @@buffer << ' '
      end
    else
      @@buffer.shift(count)
    end
  end

  # Returns the content of the buffer as a string.
  def buffer : String
    String.build do |io|
      @@buffer.each do |char|
        io << char
      end
    end
  end

  # Sets the buffer to *buffer*.
  def buffer=(@@buffer : Array(Char | Colorize::Object(Char)))
  end

  # Returns the character of the buffer at *x*, *y*.
  def buffer(x, y) : Char | Colorize::Object(Char)
    @@buffer[x + Window.width_cells * y]
  end

  # Returns the buffer as an array of characters.
  def raw_buffer : Array(Char | Colorize::Object(Char))
    @@buffer
  end

  # Draws the content of the buffer to the screen.
  def draw
    print(Lime.buffer)
  end

  # Clears the buffer.
  def clear
    @@buffer.fill { ' ' }
  end

  # Waits until a key has been pressed and returns it.
  #
  # NOTE: Ctrl+C is caught by this method and will not be handled by the system.
  def get_key_raw : String
    STDIN.raw do |io|
      bytes = Bytes.new(3)
      String.new(bytes[0, io.read(bytes)])
    end
  end

  # Returns the key that is down in the moment this method is called or `nil` if no key is down.
  #
  # NOTE: Ctrl+C is caught by this method and will not be handled by the system.
  def peek_key_raw : String?
    STDIN.read_timeout = 0.01
    get_key_raw
  rescue IO::Timeout
  ensure
    STDIN.read_timeout = nil
  end

  # TODO: remove these nodocs and the nodoc in Pixels after 0.27.2

  # :nodoc:
  private KEYS = {
    {:up, "up arrow"}, {:down, "down arrow"},
    {:left, "left arrow"}, {:right, "right arrow"},
    {:enter, "enter"},
    {:tab, "tab"},
    {:backspace, "backspace"},
    {:escape, "escape"},
    {:ctrl_c, "Ctrl+C"},
  }

  # :nodoc:
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
    # Waits until a key has been pressed and returns it compactly as a symbol.
    #
    {% for value in KEYS %}
    # * `{{value[0]}}` if {{value[1].id}} has been pressed.
    {% end %}
    #
    # If none of the above keys are pressed, the key is returned as-is.
    #
    # NOTE: Ctrl+C is caught by this method and will not be handled by the system.
    def get_key : Symbol | String
      case key = get_key_raw
      {{KEY_BODY.id}}
    end

    # Returns the key that is down in the moment this method is called compactly as a symbol or `nil` if no key is down.
    #
    {% for value in KEYS %}
    # * `{{value[0]}}` if {{value[1].id}} is down.
    {% end %}
    #
    # If none of the above keys are down, the key is returned as-is.
    #
    # NOTE: Ctrl+C is caught by this method and will not be handled by the system.
    def peek_key : Symbol | String | Nil
      case key = peek_key_raw
      {{KEY_BODY.id}}
    end
  {% end %}

  # Inserts *char* into the buffer at *x*, *y*.
  def print(char : Char | Colorize::Object(Char), x : Int32, y : Int32)
    @@buffer[x + Window.width_cells * y] = char
  end

  # Inserts *string* into the buffer at *x*, *y*.
  def print(string : String, x : Int32, y : Int32)
    string.each_char_with_index do |char, i|
      Lime.print(char, x + i, y)
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
      # Remove color escape sequences:
      string = string[string.index('m').not_nil! + 1..string.rindex('\e').not_nil! - 1]

      string.each_char_with_index do |char, i|
        Lime.print(char.colorize(fore).back(back), x + i, y)
      end
    end
  end

  # Inserts *string* formatted into the buffer at *x*, *y*.
  #
  # This method properly aligns each line in the string beneath each other.
  #
  # ```
  # Lime.printf("hello\nworld", 2, 2)
  # ```
  # ```text
  #
  #
  #   hello
  #   world
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
      # Remove color escape sequences:
      string = string[string.index('m').not_nil! + 1..string.rindex('\e').not_nil! - 1]

      i = 0
      string.each_line do |line|
        Lime.print(line.colorize.fore(fore).back(back), x, y + i)
        i += 1
      end
    end
  end

  # The order of the loop is as follows:
  #
  # **1.** Executes the given block.
  #
  # **2.** Draws the content of the buffer to the screen.
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
  #
  # ```
  # Lime.pixel(2, 2)
  # ```
  # ```text
  #
  #   ▀
  # ```
  #
  # ```
  # Lime.pixel(2, 2)
  # Lime.pixel(2, 3)
  # ```
  # ```text
  #
  #   █
  # ```
  def pixel(x : Int32, y : Int32, color : Colorize::Color = Colorize::ColorANSI::Default)
    char = Lime.buffer(x, y/2)

    pixel = if y.even?
              if char.to_s == "▀"
                if color == Colorize::ColorANSI::Default
                  '▀'
                else
                  '▀'.colorize(color)
                end
              elsif char.to_s == "█"
                if color == Colorize::ColorANSI::Default
                  '█'
                else
                  '▄'.colorize.back(color)
                end
              elsif char.to_s.includes?('▄')
                if color == Colorize::ColorANSI::Default && char.as(Colorize::Object(Char)).fore == Colorize::ColorANSI::Default
                  '█'
                elsif char.is_a?(Colorize::Object(Char))
                  if color == Colorize::ColorANSI::Default
                    '▀'.colorize.back(char.fore)
                  else
                    char.back(color)
                  end
                else
                  char.as(Char).colorize.back(color)
                end
              else
                if char.is_a?(Colorize::Object(Char))
                  '▀'.colorize(color).back(char.back)
                else
                  '▀'.colorize(color)
                end
              end
            else
              if char.to_s == "▀"
                if color == Colorize::ColorANSI::Default
                  '█'
                else
                  '▀'.colorize.back(color)
                end
              elsif char.to_s == "█"
                if color == Colorize::ColorANSI::Default
                  '█'
                else
                  '▀'.colorize.back(color)
                end
              elsif char.to_s.includes?('▀')
                if color == Colorize::ColorANSI::Default && char.as(Colorize::Object(Char)).fore == Colorize::ColorANSI::Default
                  '█'
                elsif char.is_a?(Colorize::Object(Char))
                  if color == Colorize::ColorANSI::Default
                    '▄'.colorize.back(char.fore)
                  else
                    char.back(color)
                  end
                else
                  char.as(Char).colorize.back(color)
                end
              else
                if char.is_a?(Colorize::Object(Char))
                  '▄'.colorize(color).back(char.back)
                else
                  '▄'.colorize(color)
                end
              end
            end

    Lime.print(pixel, x, y/2)
  end

  # Inserts a line from *x1*, *y1* to *x2*, *y2* with *color* into the buffer.
  #
  # ```
  # Lime.line(0, 0, 5, 5)
  # ```
  # ```text
  # ▀▄
  #   ▀▄
  #     ▀▄
  # ```
  #
  # ```
  # Lime.line(0, 0, 10, 5)
  # ```
  # ```text
  # ▀▀▄▄
  #     ▀▀▄▄
  #         ▀▀▄
  # ```
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
    if dy < 0
      yi = -1
      dy = -dy
    else
      yi = 1
    end
    d = 2*dy - dx
    y = y1
    (x1..x2).each do |x|
      Lime.pixel(x, y, color)
      if d > 0
        y += yi
        d -= 2*dx
      end
      d += 2*dy
    end
  end

  # :nodoc:
  def line_high(x1, y1, x2, y2, color)
    dx = x2 - x1
    dy = y2 - y1
    if dx < 0
      xi = -1
      dx = -dx
    else
      xi = 1
    end
    d = 2*dx - dy
    x = x1
    (y1..y2).each do |y|
      Lime.pixel(x, y, color)
      if d > 0
        x += xi
        d -= 2*dy
      end
      d += 2*dx
    end
  end
end
