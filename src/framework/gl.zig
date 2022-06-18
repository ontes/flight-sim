const builtin = @import("builtin");
const c = @import("c.zig");
const math = @import("math.zig");

var glCreateShader: @typeInfo(c.PFNGLCREATESHADERPROC).Optional.child = undefined;
var glShaderSource: @typeInfo(c.PFNGLSHADERSOURCEPROC).Optional.child = undefined;
var glCompileShader: @typeInfo(c.PFNGLCOMPILESHADERPROC).Optional.child = undefined;
var glDeleteShader: @typeInfo(c.PFNGLDELETESHADERPROC).Optional.child = undefined;

var glCreateProgram: @typeInfo(c.PFNGLCREATEPROGRAMPROC).Optional.child = undefined;
var glAttachShader: @typeInfo(c.PFNGLATTACHSHADERPROC).Optional.child = undefined;
var glLinkProgram: @typeInfo(c.PFNGLLINKPROGRAMPROC).Optional.child = undefined;
var glDetachShader: @typeInfo(c.PFNGLDETACHSHADERPROC).Optional.child = undefined;
var glUseProgram: @typeInfo(c.PFNGLUSEPROGRAMPROC).Optional.child = undefined;
var glDeleteProgram: @typeInfo(c.PFNGLDELETEPROGRAMPROC).Optional.child = undefined;

var glProgramUniform1f: @typeInfo(c.PFNGLPROGRAMUNIFORM1FPROC).Optional.child = undefined;
var glProgramUniform1i: @typeInfo(c.PFNGLPROGRAMUNIFORM1IPROC).Optional.child = undefined;
var glProgramUniform1ui: @typeInfo(c.PFNGLPROGRAMUNIFORM1UIPROC).Optional.child = undefined;
var glProgramUniform2fv: @typeInfo(c.PFNGLPROGRAMUNIFORM2FVPROC).Optional.child = undefined;
var glProgramUniform3fv: @typeInfo(c.PFNGLPROGRAMUNIFORM3FVPROC).Optional.child = undefined;
var glProgramUniform4fv: @typeInfo(c.PFNGLPROGRAMUNIFORM4FVPROC).Optional.child = undefined;
var glProgramUniformMatrix3fv: @typeInfo(c.PFNGLPROGRAMUNIFORMMATRIX3FVPROC).Optional.child = undefined;
var glProgramUniformMatrix4fv: @typeInfo(c.PFNGLPROGRAMUNIFORMMATRIX4FVPROC).Optional.child = undefined;

var glCreateBuffers: @typeInfo(c.PFNGLCREATEBUFFERSPROC).Optional.child = undefined;
var glNamedBufferStorage: @typeInfo(c.PFNGLNAMEDBUFFERSTORAGEPROC).Optional.child = undefined;
var glDeleteBuffers: @typeInfo(c.PFNGLDELETEBUFFERSPROC).Optional.child = undefined;

var glCreateVertexArrays: @typeInfo(c.PFNGLCREATEVERTEXARRAYSPROC).Optional.child = undefined;
var glBindVertexArray: @typeInfo(c.PFNGLBINDVERTEXARRAYPROC).Optional.child = undefined;
var glVertexArrayVertexBuffer: @typeInfo(c.PFNGLVERTEXARRAYVERTEXBUFFERPROC).Optional.child = undefined;
var glEnableVertexArrayAttrib: @typeInfo(c.PFNGLENABLEVERTEXARRAYATTRIBPROC).Optional.child = undefined;
var glVertexArrayAttribFormat: @typeInfo(c.PFNGLVERTEXARRAYATTRIBFORMATPROC).Optional.child = undefined;
var glVertexArrayAttribBinding: @typeInfo(c.PFNGLVERTEXARRAYATTRIBBINDINGPROC).Optional.child = undefined;
var glVertexArrayElementBuffer: @typeInfo(c.PFNGLVERTEXARRAYELEMENTBUFFERPROC).Optional.child = undefined;
var glDeleteVertexArrays: @typeInfo(c.PFNGLDELETEVERTEXARRAYSPROC).Optional.child = undefined;

