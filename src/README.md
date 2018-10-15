# How does it work exactly?

So first, after you required lime, two buffers will be automatically created. The first one is an array of spaces. The size is determined by the window width in cells multiplied by the window height in cells. The second buffer is just a shallow copy of the first buffer.
Internally they are called the `empty_buffer` and the `buffer`.

So let's say we want to print a single `a` character at the x-axis **5** and at the y-axis **10**:

```crystal
Lime.print('a', 5, 10)
```

now the buffer will be accessed and the `a` will be inserted into the buffer at a specific index. The formula for calculating the correct index is:

```crystal
x-axis + window width * y-axis
```

(Let's say your window width is **168**)

so the result is:

```crystal
5 + 168 * 10 = 1685
```

which means that the **1685**th empty space in the buffer will be replaced by an `a`. But this isn't enough yet to see the `a` on the screen!

The next step is to call `Lime.draw` which iterates through every character in the buffer and builds one big string which is then being printed. That's of course much faster than printing every character seperately.

Usually if you use `Lime.draw` in a loop, you put a `Lime.clear` after it which clears the buffer so you have room for drawing new stuff. And that's where the empty buffer that has been created at the beginning comes into play: instead of rebuilding the whole buffer every time again, we simply shallow-copy the empty buffer and assign it to the normal buffer.
