-- title:  Top Hat
-- author: Matheus Avellar
-- desc:   Dunno yet
-- script: lua
-- input:  gamepad

SCREEN_WIDTH = 240
SCREEN_HEIGHT = 136
local version = "0.2.4"
local t = 0

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

local game = {}
game.state = "title"
game.gravity = .5
game.shake = 0
game.waves = 0
game.wavei = 0
game.ox = 0

local player = {}
player.x = 0
player.y = 0
player.w = 8
player.h = 8
player.c = 1
player.s = 2
player.speed_x = 1.5
player.speed_y = 0
player.jump = 6.5
player.air = false
player.air_time = 0

local palette = {}
palette.black = 0
palette.white = 15

local gmap = {}
gmap.x = 0
gmap.y = 0
gmap.w = 60
gmap.h = 17
gmap.sx = 0
gmap.sy = 0
gmap.k = palette.black
gmap.s = 2

function load_palette()
    PAL_ARNE16="0c0c1444243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6"
    for i=0,15 do
        r = tonumber(string.sub(PAL_ARNE16,i*6+1,i*6+2),16)
        g = tonumber(string.sub(PAL_ARNE16,i*6+3,i*6+4),16)
        b = tonumber(string.sub(PAL_ARNE16,i*6+5,i*6+6),16)
        poke(0x3FC0+(i*3)+0,r)
        poke(0x3FC0+(i*3)+1,g)
        poke(0x3FC0+(i*3)+2,b)
    end
end
load_palette()

function set_border_color(color)
    poke(0x3FF8, color)
end

function shake_screen(duration)
    -- 'Shake Screen' by Vadim
    if duration > 0 then
        poke(0x3ff9, math.random(-1,1))
        poke(0x3ff9+1, math.random(-1,1))
        duration = duration - 1
        if duration == 0 then memset(0x3ff9,0,2) end
    end
    return duration
end

function scanline(row)
    if game.waves > 0 then
        -- 'Screen Wave' by Darkhog
        poke(0x3ff9, math.sin((time()/200 + row/5)) * game.wavei)
        game.waves = game.waves - 1
        if game.waves == 0 then memset(0x3ff9,0,2) end
    end
end

function TIC()
    cls(palette.black)
    if game.state == "title" then
        title_screen()
    elseif game.state == "game" then
        game_screen()
    elseif game.state == "settings" then
        settings_screen()
    end
    print("v"..version, SCREEN_WIDTH - 40, 5, palette.white, true)
    rectb(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, palette.white)
    t=t+1
end

function title_screen()
    spr(258, (SCREEN_WIDTH-64)//2, SCREEN_HEIGHT//2-32, palette.black, 2, 0, 0, 4, 2)

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
        game.state = "game"
    elseif cursor == 2 and btnp(bttn.a) then
        game.state = "settings"
        cursor = 1
    end
end

function settings_screen()
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
        game.state = "title"
        cursor = 2
    elseif cursor == 2 and btnp(bttn.a) then
        game.state = "settings"
    end
end

function game_screen()
    map(gmap.x , gmap.y,
        gmap.w, gmap.h,
        gmap.sx - game.ox,gmap.sy,
        gmap.k, gmap.s)

    game.shake = shake_screen(game.shake)

    local pc = 1
    local px = player.x / 16
    local py = player.y / 16
    local block_east = mget(px+1+1/16, py+15/16)
    --spr(32, player.x + 17 - game.ox, player.y + 15, 0, player.s, 0, 0)
    local block_west = mget(px-1/16, py+15/16)
    --spr(32, player.x - 1 - game.ox, player.y + 15, 0, player.s, 0, 0)
    local block_beneath_left = mget(px+1/16, py+1+1/16)
    --spr(32, player.x + 1 - game.ox, player.y + 17, 0, player.s, 0, 0)
    local block_beneath_right = mget(px+15/16, py+1+1/16)
    --spr(32, player.x + 15 - game.ox, player.y + 17, 0, player.s, 0, 0)

    if btn(bttn.right) then
        if is_not_solid(block_east) then player.x = player.x + player.speed_x end
        if t % 5 == 0 then
            player.c = player.c + 1
            if player.c > 4 then player.c = 2 end
        end
        if player.c < 2 then player.c = 2 end
        pc = player.c
    elseif btn(bttn.left) then
        if is_not_solid(block_west) then player.x = player.x - player.speed_x end
        if t % 5 == 0 then
            player.c = player.c - 1
            if player.c < 2 then player.c = 4 end
        end
        if player.c < 2 then player.c = 2 end
        pc = player.c
    else
        pc = 1
    end
    if player.x < 0 then player.x = 0 end

    if block_beneath_left == block_beneath_right
    and is_not_solid(block_beneath_left) then
        player.speed_y = player.speed_y - game.gravity
        player.y = player.y - player.speed_y
    else
        player.air = false
        player.speed_y = 0
        local player_y_grid = player.y // 16 * 16
        local player_y_mod = player.y % 16
        if player.y > player_y_grid then
            if player_y_mod > 0.8*16 then
                player.y = player.y + 16 - player_y_mod
            else
                player.y = player_y_grid
            end
        end
    end

    if player.speed_y > 0 then
        if not btn(bttn.up) then
            player.speed_y = player.speed_y - 2
        elseif t - player.air_time > 10 then
            player.speed_y = player.speed_y - 1
        end
    end

    if btn(bttn.down) and not btn(bttn.right) and not btn(bttn.left) then
        pc = 5
    elseif btn(bttn.up) and not player.air then
        player.air = true
        player.air_time = t
        player.speed_y = player.jump
        player.y = player.y - player.speed_y
    end
    if player.y < 0 then player.y = 0 end

    if player.x - game.ox > SCREEN_WIDTH / 2 + 20 then
        game.ox = game.ox + player.speed_x
    elseif player.x - game.ox < SCREEN_WIDTH / 2 - 20 and game.ox > 0 then
        game.ox = game.ox - player.speed_x
    end

    spr(pc, player.x - game.ox, player.y, 0, player.s, 0, 0)
end

function is_not_solid(block)
    return block == 0 or block == 35 or block == 36 or block == 37
end