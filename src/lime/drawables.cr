require "stumpy_png"

module Lime
  # This module contains drawables that can be inserted into the buffer.
  #
  # If you want to use the drawables in the Top Level Namespace,
  # you can `include` them:
  # ```
  # require "lime/drawables"
  # include Lime::Drawables
  # ```
  module Drawables
    # A drawable rectangle.
    struct Rectangle
      property x, y
      getter width, type, color

      # The type of a `Rectangle`.
      enum Type
        # The default rectangle type. It looks like this:
        # ```text
        # ┌────┐
        # │    │
        # └────┘
        # ```
        Default

        # Like the default type but with doubled lines:
        # ```text
        # ╔════╗
        # ║    ║
        # ╚════╝
        # ```
        Double

        # Like the default type but with round corners:
        # ```text
        # ╭────╮
        # │    │
        # ╰────╯
        # ```
        Round
      end

      def color=(@color : Colorize::Color)
        init
      end

      def width=(@width)
        init
      end

      def height=(@height)
      end

      def type=(@type)
        init
      end

      @top : Colorize::Object(String) | String = ""
      @tile : Colorize::Object(String) | Colorize::Object(Char) | String = ""
      @bottom : Colorize::Object(String) | String = ""

      private macro init
        if @width == 1
          @top, @tile, @bottom = "", '█'.colorize(color), ""
          {{yield}}
        elsif @height == 1
          @top, @tile, @bottom = "", ("█"*@width).colorize(color), ""
          {{yield}}
        elsif @width == 0 || @height == 0
          @top, @tile, @bottom = "", "", ""
          {{yield}}
        else
          @width -= 2 unless @width == 0
          case @type
          when .default?
            middle = "─"*@width
            @top = ('┌' + middle + '┐').colorize(@color)
            @tile = ('│' + (" "*@width) + '│').colorize(@color)
            @bottom = ('└' + middle + '┘').colorize(@color)
          when .double?
            middle = "═"*@width
            @top = ('╔' + middle + '╗').colorize(@color)
            @tile = ('║' + (" "*@width) + '║').colorize(@color)
            @bottom = ('╚' + middle + '╝').colorize(@color)
          when .round?
            middle = "─"*@width
            @top = ('╭' + middle + '╮').colorize(@color)
            @tile = ('│' + (" "*@width) + '│').colorize(@color)
            @bottom = ('╰' + middle + '╯').colorize(@color)
          end
        end
      end

      # TODO: use ` instead of ** at the Top Level Namespace constants in the
      # `initialize` description after
      # https://github.com/crystal-lang/crystal/issues/6637 is fixed.
      #
      # Currently when using ` instead of **, the constants are clickable and
      # will lead to an non-existent page: toplevel.html

      # Initializes a new `Rectangle`.
      #
      # For specifying the type, you can use the Top Level Namespace constants
      # **Default**, **Double** and **Round**.
      def initialize(@x : Int32, @y : Int32, @width : Int32, @height : Int32, @type : Type = Default, @color : Colorize::Color = Colorize::ColorANSI::Default)
        init { @y -= 1 }
        @height -= 1 unless @height == 1
      end

      # Inserts the rectangle into the buffer.
      def draw
        Lime.print(@top, @x, @y)
        i = 0
        @height.times do
          i += 1
          Lime.print(@tile, @x, @y + i)
        end
        Lime.print(@bottom, @x, @y + i)
      end
    end

    # A drawable filled rectangle.
    struct FilledRectangle
      property x, y, height
      getter width, material, color

      def width=(@width)
        initialize(@x, @y, @width, @height, @material, @color)
      end

      def material=(@material)
        initialize(@x, @y, @width, @height, @material, @color)
      end

      @tile : Colorize::Object(String)

      # Initializes a new `FilledRectangle`.
      #
      # *material* is what the filled rectangle will be built with:
      # ```
      # FilledRectangle.new(0, 0, 5, 5, "#").draw
      # ```
      #
      # ````text
      # #####
      # #####
      # #####
      # #####
      # #####
      # ```
      def initialize(@x : Int32, @y : Int32, @width : Int32, @height : Int32, @material : String = "█", @color : Colorize::Color = Colorize::ColorANSI::Default)
        @tile = (@material*@width).colorize(@color)
      end

      # Inserts the filled rectangle into the buffer.
      def draw
        @height.times do |i|
          Lime.print(@tile, @x, @y + i)
        end
      end
    end

    # A drawable circle.
    struct Circle
      getter x, y, radius, color

      def radius=(@radius)
        @internal_radius = @radius - 1
      end

      def x=(@x)
        @internal_x = @x + @radius
      end

      def y=(@y)
        @internal_y = @y + @radius
      end

      @internal_x : Int32
      @internal_y : Int32
      @internal_radius : Int32

      # Initializes a new `Circle`.
      def initialize(@x : Int32, @y : Int32, @radius : Int32, @color : Colorize::Color = Colorize::ColorANSI::Default)
        @internal_radius = @radius - 1
        @internal_x = @x + @radius
        @internal_y = @y + @radius
      end

      # Inserts the circle into the buffer.
      #
      # This method uses the [midpoint circle algorithm](https://en.wikipedia.org/wiki/Midpoint_circle_algorithm).
      def draw
        x1 = @internal_radius
        y1 = 0
        err = -@internal_radius
        while x1 >= y1
          Lime.pixel(@internal_x + x1, @internal_y + y1, @color)
          Lime.pixel(@internal_x + y1, @internal_y + x1, @color)
          Lime.pixel(@internal_x - y1, @internal_y + x1, @color)
          Lime.pixel(@internal_x - x1, @internal_y + y1, @color)
          Lime.pixel(@internal_x - x1, @internal_y - y1, @color)
          Lime.pixel(@internal_x - y1, @internal_y - x1, @color)
          Lime.pixel(@internal_x + y1, @internal_y - x1, @color)
          Lime.pixel(@internal_x + x1, @internal_y - y1, @color)

          if err <= 0
            y1 += 1
            err += y1*2
          end

          if err > 0
            x1 -= 1
            err -= x1*2
          end
        end
      end
    end

    # A drawable sequence of pixels.
    struct Pixels
      property x, y
      getter width : Int32, height : Int32

      # Raised when an invalid color character is found in a pixel string.
      class Error < Exception
      end

      @pixels = [] of Colorize::ColorRGB | Colorize::ColorANSI | Symbol

      # Initializes new `Pixels` from an image.
      #
      # *path* must lead to an PNG encoded image.
      def initialize(path : String, @x : Int32, @y : Int32)
        canvas = StumpyPNG.read(path)
        @width, @height = canvas.width, canvas.height

        i = 1
        canvas.pixels.each do |pixel|
          color = Colorize::ColorRGB.new(*pixel.to_rgb8)

          if pixel.alpha == 0
            @pixels << :skip
          else
            @pixels << color
          end
          if i == @width
            @pixels << :newline
            i = 0
          end
          i += 1
        end
        @pixels.pop
      end

      private COLOR_CHARACTERS = {
        {'1', "default"},
        {'0', "black"},
        {'9', "dark_gray"},
        {'6', "light_gray"},
        {'w', "white"},
        {'r', "red"},
        {'g', "green"},
        {'b', "blue"},
        {'y', "yellow"},
        {'m', "magenta"},
        {'c', "cyan"},
        {'R', "light_red"},
        {'G', "light_green"},
        {'B', "light_blue"},
        {'Y', "light_yellow"},
        {'M', "light_magenta"},
        {'C', "light_cyan"},
      }

      {% begin %}
        # Initializes new `Pixels` from a string.
        #
        # Iterates through every character of *color_characters* and every time a color character
        # is found, it's replaced with its color.
        #
        # Available color characters are:
        {% for char in COLOR_CHARACTERS %}
        # * `'{{char[0].id}}'`: {{char[1].gsub(/_/, " ").id}}
        {% end %}
        #
        # Comments are also allowed in the string.
        #
        # Example string:
        #
        # ```
        # # A flower:
        #  RRR
        # RYYYR # Head
        #  RRR
        #   g
        # G g G
        # GGgGG # Stem
        #  GgG
        #   g
        # ```
        #
        # becomes:
        #
        # ![flower](https://i.imgur.com/XaxqEjB.png)
        #
        # Raises `Error` when an invalid color character is found in *color_characters*.
        def initialize(@x : Int32, @y : Int32, color_characters : String)
          # Remove comments:
          lines = color_characters.lines.map do |line|
            next "" if line[0] == '#'

            line[0..(line.index('#') || 0)-1]
          end

          @width = lines.max_by { |line| line.size }.size
          @height = lines.size
          color_characters = lines.join('\n')

          color_characters.each_char do |char|
            @pixels << (case char
            when '\n'
              :newline
            when .whitespace?
              :skip
            {% for char in COLOR_CHARACTERS %}
            when {{char[0]}} then Colorize::ColorANSI::{{char[1].camelcase.id}}
            {% end %}
            else
              raise Error.new("Invalid color character: #{char}")
            end)
          end
        end
      {% end %}

      # Invokes the given block for each of the pixels, replacing the pixel with the pixel returned by the block.
      # The block must return a `Tuple(UInt8, UInt8, UInt8)`.
      # ```
      # # Invert colors of an image:
      # image.map { |pixel| {255u8 - pixel.red, 255u8 - pixel.green, 255u8 - pixel.blue} }
      # ```
      def map
        @pixels.map! do |pixel|
          if pixel.is_a?(Colorize::ColorRGB)
            Colorize::ColorRGB.new(*yield pixel)
          else
            pixel
          end
        end
      end

      # Inserts the pixels into the buffer.
      def draw
        x, y = 0, 0
        @pixels.each do |pixel|
          case pixel
          when :newline
            y += 1
            x = 0
          when :skip
            x += 1
          else
            Lime.pixel(@x + x, @y + y, pixel.as(Colorize::ColorRGB | Colorize::ColorANSI))
            x += 1
          end
        end
      end
    end
  end
end

# Alias for the default rectangle type: `Lime::Drawables::Rectangle::Type::Default`.
Default = Lime::Drawables::Rectangle::Type::Default

# Alias for the double rectangle type: `Lime::Drawables::Rectangle::Type::Double`.
Double = Lime::Drawables::Rectangle::Type::Double

# Alias for the round rectangle type: `Lime::Drawables::Rectangle::Type::Round`.
Round = Lime::Drawables::Rectangle::Type::Round
