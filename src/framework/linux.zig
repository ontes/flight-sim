const std = @import("std");
const c = @import("c.zig");
const input = @import("input.zig");

var display: *c.Display = undefined;

var glXCreateContextAttribsARB: c.PFNGLXCREATECONTEXTATTRIBSARBPROC = null;
var glXSwapIntervalEXT: c.PFNGLXSWAPINTERVALEXTPROC = null;

pub fn init() !void {
    display = c.XOpenDisplay(null) orelse return error.NoDisplayError;

    const extensions = std.mem.span(c.glXQueryExtensionsString(display, c.XDefaultScreen(display)));

    if (std.mem.indexOf(u8, extensions, "GLX_ARB_create_context_profile") != null)
        glXCreateContextAttribsARB = @ptrCast(@TypeOf(glXCreateContextAttribsARB), c.glXGetProcAddress("glXCreateContextAttribsARB"));
    if (std.mem.indexOf(u8, extensions, "GLX_EXT_swap_control") != null)
        glXSwapIntervalEXT = @ptrCast(@TypeOf(glXSwapIntervalEXT), c.glXGetProcAddress("glXSwapIntervalEXT"));
}

pub fn deinit() void {
    _ = c.XCloseDisplay(display);
    display = undefined;
}

pub const Window = struct {
    win: c.Window,
    callback: input.EventCallback,
    ctx: ?c.GLXContext = null,

    pub fn create(position: [2]i32, size: [2]u32, name: [:0]const u8, callback: input.EventCallback) !Window {
        const self = Window{
            .win = c.XCreateSimpleWindow(display, c.XDefaultRootWindow(display), //
                position[0], position[1], size[0], size[1], //
                0, 0, 0),
            .callback = callback,
        };

        self.rename(name);

        _ = c.XSelectInput(display, self.win, 0 //
        | c.KeyPressMask //
        | c.KeyReleaseMask //
        | c.PointerMotionMask //
        | c.ButtonPressMask //
        | c.ButtonReleaseMask //
        | c.EnterWindowMask //
        | c.LeaveWindowMask //
        | c.FocusChangeMask //
        | c.StructureNotifyMask //
        );

        // set up window close event
        var atom = c.XInternAtom(display, "WM_DELETE_WINDOW", c.True);
        _ = c.XSetWMProtocols(display, self.win, &atom, 1);

        return self;
    }

    pub fn destroy(self: Window) void {
        if (self.ctx) |ctx|
            c.glXDestroyContext(display, ctx);

        _ = c.XDestroyWindow(display, self.win);
    }

    pub fn show(self: Window) void {
        _ = c.XMapRaised(display, self.win);
    }

    pub fn move(self: Window, position: [2]i32) void {
        _ = c.XMoveWindow(display, self.win, position[0], position[1]);
    }

    pub fn resize(self: Window, size: [2]u32) void {
        _ = c.XResizeWindow(display, self.win, size[0], size[1]);
    }

    pub fn rename(self: Window, name: [:0]const u8) void {
        _ = c.XStoreName(display, self.win, name);
    }

    pub fn grabCursor(self: Window) void {
        _ = c.XGrabPointer(display, self.win, c.True, c.None, c.GrabModeAsync, c.GrabModeAsync, self.win, c.None, c.CurrentTime);
    }

    pub fn ungrabCursor(_: Window) void {
        _ = c.XUngrabPointer(display, c.CurrentTime);
    }

    pub fn hideCursor(self: Window) void {
        // create an empty cursor
        var color: c.XColor = undefined;
        var pixmap = c.XCreatePixmap(display, self.win, 1, 1, 1);
        defer _ = c.XFreePixmap(display, pixmap);
        var cursor = c.XCreatePixmapCursor(display, pixmap, pixmap, &color, &color, 0, 0);
        defer _ = c.XFreeCursor(display, cursor);

        _ = c.XDefineCursor(display, self.win, cursor);
    }

    pub fn unhideCursor(self: Window) void {
        _ = c.XUndefineCursor(display, self.win);
    }

    // ===
    // Input
    // ===

    pub fn pollEvents(self: *Window) void {
        const check = struct {
            fn check(_: ?*c.Display, event: ?*c.XEvent, window: c.XPointer) callconv(.C) c_int {
                return @boolToInt(event.?.xany.window == @ptrToInt(window));
            }
        }.check;

        var event: c.XEvent = undefined;
        while (c.XCheckIfEvent(display, &event, check, @intToPtr(c.XPointer, self.win)) != 0) {
            switch (event.type) {
                c.KeyPress => {
                    if (keysymToKey(c.XLookupKeysym(&event.xkey, 0))) |key|
                        self.callback(.{ .key_press = key });
                },
                c.KeyRelease => {
                    // skip auto-repeated key events
                    var next_event: c.XEvent = undefined;
                    if (c.XCheckIfEvent(display, &next_event, check, @intToPtr(c.XPointer, self.win)) != 0) {
                        if (next_event.type == c.KeyPress and next_event.xkey.keycode == event.xkey.keycode)
                            continue;
                        _ = c.XPutBackEvent(display, &next_event);
                    }

                    if (keysymToKey(c.XLookupKeysym(&event.xkey, 0))) |key|
                        self.callback(.{ .key_release = key });
                },
                c.ButtonPress => {
                    if (buttonToKey(event.xbutton.button)) |key|
                        self.callback(.{ .key_press = key });
                    if (event.xbutton.button == c.Button4)
                        self.callback(.{ .mouse_scroll = 1 });
                    if (event.xbutton.button == c.Button5)
                        self.callback(.{ .mouse_scroll = -1 });
                },
                c.ButtonRelease => {
                    if (buttonToKey(event.xbutton.button)) |key|
                        self.callback(.{ .key_press = key });
                },
                c.MotionNotify => {
                    self.callback(.{ .mouse_move = .{
                        event.xmotion.x,
                        event.xmotion.y,
                    } });
                },
                c.EnterNotify => {
                    if (event.xcrossing.mode == c.NotifyNormal)
                        self.callback(.mouse_enter);
                },
                c.LeaveNotify => {
                    if (event.xcrossing.mode == c.NotifyNormal)
                        self.callback(.mouse_leave);
                },
                c.FocusIn => {
                    if (event.xfocus.mode == c.NotifyNormal)
                        self.callback(.window_focus);
                },
                c.FocusOut => {
                    if (event.xfocus.mode == c.NotifyNormal)
                        self.callback(.window_unfocus);
                },
                c.ConfigureNotify => {
                    self.callback(.{ .window_resize = .{
                        @intCast(u16, event.xconfigure.width),
                        @intCast(u16, event.xconfigure.height),
                    } });
                },
                c.ClientMessage => {
                    if (event.xclient.data.l[0] == c.XInternAtom(display, "WM_DELETE_WINDOW", 1))
                        self.callback(.window_close);
                },
                c.MappingNotify => {
                    _ = c.XRefreshKeyboardMapping(&event.xmapping);
                },
                c.DestroyNotify => {},
                else => {},
            }
        }
    }

    pub fn createGlContext(self: *Window, colorSize: u8, alphaSize: u8, depthSize: u8, stencilSize: u8, samples: u8) !void {
        if (self.ctx != null) return;

        const fb_attribs = [_:c.None]c_int{
            c.GLX_RENDER_TYPE,    c.GLX_RGBA_BIT, //
            c.GLX_DRAWABLE_TYPE,  c.GLX_WINDOW_BIT,
            c.GLX_X_RENDERABLE,   c.True,
            c.GLX_X_VISUAL_TYPE,  c.GLX_TRUE_COLOR,
            c.GLX_DOUBLEBUFFER,   c.True,
            c.GLX_RED_SIZE,       colorSize,
            c.GLX_GREEN_SIZE,     colorSize,
            c.GLX_BLUE_SIZE,      colorSize,
            c.GLX_ALPHA_SIZE,     alphaSize,
            c.GLX_DEPTH_SIZE,     depthSize,
            c.GLX_STENCIL_SIZE,   stencilSize,
            c.GLX_SAMPLE_BUFFERS, if (samples > 0) c.True else c.False,
            c.GLX_SAMPLES,        samples,
        };

        const ctx_attribs = [_:c.None]c_int{
            c.GLX_CONTEXT_MAJOR_VERSION_ARB, 4, //
            c.GLX_CONTEXT_MINOR_VERSION_ARB, 4,
            c.GLX_CONTEXT_PROFILE_MASK_ARB,  c.GLX_CONTEXT_CORE_PROFILE_BIT_ARB,
            c.GLX_CONTEXT_FLAGS_ARB,         if (@import("builtin").mode == .Debug) c.GLX_CONTEXT_DEBUG_BIT_ARB else 0,
        };

        var fb_count: c_int = 0;
        const fb_configs = c.glXChooseFBConfig(display, c.XDefaultScreen(display), &fb_attribs, &fb_count);

        if (fb_count == 0 or fb_configs == null)
            return error.NoFramebufferError;

        const fb_config = fb_configs[0];
        _ = c.XFree(fb_configs);

        if (glXCreateContextAttribsARB) |glXCreateContextAttribs|
            self.ctx = glXCreateContextAttribs(display, fb_config, null, c.True, &ctx_attribs);
        if (self.ctx == null)
            self.ctx = c.glXCreateNewContext(display, fb_config, c.GLX_RGBA_TYPE, null, c.True) orelse return error.GlContextError;
    }

    pub fn makeCurrent(self: Window) !void {
        if (self.ctx) |ctx| {
            if (c.glXMakeCurrent(display, self.win, ctx) == 0)
                return error.GlContextError;
        }
    }

    pub fn swapBuffers(self: Window) void {
        c.glXSwapBuffers(display, self.win);
    }

    pub fn setSwapInterval(self: Window, interval: u8) void {
        if (glXSwapIntervalEXT) |glXSwapInterval|
            glXSwapInterval(display, self.win, interval);
    }
};