var glCreateTextures: @typeInfo(c.PFNGLCREATETEXTURESPROC).Optional.child = undefined;
var glTextureStorage2D: @typeInfo(c.PFNGLTEXTURESTORAGE2DPROC).Optional.child = undefined;
var glTextureSubImage2D: @typeInfo(c.PFNGLTEXTURESUBIMAGE2DPROC).Optional.child = undefined;
var glGenerateTextureMipmap: @typeInfo(c.PFNGLGENERATETEXTUREMIPMAPPROC).Optional.child = undefined;
var glBindTextureUnit: @typeInfo(c.PFNGLBINDTEXTUREUNITPROC).Optional.child = undefined;
var glTextureParameteri: @typeInfo(c.PFNGLTEXTUREPARAMETERIPROC).Optional.child = undefined;

var glCreateFramebuffers: @typeInfo(c.PFNGLCREATEFRAMEBUFFERSPROC).Optional.child = undefined;
var glDeleteFramebuffers: @typeInfo(c.PFNGLDELETEFRAMEBUFFERSPROC).Optional.child = undefined;
var glNamedFramebufferDrawBuffer: @typeInfo(c.PFNGLNAMEDFRAMEBUFFERDRAWBUFFERPROC).Optional.child = undefined;
var glNamedFramebufferTexture: @typeInfo(c.PFNGLNAMEDFRAMEBUFFERTEXTUREPROC).Optional.child = undefined;
var glBindFramebuffer: @typeInfo(c.PFNGLBINDFRAMEBUFFERPROC).Optional.child = undefined;
var glClearNamedFramebufferfv: @typeInfo(c.PFNGLCLEARNAMEDFRAMEBUFFERFVPROC).Optional.child = undefined;

// var xxx: @typeInfo(c.PFNxxxPROC).Optional.child = undefined;
// xxx = @ptrCast(@TypeOf(xxx), getProc("xxx"));

fn debugCallback(_: c.GLenum, _: c.GLuint, _: c.GLuint, severity: c.GLenum, len: c.GLsizei, msg: [*c]const c.GLchar, _: ?*const anyopaque) callconv(.C) void {
    @import("std").log.info("{s}", .{msg[0..@intCast(usize, len)]});
    if (severity == c.GL_DEBUG_SEVERITY_MEDIUM or severity == c.GL_DEBUG_SEVERITY_HIGH)
        @panic("gl error");
}

