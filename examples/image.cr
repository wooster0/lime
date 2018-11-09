require "../lime"
require "../lime/drawables"
include Lime::Drawables

# Load the image:
image_path = "#{__DIR__}/image.png"
image = Pixels.new(image_path, 5, 5)

# Insert the image pixels into the buffer:
image.draw

# Draw the content of the buffer to the screen:
Lime.draw