fn buttonToKey(n: u32) ?input.Key {
    return switch (n) {
        c.Button1 => .mouse_left,
        c.Button2 => .mouse_middle,
        c.Button3 => .mouse_right,
        8 => .mouse_back,
        9 => .mouse_forward,
        else => null,
    };
}

fn keysymToKey(sym: u64) ?input.Key {
    return switch (sym) {
        c.XK_a => .a,
        c.XK_b => .b,
        c.XK_c => .c,
        c.XK_d => .d,
        c.XK_e => .e,
        c.XK_f => .f,
        c.XK_g => .g,
        c.XK_h => .h,
        c.XK_i => .i,
        c.XK_j => .j,
        c.XK_k => .k,
        c.XK_l => .l,
        c.XK_m => .m,
        c.XK_n => .n,
        c.XK_o => .o,
        c.XK_p => .p,
        c.XK_q => .q,
        c.XK_r => .r,
        c.XK_s => .s,
        c.XK_t => .t,
        c.XK_u => .u,
        c.XK_v => .v,
        c.XK_w => .w,
        c.XK_x => .x,
        c.XK_y => .y,
        c.XK_z => .z,
        c.XK_0 => .n0,
        c.XK_1 => .n1,
        c.XK_2 => .n2,
        c.XK_3 => .n3,
        c.XK_4 => .n4,
        c.XK_5 => .n5,
        c.XK_6 => .n6,
        c.XK_7 => .n7,
        c.XK_8 => .n8,
        c.XK_9 => .n9,
        c.XK_Return => .enter,
        c.XK_Escape => .escape,
        c.XK_BackSpace => .backspace,
        c.XK_Tab => .tab,
        c.XK_space => .space,
        c.XK_minus => .minus,
        c.XK_equal => .equal,
        c.XK_bracketleft => .left_bracket,
        c.XK_bracketright => .right_bracket,
        c.XK_backslash => .backslash,
        // .nonus_hash
        c.XK_semicolon => .semicolon,
        c.XK_apostrophe => .apostrophe,
        c.XK_grave => .grave,
        c.XK_comma => .comma,
        c.XK_period => .period,
        c.XK_slash => .slash,
        c.XK_Caps_Lock => .caps_lock,
        c.XK_F1 => .f1,
        c.XK_F2 => .f2,
        c.XK_F3 => .f3,
        c.XK_F4 => .f4,
        c.XK_F5 => .f5,
        c.XK_F6 => .f6,
        c.XK_F7 => .f7,
        c.XK_F8 => .f8,
        c.XK_F9 => .f9,
        c.XK_F10 => .f10,
        c.XK_F11 => .f11,
        c.XK_F12 => .f12,
        c.XK_Print => .print,
        c.XK_Scroll_Lock => .scroll_lock,
        c.XK_Pause => .pause,
        c.XK_Insert => .insert,
        c.XK_Home => .home,
        c.XK_Page_Up => .page_up,
        c.XK_Delete => .delete,
        c.XK_End => .end,
        c.XK_Page_Down => .page_down,
        c.XK_Right => .right,
        c.XK_Left => .left,
        c.XK_Down => .down,
        c.XK_Up => .up,
        c.XK_Num_Lock => .num_lock,
        c.XK_KP_Divide => .kp_divide,
        c.XK_KP_Multiply => .kp_multiply,
        c.XK_KP_Subtract => .kp_subtract,
        c.XK_KP_Add => .kp_add,
        c.XK_KP_Enter => .kp_enter,
        c.XK_KP_0 => .kp_n0,
        c.XK_KP_1 => .kp_n1,
        c.XK_KP_2 => .kp_n2,
        c.XK_KP_3 => .kp_n3,
        c.XK_KP_4 => .kp_n4,
        c.XK_KP_5 => .kp_n5,
        c.XK_KP_6 => .kp_n6,
        c.XK_KP_7 => .kp_n7,
        c.XK_KP_8 => .kp_n8,
        c.XK_KP_9 => .kp_n9,
        c.XK_KP_Decimal => .kp_decimal,
        // .nonus_backslash
        // .application
        c.XK_Control_L => .left_ctrl,
        c.XK_Shift_L => .left_shift,
        c.XK_Alt_L => .left_alt,
        c.XK_Super_L => .left_super,
        c.XK_Control_R => .right_ctrl,
        c.XK_Shift_R => .right_shift,
        c.XK_Alt_R => .right_alt,
        c.XK_Super_R => .right_super,
        else => null,
    };
}
