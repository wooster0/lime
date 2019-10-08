require "../lime"

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
light = 1

loop do
  if light == 3
    light = 1
  else
    light += 1
  end

  case light
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
  # Clear the buffer (not the screen) so we have room for the next frame:
  Lime.clear

  # You can use `Lime.loop` instead of a normal loop to skip the above two steps

  # A short delay:
  sleep 0.5
end
