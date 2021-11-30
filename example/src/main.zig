const std = @import("std");
const rl = @import("raylib");
const rlgl = @import("rlgl");
const rlig = @import("rlig");
const nb = @import("nbnet");

pub const ig = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
});

const log = std.log.scoped(.example);

pub const log_level: std.log.Level = .info;

pub fn main() void {
    const screenWidth = 1280;
    const screenHeight = 800;
    var showDemo: [*c]bool = 1;

    rl.InitWindow(screenWidth, screenHeight, "bouncy ball");
    defer rl.CloseWindow();
    _ = rlig.rlImGuiInit();

    var ballPosition: rl.Vector2 = rl.Vector2{ .x = 5.0, .y = 5.0};
    var ballSpeed: rl.Vector2 = rl.Vector2{ .x = 5.0, .y = 4.0};
    var ballRadius: f32 = 20;
    var pause: bool = false;
    var framesCounter: u32 = 0;

    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyPressed(rl.KEY_SPACE)) pause = !pause;
        if (!pause) {
            ballPosition.x += ballSpeed.x;
            ballPosition.y += ballSpeed.y;
            if ((ballPosition.x >= 800 -% 20) or ((ballPosition.x) < 0)) ballSpeed.x *= -1.0;
            if ((ballPosition.y >= 450 -% 20) or ((ballPosition.y) < 0)) ballSpeed.y *= -1.0;
        } else {
            framesCounter += 1;
        }
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rlig.rlImGuiBegin();
        defer rlig.rlImGuiEnd();
        ig.igShowDemoWindow(showDemo);
        rl.ClearBackground(rl.DARKGRAY);
        rl.DrawCircleV(ballPosition, ballRadius, rl.DARKBLUE);
        rl.DrawText("PRESS SPACE to PAUSE BALL MOVEMENT", 10, rl.GetScreenHeight() - 25, 20, rl.LIGHTGRAY);
        if (pause == true) rl.DrawText("PAUSED", 350, 200, 30, rl.GRAY);
    }
    rlig.rlImGuiShutdown();
}