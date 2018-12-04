require "./spec_helper"
require "../src/lime/modules"

describe Window do
  describe ".width" do
    it "returns the width zero-based" do
      Window.width.should eq(Window.width_cells - 1)
    end
  end

  describe ".height" do
    it "returns the height zero-based" do
      Window.height.should eq(Window.height_cells - 1)
    end
  end

  describe ".width_pixels" do
    it "returns the width in pixels" do
      Window.width_pixels.should eq(Window.width)
    end
  end

  describe ".height_pixels" do
    it "returns the height in pixels" do
      Window.height_pixels.should eq(Window.height*2)
    end
  end
end

describe Mouse do
  describe ".extend" do
    it "extends the range" do
      Mouse.extend
      Mouse.extended.should eq(true)
    end

    it "resets the range" do
      Mouse.extend(false)
      Mouse.extended.should eq(false)
    end
  end

  describe ".mode" do
    it "returns and sets the mode" do
      Mouse.mode = Mouse::Mode::Off
      Mouse.mode.should eq(Mouse::Mode::Off)

      Mouse.mode = Mouse::Mode::Click
      Mouse.mode.should eq(Mouse::Mode::Click)
    end
  end

  describe ".peek" do
    it "returns nil if the mode is off" do
      Mouse.mode = Mouse::Mode::Off
      Mouse.peek.should eq(nil)
    end

    it "returns nil if no mouse event is happening" do
      Mouse.mode = Mouse::Mode::Click
      Mouse.peek.should eq(nil)
    end
  end

  describe Mouse::Event do
    describe "#type" do
      it "returns the type" do
        Mouse::Event.new(5, 5, :move).type.should eq(:move)
        Mouse::Event.new(5, 5, :left).type.should eq(:left)
      end
    end

    describe "#kind" do
      it "returns the kind" do
        Mouse::Event.new(5, 5, :release).kind.should eq(:release)
        Mouse::Event.new(5, 5, :move).kind.should eq(:move)
        Mouse::Event.new(5, 5, :left).kind.should eq(:click)
        Mouse::Event.new(5, 5, :wheel_up).kind.should eq(:wheel)
        Mouse::Event.new(5, 5, :left_drag).kind.should eq(:drag)
      end
    end

    it "returns the position" do
      event = Mouse::Event.new(2, 5, :left)
      event.x.should eq(2)
      event.y.should eq(5)
    end
  end
end
