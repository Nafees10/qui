module termbox;

public import termbox.color;
public import termbox.keyboard;

/* A cell, single conceptual entity on the terminal screen. The terminal screen
 * is basically a 2d array of cells. It has the following fields:
 *  - 'ch' is a unicode character
 *  - 'fg' foreground color and attributes
 *  - 'bg' background color and attributes
 */
struct Cell {
    uint ch;
    ushort fg;
    ushort bg;
};

enum EventType {
    key    = 1,
    resize = 2,
    mouse  = 3
}

/* An event, single interaction from the user. The 'mod' and 'ch' fields are
 * valid if 'type' is TB_EVENT_KEY. The 'w' and 'h' fields are valid if 'type'
 * is TB_EVENT_RESIZE. The 'x' and 'y' fields are valid if 'type' is
 * TB_EVENT_MOUSE. The 'key' field is valid if 'type' is either TB_EVENT_KEY
 * or TB_EVENT_MOUSE. The fields 'key' and 'ch' are mutually exclusive; only
 * one of them can be non-zero at a time.
 */
struct Event {
    ubyte type;
    ubyte mod; /* modifiers to either 'key' or 'ch' below */
    ushort key; /* one of the TB_KEY_* constants */
    uint ch; /* unicode character */
    int w;
    int h;
    int x;
    int y;
};

/* Error codes returned by tb_init(). All of them are self-explanatory, except
 * the pipe trap error. Termbox uses unix pipes in order to deliver a message
 * from a signal handler (SIGWINCH) to the main event reading loop. Honestly in
 * most cases you should just check the returned code as < 0.
 */
enum Error {
    unsupportedTerminal = -1,
    failedToOpenTTY     = -2,
    pipeTrapError       = -3
}

/* Initializes the termbox library. This function should be called before any
 * other functions. After successful initialization, the library must be
 * finalized using the tb_shutdown() function.
 */
private extern (C) int tb_init();
private extern (C) void tb_shutdown();

/* Returns the size of the internal back buffer (which is the same as
 * terminal's window size in characters). The internal buffer can be resized
 * after tb_clear() or tb_present() function calls. Both dimensions have an
 * unspecified negative value when called before tb_init() or after
 * tb_shutdown().
 */
private extern (C) int tb_width();
private extern (C) int tb_height();

/* Clears the internal back buffer using TB_DEFAULT color or the
 * color/attributes set by tb_set_clear_attributes() function.
 */
private extern (C) void tb_clear();
private extern (C) void tb_set_clear_attributes(ushort fg, ushort bg);

/* Synchronizes the internal back buffer with the terminal. */
private extern (C) void tb_present();

/* Sets the position of the cursor. Upper-left character is (0, 0). If you pass
 * TB_HIDE_CURSOR as both coordinates, then the cursor will be hidden. Cursor
 * is hidden by default.
 */
private extern (C) void tb_set_cursor(int cx, int cy);

/* Changes cell's parameters in the internal back buffer at the specified
 * position.
 */
private extern (C) void tb_put_cell(int x, int y, Cell* cell);
private extern (C) void tb_change_cell(int x, int y, uint ch, uint fg, uint bg);

/* Returns a pointer to internal cell back buffer. You can get its dimensions
 * using tb_width() and tb_height() functions. The pointer stays valid as long
 * as no tb_clear() and tb_present() calls are made. The buffer is
 * one-dimensional buffer containing lines of cells starting from the top.
 */
private extern (C) Cell* tb_cell_buffer();

/* Sets the termbox input mode. Termbox has two input modes:
 * 1. Esc input mode.
 *    When ESC sequence is in the buffer and it doesn't match any known
 *    ESC sequence => ESC means TB_KEY_ESC.
 * 2. Alt input mode.
 *    When ESC sequence is in the buffer and it doesn't match any known
 *    sequence => ESC enables TB_MOD_ALT modifier for the next keyboard event.
 *
 * You can also apply TB_INPUT_MOUSE via bitwise OR operation to either of the
 * modes (e.g. TB_INPUT_ESC | TB_INPUT_MOUSE). If none of the main two modes
 * were set, but the mouse mode was, TB_INPUT_ESC mode is used. If for some
 * reason you've decided to use (TB_INPUT_ESC | TB_INPUT_ALT) combination, it
 * will behave as if only TB_INPUT_ESC was selected.
 *
 * If 'mode' is TB_INPUT_CURRENT, it returns the current input mode.
 *
 * Default termbox input mode is TB_INPUT_ESC.
 */
