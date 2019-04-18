# How it works exactly

After you required lime, a buffer will be automatically created.
The buffer is a one-dimensional array of spaces. The amount of spaces is determined by the window width of the console in cells multiplied by the window height in cells.

So let's say we want to print a single `a` character at the x-axis **10** and at the y-axis **5**:

```crystal
Lime.print('a', 10, 5)
```

now the buffer will be accessed and the `a` will be inserted into it at a specific index. The formula for calculating the correct index is:

```crystal
x-axis + window width * y-axis
```

(Let's say your window width is **168**)

so the result is:

```crystal
10 + 168 * 5 = 850
```

which means that the **850**th empty space in the buffer will be replaced by an `a`. But this isn't enough yet to see the `a` on the screen.

The next step is to call `Lime.draw` which iterates through every single character in the buffer and builds one big string which is then being printed. That's of course much faster than printing every character seperately.

Usually if you use `Lime.draw` in a loop, you put a `Lime.clear` after it which clears the buffer so you have room for drawing new stuff. `Lime.clear` replaces every element of the buffer by a space. Now the buffer is containing spaces again and when the buffer is drawn, the screen will appear as empty.
