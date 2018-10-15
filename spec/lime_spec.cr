require "./spec_helper"
require "../src/lime"

describe Lime do
  describe ".print" do
    it "prints a char" do
      Lime.print('c', 1, 1)
      buffer.should eq("\n c")
    end

    it "prints a colored char" do
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
      Lime.print("default".colorize(Colorize::ColorANSI::Default), 1, 1)
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
    it "inserts a pixel into the buffer" do
      Lime.pixel(1, 1, :red)
      buffer.should eq(" \e[31m▄\e[0m")

      Lime.pixel(1, 0, :green)
      buffer.should eq(" \e[32m▀\e[0m")

      Lime.pixel(1, 1, :yellow)
      Lime.pixel(1, 0, :magenta)
      buffer.should eq(" \e[33;45m▄\e[0m")
    end

    it "inserts a default pixel into the buffer" do
      Lime.pixel(1, 1, Colorize::ColorANSI::Default)
      buffer.should eq(" ▄")

      Lime.pixel(1, 0, Colorize::ColorANSI::Default)
      buffer.should eq(" ▀")

      Lime.pixel(1, 1, Colorize::ColorANSI::Default)
      Lime.pixel(1, 0, Colorize::ColorANSI::Default)
      buffer.should eq(" █")
    end
  end

  describe ".line" do
    it "inserts a line into the buffer" do
      Lime.line(1, 1, 5, 5, :green)
      buffer.should eq(
        <<-LINE
         \e[32m▄\e[0m
                   \e[32m▀\e[0m\e[32m▄\e[0m
                                       \e[32m▀\e[0m\e[32m▄\e[0m
        LINE
      )

      Lime.line(0, 0, 10, 5, Colorize::ColorANSI::Default)
      buffer.should eq(
        <<-LINE
        ▀▀▄▄
            ▀▀▄▄
                ▀▀▄
        LINE
      )
    end
  end

  describe ".check_key" do
    it "checks for a key" do
      Lime.check_key.should eq(nil)
    end
  end
end