pub fn init() void {
    const getProc = switch (builtin.os.tag) {
        .linux => c.glXGetProcAddress,
        .windows => c.wglGetProcAddress,
        else => @compileError("unsupported os"),
    };

    glCreateShader = @ptrCast(@TypeOf(glCreateShader), getProc("glCreateShader"));
    glShaderSource = @ptrCast(@TypeOf(glShaderSource), getProc("glShaderSource"));
    glCompileShader = @ptrCast(@TypeOf(glCompileShader), getProc("glCompileShader"));
    glDeleteShader = @ptrCast(@TypeOf(glDeleteShader), getProc("glDeleteShader"));

    glCreateProgram = @ptrCast(@TypeOf(glCreateProgram), getProc("glCreateProgram"));
    glAttachShader = @ptrCast(@TypeOf(glAttachShader), getProc("glAttachShader"));
    glLinkProgram = @ptrCast(@TypeOf(glLinkProgram), getProc("glLinkProgram"));
    glDetachShader = @ptrCast(@TypeOf(glDetachShader), getProc("glDetachShader"));
    glUseProgram = @ptrCast(@TypeOf(glUseProgram), getProc("glUseProgram"));
    glDeleteProgram = @ptrCast(@TypeOf(glDeleteProgram), getProc("glDeleteProgram"));

    glProgramUniform1f = @ptrCast(@TypeOf(glProgramUniform1f), getProc("glProgramUniform1f"));
    glProgramUniform1i = @ptrCast(@TypeOf(glProgramUniform1i), getProc("glProgramUniform1i"));
    glProgramUniform1ui = @ptrCast(@TypeOf(glProgramUniform1ui), getProc("glProgramUniform1ui"));
    glProgramUniform2fv = @ptrCast(@TypeOf(glProgramUniform2fv), getProc("glProgramUniform2fv"));
    glProgramUniform3fv = @ptrCast(@TypeOf(glProgramUniform3fv), getProc("glProgramUniform3fv"));
    glProgramUniform4fv = @ptrCast(@TypeOf(glProgramUniform4fv), getProc("glProgramUniform4fv"));
    glProgramUniformMatrix3fv = @ptrCast(@TypeOf(glProgramUniformMatrix3fv), getProc("glProgramUniformMatrix3fv"));
    glProgramUniformMatrix4fv = @ptrCast(@TypeOf(glProgramUniformMatrix4fv), getProc("glProgramUniformMatrix4fv"));

    glCreateBuffers = @ptrCast(@TypeOf(glCreateBuffers), getProc("glCreateBuffers"));
    glNamedBufferStorage = @ptrCast(@TypeOf(glNamedBufferStorage), getProc("glNamedBufferStorage"));
    glDeleteBuffers = @ptrCast(@TypeOf(glDeleteBuffers), getProc("glDeleteBuffers"));

    glCreateVertexArrays = @ptrCast(@TypeOf(glCreateVertexArrays), getProc("glCreateVertexArrays"));
    glBindVertexArray = @ptrCast(@TypeOf(glBindVertexArray), getProc("glBindVertexArray"));
    glVertexArrayVertexBuffer = @ptrCast(@TypeOf(glVertexArrayVertexBuffer), getProc("glVertexArrayVertexBuffer"));
    glEnableVertexArrayAttrib = @ptrCast(@TypeOf(glEnableVertexArrayAttrib), getProc("glEnableVertexArrayAttrib"));
    glVertexArrayAttribFormat = @ptrCast(@TypeOf(glVertexArrayAttribFormat), getProc("glVertexArrayAttribFormat"));
    glVertexArrayAttribBinding = @ptrCast(@TypeOf(glVertexArrayAttribBinding), getProc("glVertexArrayAttribBinding"));
    glVertexArrayElementBuffer = @ptrCast(@TypeOf(glVertexArrayElementBuffer), getProc("glVertexArrayElementBuffer"));
    glDeleteVertexArrays = @ptrCast(@TypeOf(glDeleteVertexArrays), getProc("glDeleteVertexArrays"));

    glCreateTextures = @ptrCast(@TypeOf(glCreateTextures), getProc("glCreateTextures"));
    glTextureStorage2D = @ptrCast(@TypeOf(glTextureStorage2D), getProc("glTextureStorage2D"));
    glTextureSubImage2D = @ptrCast(@TypeOf(glTextureSubImage2D), getProc("glTextureSubImage2D"));
    glGenerateTextureMipmap = @ptrCast(@TypeOf(glGenerateTextureMipmap), getProc("glGenerateTextureMipmap"));
    glBindTextureUnit = @ptrCast(@TypeOf(glBindTextureUnit), getProc("glBindTextureUnit"));
    glTextureParameteri = @ptrCast(@TypeOf(glTextureParameteri), getProc("glTextureParameteri"));

    glCreateFramebuffers = @ptrCast(@TypeOf(glCreateFramebuffers), getProc("glCreateFramebuffers"));
    glDeleteFramebuffers = @ptrCast(@TypeOf(glDeleteFramebuffers), getProc("glDeleteFramebuffers"));
    glNamedFramebufferDrawBuffer = @ptrCast(@TypeOf(glNamedFramebufferDrawBuffer), getProc("glNamedFramebufferDrawBuffer"));
    glNamedFramebufferTexture = @ptrCast(@TypeOf(glNamedFramebufferTexture), getProc("glNamedFramebufferTexture"));
    glBindFramebuffer = @ptrCast(@TypeOf(glBindFramebuffer), getProc("glBindFramebuffer"));
    glClearNamedFramebufferfv = @ptrCast(@TypeOf(glClearNamedFramebufferfv), getProc("glClearNamedFramebufferfv"));

    if (builtin.mode == .Debug) {
        const glDebugMessageCallback = @ptrCast(@typeInfo(c.PFNGLDEBUGMESSAGECALLBACKPROC).Optional.child, getProc("glDebugMessageCallback"));
        glDebugMessageCallback(debugCallback, null);
        c.glEnable(c.GL_DEBUG_OUTPUT);
    }
}

