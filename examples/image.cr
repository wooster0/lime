require "../lime"
require "../lime/drawables"
include Lime::Drawables

# Load the image:
image_path = "#{Dir.open("examples").path}/image.png"
image = Pixels.new(image_path, 5, 5)

# Insert the image pixels into the buffer:
image.draw

# Draw the buffer on the screen:
Lime.draw