private extern (C) int tb_select_input_mode(int mode);

enum InputMode {
    current = 0,
    esc     = 1,
    alt     = 2,
    mouse   = 4
}

enum OutputMode {
    current   = 0,
    normal    = 1,
    color256  = 2,
    color216  = 3,
    grayscale = 4
}

/* Sets the termbox output mode. Termbox has three output options:
 * 1. TB_OUTPUT_NORMAL     => [1..8]
 *    This mode provides 8 different colors:
 *      black, red, green, yellow, blue, magenta, cyan, white
 *    Shortcut: TB_BLACK, TB_RED, ...
 *    Attributes: TB_BOLD, TB_UNDERLINE, TB_REVERSE
 *
 *    Example usage:
 *        tb_change_cell(x, y, '@', TB_BLACK | TB_BOLD, TB_RED);
 *
 * 2. TB_OUTPUT_256        => [0..256]
 *    In this mode you can leverage the 256 terminal mode:
 *    0x00 - 0x07: the 8 colors as in TB_OUTPUT_NORMAL
 *    0x08 - 0x0f: TB_* | TB_BOLD
 *    0x10 - 0xe7: 216 different colors
 *    0xe8 - 0xff: 24 different shades of grey
 *
 *    Example usage:
 *        tb_change_cell(x, y, '@', 184, 240);
 *        tb_change_cell(x, y, '@', 0xb8, 0xf0);
 *
 * 2. TB_OUTPUT_216        => [0..216]
 *    This mode supports the 3rd range of the 256 mode only.
 *    But you don't need to provide an offset.
 *
 * 3. TB_OUTPUT_GRAYSCALE  => [0..23]
 *    This mode supports the 4th range of the 256 mode only.
 *    But you dont need to provide an offset.
 *
 * Execute build/src/demo/output to see its impact on your terminal.
 *
 * If 'mode' is TB_OUTPUT_CURRENT, it returns the current output mode.
 *
 * Default termbox output mode is TB_OUTPUT_NORMAL.
 */
private extern (C) int tb_select_output_mode(int mode);

/* Wait for an event up to 'timeout' milliseconds and fill the 'event'
 * structure with it, when the event is available. Returns the type of the
 * event (one of TB_EVENT_* constants) or -1 if there was an error or 0 in case
 * there were no event during 'timeout' period.
 */
private extern (C) int tb_peek_event(Event* event, int timeout);

/* Wait for an event forever and fill the 'event' structure with it, when the
 * event is available. Returns the type of the event (one of TB_EVENT_*
 * constants) or -1 if there was an error.
 */
private extern (C) int tb_poll_event(Event* event);

/* Utility utf8 functions. */
enum TB_EOF = -1;
private extern (C) int tb_utf8_char_length(char c);
private extern (C) int tb_utf8_char_to_unicode(uint* out_, const char* c);
private extern (C) int tb_utf8_unicode_to_char(char* out_, uint c);


int init() { return tb_init(); }
void shutdown() { tb_shutdown(); }

int height() { return tb_height(); }
int width() { return tb_width(); }

void clear() { tb_clear(); }
void setClearAttributes(ushort fg, ushort bg) { tb_set_clear_attributes(fg, bg); }

void flush() { tb_present(); }

void setCursor(int cx, int cy) { tb_set_cursor(cx, cy); }

void putCell(int x, int y, Cell* cell) { tb_put_cell(x, y, cell); }
void setCell(int x, int y, uint ch, ushort fg, ushort bg) { tb_change_cell(x, y, ch, fg, bg); }

Cell* cellBuffer() { return tb_cell_buffer(); }

int setInputMode(InputMode mode) { return tb_select_input_mode(mode); }
int setOutputMode(OutputMode mode) { return tb_select_output_mode(mode); }

int peekEvent(Event* event, int timeout) { return tb_peek_event(event, timeout); }
int pollEvent(Event* event) { return tb_poll_event(event); }

int charLength(char c) { return tb_utf8_char_length(c); }
int charToUnicode(uint* out_, const char* c) { return tb_utf8_char_to_unicode(out_, c); }
int unicodeToChar(char* out_, uint c) { return tb_utf8_unicode_to_char(out_, c); }

void hideCursor() { setCursor(-1, -1); }
