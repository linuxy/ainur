const std = @import("std");
const rl = @import("raylib");
const rlgl = @import("rlgl");

pub const ig = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
});

var fontTex: rl.Texture2D = undefined;

pub fn rlImGuiShutdown() void {
    rl.UnloadTexture(fontTex);
    //unload other textures
}

pub fn rlImGuiInit() void {
    var ctx = ig.igCreateContext(null);
    var io = ig.igGetIO();
    _ = ctx;

    io.*.BackendPlatformName = "imgui_impl_raylib";
    io.*.BackendFlags |= ig.ImGuiBackendFlags_HasMouseCursors;

    io.*.KeyMap[ig.ImGuiKey_Tab] = rl.KEY_TAB;
    io.*.KeyMap[ig.ImGuiKey_LeftArrow] = rl.KEY_LEFT;
    io.*.KeyMap[ig.ImGuiKey_RightArrow] = rl.KEY_RIGHT;
    io.*.KeyMap[ig.ImGuiKey_UpArrow] = rl.KEY_UP;
    io.*.KeyMap[ig.ImGuiKey_DownArrow] = rl.KEY_DOWN;
    io.*.KeyMap[ig.ImGuiKey_PageUp] = rl.KEY_PAGE_DOWN;
    io.*.KeyMap[ig.ImGuiKey_PageDown] = rl.KEY_PAGE_UP;
    io.*.KeyMap[ig.ImGuiKey_Home] = rl.KEY_HOME;
    io.*.KeyMap[ig.ImGuiKey_End] = rl.KEY_END;
    io.*.KeyMap[ig.ImGuiKey_Insert] = rl.KEY_INSERT;
    io.*.KeyMap[ig.ImGuiKey_Delete] = rl.KEY_DELETE;
    io.*.KeyMap[ig.ImGuiKey_Backspace] = rl.KEY_BACKSPACE;
    io.*.KeyMap[ig.ImGuiKey_Space] = rl.KEY_SPACE;
    io.*.KeyMap[ig.ImGuiKey_Enter] = rl.KEY_ENTER;
    io.*.KeyMap[ig.ImGuiKey_Escape] = rl.KEY_ESCAPE;
    io.*.KeyMap[ig.ImGuiKey_KeyPadEnter] = rl.KEY_KP_ENTER;
    io.*.KeyMap[ig.ImGuiKey_A] = rl.KEY_A;
    io.*.KeyMap[ig.ImGuiKey_C] = rl.KEY_C;
    io.*.KeyMap[ig.ImGuiKey_V] = rl.KEY_V;
    io.*.KeyMap[ig.ImGuiKey_X] = rl.KEY_X;
    io.*.KeyMap[ig.ImGuiKey_Y] = rl.KEY_Y;
    io.*.KeyMap[ig.ImGuiKey_Z] = rl.KEY_Z;

    io.*.MousePos = ig.ImVec2 {.x = 0, .y = 0};

    //io.*.SetClipboardTextFn = rl.SetClipboardText;
    //io.*.GetClipboardTextFn = rl.GetClipboardText;

    io.*.ClipboardUserData = null;

    rlImGuiReloadFonts();
    //rlImGuiBuildFontExt("example/assets/public-sans.ttf", 12.0);
}

pub fn rlImGuiBegin() void {
    rlImGuiNewFrame();
    rlImGuiEvents();
    ig.igNewFrame();
}

