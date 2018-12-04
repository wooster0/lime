require "../lime"

# Captain Viridian from the game VVVVVV
VIRIDIAN = <<-VIRIDIAN
 CCCCCCCC
CCCCCCCCCC
CCC00CC00C
CCC00CC00C
CCCCCCCCCC
CCCCCCCCCC
CCC000000C
CCCC0000CC
 CCCCCCCC
   CCCC
 CCCCCCCC
CCCCCCCCCC
CCCCCCCCCC
CCCCCCCCCC
CC CCCC CC
CC CCCC CC
  CCCCCC
  CC  CC
 CCC  CCC
 CCC  CCC
 CCC  CCC
VIRIDIAN

# Convert the color characters to pixels:
viridian = Pixels.new(5, 5, VIRIDIAN)

# Insert Viridian into the buffer:
viridian.draw

# Draw Viridian to the screen:
Lime.draw
