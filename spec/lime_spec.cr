require "./spec_helper"
require "../src/lime"

describe Lime do
  describe ".print" do
    it "prints a character" do
      Lime.print('c', 1, 1)
      buffer.should eq("\n c")
    end

    it "prints a colored character" do
      Lime.print('c'.colorize(:green), 1, 1)
      buffer.should eq("\n \e[32mc\e[0m")
    end

    it "prints a string" do
      Lime.print("string", 1, 1)
      buffer.should eq("\n string")
    end

    it "prints a colored string" do
      Lime.print("red".colorize(:red), 1, 1)
      buffer.should eq("\n \e[31mr\e[0m\e[31me\e[0m\e[31md\e[0m")
    end

    it "prints a default string" do
      Lime.print("default".colorize(:default), 1, 1)
      buffer.should eq("\n default")
    end
  end

  describe ".printf" do
    it "printfs a string with a newline" do
      Lime.printf("formatted\nstring", 2, 2)
      buffer.should eq("\n\n  formatted\n  string")
    end

    it "printfs a colored string with a newline" do
      Lime.printf("bl\nue".colorize(:blue), 2, 2)
      buffer.should eq(
        <<-BLUE


          \e[34mb\e[0m\e[34ml\e[0m
                            \e[34mu\e[0m\e[34me\e[0m
        BLUE
      )
    end
  end

  describe ".pixel" do
    it "inserts colored pixels into the buffer" do
      Lime.pixel(1, 1, :red)
      buffer.should eq(" \e[31m▄\e[0m")

      Lime.pixel(1, 0, :green)
      buffer.should eq(" \e[32m▀\e[0m")

      Lime.pixel(1, 1, :yellow)
      Lime.pixel(1, 0, :magenta)
      buffer.should eq(" \e[33;45m▄\e[0m")

      Lime.pixel(1, 0, :magenta)
      Lime.pixel(1, 1, :yellow)
      buffer.should eq(" \e[35;43m▀\e[0m")

      Lime.pixel(1, 0, :magenta)
      Lime.pixel(1, 1, :yellow)
      Lime.pixel(1, 0, :magenta)
      Lime.pixel(1, 1, :yellow)
      buffer.should eq(" \e[35;43m▀\e[0m")

      Lime.pixel(1, 1)
      Lime.pixel(1, 0)
      Lime.pixel(1, 1, :red)
      Lime.pixel(1, 0, :green)
      buffer.should eq(" \e[32;41m▀\e[0m")

      Lime.pixel(0, 0)
      Lime.pixel(0, 0, :red)
      buffer.should eq("\e[31m▀\e[0m")

      Lime.pixel(0, 0)
      Lime.pixel(0, 0, :red)
      Lime.pixel(0, 0, :red)
      buffer.should eq("\e[31m▀\e[0m")

      Lime.pixel(0, 1)
      Lime.pixel(0, 1, :red)
      buffer.should eq("\e[31m▄\e[0m")

      Lime.pixel(0, 1)
      Lime.pixel(0, 1, :red)
      Lime.pixel(0, 1, :red)
      buffer.should eq("\e[31m▄\e[0m")

      Lime.pixel(0, 1)
      Lime.pixel(0, 1)
      Lime.pixel(0, 1, :red)
      Lime.pixel(0, 1, :red)
      buffer.should eq("\e[31m▄\e[0m")

      Lime.pixel(0, 1)
      Lime.pixel(0, 1)
      Lime.pixel(0, 0, :red)
      Lime.pixel(0, 0, :red)
      buffer.should eq("\e[41m▄\e[0m")
    end

    it "inserts default pixels into the buffer" do
      Lime.pixel(1, 1)
      buffer.should eq(" ▄")

      Lime.pixel(1, 0)
      buffer.should eq(" ▀")

      Lime.pixel(1, 1)
      Lime.pixel(1, 0)
      buffer.should eq(" █")

      Lime.pixel(1, 0)
      Lime.pixel(1, 1)
      buffer.should eq(" █")

      Lime.pixel(1, 1)
      Lime.pixel(1, 0, :red)
      Lime.pixel(1, 0)
      buffer.should eq(" █")

      Lime.pixel(1, 0)
      Lime.pixel(1, 1, :red)
      Lime.pixel(1, 1)
      buffer.should eq(" █")

      Lime.pixel(1, 1, :red)
      Lime.pixel(1, 0, :green)
      Lime.pixel(1, 1)
      Lime.pixel(1, 0)
      buffer.should eq(" █")

      Lime.pixel(1, 0)
      Lime.pixel(1, 0)
      buffer.should eq(" ▀")

      Lime.pixel(1, 1)
      Lime.pixel(1, 1)
      buffer.should eq(" ▄")
    end

    it "inserts default and colored pixels into the buffer" do
      Lime.pixel(1, 1, :red)
      Lime.pixel(1, 0)
      buffer.should eq(" \e[41m▀\e[0m")

      Lime.pixel(1, 1)
      Lime.pixel(1, 0, :red)
      buffer.should eq(" \e[41m▄\e[0m")

      Lime.pixel(1, 1, :red)
      Lime.pixel(1, 2)
      buffer.should eq(" \e[31m▄\e[0m\n          ▀")

      Lime.pixel(1, 1)
      Lime.pixel(1, 2, :red)
      buffer.should eq(" ▄\n \e[31m▀\e[0m")

      Lime.pixel(1, 0)
      Lime.pixel(1, 1)
      Lime.pixel(1, 1, :red)
      buffer.should eq(" \e[41m▀\e[0m")

      Lime.pixel(1, 0)
      Lime.pixel(1, 1)
      Lime.pixel(1, 0, :red)
      buffer.should eq(" \e[41m▄\e[0m")

      Lime.pixel(1, 0)
      Lime.pixel(1, 0, :red)
      Lime.pixel(1, 1)
      buffer.should eq(" \e[41m▄\e[0m")
    end
  end

  describe ".line" do
    it "inserts a colored line into the buffer" do
      Lime.line(0, 0, 5, 5, :red)
      buffer.should eq(
        <<-LINE
        \e[31m▀\e[0m\e[31m▄\e[0m
                            \e[31m▀\e[0m\e[31m▄\e[0m
                                                \e[31m▀\e[0m\e[31m▄\e[0m
        LINE
      )

      Lime.line(0, 0, 5, 10, :red)
      buffer.should eq(
        <<-LINE
        \e[31;41m▀\e[0m
                     \e[31;41m▀\e[0m
                                  \e[31;41m▀\e[0m
                                               \e[31;41m▀\e[0m
                                                            \e[31;41m▀\e[0m
                                                                         \e[31m▀\e[0m
        LINE
      )
    end

    it "inserts a default line into the buffer" do
      Lime.line(0, 0, 5, 5)
      buffer.should eq(
        <<-LINE
        ▀▄
          ▀▄
            ▀▄
        LINE
      )

      Lime.line(0, 0, 5, 10)
      buffer.should eq(
        <<-LINE
        █
         █
          █
           █
            █
             ▀
        LINE
      )
    end
  end

  describe ".peek_key_raw" do
    it "returns nil if no key has been pressed" do
      Lime.peek_key.should eq(nil)
    end
  end

  describe ".peek_key" do
    it "returns nil if no key has been pressed" do
      Lime.peek_key.should eq(nil)
    end
  end
end