fn rlImGuiNewFrame() void {
    var io = ig.igGetIO();

    io.*.DisplaySize.x = @intToFloat(f32, rl.GetScreenWidth());
    io.*.DisplaySize.y = @intToFloat(f32, rl.GetScreenHeight());

    io.*.DeltaTime = rl.GetFrameTime();

    io.*.KeyCtrl = rl.IsKeyDown(rl.KEY_RIGHT_CONTROL) or rl.IsKeyDown(rl.KEY_LEFT_CONTROL);
    io.*.KeyShift = rl.IsKeyDown(rl.KEY_RIGHT_SHIFT) or rl.IsKeyDown(rl.KEY_LEFT_SHIFT);
    io.*.KeyAlt = rl.IsKeyDown(rl.KEY_RIGHT_ALT) or rl.IsKeyDown(rl.KEY_LEFT_ALT);
    io.*.KeySuper = rl.IsKeyDown(rl.KEY_RIGHT_SUPER) or rl.IsKeyDown(rl.KEY_LEFT_SUPER);

    if (io.*.WantSetMousePos) {
        rl.SetMousePosition(@floatToInt(c_int, io.*.MousePos.x), @floatToInt(c_int, io.*.MousePos.y));
    }
    else
    {
        io.*.MousePos.x = @intToFloat(f32, rl.GetMouseX());
        io.*.MousePos.y = @intToFloat(f32, rl.GetMouseY());
    }

    io.*.MouseDown[0] = rl.IsMouseButtonDown(rl.MOUSE_LEFT_BUTTON);
    io.*.MouseDown[1] = rl.IsMouseButtonDown(rl.MOUSE_RIGHT_BUTTON);
    io.*.MouseDown[2] = rl.IsMouseButtonDown(rl.MOUSE_MIDDLE_BUTTON);

    if (rl.GetMouseWheelMove() > 0) {
        io.*.MouseWheel += 1;
    } else if(rl.GetMouseWheelMove() < 0) {
        io.*.MouseWheel -= 1;
    }

    if ((io.*.ConfigFlags & ig.ImGuiConfigFlags_NoMouseCursorChange) == 0) {
        var imgui_cursor = ig.igGetMouseCursor;
        if (@intCast(u32, imgui_cursor()) != @intCast(u32, ig.ImGuiMouseCursor_COUNT) or io.*.MouseDrawCursor) {
            //ig.ImGuiMouseCursor_COUNT = imgui_cursor;
            if (io.*.MouseDrawCursor == true or @intCast(u32, imgui_cursor()) == ig.ImGuiMouseCursor_None) {
                rl.HideCursor();
            } else {
                rl.ShowCursor();
    //
    //            //if (!(io.ConfigFlags & ImGuiConfigFlags_NoMouseCursorChange))
    //            //{
    //            //    auto itr = MouseCursorMap.find(imgui_cursor);
    //            //    if (itr == MouseCursorMap.end())
    //            //        SetMouseCursor(MOUSE_CURSOR_DEFAULT);
    //            //    else
    //            //        SetMouseCursor(itr->second);
    //            //}
            }
        }
    }
}

fn rlImGuiEvents() void {
    var io = ig.igGetIO();
    FOR_ALL_KEYS(io, SET_KEY_DOWN);

    var pressed = rl.GetCharPressed();
    if (pressed != 0)
        ig.ImGuiIO_AddInputCharacter(io, @intCast(c_uint, pressed));
}

pub extern fn memcpy(__dest: ?*c_void, __src: ?*const c_void, __n: c_ulong) ?*c_void;

fn rlImGuiReloadFonts() void {
    var io: *ig.ImGuiIO = ig.igGetIO();
    var pixels: [*c]u8 = undefined;
    var width: c_int = -1;
    var height: c_int = -1;
    ig.ImFontAtlas_GetTexDataAsRGBA32(io.Fonts, &pixels, &width, &height, null);

    var fontAtlas: rl.Image = rl.Image{
        .data = pixels,
        .width = width,
        .height = height,
        .mipmaps = 1,
        .format = rl.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
    };

    fontTex = rl.LoadTextureFromImage(fontAtlas);
    io.Fonts.*.TexID = @intToPtr(*c_void, fontTex.id);

    rl.UnloadImage(fontAtlas);
}

fn rlImGuiBuildFontExt(filePath: []const u8, size: f32) void {
    var io: *ig.ImGuiIO = ig.igGetIO();

    _ = ig.ImFontAtlas_AddFontFromFileTTF(io.Fonts, filePath.ptr, size, null, null);

    var w: c_int = -1;
    var h: c_int = -1;
    var pixels: [*c]u8 = undefined;
    ig.ImFontAtlas_GetTexDataAsRGBA32(io.Fonts, &pixels, &w, &h, null);

    var fontAtlas: rl.Image = rl.Image{
        .data = pixels,
        .width = w,
        .height = h,
        .mipmaps = 1,
        .format = rl.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
    };

    fontTex = rl.LoadTextureFromImage(fontAtlas);
    io.Fonts.*.TexID = @intToPtr(*c_void, fontTex.id);

    rl.UnloadImage(fontAtlas);
}