pub const ShaderType = enum(c.GLenum) {
    compute_shader = c.GL_COMPUTE_SHADER, //
    vertex_shader = c.GL_VERTEX_SHADER,
    tess_control_shader = c.GL_TESS_CONTROL_SHADER,
    tess_evaluation_shader = c.GL_TESS_EVALUATION_SHADER,
    geometry_shader = c.GL_GEOMETRY_SHADER,
    fragment_shader = c.GL_FRAGMENT_SHADER,
};

pub const DrawingMode = enum(c.GLenum) {
    points = c.GL_POINTS,
    line_strip = c.GL_LINE_STRIP,
    line_loop = c.GL_LINE_LOOP,
    lines = c.GL_LINES,
    line_strip_adjacency = c.GL_LINE_STRIP_ADJACENCY,
    lines_adjacency = c.GL_LINES_ADJACENCY,
    triangle_strip = c.GL_TRIANGLE_STRIP,
    triangle_fan = c.GL_TRIANGLE_FAN,
    triangles = c.GL_TRIANGLES,
    triangle_strip_adjacency = c.GL_TRIANGLE_STRIP_ADJACENCY,
    triangles_adjacency = c.GL_TRIANGLES_ADJACENCY,
    patches = c.GL_PATCHES,
};

pub const PolygonMode = enum(c.GLenum) {
    point = c.GL_POINT,
    line = c.GL_LINE,
    fill = c.GL_FILL,
};

pub const TextureWrap = enum(c.GLint) {
    clamp_to_edge = c.GL_CLAMP_TO_EDGE,
    clamp_to_border = c.GL_CLAMP_TO_BORDER,
    mirrored_repeat = c.GL_MIRRORED_REPEAT,
    repeat = c.GL_REPEAT,
    mirror_clamp_to_edge = c.GL_MIRROR_CLAMP_TO_EDGE,
};

pub const TextureFormat = enum(c.GLenum) {
    r8 = c.GL_R8,
    r8_snorm = c.GL_R8_SNORM,
    r16 = c.GL_R16,
    r16_snorm = c.GL_R16_SNORM,
    rg8 = c.GL_RG8,
    rg8_snorm = c.GL_RG8_SNORM,
    rg16 = c.GL_RG16,
    rg16_snorm = c.GL_RG16_SNORM,
    r3_g3_b2 = c.GL_R3_G3_B2,
    rgb4 = c.GL_RGB4,
    rgb5 = c.GL_RGB5,
    rgb8 = c.GL_RGB8,
    rgb8_snorm = c.GL_RGB8_SNORM,
    rgb10 = c.GL_RGB10,
    rgb12 = c.GL_RGB12,
    rgb16_snorm = c.GL_RGB16_SNORM,
    rgba2 = c.GL_RGBA2,
    rgba4 = c.GL_RGBA4,
    rgb5_a1 = c.GL_RGB5_A1,
    rgba8 = c.GL_RGBA8,
    rgba8_snorm = c.GL_RGBA8_SNORM,
    rgb10_a2 = c.GL_RGB10_A2,
    rgb10_a2ui = c.GL_RGB10_A2UI,
    rgba12 = c.GL_RGBA12,
    rgba16 = c.GL_RGBA16,
    srgb8 = c.GL_SRGB8,
    srgb8_alpha8 = c.GL_SRGB8_ALPHA8,
    r16f = c.GL_R16F,
    rg16f = c.GL_RG16F,
    rgb16f = c.GL_RGB16F,
    rgba16f = c.GL_RGBA16F,
    r32f = c.GL_R32F,
    rg32f = c.GL_RG32F,
    rgb32f = c.GL_RGB32F,
    rgba32f = c.GL_RGBA32F,
    r11f_g11f_b10f = c.GL_R11F_G11F_B10F,
    rgb9_e5 = c.GL_RGB9_E5,
    r8i = c.GL_R8I,
    r8ui = c.GL_R8UI,
    r16i = c.GL_R16I,
    r16ui = c.GL_R16UI,
    r32i = c.GL_R32I,
    r32ui = c.GL_R32UI,
    rg8i = c.GL_RG8I,
    rg8ui = c.GL_RG8UI,
    rg16i = c.GL_RG16I,
    rg16ui = c.GL_RG16UI,
    rg32i = c.GL_RG32I,
    rg32ui = c.GL_RG32UI,
    rgb8i = c.GL_RGB8I,
    rgb8ui = c.GL_RGB8UI,
    rgb16i = c.GL_RGB16I,
    rgb16ui = c.GL_RGB16UI,
    rgb32i = c.GL_RGB32I,
    rgb32ui = c.GL_RGB32UI,
    rgba8i = c.GL_RGBA8I,
    rgba8ui = c.GL_RGBA8UI,
    rgba16i = c.GL_RGBA16I,
    rgba16ui = c.GL_RGBA16UI,
    rgba32i = c.GL_RGBA32I,
    rgba32ui = c.GL_RGBA32UI,
    depth_component32f = c.GL_DEPTH_COMPONENT32F,
    depth_component24 = c.GL_DEPTH_COMPONENT24,
    depth_component16 = c.GL_DEPTH_COMPONENT16,
    depth32f_stencil8 = c.GL_DEPTH32F_STENCIL8,
    depth24_stencil8 = c.GL_DEPTH24_STENCIL8,
    stencil_index8 = c.GL_STENCIL_INDEX8,
};

