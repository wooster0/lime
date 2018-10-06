require "../lime"
require "../lime/drawables"
include Lime::Drawables

hill_path = "#{Dir.open("examples").path}/hill.png"

hill = Image.new(hill_path, 5, 5)

# Insert the image pixels into the buffer:
hill.draw

# Draw the buffer on the screen:
Lime.draw