fn SET_KEY_DOWN(io: anytype, KEY: c_int) void {
    io.*.KeysDown[@intCast(usize, KEY)] = rl.IsKeyDown(KEY);
}

fn FOR_ALL_KEYS(io: anytype, X: anytype) void {
    X(io, rl.KEY_APOSTROPHE);
    X(io, rl.KEY_COMMA);
    X(io, rl.KEY_MINUS);
    X(io, rl.KEY_PERIOD);
    X(io, rl.KEY_SLASH);
    X(io, rl.KEY_ZERO);
    X(io, rl.KEY_ONE);
    X(io, rl.KEY_TWO);
    X(io, rl.KEY_THREE);
    X(io, rl.KEY_FOUR);
    X(io, rl.KEY_FIVE);
    X(io, rl.KEY_SIX);
    X(io, rl.KEY_SEVEN);
    X(io, rl.KEY_EIGHT);
    X(io, rl.KEY_NINE);
    X(io, rl.KEY_SEMICOLON);
    X(io, rl.KEY_EQUAL);
    X(io, rl.KEY_A);
    X(io, rl.KEY_B);
    X(io, rl.KEY_C);
    X(io, rl.KEY_D);
    X(io, rl.KEY_E);
    X(io, rl.KEY_F);
    X(io, rl.KEY_G);
    X(io, rl.KEY_H);
    X(io, rl.KEY_I);
    X(io, rl.KEY_J);
    X(io, rl.KEY_K);
    X(io, rl.KEY_L);
    X(io, rl.KEY_M);
    X(io, rl.KEY_N);
    X(io, rl.KEY_O);
    X(io, rl.KEY_P);
    X(io, rl.KEY_Q);
    X(io, rl.KEY_R);
    X(io, rl.KEY_S);
    X(io, rl.KEY_T);
    X(io, rl.KEY_U);
    X(io, rl.KEY_V);
    X(io, rl.KEY_W);
    X(io, rl.KEY_X);
    X(io, rl.KEY_Y);
    X(io, rl.KEY_Z);
    X(io, rl.KEY_SPACE);
    X(io, rl.KEY_ESCAPE);
    X(io, rl.KEY_ENTER);
    X(io, rl.KEY_TAB);
    X(io, rl.KEY_BACKSPACE);
    X(io, rl.KEY_INSERT);
    X(io, rl.KEY_DELETE);
    X(io, rl.KEY_RIGHT);
    X(io, rl.KEY_LEFT);
    X(io, rl.KEY_DOWN);
    X(io, rl.KEY_UP);
    X(io, rl.KEY_PAGE_UP);
    X(io, rl.KEY_PAGE_DOWN);
    X(io, rl.KEY_HOME);
    X(io, rl.KEY_END);
    X(io, rl.KEY_CAPS_LOCK);
    X(io, rl.KEY_SCROLL_LOCK);
    X(io, rl.KEY_NUM_LOCK);
    X(io, rl.KEY_PRINT_SCREEN);
    X(io, rl.KEY_PAUSE);
    X(io, rl.KEY_F1);
    X(io, rl.KEY_F2);
    X(io, rl.KEY_F3);
    X(io, rl.KEY_F4);
    X(io, rl.KEY_F5);
    X(io, rl.KEY_F6);
    X(io, rl.KEY_F7);
    X(io, rl.KEY_F8);
    X(io, rl.KEY_F9);
    X(io, rl.KEY_F10);
    X(io, rl.KEY_F11);
    X(io, rl.KEY_F12);
    X(io, rl.KEY_LEFT_SHIFT);
    X(io, rl.KEY_LEFT_CONTROL);
    X(io, rl.KEY_LEFT_ALT);
    X(io, rl.KEY_LEFT_SUPER);
    X(io, rl.KEY_RIGHT_SHIFT);
    X(io, rl.KEY_RIGHT_CONTROL);
    X(io, rl.KEY_RIGHT_ALT);
    X(io, rl.KEY_RIGHT_SUPER);
    X(io, rl.KEY_KB_MENU);
    X(io, rl.KEY_LEFT_BRACKET);
    X(io, rl.KEY_BACKSLASH);
    X(io, rl.KEY_RIGHT_BRACKET);
    X(io, rl.KEY_GRAVE);
    X(io, rl.KEY_KP_0);
    X(io, rl.KEY_KP_1);
    X(io, rl.KEY_KP_2);
    X(io, rl.KEY_KP_3);
    X(io, rl.KEY_KP_4);
    X(io, rl.KEY_KP_5);
    X(io, rl.KEY_KP_6);
    X(io, rl.KEY_KP_7);
    X(io, rl.KEY_KP_8);
    X(io, rl.KEY_KP_9);
    X(io, rl.KEY_KP_DECIMAL);
    X(io, rl.KEY_KP_DIVIDE);
    X(io, rl.KEY_KP_MULTIPLY);
    X(io, rl.KEY_KP_SUBTRACT);
    X(io, rl.KEY_KP_ADD);
    X(io, rl.KEY_KP_ENTER);
    X(io, rl.KEY_KP_EQUAL);    
}

