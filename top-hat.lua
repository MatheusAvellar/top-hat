-- title:  Top Hat
-- author: Matheus Avellar
-- desc:   Dunno yet
-- script: lua
-- input:  gamepad

SCREEN_WIDTH = 240
SCREEN_HEIGHT = 136
local version = "0.2.5"
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
game.debug = false
game.shake = 0
game.waves = 0
game.wavei = 0
game.ox = 0
game.oy = 0
game.done = false
game.start_time = 0
game.current_time = 0
game.current_dialog = {}
game.dialog_pointer = 0

local player = {}
player.x = 0
player.y = 68
player.w = 8
player.h = 8
player.c = 1
player.s = 2
player.speed_x = 1.5
player.speed_y = 0
player.jump = 6.5
player.air = false
player.air_time = 0
player.terminal_velocity = 35
player.locked = false
player.lives = 5

local palette = {}
palette.black = 0
palette.sky_blue = 13
palette.white = 15

local gmap = {}
gmap.x = 0
gmap.y = 0
gmap.w = 90
gmap.h = 17
gmap.sx = 0
gmap.sy = 0
gmap.k = palette.black
gmap.s = 2

local dialog = {}
dialog[0] = {
    "Hello! Welcome to this lovely world!",
    "As you might have noticed, there is a",
    "timer ticking on the top left of the",
    "screen.",
    "That's how much time you have spent",
    "on this level. The less time you",
    "take, the more points you get!"
}


function load_palette()
    local palette_string = "140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa998ebed6dad45edeeed6"
    for i=0,15 do
        r = tonumber(string.sub(palette_string,i*6+1,i*6+2),16)
        g = tonumber(string.sub(palette_string,i*6+3,i*6+4),16)
        b = tonumber(string.sub(palette_string,i*6+5,i*6+6),16)
        poke(0x3FC0+(i*3)+0,r)
        poke(0x3FC0+(i*3)+1,g)
        poke(0x3FC0+(i*3)+2,b)
    end
end
load_palette()

function set_border_color(color)
    poke(0x3FF8, color)
end

