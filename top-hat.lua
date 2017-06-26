-- title:  Test thing
-- author: Matheus Avellar
-- desc:   Dunno
-- script: lua
-- input:  gamepad

SCREEN_WIDTH = 240
SCREEN_HEIGHT = 136
local version = "0.2.0"
local t = 0
local game_state = "title"
local title = "TopHat"
local title_width = print(title,0,-6)

local play = "play"
local play_width = print(play,0,-6)
local settings = "settings"
local settings_width = print(settings,0,-6)
local press_info = "( press A button to select )"
local press_info_width = print(press_info,0,-6)

local stn_back = "back"
local stn_back_width = print(stn_back,0,-6)
local stn_1 = "setting #1"
local stn_1_width = print(stn_1,0,-6)
local stn_2 = "setting #2"

local bttn = {}
bttn.up    = 0
bttn.down  = 1
bttn.left  = 2
bttn.right = 3
bttn.a     = 4
bttn.b     = 5

local cursor = 1
local cursor_t = "> "
local cursor_b = "  "
local unpressed = true

local player = {}
player.x = 0
player.y = 0
player.w = 8
player.h = 8
player.c = 1
player.s = 2

local palette = {}
palette.black = 0
palette.white = 15

local gmap = {}
gmap.x = 0
gmap.y = 0
gmap.w = 30
gmap.h = 17
gmap.sx = 0
gmap.sy = 0
gmap.k = palette.black
gmap.s = 2

function TIC()
    cls(palette.black)
    if game_state == "title" then
        print(title,
            (SCREEN_WIDTH-title_width)//2, (SCREEN_HEIGHT-6)//2)
        print((cursor == 1 and cursor_t or cursor_b) .. play,
            SCREEN_WIDTH//2 - settings_width, (SCREEN_HEIGHT-6)//2+6*4)
        print((cursor == 2 and cursor_t or cursor_b) .. settings,
            SCREEN_WIDTH//2-settings_width, (SCREEN_HEIGHT-6)//2+6*6)
        print(press_info,
            (SCREEN_WIDTH-press_info_width)//2, (SCREEN_HEIGHT-6)//2+6*10)

        if btnp(bttn.down) then cursor = cursor + 1
        elseif btnp(bttn.up) then cursor = cursor - 1 end

        if cursor > 2 then cursor = 2 end
        if cursor < 1 then cursor = 1 end

        if cursor == 1 and btnp(bttn.a) then
            game_state = "game"
        elseif cursor == 2 and btnp(bttn.a) then
            game_state = "settings"
            cursor = 1
        end
    elseif game_state == "game" then
        map(gmap.x, gmap.y,
            gmap.w, gmap.h,
            gmap.sx,gmap.sy,
            gmap.k, gmap.s)

        if btn(bttn.right) then
            player.x = player.x + 1
            if t % 10 == 0 then
                player.c = player.c + 1
                if player.c > 4 then player.c = 2 end
            end
            if player.c < 2 then player.c = 2 end
            spr(player.c, player.x, player.y, 0, player.s, 0, 0)
        elseif btn(bttn.left) then
            player.x = player.x - 1
            if t % 10 == 0 then
                player.c = player.c - 1
                if player.c < 2 then player.c = 4 end
            end
            if player.c < 2 then player.c = 2 end
            spr(player.c, player.x, player.y, 0, player.s, 0, 0)
        else
            spr(1, player.x, player.y, 0, player.s, 0, 0)
        end

        if btn(bttn.down) then
            player.y = player.y + 1
        elseif btn(bttn.up) then
            player.y = player.y - 1
        end

        print(player.x .. " | " .. player.y, 10, 10)
        print(mget(player.x, player.y), 10, 20)
    elseif game_state == "settings" then
        print((cursor == 1 and cursor_t or cursor_b) .. stn_back, 12, 10)
        print((cursor == 2 and cursor_t or cursor_b) .. stn_1,
            SCREEN_WIDTH//2 - settings_width, (SCREEN_HEIGHT-6)//2+6*4)
        print((cursor == 3 and cursor_t or cursor_b) .. stn_2,
            SCREEN_WIDTH//2-settings_width, (SCREEN_HEIGHT-6)//2+6*6)
        print(press_info,
            (SCREEN_WIDTH-press_info_width)//2, (SCREEN_HEIGHT-6)//2+6*10)

        if btnp(bttn.down) then cursor = cursor + 1
        elseif btnp(bttn.up) then cursor = cursor - 1 end

        if cursor > 3 then cursor = 3 end
        if cursor < 1 then cursor = 1 end

        if cursor == 1 and btnp(bttn.a) then
            game_state = "title"
            cursor = 2
        elseif cursor == 2 and btnp(bttn.a) then
            game_state = "settings"
        end
    end
    rectb(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, palette.white)
    t=t+1
end