pub fn rlImGuiEnd() void {
    ig.igRender();
    rlRenderData();
}

pub fn rlRenderData() void {
    ig.igRender();
    var dd: *ig.ImDrawData = ig.igGetDrawData();

    rlgl.rlDisableBackfaceCulling();

    if(dd.CmdLists == null) {
        rlgl.rlEnableBackfaceCulling();
        return;
    }
    var n: usize = 0;
    while(n < @intCast(usize, dd.CmdListsCount)) : (n += 1) {

        var draws: *ig.ImDrawList = dd.CmdLists[n];
        var vertBuf: [*c]ig.ImDrawVert = draws.VtxBuffer.Data;
        var indBuf: [*c]ig.ImDrawIdx = draws.IdxBuffer.Data;

        var i: usize = 0;
        while (i < draws.CmdBuffer.Size) : (i += 1) {
            var cmd: ig.ImDrawCmd = draws.CmdBuffer.Data[i];
            if(cmd.UserCallback != null) {
                cmd.UserCallback.?(draws, &cmd);
            } else {
                var pos = dd.DisplayPos;
                var rX = @floatToInt(c_int, cmd.ClipRect.x - pos.x);
                var rY = @floatToInt(c_int, cmd.ClipRect.y - pos.y);
                var rW = @floatToInt(c_int, cmd.ClipRect.z - @intToFloat(f32, rX));
                var rH = @floatToInt(c_int, cmd.ClipRect.w - @intToFloat(f32, rY));

                EnableScissor(rX,rY,rW,rH);
                rlImGuiRenderTriangles(cmd.ElemCount, indBuf, vertBuf, @truncate(u32, @ptrToInt(cmd.TextureId.?)));
            }
            indBuf += cmd.ElemCount;
        }
    }

    rlgl.rlDisableScissorTest();
    rlgl.rlEnableBackfaceCulling();
}

fn rlImGuiRenderVert(vertex: ig.ImDrawVert) void {
    var c = @bitCast([4]u8, vertex.col);
    rlgl.rlColor4ub(c[0],c[1],c[2],c[3]);
    rlgl.rlTexCoord2f(vertex.uv.x, vertex.uv.y);
    rlgl.rlVertex2f(vertex.pos.x, vertex.pos.y);
}

fn rlImGuiRenderTriangles(count: usize, indexBuf: [*c]ig.ImDrawIdx, indexVert: [*c]ig.ImDrawVert, textureId: u32) void {
    var i: usize = 0;
    while(i <= (count - 3)) : (i += 3) {
        rlgl.rlPushMatrix();
        rlgl.rlBegin(rlgl.RL_TRIANGLES);
        rlgl.rlSetTexture(textureId);

        rlImGuiRenderVert(indexVert[indexBuf[i]]);
        rlImGuiRenderVert(indexVert[indexBuf[i+2]]);
        rlImGuiRenderVert(indexVert[indexBuf[i+1]]);

        rlgl.rlSetTexture(0);
        rlgl.rlEnd();
        rlgl.rlPopMatrix();
    }
}

fn EnableScissor(c: c_int, y: c_int, width: c_int, height: c_int) void {
    rlgl.rlEnableScissorTest();
    rlgl.rlScissor(c, rl.GetScreenHeight() - (y + height), width, height);
}