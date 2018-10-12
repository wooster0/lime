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
    class_getter height_pixels : Int32 = height*2

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
      print "\e[#{position[1] + 1};#{position[0] + 1}H" # row, column
    end
  end
end
