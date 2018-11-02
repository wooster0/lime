require "./spec_helper"
require "../src/lime/modules"

describe Lime::Window do
  describe ".width" do
    it "returns the width zero-based" do
      Lime::Window.width.should eq(Lime::Window.width_cells - 1)
    end
  end

  describe ".height" do
    it "returns the height zero-based" do
      Lime::Window.height.should eq(Lime::Window.height_cells - 1)
    end
  end

  describe ".width_pixels" do
    it "returns the width in pixels" do
      Lime::Window.width_pixels.should eq(Lime::Window.width)
    end
  end

  describe ".height_pixels" do
    it "returns the height in pixels" do
      Lime::Window.height_pixels.should eq(Lime::Window.height*2)
    end
  end
end

describe Lime::Mouse do
  describe ".extend" do
    it "extends the range" do
      Lime::Mouse.extend
      Lime::Mouse.extended.should eq(true)
    end

    it "resets the range" do
      Lime::Mouse.extend(false)
      Lime::Mouse.extended.should eq(false)
    end
  end

  describe ".peek" do
    it "returns nil if no event is happening" do
      Lime::Mouse.peek.should eq(nil)
    end
  end

  describe Lime::Mouse::Event do
    describe "#type" do
      it "returns the type" do
        Lime::Mouse::Event.new(5, 5, :move).type.should eq(:move)
        Lime::Mouse::Event.new(5, 5, :left).type.should eq(:left)
      end
    end

    describe "#kind" do
      it "returns the kind" do
        Lime::Mouse::Event.new(5, 5, :release).kind.should eq(:release)
        Lime::Mouse::Event.new(5, 5, :move).kind.should eq(:move)
        Lime::Mouse::Event.new(5, 5, :left).kind.should eq(:click)
        Lime::Mouse::Event.new(5, 5, :wheel_up).kind.should eq(:wheel)
        Lime::Mouse::Event.new(5, 5, :left_drag).kind.should eq(:drag)
      end
    end

    it "returns the position" do
      event = Lime::Mouse::Event.new(2, 5, :left)
      event.x.should eq(2)
      event.y.should eq(5)
    end
  end
end
