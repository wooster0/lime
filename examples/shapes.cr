require "../lime"

# Create the shapes:
rectangle1 = Rectangle.new(2, 1, 10, 5, Default, :light_green)
rectangle2 = Rectangle.new(13, 1, 10, 5, Double, :light_yellow)
rectangle3 = Rectangle.new(24, 1, 10, 5, Round, :light_magenta)
filled_rectangle = FilledRectangle.new(2, 7, 10, 5, color: :light_red)
circle = Circle.new(12, 13, 11, :light_blue)

# Insert the shapes into the buffer:
rectangle1.draw
rectangle2.draw
rectangle3.draw
filled_rectangle.draw
circle.draw

# Draw the content of the buffer to the screen:
Lime.draw
