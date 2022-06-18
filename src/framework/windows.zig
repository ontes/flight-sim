const std = @import("std");
const c = @import("c.zig");
const input = @import("input.zig");

var wclass: c.WNDCLASSA = undefined;

pub fn init() !void {
    wclass = std.mem.zeroes(c.WNDCLASSA);
    wclass.style = c.CS_OWNDC;
    wclass.lpfnWndProc = windowProc;
    wclass.hInstance = c.GetModuleHandleA(null);
    wclass.lpszClassName = "ONTES";

    if (c.RegisterClassA(&wclass) == 0)
        return error.WindowsError;
}

pub fn deinit() void {}

pub const Window = struct {
    win: c.HWND,
    dc: c.HDC,
    ctx: ?c.HGLRC = null,

    pub fn create(position: [2]i32, size: [2]u32, name: [:0]const u8, callback: input.EventCallback) !Window {
        const win = c.CreateWindowExA( //
            c.WS_EX_APPWINDOW, wclass.lpszClassName, name, c.WS_OVERLAPPEDWINDOW, //
            position[0], position[1], @intCast(c_int, size[0]), @intCast(c_int, size[1]), //
            0, 0, wclass.hInstance, @intToPtr(*anyopaque, @ptrToInt(callback)) //
        ) orelse return error.WindowError;

        return Window{
            .win = win,
            .dc = c.GetDC(win),
        };
    }

    pub fn destroy(self: Window) void {
        if (self.ctx) |ctx|
            _ = c.wglDeleteContext(ctx);

        _ = c.ReleaseDC(self.win, self.dc);
        _ = c.DestroyWindow(self.win);
    }

    pub fn show(self: Window) void {
        _ = c.ShowWindow(self.win, c.SW_SHOW);
    }

    pub fn pollEvents(self: *Window) void {
        var msg: c.MSG = undefined;
        while (c.PeekMessageA(&msg, self.win, 0, 0, c.PM_REMOVE) != 0) {
            _ = c.TranslateMessage(&msg);
            _ = c.DispatchMessageA(&msg);
        }
    }

    pub fn createGlContext(self: *Window, colorSize: u8, alphaSize: u8, depthSize: u8, stencilSize: u8, _: u8) !void {
        var pf_desc = std.mem.zeroes(c.PIXELFORMATDESCRIPTOR);
        pf_desc.nSize = @sizeOf(c.PIXELFORMATDESCRIPTOR);
        pf_desc.nVersion = 1;
        pf_desc.dwFlags = c.PFD_DRAW_TO_WINDOW | c.PFD_SUPPORT_OPENGL | c.PFD_GENERIC_ACCELERATED | c.PFD_DOUBLEBUFFER; // | c.PFD_DRAW_TO_BITMAP
        pf_desc.iPixelType = c.PFD_TYPE_RGBA;
        pf_desc.cColorBits = 3 * colorSize;
        pf_desc.cAlphaBits = alphaSize;
        pf_desc.cDepthBits = depthSize;
        pf_desc.cStencilBits = stencilSize;

        const pf = c.ChoosePixelFormat(self.dc, &pf_desc);
        if (pf == 0)
            return error.NoFramebufferError;

        _ = c.SetPixelFormat(self.dc, pf, &pf_desc);

        self.ctx = c.wglCreateContext(self.dc);
    }

    pub fn makeCurrent(self: Window) !void {
        if (self.ctx) |ctx| {
            if (c.wglMakeCurrent(self.dc, ctx) == 0)
                return error.ContextError;
        }
    }

    pub fn swapBuffers(self: Window) void {
        _ = c.SwapBuffers(self.dc);
    }

    pub fn setSwapInterval(_: Window, _: u8) void {
        // TODO
    }
};

fn windowProc(win: c.HWND, msg: c.UINT, w: c.WPARAM, l: c.LPARAM) callconv(.C) c.LRESULT {
    const callback = @intToPtr(?input.EventCallback, @intCast(usize, c.GetWindowLongPtrA(win, c.GWLP_USERDATA)));

    switch (msg) {
        c.WM_CREATE => {
            _ = c.SetWindowLongPtrA(win, c.GWLP_USERDATA, @intCast(c_longlong, @ptrToInt(@intToPtr(*c.CREATESTRUCTA, @intCast(usize, l)).lpCreateParams)));
        },
        c.WM_KEYDOWN, c.WM_SYSKEYDOWN => {
            // skip auto-repeated key events
            if ((l >> 16) & c.KF_REPEAT == 0) { // c.HIWORD
                if (keycodeToKey(w)) |key|
                    callback.?(.{ .key_press = key });
            }
        },
        c.WM_KEYUP, c.WM_SYSKEYUP => {
            if (keycodeToKey(w)) |key|
                callback.?(.{ .key_release = key });
        },
        c.WM_LBUTTONDOWN, c.WM_MBUTTONDOWN, c.WM_RBUTTONDOWN, c.WM_XBUTTONDOWN => {
            if (buttonToKey(msg, w)) |key|
                callback.?(.{ .key_press = key });
        },
        c.WM_LBUTTONUP, c.WM_MBUTTONUP, c.WM_RBUTTONUP, c.WM_XBUTTONUP => {
            if (buttonToKey(msg, w)) |key|
                callback.?(.{ .key_release = key });
        },
        c.WM_MOUSEMOVE => {
            callback.?(.{
                .mouse_move = .{
                    @intCast(i32, (l) & 0xffff), // c.GET_X_LPARAM
                    @intCast(i32, (l >> 16) & 0xffff), // c.GET_Y_LPARAM
                },
            });
        },
        c.WM_MOUSEWHEEL => {
            callback.?(.{ .mouse_scroll = @intCast(i8, @divTrunc(@bitCast(i16, @intCast(u16, @bitCast(u64, w) >> 16)), c.WHEEL_DELTA)) });
        },
        c.WM_SIZE => {
            callback.?(.{ .window_resize = .{
                @intCast(u32, l & 0xffff),
                @intCast(u32, (l >> 16) & 0xffff),
            } });
        },
        c.WM_CLOSE => {
            callback.?(.window_close);
        },
        else => {
            return c.DefWindowProcA(win, msg, w, l);
        },
    }
    return 0;
}

