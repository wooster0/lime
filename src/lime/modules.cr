module Lime
  # The window of the console.
  module Window
    extend self

    # Returns the width of the window in cells.
    class_getter width : Int32 = `tput cols`.to_i

    # Returns the height of the window in cells.
    class_getter height : Int32 = `tput lines`.to_i

    # Returns the width of the window in blocks.
    def self.width_blocks
      @@width
    end

    # Returns the height of the window in blocks.
    class_getter height_blocks : Int32 = height*2

    # Updates the values of `width`, `height` and
    # `width_blocks`, `height_blocks`.
    def update
      @@width = `tput cols`.to_i
      @@height = `tput lines`.to_i
      @@height_blocks = @@height*2
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

    # Shows or hides the cursor.
    def visible=(visible : Bool)
      print (visible ? "\e[?25h" : "\e[?25l")
    end

    def move_up(cells = 1)
      print "\e[#{cells}A"
    end

    def move_down(cells = 1)
      print "\e[#{cells}B"
    end

    def move_right(cells = 1)
      print "\e[#{cells}C"
    end

    def move_left(cells = 1)
      print "\e[#{cells}D"
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
