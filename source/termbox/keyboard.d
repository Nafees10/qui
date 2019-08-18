module termbox.keyboard;

// Key constants. See also struct Event's key field.
enum Key : ushort {
    /* These are a safe subset of terminfo keys, which exist on all popular
     * terminals. Termbox uses only them to stay truly portable.
     */
    f1             = 0xffff-0,
    f2             = 0xffff-1,
    f3             = 0xffff-2,
    f4             = 0xffff-3,
    f5             = 0xffff-4,
    f6             = 0xffff-5,
    f7             = 0xffff-6,
    f8             = 0xffff-7,
    f9             = 0xffff-8,
    f10            = 0xffff-9,
    f11            = 0xffff-10,
    f12            = 0xffff-11,
    insert         = 0xffff-12,
    del            = 0xffff-13,
    home           = 0xffff-14,
    end            = 0xffff-15,
    pgup           = 0xffff-16,
    pgdn           = 0xffff-17,
    arrowUp        = 0xffff-18,
    arrowDown      = 0xffff-19,
    arrowLeft      = 0xffff-20,
    arrowRight     = 0xffff-21,
    mouseLeft      = 0xffff-22,
    mouseRight     = 0xffff-23,
    mouseMiddle    = 0xffff-24,
    mouseRelease   = 0xffff-25,
    mouseWheelUp   = 0xffff-26,
    mouseWheelDown = 0xffff-27,

    /* These are all ASCII code points below SPACE character and a BACKSPACE key. */
    ctrlTilde      = 0x00,
    ctrl2          = 0x00, /* clash with 'ctrl_tilde' */
    ctrlA          = 0x01,
    ctrlB          = 0x02,
    ctrlC          = 0x03,
    ctrlD          = 0x04,
    ctrlE          = 0x05,
    ctrlF          = 0x06,
    ctrlG          = 0x07,
    backspace      = 0x08,
    ctrlH          = 0x08, /* clash with 'ctrl_backspace' */
    tab            = 0x09,
    ctrlI          = 0x09, /* clash with 'tab' */
    ctrlJ          = 0x0a,
    ctrlK          = 0x0b,
    ctrlL          = 0x0c,
    enter          = 0x0d,
    ctrlM          = 0x0d, /* clash with 'enter' */
    ctrlN          = 0x0e,
    ctrlO          = 0x0f,
    ctrlP          = 0x10,
    ctrlQ          = 0x11,
    ctrlR          = 0x12,
    ctrlS          = 0x13,
    ctrlT          = 0x14,
    ctrlU          = 0x15,
    ctrlV          = 0x16,
    ctrlW          = 0x17,
    ctrlX          = 0x18,
    ctrlY          = 0x19,
    ctrlZ          = 0x1a,
    esc            = 0x1b,
    ctrlLsqBracket = 0x1b, /* clash with 'esc' */
    ctrl3          = 0x1b, /* clash with 'esc' */
    ctrl4          = 0x1c,
    ctrlBackslash  = 0x1c, /* clash with 'ctrl_4' */
    ctrl5          = 0x1d,
    ctrlRsqBracket = 0x1d, /* clash with 'ctrl_5' */
    ctrl6          = 0x1e,
    ctrl7          = 0x1f,
    ctrlSlash      = 0x1f, /* clash with 'ctrl_7' */
    ctrlUnderscore = 0x1f, /* clash with 'ctrl_7' */
    space          = 0x20,
    backspace2     = 0x7f,
    ctrl8          = 0x7f /* clash with 'backspace2' */
}

/* Currently there is only one modifier. See also struct Event's mod
 * field.
 */
enum Mod : ubyte {
    alt = 0x01
}
