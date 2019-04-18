[![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://r00ster91.github.io/lime/)

# lime

A library for drawing graphics on the console screen

## Features

* Drawing of
  * text
  * lines
  * rectangles
  * filled rectangles
  * circles
  * PNG images
* Management of the window
* Controlling of the console cursor
* Keyboard and mouse pointer input

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  lime:
    github: r00ster91/lime
```

Then run `shards install`

## Example

Three lights flashing repeatedly in order:

```crystal
require "lime"

# Create the lights:
# They are red, green and blue rectangles with doubled lines
light1 = Rectangle.new(
  x: 2, y: 1,
  width: 5, height: 3,
  type: Double, color: :red
)
light2 = Rectangle.new(8, 1, 5, 3, Double, :green)
light3 = Rectangle.new(14, 1, 5, 3, Double, :blue)

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

  # A short delay:
  sleep 0.5
end
```

In the top left corner we can see:

![lights](https://i.imgur.com/hDHDiJB.gif)

See [`examples`](https://github.com/r00ster91/lime/tree/master/examples) for more examples.

For technical information about lime, see [`src/README.md`](https://github.com/r00ster91/lime/tree/master/src/README.md).

## Contributing

1. Fork it (<https://github.com/r00ster91/lime/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Install required shards (`shards install`)
4. Make your changes
5. Format the code (`crystal tool format`)
6. Make sure the specs compile (`crystal spec -v`)
7. Commit your changes (`git commit -am 'Add some feature'`)
8. Push to the branch (`git push origin my-new-feature`)
9. Create a new Pull Request

## Contributors

- [r00ster](https://github.com/r00ster91) - creator and maintainer