pub const Face = enum(c.GLenum) {
    cw = c.GL_CW,
    ccw = c.GL_CCW,
};

pub fn clearColor(color: [4]f32) void {
    c.glClearColor(color[0], color[1], color[2], color[3]);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
}

pub fn clearDepth(depth: f64) void {
    c.glClearDepth(depth);
    c.glClear(c.GL_DEPTH_BUFFER_BIT);
}

pub fn setViewport(position: [2]i32, size: [2]u32) void {
    c.glViewport(position[0], position[1], @intCast(c_int, size[0]), @intCast(c_int, size[1]));
}

pub fn getVersion() [*:0]const u8 {
    return c.glGetString(c.GL_VERSION);
}

pub fn enableAlphaBlending() void {
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glEnable(c.GL_BLEND);
}

pub fn disableAlphaBlending() void {
    c.glDisable(c.GL_BLEND);
}

pub fn enableFaceCulling() void {
    c.glEnable(c.GL_CULL_FACE);
}

pub fn disableFaceCulling() void {
    c.glDisable(c.GL_CULL_FACE);
}

pub fn setFrontFace(face: Face) void {
    c.glFrontFace(@enumToInt(face));
}

pub fn enableDepthTest() void {
    c.glEnable(c.GL_DEPTH_TEST);
}

pub fn disableDepthTest() void {
    c.glDisable(c.GL_DEPTH_TEST);
}

pub fn enableMultisampling() void {
    c.glEnable(c.GL_MULTISAMPLE);
}
pub fn disableMultisampling() void {
    c.glDisable(c.GL_MULTISAMPLE);
}

pub fn setPolygonMode(mode: PolygonMode) void {
    c.glPolygonMode(c.GL_FRONT_AND_BACK, @enumToInt(mode));
}

const ShaderSource = struct { t: ShaderType, src: [*:0]const u8 };

