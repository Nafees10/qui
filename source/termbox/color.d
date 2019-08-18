module termbox.color;

/* Colors (see struct Cell's fg and bg fields). */
enum Color : ushort {
    basic   = 0x00,
    black   = 0x01,
    red     = 0x02,
    green   = 0x03,
    yellow  = 0x04,
    blue    = 0x05,
    magenta = 0x06,
    cyan    = 0x07,
    white   = 0x08
}

/* Attributes, it is possible to use multiple attributes by combining them
 * using bitwise OR ('|'). Although, colors cannot be combined. But you can
 * combine attributes and a single color. See also struct Cell's fg and bg
 * fields.
 */
enum Attribute : ushort {
    bold      = 0x0100,
    underline = 0x0200,
    reverse   = 0x0400
}