fn buttonToKey(msg: c.UINT, w: c.WPARAM) ?input.Key {
    return switch (msg) {
        c.WM_LBUTTONDOWN, c.WM_LBUTTONUP => .mouse_left,
        c.WM_MBUTTONDOWN, c.WM_MBUTTONUP => .mouse_middle,
        c.WM_RBUTTONDOWN, c.WM_RBUTTONUP => .mouse_right,
        c.WM_XBUTTONDOWN, c.WM_XBUTTONUP => return if ((w >> 16) == 1) .mouse_back else .mouse_forward,
        else => null,
    };
}

fn keycodeToKey(wparam: c.WPARAM) ?input.Key {
    return switch (wparam) {
        'A' => .a,
        'B' => .b,
        'C' => .c,
        'D' => .d,
        'E' => .e,
        'F' => .f,
        'G' => .g,
        'H' => .h,
        'I' => .i,
        'J' => .j,
        'K' => .k,
        'L' => .l,
        'M' => .m,
        'N' => .n,
        'O' => .o,
        'P' => .p,
        'Q' => .q,
        'R' => .r,
        'S' => .s,
        'T' => .t,
        'U' => .u,
        'V' => .v,
        'W' => .w,
        'X' => .x,
        'Y' => .y,
        'Z' => .z,
        '0' => .n0,
        '1' => .n1,
        '2' => .n2,
        '3' => .n3,
        '4' => .n4,
        '5' => .n5,
        '6' => .n6,
        '7' => .n7,
        '8' => .n8,
        '9' => .n9,
        c.VK_RETURN => .enter,
        c.VK_ESCAPE => .escape,
        c.VK_BACK => .backspace,
        c.VK_TAB => .tab,
        c.VK_SPACE => .space,
        c.VK_OEM_MINUS => .minus,
        c.VK_OEM_PLUS => .equal,
        c.VK_OEM_4 => .left_bracket,
        c.VK_OEM_6 => .right_bracket,
        c.VK_OEM_5 => .backslash,
        c.VK_OEM_8 => .nonus_hash,
        c.VK_OEM_1 => .semicolon,
        c.VK_OEM_7 => .apostrophe,
        c.VK_OEM_3 => .grave,
        c.VK_OEM_COMMA => .comma,
        c.VK_OEM_PERIOD => .period,
        c.VK_OEM_2 => .slash,
        c.VK_CAPITAL => .caps_lock,
        c.VK_F1 => .f1,
        c.VK_F2 => .f2,
        c.VK_F3 => .f3,
        c.VK_F4 => .f4,
        c.VK_F5 => .f5,
        c.VK_F6 => .f6,
        c.VK_F7 => .f7,
        c.VK_F8 => .f8,
        c.VK_F9 => .f9,
        c.VK_F10 => .f10,
        c.VK_F11 => .f11,
        c.VK_F12 => .f12,
        c.VK_SNAPSHOT => .print,
        c.VK_SCROLL => .scroll_lock,
        c.VK_PAUSE => .pause,
        c.VK_INSERT => .insert,
        c.VK_HOME => .home,
        c.VK_PRIOR => .page_up,
        c.VK_DELETE => .delete,
        c.VK_END => .end,
        c.VK_NEXT => .page_down,
        c.VK_RIGHT => .right,
        c.VK_LEFT => .left,
        c.VK_DOWN => .down,
        c.VK_UP => .up,
        c.VK_NUMLOCK => .num_lock,
        c.VK_DIVIDE => .kp_divide,
        c.VK_MULTIPLY => .kp_multiply,
        c.VK_SUBTRACT => .kp_subtract,
        c.VK_ADD => .kp_add,
        c.VK_SEPARATOR => .kp_enter,
        c.VK_NUMPAD0 => .kp_n0,
        c.VK_NUMPAD1 => .kp_n1,
        c.VK_NUMPAD2 => .kp_n2,
        c.VK_NUMPAD3 => .kp_n3,
        c.VK_NUMPAD4 => .kp_n4,
        c.VK_NUMPAD5 => .kp_n5,
        c.VK_NUMPAD6 => .kp_n6,
        c.VK_NUMPAD7 => .kp_n7,
        c.VK_NUMPAD8 => .kp_n8,
        c.VK_NUMPAD9 => .kp_n9,
        c.VK_DECIMAL => .kp_decimal,
        c.VK_OEM_102 => .nonus_backslash,
        c.VK_APPS => .application,
        c.VK_CONTROL, c.VK_LCONTROL => .left_ctrl,
        c.VK_SHIFT, c.VK_LSHIFT => .left_shift,
        c.VK_MENU, c.VK_LMENU => .left_alt,
        c.VK_LWIN => .left_super,
        c.VK_RCONTROL => .right_ctrl,
        c.VK_RSHIFT => .right_shift,
        c.VK_RMENU => .right_alt,
        c.VK_RWIN => .right_super,
        else => null,
    };
}