pub const Program = struct {
    handle: c.GLuint,

    pub fn create(comptime shader_sources: []const ShaderSource) !Program {
        const self = Program{ .handle = glCreateProgram() };
        var shaders: [shader_sources.len]c.GLuint = undefined;
        for (shader_sources) |source, i| {
            const shader = glCreateShader(@enumToInt(source.t));
            glShaderSource(shader, 1, &source.src, null);
            glCompileShader(shader);
            glAttachShader(self.handle, shader);
            shaders[i] = shader;
        }
        glLinkProgram(self.handle);
        for (shaders) |shader| {
            glDetachShader(self.handle, shader);
            glDeleteShader(shader);
        }
        return self;
    }

    pub fn destroy(self: Program) void {
        glDeleteProgram(self.handle);
    }

    pub fn setUniform(self: Program, loc: u16, val: anytype) void {
        switch (@TypeOf(val)) {
            f32 => glProgramUniform1f(self.handle, loc, val),
            i32 => glProgramUniform1i(self.handle, loc, val),
            u32 => glProgramUniform1ui(self.handle, loc, val),
            math.Vec2 => glProgramUniform2fv(self.handle, loc, 1, &val.asArray()[0]),
            math.Vec3 => glProgramUniform3fv(self.handle, loc, 1, &val.asArray()[0]),
            math.Vec4 => glProgramUniform4fv(self.handle, loc, 1, &val.asArray()[0]),
            math.Mat3 => glProgramUniformMatrix3fv(self.handle, loc, 1, 0, &val.asArray()[0][0]),
            math.Mat4 => glProgramUniformMatrix4fv(self.handle, loc, 1, 0, &val.asArray()[0][0]),
            else => @compileError("unsupported uniform type"),
        }
    }
};

pub const Buffer = struct {
    handle: c.GLuint,

    pub fn create() Buffer {
        var handle: c.GLuint = undefined;
        glCreateBuffers(1, &handle);
        return .{ .handle = handle };
    }

    pub fn storage(self: *Buffer, comptime T: type, data: []T) void {
        glNamedBufferStorage(self.handle, @intCast(c_long, data.len * @sizeOf(T)), data.ptr, 0);
    }

    pub fn destroy(self: Buffer) void {
        glDeleteBuffers(1, &self.handle);
    }
};

pub const VertexArray = struct {
    handle: c.GLuint,
    vertex_buf_count: u16 = 0,
    vertex_attrib_count: u16 = 0,
    index_type: ?c.GLenum = null,

    pub fn create() VertexArray {
        var handle: c.GLuint = undefined;
        glCreateVertexArrays(1, &handle);
        return .{ .handle = handle };
    }

    pub fn addVertexBuffer(self: *VertexArray, comptime Vertex: type, buf: Buffer) void {
        glVertexArrayVertexBuffer(self.handle, self.vertex_buf_count, buf.handle, 0, @sizeOf(Vertex));

        if (@typeInfo(Vertex) != .Struct)
            @compileError("vertex is not a struct");
        inline for (@typeInfo(Vertex).Struct.fields) |field|
            self.addVertexAttrib(field.field_type, @offsetOf(Vertex, field.name));

        self.vertex_buf_count += 1;
    }

    pub fn addIndexBuffer(self: *VertexArray, comptime Index: type, buf: Buffer) void {
        glVertexArrayElementBuffer(self.handle, buf.handle);

        self.index_type = switch (Index) {
            u8 => c.GL_UNSIGNED_BYTE,
            u16 => c.GL_UNSIGNED_SHORT,
            u32 => c.GL_UNSIGNED_INT,
            else => @compileError("unsupported index type"),
        };
    }

    fn addVertexAttrib(self: *VertexArray, comptime T: type, offset: u32) void {
        const gl_type: c.GLenum = switch (T) {
            i8 => c.GL_BYTE,
            u8 => c.GL_UNSIGNED_BYTE,
            i16 => c.GL_SHORT,
            u16 => c.GL_UNSIGNED_SHORT,
            i32 => c.GL_INT,
            u32 => c.GL_UNSIGNED_INT,
            f16 => c.GL_HALF_FLOAT,
            f32 => c.GL_FLOAT,
            f64 => c.GL_DOUBLE,
            math.Vec4, math.Vec3, math.Vec2 => c.GL_FLOAT,
            else => @compileError("unsupported field in vertex"),
        };

        const count = switch (T) {
            math.Vec4 => 4,
            math.Vec3 => 3,
            math.Vec2 => 2,
            else => 1,
        };

        const normalize = false;

        glEnableVertexArrayAttrib(self.handle, self.vertex_attrib_count);
        glVertexArrayAttribFormat(self.handle, self.vertex_attrib_count, count, gl_type, @boolToInt(normalize), offset);
        glVertexArrayAttribBinding(self.handle, self.vertex_attrib_count, self.vertex_buf_count);

        self.vertex_attrib_count += 1;
    }

    pub fn destroy(self: VertexArray) void {
        glDeleteVertexArrays(1, &self.handle);
    }
};