function shake_screen()
    -- 'Shake Screen' by Vadim
    if game.shake > 0 then
        poke(0x3ff9, math.random(-1,1))
        poke(0x3ff9+1, math.random(-1,1))
        game.shake = game.shake - 1
        if game.shake == 0 then memset(0x3ff9,0,2) end
    end
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
    if game.state == "title" then
        cls(palette.black)
        title_screen()
    elseif game.state == "game" then
        cls(palette.sky_blue)
        game_screen()
    elseif game.state == "settings" then
        cls(palette.black)
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
        game.start_time = time()
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
        gmap.sx - game.ox, gmap.sy - game.oy,
        gmap.k, gmap.s)
    shake_screen(game.shake)

    local pc = 1
    local px = player.x / 16
    local py = player.y / 16
    local block_east = mget(px+1+1/16, py+15/16)
    local block_west = mget(px-1/16, py+15/16)
    local block_beneath_left = mget(px+1/16, py+1+1/16)
    local block_beneath_right = mget(px+15/16, py+1+1/16)
    local block_behind = mget(px + 8/16, py + 8/16)

    if not player.locked then
        if btn(bttn.right) then
            if is_not_solid(block_east) then player.x = player.x + player.speed_x end
            if t % 5 == 0 then
                player.c = player.c + 1
                if player.c > 4 then player.c = 2 end
            end
            if player.c < 2 then player.c = 2 end
            pc = player.c
        elseif not player.locked and btn(bttn.left) then
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

        if is_not_solid(block_beneath_left) and is_not_solid(block_beneath_right) then
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

        if player.speed_y > player.terminal_velocity then
            player.speed_y = player.terminal_velocity
        elseif player.speed_y < -player.terminal_velocity then
            player.speed_y = -player.terminal_velocity
        end

        if btn(bttn.down) and not btn(bttn.right) and not btn(bttn.left) then
            pc = 5
        elseif btn(bttn.up) and not player.air then
            player.air = true
            player.air_time = t
            player.speed_y = player.jump
            player.y = player.y - player.speed_y
        end

        if btn(bttn.a) and block_behind == 34 then
            player.x = player.x + 320
            game.ox = game.ox + 20
        end

        if player.y > SCREEN_HEIGHT then
            player.y = SCREEN_HEIGHT + 50
            player.locked = true
            game.shake = 20
        end

        if player.x - game.ox > SCREEN_WIDTH / 2 + 20 then
            game.ox = game.ox + player.speed_x
        elseif player.x - game.ox < SCREEN_WIDTH / 2 - 20 and game.ox > 0 then
            game.ox = game.ox - player.speed_x
        end
        if player.y - game.oy > SCREEN_HEIGHT / 2 then
            game.oy = game.oy + 1
        elseif player.y - game.oy < SCREEN_HEIGHT / 2 then
            game.oy = game.oy - 1
        end

        if block_behind == 160 and player.x == 63 then
            player.locked = true
            game.in_dialog = true
            game.current_dialog = dialog[0]
            game.shake = 10
        end

        spr(pc, player.x - game.ox, player.y - game.oy, 0, player.s, 0, 0)

    elseif player.locked then
        spr(pc, player.x - game.ox, player.y - game.oy, 0, player.s, 0, 0)

        if game.in_dialog then
            rect(10, SCREEN_HEIGHT/2 + 10, SCREEN_WIDTH - 20, SCREEN_HEIGHT/2 - 20, 0)
            print(game.current_dialog[game.dialog_pointer + 1]
            ..'\n\n'..game.current_dialog[game.dialog_pointer + 2]
            ..'\n\n'..game.current_dialog[game.dialog_pointer + 3], 20, SCREEN_HEIGHT/2 + 20)

            if btnp(bttn.a) then
                game.dialog_pointer = game.dialog_pointer + 1
                if not game.current_dialog[game.dialog_pointer+3] then
                    player.x = player.x + player.speed_x
                    game.dialog_pointer = 0
                    player.locked = false
                    game.in_dialog = false
                end
            end
        elseif not game.in_dialog
           and game.shake == 0
           and game.waves == 0 then
            player.x = 0
            player.y = 68
            game.ox = 0
            game.oy = 0
            player.locked = false
        end
    end

    if not game.done then game.current_time = time() - game.start_time end
    print(pretty_time(math.floor(game.current_time / 10)/100), 10, 10, 15, true)

    if game.debug then
        if btnp(bttn.b) then
            game.done = true
        end

        print(player.x - game.ox, 50, 10, 10)
        print(player.y - game.oy, 50, 20, 10)
        print(player.speed_x, 100, 10, 15)
        print(player.speed_y, 100, 20, 15)
        print(block_west, 10, 10, 8)
        print(block_east, 30, 10, 11)
        print(block_beneath_left, 10, 20, 9)
        print(block_beneath_right, 30, 20, 6)
        print(block_behind, 20, 30, 2)
        print(game.shake, 140, 10, 7)
        print(game.waves, 140, 20, 7)
        rect(player.x + 17 - game.ox, player.y + 15 - game.oy, 1, 1, 11) -- block east green
        rect(player.x - 1 - game.ox, player.y + 15 - game.oy, 1, 1, 8) -- block west light blue
        rect(player.x + 1 - game.ox, player.y + 17 - game.oy, 1, 1, 9) -- beneath left orange
        rect(player.x + 15 - game.ox, player.y + 17 - game.oy, 1, 1, 6) -- beneath right red
        rect(player.x + 8 - game.ox, player.y + 8 - game.oy, 1, 1, 2) -- behind dark blue
    end
end

function pad(num)
    if num < 10 then
        return "0" .. num
    end
    return num .. ""
end

function pretty_time(ctime)
    local floor_time = math.floor(ctime)
    local ms = math.floor((ctime - floor_time) * 100)
    local s = floor_time % 60
    local m = math.floor(ctime / 60)
    return pad(m) .. ":" .. pad(s) .. "." .. pad(ms)
end

function is_not_solid(block)
    return block == 0
        or block >= 128
end