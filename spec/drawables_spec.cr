require "./spec_helper"
require "../src/lime/drawables"
include Lime::Drawables

describe Rectangle do
  describe ".initialize" do
    it "initializes" do
      rectangle = Rectangle.new(0, 0, 5, 5, Default, :red)
      rectangle.@top.to_s.should eq("\e[31m┌───┐\e[0m")
      rectangle.@tile.to_s.should eq("\e[31m│   │\e[0m")
      rectangle.@bottom.to_s.should eq("\e[31m└───┘\e[0m")

      rectangle = Rectangle.new(0, 0, 5, 5, Double, :green)
      rectangle.@top.to_s.should eq("\e[32m╔═══╗\e[0m")
      rectangle.@tile.to_s.should eq("\e[32m║   ║\e[0m")
      rectangle.@bottom.to_s.should eq("\e[32m╚═══╝\e[0m")

      rectangle = Rectangle.new(0, 0, 5, 5, Round, :blue)
      rectangle.@top.to_s.should eq("\e[34m╭───╮\e[0m")
      rectangle.@tile.to_s.should eq("\e[34m│   │\e[0m")
      rectangle.@bottom.to_s.should eq("\e[34m╰───╯\e[0m")

      rectangle = Rectangle.new(0, 0, 2, 2, Default, Colorize::ColorANSI::Default)
      rectangle.@top.to_s.should eq("┌┐")
      rectangle.@tile.to_s.should eq("││")
      rectangle.@bottom.to_s.should eq("└┘")
    end

    it "uses block characters" do
      rectangle = Rectangle.new(0, 0, 5, 1, Default, :blue)
      rectangle.@top.to_s.should eq("")
      rectangle.@tile.to_s.should eq("\e[34m█████\e[0m")
      rectangle.@bottom.to_s.should eq("")

      rectangle = Rectangle.new(0, 0, 1, 5, Default, :blue)
      rectangle.@top.to_s.should eq("")
      rectangle.@tile.to_s.should eq("\e[34m█\e[0m")
      rectangle.@bottom.to_s.should eq("")

      rectangle = Rectangle.new(0, 0, 1, 1, Default, Colorize::ColorANSI::Default)
      rectangle.@top.to_s.should eq("")
      rectangle.@tile.to_s.should eq("█")
      rectangle.@bottom.to_s.should eq("")
    end
  end

  it "draws" do
    rectangle = Rectangle.new(2, 2, 4, 4, Default, Colorize::ColorANSI::Default)
    rectangle.draw
    buffer.should eq(
      <<-RECTANGLE


        ┌──┐
        │  │
        │  │
        └──┘
      RECTANGLE
    )
  end
end