pub fn draw(mode: DrawingMode, program: Program, array: VertexArray, offset: u32, count: u32) void {
    glUseProgram(program.handle);
    glBindVertexArray(array.handle);

    if (array.index_type) |index_type| {
        c.glDrawElements(@enumToInt(mode), @intCast(c_int, count), index_type, null); // TODO offset
    } else {
        c.glDrawArrays(@enumToInt(mode), @intCast(c_int, offset), @intCast(c_int, count));
    }
}

pub const Texture = struct {
    handle: c.GLuint,

    pub fn create(format: TextureFormat, size: [2]u32, mipmap_levels: u8) Texture {
        var handle: c.GLuint = undefined;
        glCreateTextures(c.GL_TEXTURE_2D, 1, &handle);
        glTextureStorage2D(handle, mipmap_levels, @enumToInt(format), @intCast(c_int, size[0]), @intCast(c_int, size[1]));
        return .{ .handle = handle };
    }

    pub fn storage(self: Texture, size: [2]u32, channels: u8, data: [*]const u8) void {
        const format: c.GLenum = switch (channels) {
            1 => c.GL_RED,
            2 => c.GL_RG,
            3 => c.GL_RGB,
            4 => c.GL_RGBA,
            else => unreachable,
        };
        glTextureSubImage2D(self.handle, 0, 0, 0, @intCast(c_int, size[0]), @intCast(c_int, size[1]), format, c.GL_UNSIGNED_BYTE, data);
    }

    pub fn generateMipmap(self: Texture) void {
        glGenerateTextureMipmap(self.handle);
    }

    pub fn bind(self: Texture, binding: u16) void {
        glBindTextureUnit(binding, self.handle);
    }

    pub fn setWrapHorizontal(self: Texture, wrap: TextureWrap) void {
        glTextureParameteri(self.handle, c.GL_TEXTURE_WRAP_S, @enumToInt(wrap));
    }

    pub fn setWrapVertical(self: Texture, wrap: TextureWrap) void {
        glTextureParameteri(self.handle, c.GL_TEXTURE_WRAP_T, @enumToInt(wrap));
    }

    pub fn setWrap(self: Texture, wrap: TextureWrap) void {
        self.setWrapHorizontal(wrap);
        self.setWrapVertical(wrap);
    }

    pub fn destroy(self: Texture) void {
        c.glDeleteTextures(1, &self.handle);
    }
};

pub const Framebuffer = struct {
    handle: c.GLuint,

    pub fn create() Framebuffer {
        var handle: c.GLuint = undefined;
        glCreateFramebuffers(1, &handle);
        return .{ .handle = handle };
    }

    pub fn attachColorTexture(self: Framebuffer, texture: Texture) void {
        glNamedFramebufferDrawBuffer(self.handle, c.GL_COLOR_ATTACHMENT0);
        glNamedFramebufferTexture(self.handle, c.GL_COLOR_ATTACHMENT0, texture.handle, 0);
    }

    pub fn attachDepthTexture(self: Framebuffer, texture: Texture) void {
        glNamedFramebufferTexture(self.handle, c.GL_DEPTH_ATTACHMENT, texture.handle, 0);
    }

    pub fn bind(self: Framebuffer) void {
        glBindFramebuffer(c.GL_FRAMEBUFFER, self.handle);
    }

    pub fn unbind() void {
        glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
    }

    pub fn clearColor(self: Framebuffer, color: [4]f32) void {
        glClearNamedFramebufferfv(self.handle, c.GL_COLOR, 0, &color);
    }

    pub fn clearDepth(self: Framebuffer, depth: f32) void {
        glClearNamedFramebufferfv(self.handle, c.GL_DEPTH, 0, &depth);
    }

    pub fn destroy(self: Framebuffer) void {
        glDeleteFramebuffers(1, &self.handle);
    }
};
