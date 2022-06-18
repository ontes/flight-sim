usingnamespace @cImport({
    switch (@import("builtin").os.tag) {
        .linux => {
            @cInclude("GL/glx.h");
        },
        .windows => {
            @cDefine("__MSABI_LONG(x)", "(long)(x)"); // fix translate-c issue#9120
            @cInclude("windows.h");
            @cInclude("GL/gl.h");
            @cInclude("glcorearb.h"); // latest header with modern OpenGL support
        },
        else => @compileError("unsupported os"),
    }

    @cDefine("STB_IMAGE_IMPLEMENTATION", {});
    @cDefine("STBI_ONLY_PNG", {});
    @cDefine("STBI_NO_STDIO", {});
    @cInclude("stb_image.h");
});
