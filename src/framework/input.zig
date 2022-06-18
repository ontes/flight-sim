pub const Event = union(enum) {
    key_press: Key,
    key_release: Key,
    mouse_move: [2]i32,
    mouse_scroll: i8,
    mouse_enter: void,
    mouse_leave: void,
    window_move: [2]i32,
    window_resize: [2]u32,
    window_focus: void,
    window_unfocus: void,
    window_close: void,
};

pub const EventCallback = fn (Event) void;

// keycodes from HID https://usb.org/sites/default/files/hut1_3_0.pdf (chapter 10)
pub const Key = enum(u8) {
    // common keys
    a = 4,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,
    n1,
    n2,
    n3,
    n4,
    n5,
    n6,
    n7,
    n8,
    n9,
    n0,
    enter,
    escape,
    backspace,
    tab,
    space,
    minus, //         - and _
    equal, //         = and +
    left_bracket, //  [ and {
    right_bracket, // ] and }
    backslash, //     \ and |
    nonus_hash, //    # and ~
    semicolon, //     ; and :
    apostrophe, //    ' and "
    grave, //         ` and ~
    comma, //         , and <
    period, //        . and >
    slash, //         / and ?
    caps_lock,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
    print,
    scroll_lock,
    pause,
    insert,
    home,
    page_up,
    delete,
    end,
    page_down,
    right,
    left,
    down,
    up,

    // uncommon keys
    num_lock,
    kp_divide,
    kp_multiply,
    kp_subtract,
    kp_add,
    kp_enter,
    kp_n1,
    kp_n2,
    kp_n3,
    kp_n4,
    kp_n5,
    kp_n6,
    kp_n7,
    kp_n8,
    kp_n9,
    kp_n0,
    kp_decimal,
    nonus_backslash,
    application,

    // rare keys
    power,
    kp_equal,
    f13,
    f14,
    f15,
    f16,
    f17,
    f18,
    f19,
    f20,
    f21,
    f22,
    f23,
    f24,
    execute,
    help,
    menu,
    select,
    stop,
    again,
    undo,
    cut,
    copy,
    paste,
    find,
    mute,
    volume_up,
    volume_down,

    // (not listed) legendary keys

    // modifier keys
    left_ctrl = 224,
    left_shift,
    left_alt,
    left_super,
    right_ctrl,
    right_shift,
    right_alt,
    right_super,

    // mouse (not in HID)
    mouse_left,
    mouse_right,
    mouse_middle,
    mouse_back,
    mouse_forward,
};

pub const Input = struct {
    keys: [256]bool = .{false} ** 256,
    mouse_position: [2]i32 = .{ 0, 0 },
    mouse_scroll: i32 = 0,
    mouse_inside: bool = false,

    window_position: [2]i32 = .{ 0, 0 },
    window_size: [2]u32 = .{ 0, 0 },
    window_focused: bool = false,

    should_close: bool = false,

    pub fn handleEvent(self: *Input, event: Event) void {
        switch (event) {
            .key_press => |key| {
                self.keys[@enumToInt(key)] = true;
            },
            .key_release => |key| {
                self.keys[@enumToInt(key)] = false;
            },
            .mouse_move => |position| {
                self.mouse_position = position;
            },
            .mouse_scroll => |offset| {
                self.mouse_scroll += offset;
            },
            .mouse_enter => {
                self.mouse_inside = true;
            },
            .mouse_leave => {
                self.mouse_inside = false;
            },
            .window_move => |position| {
                self.window_position = position;
            },
            .window_resize => |size| {
                self.window_size = size;
            },
            .window_focus => {
                self.window_focused = true;
            },
            .window_unfocus => {
                self.window_focused = false;
            },
            .window_close => {
                self.should_close = true;
            },
        }
    }

    pub fn isPressed(self: Input, key: Key) bool {
        return self.keys[@enumToInt(key)];
    }
};
