# lime

A library for drawing graphics on the console screen

## Features

* Drawing of
  * PNG images
  * rectangles
  * filled rectangles
  * circles
  * lines
* Non-blocking key input
* Management of the window and cursor

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  lime:
    github: r00ster91/lime
```

## Example usage

Three lights flashing repeatedly in order:

```crystal
require "lime"

# Make drawables like Rectangle, Circle available
require "lime/drawables"
include Lime::Drawables

# Create the lights.
# They are red, green and blue rectangles with doubled lines
light1 = Rectangle.new(
  x: 1, y: 1,
  width: 5, height: 3,
  type: Double, color: :red
)
light2 = Rectangle.new(7, 1, 5, 3, Double, :green)
light3 = Rectangle.new(13, 1, 5, 3, Double, :blue)

# The light that is currently on
active = 1

loop do
  if active == 3
    active = 1
  else
    active += 1
  end

  case active
  when 1
    light1.color = :light_red
    light2.color = :green
    light3.color = :blue
  when 2
    light1.color = :red
    light2.color = :light_green
    light3.color = :blue
  when 3
    light1.color = :red
    light2.color = :green
    light3.color = :light_blue
  end

  # Insert the lights into the buffer:
  light1.draw
  light2.draw
  light3.draw

  # Draw the content of the buffer to the screen:
  Lime.draw
  # Clear the buffer so we have room for new stuff:
  Lime.clear

  # You can use `Lime.loop` instead of a normal loop to skip the above two steps

  sleep 0.5
end
```

See `examples/` for more examples.

## Contributing

1. Fork it (https://github.com/r00ster91/lime/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [r00ster91](https://github.com/r00ster91) - creator, maintainer
