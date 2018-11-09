module Lime
  # The window of the console.
  module Window
    extend self

    # :nodoc:
    class_getter width_cells : Int32 = `tput cols`.to_i

    # :nodoc:
    class_getter height_cells : Int32 = `tput lines`.to_i

    # Returns the width of the window in cells.
    class_getter width : Int32 = @@width_cells - 1

    # Returns the height of the window in cells.
    class_getter height : Int32 = @@height_cells - 1

    # Returns the width of the window in pixels.
    def self.width_pixels
      @@width
    end

    # Returns the height of the window in pixels.
    class_getter height_pixels : Int32 = @@height*2

    # Updates the values of `width`, `height` and
    # `width_pixels`, `height_pixels`.
    def update
      @@width_cells = `tput cols`.to_i
      @@height_cells = `tput lines`.to_i
      @@width = @@width_cells - 1
      @@height = @@height_cells - 1
      @@height_pixels = @@height*2
    end

    # Sets the title of the window to *title*.
    def title=(title)
      print "\e]0;#{title}\a"
    end

    # Disables or enables the alternative buffer which doesn't has a scrollbar.
    def scrollbar=(scrollbar : Bool)
      system(scrollbar ? "tput rmcup" : "tput smcup")
    end
  end

  # The cursor of the console.
  module Cursor
    extend self

    # Moves the cursor up by *cells* cells.
    def move_up(cells = 1)
      print "\e[#{cells}A"
    end

    # Moves the cursor down by *cells* cells.
    def move_down(cells = 1)
      print "\e[#{cells}B"
    end

    # Moves the cursor right by *cells* cells.
    def move_right(cells = 1)
      print "\e[#{cells}C"
    end

    # Moves the cursor left by *cells* cells.
    def move_left(cells = 1)
      print "\e[#{cells}D"
    end

    # Shows or hides the cursor.
    def visible=(visible : Bool)
      print(visible ? "\e[?25h" : "\e[?25l")
    end

    # Sets the position of the cursor to *position*.
    # ```
    # Lime::Cursor.position = {5, 5}
    # ```
    def position=(position : Tuple(Int32, Int32))
      # Row and column for the ANSI escape sequence need to be one-based
      print "\e[#{position[1] + 1};#{position[0] + 1}H"
    end
  end

  # The mouse pointer.
  module Mouse
    extend self

    # Returns `true` if the mouse event report range is extended, otherwise `false`.
    class_getter extended = false

    # Returns the current mouse event report mode.
    class_getter mode : Mode = Mouse::Mode::Off

    # The mouse event report mode.
    #
    # The default mode is `Off`.
    enum Mode
      # Reports only mouse click events.
      Click

      # Reports only mouse drag events.
      Drag

      # Reports all mouse events: movements, clicks and drags.
      All

      # Reports no mouse events.
      Off
    end

    # Sets the mouse event report mode to *mode*.
    def mode=(@@mode : Mode)
      case mode
      when .click?
        print "\e[?1000h"
      when .drag?
        print "\e[?1002h"
      when .all?
        print "\e[?1003h"
      when .off?
        off
      end
    end

    private def off
      case mode
      when .click?
        print "\e[?1000l"
      when .drag?
        print "\e[?1002l"
      when .all?
        print "\e[?1003l"
      end
    end

    at_exit do
      off
      print "\e[?1006l" if @@extended
    end

    # Extends the mouse event report range if *bool* is `true`, otherwise resets the range.
    #
    # The default X10 mouse protocol doesn't support mouse event reporting with
    # x, y coordinates greater than 94.
    # This extends the range to be greater than 94 by using the 1006 SGR (Select Graphic Rendition) mouse protocol.
    def extend(bool = true) # The argument can't be named `extend` since it's a keyword
      if bool
        print "\e[?1006h"
        @@extended = true
      else
        print "\e[?1006l"
        @@extended = false
      end
    end

    # A mouse event.
    record Event, x : Int32, y : Int32, type : Symbol do
      # Returns the type of mouse event.
      #
      # * `:release` if a mouse button has been released.
      # * `:move` if the mouse has been moved.
      #
      # * `:left` if the left mouse button has been pressed.
      # * `:wheel` if the mouse wheel button has been pressed.
      # * `:right` if the right mouse button has been pressed.
      #
      # * `:wheel_up` if the mouse wheel has been scrolled up.
      # * `:wheel_down` if the mouse wheel has been scrolled down.
      #
      # Only if `Mouse.mode` is `Mode::Drag` or `Mode::All`:
      #
      # * `:left_drag` if the left mouse button has been pressed and the mouse has been moved.
      # * `:wheel_drag` if the mouse wheel button has been pressed and the mouse has been moved.
      # * `:right_drag` if the right mouse button has been pressed and the mouse has been moved.
      getter type : Symbol

      # Returns the kind of mouse event based on `type`.
      #
      # * `:release` if a mouse button has been released.
      # * `:move` if the mouse has been moved.
      #
      # * `:click` if a mouse button has been pressed.
      # * `:wheel` if the wheel has been scrolled.
      # * `:drag` if a mouse button has been pressed and the mouse has been moved.
      def kind : Symbol
        case type
        when :left, :wheel, :right
          :click
        when :left_drag, :wheel_drag, :right_drag
          :drag
        when :wheel_up, :wheel_down
          :wheel
        when :release
          :release
        else
          :move
        end
      end
    end

    # Waits for input and returns `Event` if the input is a mouse event,
    # `nil` if the input is not a mouse event or if `mode` is `Mode::Off`.
    def get : Event?
      return nil if mode.off?

      return get_1006 if @@extended

      input = STDIN.raw do |io|
        string = String.new(io.peek)
        io.skip(string.size)
        string
      end

      return nil unless input.starts_with?('\e')

      type = case input[3]
             when ' ' then :left
             when '!' then :wheel
             when '"' then :right
             when '@' then :left_drag
             when 'A' then :wheel_drag
             when 'B' then :right_drag
             when '#' then :release
             when '`' then :wheel_up
             when 'a' then :wheel_down
             else          :move
             end

      # 32 to decode the character, 1 more to make the number zero-based
      Event.new(input[4].ord - 33, input[5].ord - 33, type)
    end

    # Returns the mouse event happening in the moment this method is called as `Event`,
    # `nil` if the input is not a mouse event or if `mode` is `Mode::Off`.
    def peek : Event?
      STDIN.read_timeout = 0.01
      get
    rescue IO::Timeout
    ensure
      STDIN.read_timeout = nil
    end

    # :nodoc:
    def get_1006 : Event?
      input = STDIN.raw do |io|
        string = String.new(io.peek)
        io.skip(string.size)
        string
      end

      if input
        return nil unless input.starts_with?('\e')
      else
        return nil
      end

      release = input.ends_with?('m')

      input = input.lchop("\e[<").rchop.split(';')

      if release
        type = :release
      else
        type = case input[0]
               when "0"  then :left
               when "1"  then :wheel
               when "2"  then :right
               when "64" then :wheel_up
               when "65" then :wheel_down
               when "32" then :left_move
               when "33" then :wheel_move
               when "34" then :right_move
               else           :move
               end
      end

      Event.new(input[1].to_i - 1, input[2].to_i - 1, type)
    end
  end
end
