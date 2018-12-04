module Lime
  # Modules for interacting with various functionality.
  #
  # The modules are available on the Top Level Namespace by default.
  module Modules
    # The window of the console.
    module Window
      extend self

      # Returns the height of the window in cells, one-based.
      class_getter width_cells : Int32 = `tput cols`.to_i

      # Returns the width of the window in cells, one-based.
      class_getter height_cells : Int32 = `tput lines`.to_i

      # Returns the width of the window in cells, zero-based.
      class_getter width : Int32 = @@width_cells - 1

      # Returns the height of the window in cells, zero-based.
      class_getter height : Int32 = @@height_cells - 1

      # Returns the width of the window in pixels.
      def self.width_pixels
        @@width
      end

      # Returns the height of the window in pixels.
      class_getter height_pixels : Int32 = @@height*2

      # Updates the values of `width`, `height`, `width_cells`, `height_cells` and
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

      # Disables or enables the alternative screen buffer for the console which doesn't have a scrollbar.
      def scrollbar=(scrollbar : Bool)
        system(scrollbar ? "tput rmcup" : "tput smcup")
      end
    end

    # The cursor of the console.
    module Cursor
      extend self

      # Moves the cursor up by *cells*.
      def move_up(cells = 1)
        print "\e[#{cells}A"
      end

      # Moves the cursor down by *cells*.
      def move_down(cells = 1)
        print "\e[#{cells}B"
      end

      # Moves the cursor right by *cells*.
      def move_right(cells = 1)
        print "\e[#{cells}C"
      end

      # Moves the cursor left by *cells*.
      def move_left(cells = 1)
        print "\e[#{cells}D"
      end

      # Shows or hides the cursor.
      def visible=(visible : Bool)
        print(visible ? "\e[?25h" : "\e[?25l")
      end

      # Sets the position of the cursor to *position*.
      # ```
      # Cursor.position = {5, 5}
      # ```
      def position=(position : Tuple(Int32, Int32))
        # Row and column for the ANSI escape sequence need to be one-based
        print "\e[#{position[1] + 1};#{position[0] + 1}H"
      end
    end

    # The mouse pointer.
    #
    # NOTE: The default mouse event report mode is `Mode::Off` which won't report any mouse events.
    # To set a mouse event report mode, use `mode=`.
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
        # Reports no mouse events.
        Off

        # Reports only mouse click events.
        Click

        # Reports only mouse drag events.
        Drag

        # Reports all mouse events: movements, clicks and drags.
        All
      end

      # Sets the mouse event report mode to *mode*.
      def mode=(@@mode : Mode)
        case mode
        when .off?
          off
        when .click?
          print "\e[?1000h"
        when .drag?
          print "\e[?1002h"
        when .all?
          print "\e[?1003h"
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
        #
        # * `:left` if the left mouse button has been pressed.
        # * `:wheel` if the mouse wheel button has been pressed.
        # * `:right` if the right mouse button has been pressed.
        #
        # * `:wheel_up` if the mouse wheel has been scrolled up.
        # * `:wheel_down` if the mouse wheel has been scrolled down.
        #
        # Only if `mode` is `Mode::Drag` or `Mode::All`:
        #
        # * `:left_drag` if the left mouse button has been pressed and the mouse has been moved.
        # * `:wheel_drag` if the mouse wheel button has been pressed and the mouse has been moved.
        # * `:right_drag` if the right mouse button has been pressed and the mouse has been moved.
        #
        # Only if `mode` is `Mode::All`:
        #
        # * `:move` if the mouse has been moved.
        getter type : Symbol

        # Returns the kind of mouse event based on `type`.
        #
        # * `:release` if a mouse button has been released.
        # * `:click` if a mouse button has been pressed.
        # * `:wheel` if the wheel has been scrolled.
        #
        # Only if `mode` is `Mode::Drag` or `Mode::All`:
        #
        # * `:drag` if a mouse button has been pressed and the mouse has been moved.
        #
        # Only if `mode` is `Mode::All`:
        #
        # * `:move` if the mouse has been moved.
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

        return nil if input.count('\e') == 0 || input.size < 6

        type = case input[3]
               when ' ' then :left
               when '!' then :wheel
               when '"' then :right
               when '#' then :release
               when '@' then :left_drag
               when 'A' then :wheel_drag
               when 'B' then :right_drag
               when 'C' then :move
               when '`' then :wheel_up
               when 'a' then :wheel_down
               else
                 return nil
               end

        # 32 to decode the character, 1 more to make the numbers zero-based
        Event.new(input[4].ord - 33, input[5].ord - 33, type)
      end

      # :nodoc:
      def get_1006 : Event?
        input = STDIN.raw do |io|
          string = String.new(io.peek)
          io.skip(string.size)
          string
        end

        if input
          return nil if input.count('\e') == 0 || input.size < 9
        else
          return nil
        end

        input = input.lchop("\e[<").rchop.split(';')

        type = case input[0]
               when "0"  then :left
               when "1"  then :wheel
               when "2"  then :right
               when "3"  then :release
               when "32" then :left_move
               when "33" then :wheel_move
               when "34" then :right_move
               when "35" then :move
               when "64" then :wheel_up
               when "65" then :wheel_down
               else
                 return nil
               end

        Event.new(input[1].to_i - 1, input[2].to_i - 1, type)
      end

      # Returns the mouse event happening in the moment this method is called as `Event`,
      # `nil` if the input is not a mouse event or if `mode` is `Mode::Off`.
      def peek : Event?
        STDIN.read_timeout = 0.01
        Mouse.get
      rescue IO::Timeout
      ensure
        STDIN.read_timeout = nil
      end
    end
  end
end

include Lime::Modules