describe FilledRectangle do
  it "initializes" do
    filled_rectangle = FilledRectangle.new(0, 0, 5, 5, "#", :red)
    filled_rectangle.@tile.to_s.should eq("\e[31m#####\e[0m")

    filled_rectangle = FilledRectangle.new(0, 0, 10, 10, color: Colorize::ColorANSI::Default)
    filled_rectangle.@tile.to_s.should eq("██████████")
  end

  it "draws" do
    filled_rectangle = FilledRectangle.new(5, 5, 2, 2, "O", :yellow)
    filled_rectangle.draw
    buffer.should eq(
      <<-FILLED_RECTANGLE





           \e[33mO\e[0m\e[33mO\e[0m
                             \e[33mO\e[0m\e[33mO\e[0m
      FILLED_RECTANGLE
    )
  end
end

describe Circle do
  it "initializes" do
    circle = Circle.new(1, 1, 5, :green)
    circle.x.should eq(1)
    circle.y.should eq(1)
    circle.radius.should eq(5)
    circle.color.should eq(Colorize::ColorANSI::Green)
  end

  it "draws" do
    circle = Circle.new(2, 2, 3, :yellow)
    circle.draw
    buffer.should eq(
      <<-CIRCLE

          \e[33m▄\e[0m\e[33m▄\e[0m\e[33m▄\e[0m
                                    \e[33;43m▄\e[0m   \e[33;43m▄\e[0m
                                                            \e[33m▀\e[0m\e[33m▄\e[0m\e[33m▄\e[0m\e[33m▄\e[0m\e[33m▀\e[0m
      CIRCLE
    )
  end
end

describe Pixels do
  describe ".initialize" do
    it "initializes color characters" do
      pixels = Pixels.new(5, 5,
        <<-COLOR_CHARACTERS
        RGBRGB
        COLOR_CHARACTERS
      )
      pixels.x.should eq(5)
      pixels.y.should eq(5)
      pixels.@pixels.should eq(
        [Colorize::ColorANSI::LightRed,
         Colorize::ColorANSI::LightGreen,
         Colorize::ColorANSI::LightBlue,
         Colorize::ColorANSI::LightRed,
         Colorize::ColorANSI::LightGreen,
         Colorize::ColorANSI::LightBlue]
      )
    end

    it "raises when there's an invalid color character" do
      expect_raises(Pixels::Error, "Invalid color character") do
        pixels = Pixels.new(5, 5, "I")
      end
    end

    it "handles comments" do
      pixels = Pixels.new(0, 0,
        <<-COMMENTS
        R # #Comment
        # Comment
         G # #Comment
         # Comment
          B # #Comment
          # Comment
        COMMENTS
      )
    end

    it "initializes an image" do
      image_path = "#{Dir.open("spec").path}/image.png"
      image = Pixels.new(image_path, 0, 0)
      image.@pixels.should eq(
        [Colorize::ColorRGB.new(237_u8, 28_u8, 36_u8),
         Colorize::ColorRGB.new(0_u8, 255_u8, 0_u8),
         Colorize::ColorRGB.new(0_u8, 0_u8, 255_u8), :newline,
         Colorize::ColorRGB.new(0_u8, 255_u8, 0_u8),
         Colorize::ColorRGB.new(237_u8, 28_u8, 36_u8),
         Colorize::ColorRGB.new(0_u8, 255_u8, 0_u8), :newline,
         Colorize::ColorRGB.new(0_u8, 0_u8, 255_u8),
         Colorize::ColorRGB.new(0_u8, 255_u8, 0_u8),
         Colorize::ColorRGB.new(237_u8, 28_u8, 36_u8)])
    end
  end

  describe "#map" do
    it "modifies an image" do
      image_path = "#{Dir.open("spec").path}/image.png"
      image = Pixels.new(image_path, 5, 5)
      image.map { |pixel| {255u8 - pixel.red, 255u8 - pixel.green, 255u8 - pixel.blue} }
      image.@pixels.should eq(
        [Colorize::ColorRGB.new(18_u8, 227_u8, 219_u8),
         Colorize::ColorRGB.new(255_u8, 0_u8, 255_u8),
         Colorize::ColorRGB.new(255_u8, 255_u8, 0_u8), :newline,
         Colorize::ColorRGB.new(255_u8, 0_u8, 255_u8),
         Colorize::ColorRGB.new(18_u8, 227_u8, 219_u8),
         Colorize::ColorRGB.new(255_u8, 0_u8, 255_u8), :newline,
         Colorize::ColorRGB.new(255_u8, 255_u8, 0_u8),
         Colorize::ColorRGB.new(255_u8, 0_u8, 255_u8),
         Colorize::ColorRGB.new(18_u8, 227_u8, 219_u8)]
      )
    end

    it "modifies color characters" do
      pixels = Pixels.new(5, 5,
        <<-COLOR_CHARACTERS
        R G B
        G R G
        B G R
        COLOR_CHARACTERS
      )
      pixels.@pixels.should eq(
        [Colorize::ColorANSI::LightRed, :skip,
         Colorize::ColorANSI::LightGreen, :skip,
         Colorize::ColorANSI::LightBlue, :newline,
         Colorize::ColorANSI::LightGreen, :skip,
         Colorize::ColorANSI::LightRed, :skip,
         Colorize::ColorANSI::LightGreen, :newline,
         Colorize::ColorANSI::LightBlue, :skip,
         Colorize::ColorANSI::LightGreen, :skip,
         Colorize::ColorANSI::LightRed]
      )
    end
  end

  describe "#draw" do
    it "draws an image" do
      image_path = "#{Dir.open("spec").path}/image.png"
      image = Pixels.new(image_path, 5, 5)
      image.draw
      buffer.should eq(
        <<-IMAGE


             \e[38;2;237;28;36m▄\e[0m\e[38;2;0;255;0m▄\e[0m\e[38;2;0;0;255m▄\e[0m
                                                                        \e[38;2;0;255;0;48;2;0;0;255m▀\e[0m\e[38;2;237;28;36;48;2;0;255;0m▀\e[0m\e[38;2;0;255;0;48;2;237;28;36m▀\e[0m
        IMAGE
      )
    end

    it "draws color characters" do
      pixels = Pixels.new(5, 5,
        <<-COLOR_CHARACTERS
        R G B
        G R G
        B G R
        COLOR_CHARACTERS
      )
      pixels.draw
      buffer.should eq(
        <<-PIXELS


             \e[91m▄\e[0m \e[92m▄\e[0m \e[94m▄\e[0m
                                        \e[92;104m▀\e[0m \e[91;102m▀\e[0m \e[92;101m▀\e[0m
        PIXELS
      )
    end
  end
end
