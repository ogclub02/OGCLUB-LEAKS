local ui_menu_size,renderer_rectangle,ui_menu_position,ui_mouse_position = ui.menu_size,renderer.rectangle,ui.menu_position,ui.mouse_position
local anti_aim_funcs = require ("gamesense/antiaim_funcs") or error("Failed to retrieve antiaim_funcs | https://gamesense.pub/forums/viewtopic.php?id=29665")
local clipboard = require("gamesense/clipboard") or error("Failed to load clipboard | https://gamesense.pub/forums/viewtopic.php?id=28678")
local base64 = require("gamesense/base64") or error("Failed to load base64 | https://gamesense.pub/forums/viewtopic.php?id=21619")
local csgo_weapons = require("gamesense/csgo_weapons") or error("Failed to load csgo_weapons")
local ent = require "gamesense/entity" or error("Failed to load entity | https://gamesense.pub/forums/viewtopic.php?id=27529")
local trace = require "gamesense/trace" or error("Failed to load trace")
local http = require "gamesense/http" or error("Failed to load http | https://gamesense.pub/forums/viewtopic.php?id=19253")
local images = require("gamesense/images") or error("Failed to load images | https://gamesense.pub/forums/viewtopic.php?id=22917")
local vector = require "vector"
local obex_data = obex_fetch and obex_fetch() or {username = 'mini', build = 'private', discord=''}
local tab,place =  "AA","Anti-aimbot angles"
local ffi = require 'ffi'

local what_noti_image = nil

http.get("https://i.imgur.com/8AeuI7l.png", function(s, r)
    if s and r.status == 200 then
        what_noti_image = images.load(r.body)
    else
        error("error getting image - error  " .. response.status_message)
    end
end)


local has_intro = database.read("has_intro_starlight")

local tab_coded_by_chupeta=ui.new_combobox(tab, place, "Coded by africa", {"AA","AA2","Visuals","Misc","Config"})

function rounded_rectangle(x, y, w, h, r, g, b, a, radius, thickness)
    y = y + radius
    local data_circle = {
        {x + radius, y, 180},
        {x + w - radius, y, 270},
        {x + radius, y + h - radius * 2, 90},
        {x + w - radius, y + h - radius * 2, 0},
    }

    local data = {
        {x + radius, y - radius, w - radius * 2, thickness},
        {x + radius, y + h - radius - thickness, w - radius * 2, thickness},
        {x, y, thickness, h - radius * 2},
        {x + w - thickness, y, thickness, h - radius * 2},
    }

    for _, data in next, data_circle do
        renderer.circle_outline(data[1], data[2], r, g, b, a, radius, data[3], 0.25, thickness)
    end

    for _, data in next, data do
        renderer.rectangle(data[1], data[2], data[3], data[4], r, g, b, a)
    end
end

local function table_contains(tbl, val)
    for i=1,#tbl do
        if tbl[i] == val then
            return true
        end
    end
    return false
end



local w,h = client.screen_size()
local tex_id = renderer.load_rgba(pattern, 4, 4)

local menu_reference = {
    enabled = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
    pitch = { ui.reference("AA", "Anti-aimbot angles", "pitch") },
    roll = ui.reference("AA", "Anti-aimbot angles", "roll"),
    yawbase = ui.reference("AA", "Anti-aimbot angles", "Yaw base"),
    yaw = {ui.reference("AA", "Anti-aimbot angles", "Yaw")},
    fsbodyyaw = ui.reference("AA", "anti-aimbot angles", "Freestanding body yaw"),
    edgeyaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
    dtholdaim = ui.reference("misc", "settings", "sv_maxusrcmdprocessticks_holdaim"),
    fakeduck = ui.reference("RAGE", "Other", "Duck peek assist"),
    minimum_damage = ui.reference("RAGE", "Aimbot", "Minimum damage"),
    safepoint = ui.reference("RAGE", "Aimbot", "Force safe point"),
    forcebaim = ui.reference("RAGE", "Aimbot", "Force body aim"),
    player_list = ui.reference("PLAYERS", "Players", "Player list"),
    reset_all = ui.reference("PLAYERS", "Players", "Reset all"),
    apply_all = ui.reference("PLAYERS", "Adjustments", "Apply to all"),
    load_cfg = ui.reference("Config", "Presets", "Load"),
    fl_limit = ui.reference("AA", "Fake lag", "Limit"),
    dt_limit = ui.reference("RAGE", "Aimbot", "Double tap fake lag limit"),
    quickpeek = {ui.reference("RAGE", "Other", "Quick peek assist")},
    yawjitter = {ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")},
    bodyyaw = {ui.reference("AA", "Anti-aimbot angles", "Body yaw")},
    freestand = {ui.reference("AA", "Anti-aimbot angles", "Freestanding")},
    freestand_body = {ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw")},
    os = {ui.reference("AA", "Other", "On shot anti-aim")},
    slow = {ui.reference("AA", "Other", "Slow motion")},
    dt = {ui.reference("RAGE", "Aimbot", "Double tap")},
    fakelag = {ui.reference("AA", "Fake lag", "Limit")},
    fakelag_variance = ui.reference("AA", "Fake lag", "Variance"),
    fake_lag_amount = ui.reference("AA", "Fake lag", "Amount"),
    leg_movement = ui.reference("AA", "Other", "Leg movement"),
    ammo = ui.reference("VISUALS","Player ESP","Ammo"),
    weapon_text = ui.reference("VISUALS","Player ESP","Weapon text"),
    weapon_icon = ui.reference("VISUALS","Player ESP","Weapon icon"),
    ping = { ui.reference("MISC","Miscellaneous","Ping spike") },
    clan_tag_spammer = ui.reference("MISC","Miscellaneous","Clan tag spammer"),
    min_dmg_override = { ui.reference("RAGE","Aimbot","Minimum damage override") },
    menu_key = { ui.reference("MISC","Settings","Menu key") },
    dpi_scale = ui.reference("MISC","Settings","DPI scale")
}

local aa = {
    aa_states = {"standing","walking","jumping","jump ducking","ducking","duck moving","slow walking","manual","fakelag","legit"},
    manual_state = "reset",
    color_left = {120,120,120,255},
    color_right = {120,120,120,255},
    color_body_r = {120,120,120,255},
    color_body_l = {120,120,120,255},
    last_pressed = 0,
}

local new_menu_references = {
    --extra_label = ui.new_label(tab,place,"~ aa extras tab ~"),
    aa_tab = ui.new_combobox(tab,place,"extras",{"main","jitter","bruteforce"}),
   
    ["aa"] = {
        aa_state_menu = ui.new_combobox(tab,place,"\aaac8fbffanti aim\affffffff state",aa.aa_states),
        aa_state = {},
        anti_kniv = ui.new_checkbox(tab, place, "anti stab"),
        safe_dangerous = ui.new_checkbox(tab, place, "safe knife | taser"),
        label_jitter_ways = ui.new_label(tab,place,"Only works if you enable jitter ways"),
        freestanding_options = ui.new_combobox(tab, place, "freestanding options",{"disabled","static","jitter"}),
        freestanding_disabler = ui.new_multiselect(tab, place, "freestanding disabler",aa.aa_states),
    },

    ["visuals"] = {
        
        enable_indicators = ui.new_combobox(tab,place,"indicators",{"off","default","minimal","tonka"}),
        indicator_color = ui.new_color_picker(tab, place, "indicatorz", 101, 130, 190, 255),
        scoped_animation = ui.new_checkbox(tab, place, "scoped animation"),
        enable_manual = ui.new_combobox(tab, place, "manual indicators",{"off","ts","minimal"}),
        indicator_manual_color = ui.new_color_picker(tab, place, "indicatorzmanual", 255, 255, 255, 255),
        enable_velocity_adaptive = ui.new_checkbox(tab, place, "velocity adaptive"),
        enable_defensive_indicator = ui.new_checkbox(tab, place, "defensive indicator"),
        indicator_defensive_color = ui.new_color_picker(tab, place, "indicatorzdefensive", 255, 255, 255, 255),
        slow_indicator = ui.new_checkbox(tab, place, "slow down indicator"),
        indicator_slow_color = ui.new_color_picker(tab, place, "indicatorzslow", 255, 255, 255, 255),
        enable_min_dmg_ovrrd = ui.new_checkbox(tab, place, "minimum damage indicator"),
        enable_desync_indicator = ui.new_checkbox(tab, place, "desync indicator"),
        indicator_desync_color = ui.new_color_picker(tab, place, "indicatorzdesync", 255, 255, 255, 255),
        draw_logs = ui.new_checkbox(tab, place, "console logs"),
        zeus = ui.new_multiselect(tab, place, "> zeus indicator",{"player","out of view"}),
        extra_visuals = ui.new_multiselect(tab, place, "> extras",{"beta logs","beta dt indicator","at target flag"}),
        noti_timer = ui.new_slider(tab,place,"notifcation timer", 1, 10, 5,1,"s"),
        noti_padding = ui.new_slider(tab,place,"notifcation padding", 0, 50, 10,1,"px"),
        aim_logs_label = ui.new_label(tab,place,"aim logs outline"),
        aim_logs_outline_color = ui.new_color_picker(tab,place,"aim logs outlinez",101,130,190,255),
        watermark_label = ui.new_label(tab,place,"watermark"),
        watermark_color = ui.new_color_picker(tab,place,"water_colorz",101,130,190,255),
        watormuk = ui.new_checkbox(tab, place, "waturmurk"),
        aimer_legs = ui.new_checkbox(tab, place, "aimer_lugs"),
        whatsappi = ui.new_checkbox(tab, place, "whatsappi"),
    },

    ["misc"] = {
        
        enable_clan_tag = ui.new_checkbox(tab, place, "synced tag"),
        enable_kill_say = ui.new_combobox(tab, place, "kill say",{"Disabled","Starlight","Tonka"}),
        enable_sun_rise = ui.new_checkbox(tab, place, "sun rise mode"),
        enable_nigthermode = ui.new_checkbox(tab, place, "nightmode v2"),
        enable_local_animations = ui.new_multiselect(tab, place, "> local animations",{"pitch 0","reversed legs","moonwalk","static legs","blind","t-pose"}),
        debug_ragebot = ui.new_multiselect(tab, place, "[\aaac8fbffdebug\affffffff] ragebot enhancer",{"defensive aa resolver (exprimental)","safe point enhancer"}),
        safe_point = ui.new_multiselect(tab, place, "safe point enhancer",{"standing","on lethal","default","wide jitter","small jitter"}),
    },

    ["keys"] = {
        enable_key = ui.new_checkbox(tab, place, "keys"),
        manual_left = ui.new_hotkey(tab,place, "- manual left",false),
        manual_right = ui.new_hotkey(tab,place, "- manual right",false),
        manual_forward = ui.new_hotkey(tab,place, "- manual forward",false),
        manual_reset =ui.new_hotkey(tab,place, "- reset angles",false),
        global_fs = ui.new_hotkey(tab,place, "- freestanding",false),
    },

    ["config"] = {
       
    },

    ["bruteforce"] = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
    },
}

ui.set_visible(new_menu_references["visuals"].watormuk, false)
ui.set_visible(new_menu_references["visuals"].aimer_legs, false)
ui.set_visible(new_menu_references["visuals"].whatsappi, false)


local aa_functions = {
    aa_number = "standing",
    jitter_way_number = 1,
    old_weapon = 0,
    actual_weapon = 0,
    actual_tick = 0,
    to_start = false,
    to_jitter = false,  
    bomb_was_bombed = false,
    bomb_was_defused = false,
    can_defensive = false,
    def_ticks = 0,
}

local visual_functions = {
    indicator_bottom = 0,
    damage_indi = "0",
    dt_indicator_animation = 0,
    hs_indicator_animation = 0,
    offset = 0,
    offset2 = 0,
    defensive_ready = false,
    is_defensive = false,
    outline_text_alpha = 255,
    text_alpha = 255,
    is_defensive_state = false,
    is_defensive_ticks = 0,
    is_defensive_disable = false,
    ticks = 0,
    old_weapon = 0,
    current_weapon = 0,
    is_in_attack = false,
    in_fire = false,
    move = false,
    damage_predict_string_calc = "",
    calc_dmg = 0,
    chance = 0,
    bt = 0,
    predicted_damage = 0,
    predicted_hitgroup = 0,
}

local misc_functions = {
    kill_say = {["Starlight"] = {"U think u good? luckily im here #STARLIGHT","youre value compared to me  is but a grain of sand","all romanian(you) will die to me(gypys king)",
    "this isnt phasmaphobia: global offensive please dont speak","starlight trap house","I guarntee youre loss forever and always","𝕡𝕣𝕠𝕓𝕝𝕖𝕞?","cope",
    " 格拉格拉 < you? 无功无过 < me B) #STARLIGHT","in hvh war i will win","below average performance starlight performance","SPEAK BULGARIAN? WILL TALK CN",
    "you are loss it is decided with my starlight.lua","you do not perform this hvh against starlight","qahahaha i am top of this region","this weak snail is spoke of victory but is door unhinged to loss",
    "you do not have the impression of owning the performance-enhancing software known as Gamesense.pub","how you will feel knowing im skeethaving and u will skeetless #starlight",
    "your mexican familia never make it out from trailer #starlight","cant understand u. any noname translator? #STARLIGHT","you waste aka fecal matter/shit(you)","sorry for u loss, me always better like life",
    "better luck next round, oh wait i alr won BAHAHHA","ur lua & u sucks get STARLIGHT >.<","when you spawn tell me why u die to me","how hit chance in deagle? i sit.",
    "shitting on your cheat speedrun any% WR run feat starlight","smelly lapdog dreams of success in 1x1 but is handed 9 casualities","dude where are my diamonds?","all weak dogs fall to starlight","WOW STARLIGHT .。GYPSY 的科技 (TECHNOLOGY) ? "},
    ["Tonka"] = {"I got beef with my kidney, he said that we got a problem","first my money twerk, now its lifting weights money in the gym, now its heavyweight",
    "I just popped a X pill and half my body glitched", "Yeah, this percy got me snail, you should call me Gary","Mad bout that"}},
    clan_tag = {"", "st","sta","star","starl","starli","starlig","starligh","starlight","starligh","starlig","starli","starl","star","sta","st"},
    ct_tick = 0,
    ct_old_tick = 0,
    save_tick = 0,
    clan_tag_change_potential = "change",
    was_ct_enabled_before = false,
    ground_ticks = 1,
    end_time = 0,
}

local function lerp(a, b, t)
    return a + (b - a) * t
end




local brute_stage = {
    brute = {},
    last_miss = 0,
    to_death_reset = false,
    to_reset = false,
    round_starting = false,
}

local light_blue = "\aaac8fbff"
local white = "\affffffff: "
-- menu aa ui
for k,v in ipairs(aa.aa_states) do
    
    
    brute_stage.brute[v] = {}
    local y = string.sub(v,1,1)
    local new_streng = string.gsub(v,y,string.upper(y))
    new_menu_references["aa"].aa_state[v] = {}
    new_menu_references["aa"].aa_state[v].jway_counter = ui.new_slider(tab,place, "jitter slider \n" .. new_streng, 2, 12, 2)
    new_menu_references["aa"].aa_state[v].enabled = ui.new_checkbox(tab,place,"enable '" .. light_blue .. new_streng .. "'" .. "\affffffff" )
    new_menu_references["aa"].aa_state[v].pitch = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."pitch\n" .. v,{"off", "default", "down", "minimal","custom"})
    new_menu_references["aa"].aa_state[v].pitch_slider = ui.new_slider(tab,place,"\n" .. light_blue .. new_streng .. white .. "custom pitch", -89, 89, 0)


    new_menu_references["aa"].aa_state[v].yawbase = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."yaw base\n" .. v,{"local view", "at targets"})
    new_menu_references["aa"].aa_state[v].yaw = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."yaw\n" .. v,{"off", "180", "180 z", "crosshair","jittery","delayed","l & r"})
    
    new_menu_references["aa"].aa_state[v].yawadd = ui.new_slider(tab,place, light_blue .. new_streng .. white .."yaw right\n" .. v, -180, 180, k == 9 and 180 or 0)

    if v ~= "manual" and v ~= "legit" then
        new_menu_references["aa"].aa_state[v].yawaddleft = ui.new_slider(tab,place, light_blue .. new_streng .. white .."yaw left \n" .. v, -180, 180, 0)
        new_menu_references["aa"].aa_state[v].ticker_slider = ui.new_slider(tab,place, light_blue .. new_streng .. white .."ticks delay \n" .. v, 1, 10, 1)
    end
    new_menu_references["aa"].aa_state[v].yawjitter = ui.new_combobox( tab,place,light_blue .. new_streng .. white .."yaw jitter\n" .. v,{"off", "offset", "center", "random","skitter","jitter ways","sway","l & r"})
    new_menu_references["aa"].aa_state[v].yawjitteradd = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "yaw jitter" , -180, 180, 0)
    new_menu_references["aa"].aa_state[v].yawjitteradd2 = ui.new_slider(tab,place, light_blue .. new_streng .. white .."yaw jitter left", -180, 180, 0)
    new_menu_references["aa"].aa_state[v].swaym = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "sway min\n" .. v, -180, 180, 0)
    new_menu_references["aa"].aa_state[v].swaymx = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "sway max\n" .. v, -180, 180, 0)
    new_menu_references["aa"].aa_state[v].swayspeed = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "sway speed\n" .. v, 1, 10,1)
    new_menu_references["aa"].aa_state[v].sway_value = 0
    new_menu_references["aa"].aa_state[v].to_sway = false
    new_menu_references["aa"].aa_state[v].gs_bodyyaw = ui.new_combobox( tab,place,light_blue .. new_streng .. white .."body yaw\n" .. v,{"off","jitter", "static","anti bruteforce","auto jitter","delayed yaw"})
    new_menu_references["aa"].aa_state[v].delayed_method = ui.new_combobox( tab,place,light_blue .. new_streng .. white .."delayed method\n" .. v,{"simple","advanced"})
    new_menu_references["aa"].aa_state[v].gs_bodyyawadd = ui.new_slider(tab,place,"\n" .. light_blue .. new_streng .. white .. "body yaw\n" .. v, -180, 180, 0)
    new_menu_references["aa"].aa_state[v].edgeyaw = ui.new_checkbox(tab,place,light_blue .. new_streng .. white .. "edge yaw\n" .. v)
    new_menu_references["aa"].aa_state[v].roll = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "roll\n" .. v, -45, 45, 0)

    new_menu_references["aa"].aa_state[v].pedro_aas2 = { ui.new_slider(tab,place, light_blue .. new_streng .. white .."jitter way 1 \n" .. k, -180, 180, 0),ui.new_slider(tab,place, "jitter way 2\n" .. k, -180, 180, 0)
    ,ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 3 \n".. k, -180, 180, 0),ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 4 \n" .. k, -180, 180, 0)
    ,ui.new_slider(tab,place, light_blue .. new_streng .. white .."jitter way 5 \n".. k, -180, 180, 0),ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 6\n" .. k, -180, 180, 0)
    ,ui.new_slider(tab,place, light_blue .. new_streng .. white .."jitter way 7 \n".. k, -180, 180, 0),ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 8\n" .. k, -180, 180, 0)
    ,ui.new_slider(tab,place, light_blue .. new_streng .. white .."jitter way 9 \n" .. k, -180, 180, 0),ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 10\n" .. k, -180, 180, 0),ui.new_slider(tab,place, "jitter way 11\n".. k, -180, 180, 0)
    ,ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 12\n".. k, -180, 180, 0)}

    if v ~= "manual" and v ~= "fakelag" and v ~= "legit" then
        new_menu_references["aa"].aa_state[v].enabled_exploit = ui.new_checkbox(tab,place,light_blue .. new_streng .. white .."enable defensive\n " .. v)
        new_menu_references["aa"].aa_state[v].enabled_defensive_force = ui.new_checkbox(tab,place,light_blue .. new_streng .. white .."force defensive\n " .. v)
        new_menu_references["aa"].aa_state[v].pitch_defensive = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."pitch defensive\n" .. v,{"off", "custom","up", "random","zero"})
        new_menu_references["aa"].aa_state[v].pitch_custom_defensive = ui.new_slider(tab,place,"\n" .. light_blue .. new_streng .. white .. "custom pitch", -89, 89, 0)
        new_menu_references["aa"].aa_state[v].yaw_defensive = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."yaw defensive\n" .. v,{"off", "180", "spin","randomize"})
        new_menu_references["aa"].aa_state[v].yawadd_defensive = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "add defensive\n" .. v, -180, 180,0)
        new_menu_references["aa"].aa_state[v].skitter_defensive = ui.new_checkbox(tab,place,light_blue .. new_streng .. white .."skitter defensive\n " .. v)
        new_menu_references["aa"].aa_state[v].skitter_slider_defensive = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "skitter add defensive\n" .. v, -180, 180,0)
    end

    brute_stage.brute[v].missed_bullets = 0
end

for f = 1,4 do
    new_menu_references["bruteforce"][f] = ui.new_slider(tab,place, "bruteforce stage " .. f .. "\n" .. f, -180, 180, 0)
end

local jitter_add = ui.new_button(tab,place,"add jitter",function()
    local get_value = new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].jway_counter
    local nigga = ui.get(get_value)

    if nigga >= 12 then
        print("Can't go over 12 jitter angles")
        return 
    end

    ui.set(get_value,nigga + 1)
end)

local jitter_remove = ui.new_button(tab,place,"remove jitter",function()
    local get_value = new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].jway_counter
    local nigga = ui.get(get_value)

    if nigga <= 2 then
        print("Can't go lower than 2 jitter angles")
        return 
    end

    ui.set(get_value,nigga - 1)
end)

local function get_velocity(player)
    local x, y, z = entity.get_prop(player, "m_vecVelocity")
    if x == nil then
        return
    end
    return math.sqrt(x * x + y * y + z * z)
end

local function clamp(value, minVal, maxVal)
    return math.max(minVal, math.min(value, maxVal))
end



local prev_simulation_time = 0
function aa_functions:sim_diff() 
    local current_simulation_time = math.floor(0.5 + (entity.get_prop(entity.get_local_player(), "m_flSimulationTime") / globals.tickinterval())) 
    local diff = current_simulation_time - prev_simulation_time
    prev_simulation_time = current_simulation_time
    return diff
end

local tick = 0
local ticker = 0
local lerp_alpha = 0
function visual_functions:defensive_indicator()

    visual_functions.ticks = aa_functions.sim_diff()
    if ui.get(new_menu_references["visuals"].enable_defensive_indicator) then

        local w,h = client.screen_size()
        
    
        local defensive = {ui.get(new_menu_references["visuals"].indicator_defensive_color)}
        if visual_functions.ticks < 0 and ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) and not ui.get(menu_reference.fakeduck) then
            tick = globals.tickcount()
            visual_functions.defensive_ready = true
            ticker = 0
            lerp_alpha = 255
        end
    
        if visual_functions.defensive_ready == true then
    
            local expand = visual_functions.is_defensive and 98 or ticker * 98 / 175
    
            renderer.text(w / 2 , visual_functions.is_defensive and h / 2  * 0.5 - 20 or h / 2  * 0.5 - 10 ,255,255,255,lerp_alpha,"c",0,visual_functions.is_defensive and "defensive" or "- defensive -")
            if visual_functions.is_defensive then
                renderer.text(w / 2 , h / 2  * 0.5 - 10 ,255,255,255,lerp_alpha,"c+",0,"∞")
            end
            renderer.rectangle(w / 2 - 50, h / 2  * 0.5, 100, 4, 12, 12, 12,lerp_alpha <= 150 and lerp_alpha or 150)
            renderer.rectangle(w / 2 - 49, h / 2  * 0.5 + 1,expand,2,defensive[1],defensive[2],defensive[3],lerp_alpha)
    
           

            if ticker > 155 then 
                lerp_alpha = lerp(lerp_alpha,0,globals.frametime() * 30)

                if lerp_alpha < 20 then
                    visual_functions.defensive_ready = false
                end
            end
            ticker = ticker + 1
        end
    end
end

function visual_functions:slow_indicator()

    if not ui.get(new_menu_references["visuals"].slow_indicator) then return end

    local NOVINHA_QUEISSO = entity.get_prop(entity.get_local_player(),"m_flVelocityModifier") * 100

    if NOVINHA_QUEISSO < 100 then

        local sizer = vector(client.screen_size())
    
        local size_bar = NOVINHA_QUEISSO * 98 / 100

        local defensive = {ui.get(new_menu_references["visuals"].indicator_slow_color)}
        
        renderer.text(sizer.x /2,sizer.y/2- 240,230,230,230,255,"c",nil,string.format("slowed by %s",math.floor(100 - NOVINHA_QUEISSO)) .. "%")
        renderer.rectangle(sizer.x / 2 - 50,sizer.y/2 - 232,100,4,12,12,12,180)
        renderer.rectangle(sizer.x / 2-49,sizer.y/2 - 231,size_bar,2,defensive[1],defensive[2],defensive[3],defensive[4])
    
    end
end

function aa_functions:manual_anti_aim()
    if ui.get(new_menu_references["aa"].aa_state["manual"].enabled) then
        
        ui.set(new_menu_references["aa"].aa_state["manual"].yaw,"180")
        if ui.get(new_menu_references["keys"].manual_right) and aa.last_pressed + 0.2 < globals.curtime() then
            aa.manual_state = aa.manual_state == "right" and "reset" or "right"
            aa.last_pressed = globals.curtime()
        elseif ui.get(new_menu_references["keys"].manual_left) and aa.last_pressed + 0.2 < globals.curtime() then
            aa.manual_state = aa.manual_state == "left" and "reset" or "left"
            aa.last_pressed = globals.curtime()
        elseif ui.get(new_menu_references["keys"].manual_forward) and aa.last_pressed + 0.2 < globals.curtime() then
            aa.manual_state = aa.manual_state == "forward" and "reset" or "forward"
            aa.last_pressed = globals.curtime()
        elseif ui.get(new_menu_references["keys"].manual_reset) and aa.last_pressed + 0.2 < globals.curtime() then
            aa.manual_state = "reset"
            aa.last_pressed = globals.curtime()
        elseif aa.last_pressed > globals.curtime() then
            aa.last_pressed = globals.curtime()
        end
    
        if aa.manual_state ~= "reset" then
            ui.set(menu_reference.yawbase,"At targets")
            ui.set(menu_reference.edgeyaw,false)
        end

        if aa.manual_state == "right" then
            ui.set(menu_reference.yaw[1],"180")
            ui.set(menu_reference.yaw[2],90)
        elseif aa.manual_state == "left" then
            ui.set(menu_reference.yaw[1],"180")
            ui.set(menu_reference.yaw[2],-90)
        elseif aa.manual_state == "forward" then
            ui.set(menu_reference.yaw[1],"180")
            ui.set(menu_reference.yaw[2],-180)
        end
    end
end

function aa_functions.anti_brute_bullet_impact(event)

    local me = entity.get_local_player()

	if not entity.is_alive(me) then return end

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw ) ~= "anti bruteforce" then return end

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "l & r" or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "delayed" or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "jittery" then
        return
    end

	local shooter_id = event.userid
	local shooter = client.userid_to_entindex(shooter_id)

	if not entity.is_enemy(shooter) or entity.is_dormant(shooter) then return end

	local lx, ly, lz = entity.hitbox_position(me, "head_0")
	
	local ox, oy, oz = entity.get_prop(me, "m_vecOrigin")
	local ex, ey, ez = entity.get_prop(shooter, "m_vecOrigin")

	local dist = ((event.y - ey)*lx - (event.x - ex)*ly + event.x*ey - event.y*ex) / math.sqrt((event.y-ey)^2 + (event.x - ex)^2)
    
	
	if math.abs(dist) <= 35 and globals.curtime() - brute_stage.last_miss > 0.015 then
        brute_stage.last_miss = globals.curtime()

        
        brute_stage.brute[aa_functions.aa_number].missed_bullets = brute_stage.brute[aa_functions.aa_number].missed_bullets + 1

        if  brute_stage.brute[aa_functions.aa_number].missed_bullets >= 5 then 
            brute_stage.brute[aa_functions.aa_number].missed_bullets = 1
            print("Back to stage 1 | Stages were superior than 4")
        end
        print("anti-bruteforce [" .. aa_functions.aa_number ..  "] stage:" .. brute_stage.brute[aa_functions.aa_number].missed_bullets)

    end
    
end

function aa_functions:anti_brute_anti_aim()

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw) ~= "anti bruteforce" then return end

    if not entity.is_alive(entity.get_local_player()) then return end

    if brute_stage.brute[aa_functions.aa_number].missed_bullets >= 1 then

        if  brute_stage.brute[aa_functions.aa_number].missed_bullets == 1 then
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],ui.get(new_menu_references["bruteforce"][1]))
        elseif  brute_stage.brute[aa_functions.aa_number].missed_bullets == 2 then
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],ui.get(new_menu_references["bruteforce"][2]))
        elseif  brute_stage.brute[aa_functions.aa_number].missed_bullets == 3 then
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],ui.get(new_menu_references["bruteforce"][3]))
        elseif  brute_stage.brute[aa_functions.aa_number].missed_bullets == 4 then
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],ui.get(new_menu_references["bruteforce"][4]))
        end
    else
        ui.set(menu_reference.bodyyaw[1],"Jitter")
        ui.set(menu_reference.bodyyaw[2],1)
    end

end

function aa_functions:anti_knife()

    if ui.get(new_menu_references["aa"].anti_kniv)then
        local players = entity.get_players(true)
        local opos = vector(entity.get_prop(entity.get_local_player(), "m_vecOrigin"))
        local yaw, yaw_slider = ui.reference("AA", "Anti-aimbot angles", "Yaw")
        local pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch")

        for i = 1, #players do
            local plpos = vector(entity.get_prop(players[i], "m_vecOrigin"))
            
            local weapon = entity.get_player_weapon(players[i])

            if entity.get_classname(weapon) == "CKnife" and opos:dist(plpos) < 200 then
                local eyepos = vector(client.eye_position())
                local hxpl = vector(entity.hitbox_position(players[i],4))
              
                local fraction, entindex_hit = client.trace_line(players[i], hxpl.x, hxpl.y, hxpl.z,eyepos.x,eyepos.y, eyepos.z)

                if entindex_hit == entity.get_local_player() or fraction == 1 then
                    ui.set(menu_reference.yawbase,"At targets")
                    ui.set(menu_reference.yaw[1],"180")
                    ui.set(menu_reference.yaw[2],180)
                    ui.set(menu_reference.yawjitter[1],"Off")
                    ui.set(menu_reference.yawjitter[2],60)
                    ui.set(menu_reference.bodyyaw[1],"jitter")
                    ui.set(menu_reference.bodyyaw[2],0)
                    ui.set(pitch, "Default")
                end
            end
        end
    end
end


function aa_functions:legit_aa(cmd)

    if not ui.get(new_menu_references["aa"].aa_state["legit"].enabled) then return end

    local in_use = cmd.in_use == 1
    local in_bombsite = entity.get_prop(entity.get_local_player(), "m_bInBombZone") > 0
    local nTeam = entity.get_prop(entity.get_local_player(), "m_iTeamNum")
    lx,ly,lz = entity.get_origin(entity.get_local_player())
    ui.set(new_menu_references["aa"].aa_state["legit"].yaw,"180")

    local from = vector(client.eye_position())
	local to = from + vector():init_from_angles(client.camera_angles()) * 1024

    local tr = trace.line(from, to, { skip = entity.get_local_player(), mask = "MASK_SHOT" })

    local local_pos = vector(entity.get_origin(entity.get_local_player()))

    if tr.fraction >= 1 then
        tr.entindex = 0
    end
   
   if entity.get_classname(tr.entindex) ~= "CWorld" and entity.get_classname(tr.entindex) ~= "CCSPlayer" and entity.get_classname(tr.entindex) ~= "CFuncBrush" and entity.get_classname(tr.entindex) ~= "CBaseButton" and entity.get_classname(tr.entindex) ~= "CDynamicProp" and entity.get_classname(tr.entindex) ~= "CPhysicsPropMultiplayer" and entity.get_classname(tr.entindex) ~= "CBaseEntity" and entity.get_classname(tr.entindex) ~= "CC4" then 
      
        local not_wepwep = vector(entity.get_origin(tr.entindex))

        if entity.get_classname(tr.entindex) == "CPropDoorRotating" or (entity.get_classname(tr.entindex) == "CHostage" and nTeam == 3) then
            
            if local_pos:dist(not_wepwep) < 125 then

                return false
            end

        elseif entity.get_classname(tr.entindex) ~= "CPropDoorRotating" and entity.get_classname(tr.entindex) ~= "CHostage" then

            if local_pos:dist(not_wepwep) < 200 then
                return false
            end
        end
   end
  
    local bomb_table    = entity.get_all("CPlantedC4")
    local bomb_planted  = #bomb_table > 0
    local bomb_distance = 100

    if bomb_planted then
        local bomb_entity = bomb_table[#bomb_table]
        local bomb_pos = vector(entity.get_origin(bomb_entity))
        bomb_distance = local_pos:dist(bomb_pos)
    end

    local defusing = bomb_distance < 50 and nTeam == 3 and aa_functions.bomb_was_bombed == false and aa_functions.bomb_was_defused == false

    if defusing then return false end

    if in_use then
        cmd.in_use = 0
        return true
    end
    return false
end

function aa_functions:static_in_aerophobic(cmd)

    if not ui.get(new_menu_references["aa"].safe_dangerous) then return end
    local local_player = entity.get_local_player()

    if not entity.is_alive(local_player) then return end
    local on_ground = bit.band(entity.get_prop(local_player, "m_fFlags"), 1) == 1 and cmd.in_jump == 0
    local weapon_ent = entity.get_player_weapon(local_player)
    if weapon_ent == nil then return end

    local weapon_idx = entity.get_prop(weapon_ent, "m_iItemDefinitionIndex")
    local weapon = csgo_weapons[weapon_idx]
    if weapon_ent == nil then return end

    if weapon.type == "knife" or weapon.type == "taser" then
        if not on_ground or (not on_ground and cmd.in_duck == 1) then

            ui.set(menu_reference.yawbase,"At targets")
            ui.set(menu_reference.yaw[1],"180")
            ui.set(menu_reference.yaw[2],0)
            ui.set(menu_reference.yawjitter[1],"Off")
            ui.set(menu_reference.yawjitter[2],0)
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],0)
        end
    end
end

local old_def_state = "standing"
function aa_functions:defensive_setup(cmd)

    if not ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled) then 
        return 
    end

    visual_functions.is_defensive = false

    aa_functions.old_weapon =  aa_functions.actual_weapon
    aa_functions.actual_weapon = entity.get_player_weapon(entity.get_local_player())
    
    if aa_functions.old_weapon ~= aa_functions.actual_weapon then
        aa_functions.to_start = true
    end
    
    if entity.get_player_weapon(entity.get_local_player()) ~= aa_functions.old_weapon then
        aa_functions.actual_tick = 0
        aa_functions.to_start = true
    end
    
    if aa_functions.to_start == true and aa_functions.actual_tick < 100 then
        aa_functions.actual_tick = aa_functions.actual_tick + 1
    elseif aa_functions.actual_tick >= 100 then
        aa_functions.actual_tick = 0
        aa_functions.to_start = false
    end
    
    aa_functions.old_weapon = entity.get_player_weapon(entity.get_local_player())

    if aa_functions.can_defensive then
        if ui.get(new_menu_references["aa"].aa_state[old_def_state].enabled_exploit) ~= ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled_exploit) then
            aa_functions.can_defensive = false
        end
    end
    old_def_state = aa_functions.aa_number

    if aa_functions.can_defensive  then
        aa_functions.def_ticks = 27
        aa_functions.can_defensive = false
    end

       if aa_functions.def_ticks > 0 then
          aa_functions.def_ticks = aa_functions.def_ticks - 1
       else
         aa_functions.can_defensive = false
       end

    if aa_functions.to_start == true then return end

    if aa_functions.aa_number ~= "manual" and aa_functions.aa_number ~= "legit" and aa_functions.aa_number ~= "fakelag" then
        if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled_exploit) and (ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) or ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2])) and not ui.get(menu_reference.fakeduck)  then
           
            if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled_defensive_force) then 
                cmd.force_defensive = true
            end
           if cmd.force_defensive == true then visual_functions.is_defensive = true end

           if cmd.force_defensive then
                if globals.tickcount() % 10 <= 2 then
                    cmd.force_defensive = false
                    return
                end
           end

           if aa_functions.def_ticks > 0 or cmd.force_defensive == true then 
            if  ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive) == "zero" then
                ui.set(menu_reference.pitch[1],"Off")
            elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive) == "custom" then
                ui.set(menu_reference.pitch[1],"Custom")
                ui.set(menu_reference.pitch[2],ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_custom_defensive))
           elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive) ~= "off" then
               ui.set(menu_reference.pitch[1],ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive))
           end
           
            if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw_defensive) == "randomize" then 
               ui.set(menu_reference.yaw[1],"180")
               ui.set(menu_reference.yaw[2],client.random_int(-180, 180))
            elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw_defensive) ~= "off" then
                ui.set(menu_reference.yaw[1],ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw_defensive))
                ui.set(menu_reference.yaw[2],ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd_defensive))
            end
   
           if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].skitter_defensive) then
               ui.set(menu_reference.yawjitter[1],"Skitter")
               ui.set(menu_reference.yawjitter[2],ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].skitter_slider_defensive))
           end
           end
        end
    end
end

local QUEISSO = false
local current_tickcount = 0
local side = nil
local setting_secret_1 = nil
local setting_secret_2 = nil
function aa_functions:setup(cmd)

    if not entity.is_alive(entity.get_local_player()) then return end

    local lp = entity.get_local_player()
    local on_ground = bit.band(entity.get_prop(entity.get_local_player(), "m_fFlags"), 1) == 1 and cmd.in_jump == 0
    local is_slow = ui.get(menu_reference.slow[1]) and ui.get(menu_reference.slow[2])

    local bodyyaw = entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) * 120 - 60

    if ui.get(new_menu_references["aa"].aa_state["legit"].enabled) and aa_functions:legit_aa(cmd) then
        aa_functions.aa_number = "legit"
    elseif  ui.get(new_menu_references["aa"].aa_state["manual"].enabled) and aa.manual_state ~= "reset" then
        aa_functions.aa_number = "manual"
    elseif  ui.get(new_menu_references["aa"].aa_state["fakelag"].enabled) and not ui.get(menu_reference.dt[2]) and not ui.get(menu_reference.os[2]) then
        aa_functions.aa_number = "fakelag"
    elseif on_ground and cmd.in_duck == 1 and get_velocity(lp) < 3 then
        aa_functions.aa_number = "ducking"
    elseif on_ground and cmd.in_duck == 1 and get_velocity(lp) >= 3 then
        aa_functions.aa_number = "duck moving"
    elseif not on_ground and cmd.in_duck == 1 then
        aa_functions.aa_number = "jump ducking"
    elseif not on_ground then
        aa_functions.aa_number = "jumping"
    elseif is_slow then
        aa_functions.aa_number = "slow walking"
    elseif on_ground and get_velocity(lp) < 3 then
        aa_functions.aa_number = "standing"
    elseif on_ground and get_velocity(lp) >= 3 then
        aa_functions.aa_number = "walking"
    end

    if cmd.chokedcommands == 0 then
        side = bodyyaw > 0 and true or false
        
        if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "jitter ways" then
       
            aa_functions.jitter_way_number = aa_functions.jitter_way_number + 1 
        
        
            if aa_functions.jitter_way_number > ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].jway_counter) then
                aa_functions.jitter_way_number = 1
            end
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "sway" then
    
           
          
                ui.set(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym,math.min(ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym),ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaymx)))
                local number = ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swayspeed) 
                local number_to_add = new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway and number or -number
                
                new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value = new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value + number_to_add
                if new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value < ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym) then
                    new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value = ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym)
                elseif new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value > ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaymx) then
                    new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value = ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaymx)
                end
            
                    if new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value >= ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaymx) and new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway then
                        new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway = false
                    elseif new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value <= ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym) and not new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway  then
                        new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway = true
                    end
        end
    end



    if aa_functions.aa_number ~= "legit" and aa_functions.aa_number ~= "manual" then
        if globals.tickcount() > current_tickcount + ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].ticker_slider)  then
            if cmd.chokedcommands == 0 then
               aa_functions.to_jitter = not aa_functions.to_jitter
               current_tickcount = globals.tickcount()
            end
        elseif globals.tickcount() <  current_tickcount then
            current_tickcount = globals.tickcount()
        end

    end
    
    ui.set(menu_reference.enabled,ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled))
  
    ui.set(menu_reference.pitch[1], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch))

    ui.set(menu_reference.pitch[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_slider))
        
    
    ui.set(menu_reference.yawbase, ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawbase))

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "jittery" then
        ui.set(menu_reference.yaw[1], "180")
        if cmd.chokedcommands == 0 then
            aa_functions.random_extrapolated = client.random_int(0,1) == 1
            ui.set(menu_reference.yaw[2],  aa_functions.random_extrapolated and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawaddleft) or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd))
        end
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "delayed" then

        ui.set(menu_reference.yaw[1], "180")
        if cmd.chokedcommands == 0 then
            ui.set(menu_reference.yaw[2],  aa_functions.to_jitter and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawaddleft) or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd))
        end
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "l & r" then
        ui.set(menu_reference.yaw[1], "180")
        if cmd.chokedcommands == 0 then
            if side ~= nil then 
                ui.set(menu_reference.yaw[2], side and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawaddleft) or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd))
            end
        end
    
    else
        ui.set(menu_reference.yaw[1], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw))
        ui.set(menu_reference.yaw[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd))
    end

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "jitter ways" then
        
        ui.set(menu_reference.yawjitter[1],"Center")
        ui.set(menu_reference.yawjitter[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pedro_aas2[aa_functions.jitter_way_number]))
        
    elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "sway" then
        
        ui.set(menu_reference.yawjitter[1],"Center")
        
            ui.set(menu_reference.yawjitter[2], new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value)
        
    elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "l & r" then
        --if cmd.chokedcommands == 0 then
            ui.set(menu_reference.yawjitter[1], "Center")
            ui.set(menu_reference.yawjitter[2], side and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitteradd) or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitteradd2))
       -- end
    else
        ui.set(menu_reference.yawjitter[1], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter))
        ui.set(menu_reference.yawjitter[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitteradd))
    end

    if cmd.chokedcommands == 0 then
        if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw) == "anti bruteforce" then
            aa_functions.anti_brute_anti_aim()
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw) == "auto jitter" then
            ui.set(menu_reference.bodyyaw[1], "Jitter")
            ui.set(menu_reference.bodyyaw[2], ui.get(menu_reference.yawjitter[2]))
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw) == "delayed yaw" then
            if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].delayed_method) == "simple" then
                ui.set(menu_reference.bodyyaw[1], "Static")
                ui.set(menu_reference.bodyyaw[2],aa_functions.to_jitter and -115 or 115)
            else
                ui.set(menu_reference.bodyyaw[1], "Static")
                ui.set(menu_reference.bodyyaw[2], ui.get(menu_reference.yaw[2]))
            end
        else
            ui.set(menu_reference.bodyyaw[1], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw))
            ui.set(menu_reference.bodyyaw[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyawadd))
        end
    end
    
    
    ui.set(menu_reference.edgeyaw ,ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].edgeyaw))
    ui.set(menu_reference.roll ,ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].roll))

    if ui.get(new_menu_references["keys"].global_fs) and aa_functions.aa_number ~= "legit" and aa_functions.aa_number ~= "manual" and not table_contains(ui.get(new_menu_references["aa"].freestanding_disabler),aa_functions.aa_number) then
        ui.set(menu_reference.freestand[1],true)
        ui.set(menu_reference.freestand[2],"Always on")
      
    elseif not ui.get(new_menu_references["keys"].global_fs) or aa_functions.aa_number == "legit" or aa_functions.aa_number == "manual" or table_contains(ui.get(new_menu_references["aa"].freestanding_disabler),aa_functions.aa_number) then
        ui.set(menu_reference.freestand[1],false)
    end


    if ui.get(menu_reference.freestand[1]) == true then
        if ui.get(new_menu_references["aa"].freestanding_options) == "static" then
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],1)
            ui.set(menu_reference.yawjitter[1],"Off")
            ui.set(menu_reference.yaw[2],0)
        elseif ui.get(new_menu_references["aa"].freestanding_options) == "jitter" then
            ui.set(menu_reference.bodyyaw[1],"Jitter")
            ui.set(menu_reference.yawjitter[1],"Off")
            ui.set(menu_reference.yaw[2],0)
        end
    end
    
    aa_functions:manual_anti_aim()
    aa_functions:static_in_aerophobic(cmd)
    aa_functions:defensive_setup(cmd)
    aa_functions:anti_knife()
end

local text_anim = {0,0,0,0,0}
local add_y = {0,0}
local bottom = 0
local addition = 0 
function visual_functions:indicators()

   
    local w,h = client.screen_size()
    local scoped = entity.get_prop(entity.get_local_player(),"m_bIsScoped") == 1 and true or false
    local scoped_and_box = ui.get(new_menu_references["visuals"].scoped_animation) and scoped
    local indicator_color = { ui.get(new_menu_references["visuals"].indicator_color) }

    renderer.text(w / 2 + math.ceil(text_anim[1])-1,h / 2 + 24,indicator_color[1],indicator_color[2],indicator_color[3],indicator_color[4],"c-",0,"S  T  A  R  L  I  G  H  T")
   
    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then 
        renderer.text(w / 2 + math.ceil(text_anim[2])-1,h / 2 + 24 + math.ceil(add_y[1]),255,255,255,anti_aim_funcs.get_double_tap() and 255 or 130 ,"c-",0,"DT")
    end

    if ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2]) then
        renderer.text(w / 2 + math.ceil(text_anim[3])-1,h / 2 + 24+ math.ceil(add_y[2]),255,255,255,255 ,"c-",0,"HS")
    end

    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then
        addition = add_y[1]
    elseif ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2]) then
        addition = add_y[2]
    else 
        addition = lerp(addition,0,globals.frametime() * 15)
    end
    

    renderer.text(w / 2 - 2 + math.ceil(text_anim[4]) ,h / 2 + 33 + math.ceil(addition),255,255,255,ui.get(menu_reference.freestand[1]) and 255 or 130,"c-",0,"FS")
    renderer.text(w / 2 - 18 + math.ceil(text_anim[4]),h / 2 + 33 + math.ceil(addition),255,255,255,ui.get(menu_reference.forcebaim) and 255 or 130,"c-",0,"BAIM")
    renderer.text(w / 2 + 16 +  math.ceil(text_anim[4]),h / 2 + 33 + math.ceil(addition),255,255,255,ui.get(menu_reference.quickpeek[2]) and ui.get(menu_reference.quickpeek[1]) and 255 or 130,"c-",0,"QUICK")

    local text = {"S  T  A  R  L  I  G  H  T","DT","HS","BAIM"}
    for i = 1,#text do
        local measure = vector(renderer.measure_text("c-", text[i]))
        local can2 = scoped_and_box

        if i == 4 then
            text_anim[i] = lerp(text_anim[i],can2 and measure.x/2 + 19 or 0,globals.frametime() * 15)
        else
            text_anim[i] = lerp(text_anim[i],can2 and measure.x/2 + 2 or 0,globals.frametime() * 15)
        end

        if i < 3 then
            if i == 1 then
                add_y[i] = lerp(add_y[i],(ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2])) and 9 or 0,globals.frametime() * 15)
            else
                local can = ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2])
                add_y[i] = lerp(add_y[i],can and 9 or 0,globals.frametime() * 15)
            end
        end
    end
end

local function text_plus(update_tick,text,speed)
    string_size = string.len(text)
    
    if update_tick < #text then
        update_tick = update_tick + 1 * globals.frametime() * speed
    else
        update_tick = update_tick
    end

    string_minus = string_size - string_size + update_tick

    text_render = string.sub(text,1,string_minus)

    return update_tick,text_render
end


local last_state = "Standing"
local text_index,text_string = 0,"Standing"
function visual_functions:indicators2()
    local w,h = client.screen_size()
    local scoped = entity.get_prop(entity.get_local_player(),"m_bIsScoped") == 1 and true or false
    local scoped_and_box = ui.get(new_menu_references["visuals"].scoped_animation) and scoped
    local indicator_color = { ui.get(new_menu_references["visuals"].indicator_color) }

    if last_state ~= aa_functions.aa_number then
        if #last_state < #aa_functions.aa_number then
            text_index = #last_state
        else
            text_index = #aa_functions.aa_number / 2
        end
    end

    last_state = aa_functions.aa_number


    text_index,text_string = text_plus(text_index,aa_functions.aa_number,50)
    

    renderer.text(w / 2 + math.ceil(text_anim[1]),h / 2 + 24,indicator_color[1],indicator_color[2],indicator_color[3],indicator_color[4],"c",0,"starlight")
    renderer.text(w / 2 + math.ceil(text_anim[2]),h / 2 + 36,255,255,255,255,"c",0,"- " .. text_string .. " -")
   
    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then 
        renderer.text(w / 2 + math.ceil(text_anim[3]),h / 2 + 36 + math.ceil(add_y[1]),255,255,255,anti_aim_funcs.get_double_tap() and 255 or 130 ,"c",0,"double tap")
    end

    if ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2]) then
        renderer.text(w / 2 + math.ceil(text_anim[4]),h / 2 + 36+ math.ceil(add_y[2]),255,255,255,255 ,"c",0,"on shot")
    end

    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then
        addition = add_y[1]
    elseif ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2]) then
        addition = add_y[2]
    else 
        addition = lerp(addition,0,globals.frametime() * 15)
    end



    renderer.text(w / 2 + math.ceil(text_anim[5]) ,h / 2 + 48 + math.ceil(addition),255,255,255,ui.get(menu_reference.freestand[1]) and 255 or 130,"c",0,"fs")
    renderer.text(w / 2 - 18 + math.ceil(text_anim[5]),h / 2 + 48 + math.ceil(addition),255,255,255,ui.get(menu_reference.forcebaim) and 255 or 130,"c",0,"baim")
    renderer.text(w / 2 + 18 +  math.ceil(text_anim[5]),h / 2 + 48 + math.ceil(addition),255,255,255,ui.get(menu_reference.quickpeek[2]) and ui.get(menu_reference.quickpeek[1]) and 255 or 130,"c",0,"quick")

    local text = {"starlight","- " .. text_string .. " -","double tap","on shot","baim"}
    for i = 1,#text do
        local measure = vector(renderer.measure_text("c", text[i]))
        local can2 = scoped_and_box

        if i == 5 then
            text_anim[i] = lerp(text_anim[i],can2 and measure.x/2 + 19 or 0,globals.frametime() * 15)
        else
            text_anim[i] = lerp(text_anim[i],can2 and measure.x/2 + 2 or 0,globals.frametime() * 15)
        end

        if i < 3 then
            if i == 1 then
                add_y[i] = lerp(add_y[i],(ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2])) and 12 or 0,globals.frametime() * 15)
            else
                local can = ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2])
                add_y[i] = lerp(add_y[i],can and 12 or 0,globals.frametime() * 15)
            end
        end
    end
end


function visual_functions:indicators3()

    visual_functions.indicator_bottom = 0
    local w,h = client.screen_size()
    local indicator_color = { ui.get(new_menu_references["visuals"].indicator_color) }

    renderer.text(w / 2 + visual_functions.offset,h / 2 + 25,indicator_color[1],indicator_color[2],indicator_color[3],indicator_color[4],"c-",0,string.format("LUH\a96C83C%02XTONKA",indicator_color[4],indicator_color[4]))
    
    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then
        visual_functions.indicator_bottom = visual_functions.indicator_bottom + 10
        visual_functions.dt_indicator_animation = lerp(visual_functions.dt_indicator_animation,visual_functions.indicator_bottom,globals.frametime() * 15)
        renderer.text(w / 2 + visual_functions.offset,h / 2 + 25 + visual_functions.dt_indicator_animation,255,255,255,anti_aim_funcs.get_double_tap() and 255 or 50, "c-", 0,"DOUBLE")
        
    end

    if ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) then
        visual_functions.indicator_bottom = visual_functions.indicator_bottom + 10
        visual_functions.hs_indicator_animation = lerp(visual_functions.hs_indicator_animation,visual_functions.indicator_bottom,globals.frametime() * 15)

        renderer.text(w / 2 + visual_functions.offset,h / 2 + 25 + visual_functions.hs_indicator_animation, 255,255,255,not ui.get(menu_reference.dt[2]) and 255 or 50, "c-", 0, "SHHHH")
        
        
    end
    
    bottom = lerp(bottom,visual_functions.indicator_bottom + 10,globals.frametime() * 15)
    renderer.text(w / 2 + visual_functions.offset ,h / 2 + 25 + bottom,255,255,255,ui.get(menu_reference.freestand[1]) and 255 or 50,"c-",0,"FS")
    renderer.text(w / 2 - 15 + visual_functions.offset,h / 2 + 25 + bottom,255,255,255,ui.get(menu_reference.forcebaim) and 255 or 50,"c-",0,"BAIM")
    renderer.text(w / 2 + 18 +  visual_functions.offset,h / 2 + 25 + bottom,255,255,255,ui.get(menu_reference.quickpeek[2]) and ui.get(menu_reference.quickpeek[1]) and 255 or 50,"c-",0,"QUICK")


    if not ui.get(menu_reference.dt[2]) then
        visual_functions.dt_indicator_animation = 0
    end

    if not ui.get(menu_reference.os[2]) then
        visual_functions.hs_indicator_animation = 0
    end
end

local DT_Color = {}
function visual_functions:green_dt_skeet_beta()

  
    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then
    
       
    
     
    end

end

function visual_functions:manual_indicator()

    local w,h = client.screen_size()
    local bodyyaw = entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) * 120 - 60

    aa.color_left = {12,12,12,130}
    aa.color_right = {12,12,12,130}
    if aa.manual_state == "left" then
        aa.color_left = {ui.get(new_menu_references["visuals"].indicator_manual_color)}
    elseif aa.manual_state == "right" then
        aa.color_right = {ui.get(new_menu_references["visuals"].indicator_manual_color)}
    end

    if ui.get(new_menu_references["visuals"].enable_manual) == "ts" then


        aa.color_body_l = {12,12,12,130}
        aa.color_body_r = {12,12,12,130}
        if bodyyaw < -10 then
            aa.color_body_r = {ui.get(new_menu_references["visuals"].indicator_manual_color)}
        elseif bodyyaw > 10 then
            aa.color_body_l = {ui.get(new_menu_references["visuals"].indicator_manual_color)}
        end
    
        local vel_adap = (ui.get(new_menu_references["visuals"].enable_velocity_adaptive) and get_velocity(entity.get_local_player()) * 45 / 300)  or 0


        renderer.triangle(w / 2 + 55 + vel_adap, h / 2 + 2, w / 2 + 42 + vel_adap, h / 2 - 7, w / 2 + 42 + vel_adap, h / 2 + 11, aa.color_right[1],aa.color_right[2],aa.color_right[3],aa.color_right[4]) 

        renderer.triangle(w / 2 - 55 + -vel_adap, h / 2 + 2, w / 2 - 42 + -vel_adap, h / 2 - 7, w / 2 - 42 + -vel_adap, h / 2 + 11, aa.color_left[1],aa.color_left[2],aa.color_left[3],aa.color_left[4]) 

        renderer.rectangle(w / 2 + 38 + vel_adap, h / 2 - 7, 2, 18, aa.color_body_r[1],aa.color_body_r[2],aa.color_body_r[3],aa.color_body_r[4])
       renderer.rectangle(w / 2 - 40 + -vel_adap, h / 2 - 7, 2, 18,aa.color_body_l[1],aa.color_body_l[2],aa.color_body_l[3],aa.color_body_l[4])
    elseif ui.get(new_menu_references["visuals"].enable_manual) == "minimal" then
    
        local vel_adap = (ui.get(new_menu_references["visuals"].enable_velocity_adaptive) and get_velocity(entity.get_local_player()) * 45 / 300)  or 0
        renderer.text(w / 2 + 35 + vel_adap, h / 2 ,aa.color_right[1],aa.color_right[2],aa.color_right[3],aa.color_right[4],"cb",0,"⮞")
        renderer.text(w / 2 - 35 + -vel_adap, h / 2 ,aa.color_left[1],aa.color_left[2],aa.color_left[3],aa.color_left[4],"cb",0,"⮜")
    end
end

function visual_functions:min_dmg_indicator()

    if ui.get(new_menu_references["visuals"].enable_min_dmg_ovrrd) then

        local w,h = client.screen_size()

        if ui.get(menu_reference.min_dmg_override[1]) and ui.get(menu_reference.min_dmg_override[2]) then
            if ui.get(menu_reference.min_dmg_override[3]) == 0 then
                visual_functions.damage_indi = "auto"
            elseif ui.get(menu_reference.min_dmg_override[3]) > 100 then
                visual_functions.damage_indi = "HP+" .. ui.get(menu_reference.min_dmg_override[3]) - 100
            elseif ui.get(menu_reference.min_dmg_override[3]) <= 100 then
                visual_functions.damage_indi = ui.get(menu_reference.min_dmg_override[3])
            end
           
        elseif  not ui.get(menu_reference.min_dmg_override[1]) or not ui.get(menu_reference.min_dmg_override[2]) then 
    
            if ui.get(menu_reference.minimum_damage) == 0 then
                visual_functions.damage_indi = "auto"
            elseif ui.get(menu_reference.minimum_damage) > 100 then
                visual_functions.damage_indi = "HP+" .. ui.get(menu_reference.minimum_damage) - 100
            elseif ui.get(menu_reference.minimum_damage) <= 100 then
                visual_functions.damage_indi = ui.get(menu_reference.minimum_damage)
            end
        end
    
        renderer.text(w / 2 + 13, h / 2 - 15 , 255, 255, 255, 255,"c-",0,tostring(visual_functions.damage_indi):upper())
    end
end

function visual_functions:desync_indicator()

    if ui.get(new_menu_references["visuals"].enable_desync_indicator) then

        local scoped = entity.get_prop(entity.get_local_player(),"m_bIsScoped") == 1 and true or false
       local scoped_and_box = ui.get(new_menu_references["visuals"].scoped_animation) and scoped
       visual_functions.offset2 = lerp(visual_functions.offset2,scoped_and_box and 17 or 0,globals.frametime() * 15)

        local w,h = client.screen_size()
        local desync_color = {ui.get(new_menu_references["visuals"].indicator_desync_color)}

        local desync =  math.floor(math.min(60, (entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) * 120 - 60)))

        if desync < 0 then
            desync = -desync
        end

        local desync_bar = desync * 26 / 60
    
        local indicator_set = ui.get(new_menu_references["visuals"].enable_indicators) == "default" and visual_functions.offset or visual_functions.offset2
        renderer.rectangle(w / 2 - 14 + indicator_set , h / 2 + 13,29,4,0,0,0,255)
        renderer.gradient(w / 2 - 13 + indicator_set, h / 2 + 14,desync_bar,2,desync_color[1],desync_color[2],desync_color[3],desync_color[4],  desync_color[1],desync_color[2],desync_color[3],0,true)
    end 
end

function misc_functions:global_counter()

   
end


local old_sun = {0,0,0}
local yes = false
function misc_functions:sunset()
   
    
end

client.register_esp_flag("AT", 255, 255, 255, function(ent)
    if table_contains(ui.get(new_menu_references["visuals"].extra_visuals),"at target flag") then
        if ent == client.current_threat() then
            return true
        end
    end
end)


local function rotate_around_center(ang, center, point, point2)
	local s, c = math.sin(ang), math.cos(ang)
	point.x,point.y,point2.x,point2.y=point.x-center.x,point.y-center.y,point2.x-center.x,point2.y-center.y

	local x, y = point.x*c - point.y*s, point.x*s + point.y*c
	local x2, y2 = point2.x*c - point2.y*s, point2.x*s + point2.y*c

	return x+center.x, y+center.y, x2+center.x, y2+center.y
end

local zeus_table = {}
local to_add_y = 0
function visual_functions:zeus_indicator()

 
end

function visual_functions:zeus_nigga()

end


local overwritten = false
local function entity_override()
  
end


local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
         return maxValue
    end

    return value
end

local rgba_to_hex = function(b, c, d, e)
    return string.format('%02x%02x%02x%02x', b, c, d, e)
end

local function text_fade_animation(x, y, speed, color1, color2, text)
    local final_text = ''
    local curtime = globals.curtime()
    for i = 0, #text do
        local x = i * 10  
        local wave = math.cos(2 * speed * curtime / 4 + x / 50)
        local color = rgba_to_hex(
            lerp(color1.r, color2.r, clamp(wave, 0, 1)),
            lerp(color1.g, color2.g, clamp(wave, 0, 1)),
            lerp(color1.b, color2.b, clamp(wave, 0, 1)),
            color1.a
        ) 
        final_text = final_text .. ' \a' .. color .. text:sub(i, i) 
    end
    
    renderer.text(x, y, color1.r, color1.g, color1.b, color1.a, "c", nil, final_text)
end


function visual_functions:watermark()
    local w,h = client.screen_size()
    local wm = { ui.get(new_menu_references["visuals"].watermark_color) }
    

    text_fade_animation(w - 50,h / 2,5,{r=255,g=255,b=255,a=255},{r=wm[1],g=wm[2],b=wm[3],a=wm[4]},"starlight")
end


new_menu_references.config.export_file = ui.new_button(tab,place, "export to clipboard", function()

  
end)


new_menu_references.config.import_config = ui.new_button(tab,place,"import from clipboard",function()


  

end)

local function hide_default_aa(conditions)
    ui.set_visible(menu_reference.enabled,conditions)
    ui.set_visible(menu_reference.pitch[1], conditions)
    ui.set_visible(menu_reference.pitch[2], conditions)
    ui.set_visible(menu_reference.roll, conditions)
    ui.set_visible(menu_reference.yawbase, conditions)
    ui.set_visible(menu_reference.yaw[1], conditions)
    ui.set_visible(menu_reference.yaw[2], conditions)
    ui.set_visible(menu_reference.yawjitter[1], conditions)
    ui.set_visible(menu_reference.yawjitter[2], conditions)
    ui.set_visible(menu_reference.bodyyaw[1], conditions)
    ui.set_visible(menu_reference.bodyyaw[2], conditions)
    ui.set_visible(menu_reference.freestand[1], conditions)
    ui.set_visible(menu_reference.freestand[2], conditions)
    ui.set_visible(menu_reference.fsbodyyaw,conditions)
    ui.set_visible(menu_reference.edgeyaw, conditions)
end

-- aa = 1,visuals = 2,misc = 3,config = 4

local ui_menu = {
    selected_tab=1,
    is_hovered=false,
}

local function new_menu_visibility()

    local manual_page = ui.get(new_menu_references["aa"].aa_state_menu) == "manual"
    local main_page = ui.get(new_menu_references.aa_tab) == "main"
    local jitter_page = ui.get(new_menu_references.aa_tab) == "jitter"
    local bruteforce_page = ui.get(new_menu_references.aa_tab) == "bruteforce"
   
    --aa
   -- ui.set_visible(new_menu_references["aa"].aa_label,ui_menu.selected_tab == 1)
    ui.set_visible(new_menu_references["aa"].aa_state_menu,ui.get(tab_coded_by_chupeta) == "AA" or ui.get(tab_coded_by_chupeta) == "AA2" and jitter_page)
    ui.set_visible(new_menu_references.aa_tab,ui.get(tab_coded_by_chupeta) == "AA2")
    
    --local anti_bruteforce = ui.get(new_menu_references["aa"]_tab) == "bruteforce"
    for k,v in ipairs(aa.aa_states) do
        ui.set_visible(new_menu_references["aa"].aa_state[v].enabled,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v)
        ui.set_visible( new_menu_references["aa"].aa_state[v].pitch,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v)
        ui.set_visible( new_menu_references["aa"].aa_state[v].pitch_slider,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].pitch) == "custom")
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawbase,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and not manual_page) 
        ui.set_visible( new_menu_references["aa"].aa_state[v].yaw,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and v ~= "legit" and v ~= "manual") 
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawadd,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and not manual_page and ui.get(new_menu_references["aa"].aa_state[v].yaw) ~= "off") 
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawjitter,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v)  
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawjitteradd,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) ~= "off" and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) ~= "jitter ways" and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) ~= "sway")  
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawjitteradd2,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) == "l & r")  
        ui.set_visible( new_menu_references["aa"].aa_state[v].gs_bodyyaw,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v) 
        ui.set_visible( new_menu_references["aa"].aa_state[v].delayed_method,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) == "delayed yaw") 
        ui.set_visible( new_menu_references["aa"].aa_state[v].gs_bodyyawadd,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) ~= "off" and ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) ~= "anti bruteforce" and ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) ~= "auto jitter" and  ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) ~= "delayed yaw") 
        ui.set_visible( new_menu_references["aa"].aa_state[v].edgeyaw,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and not manual_page) 
        ui.set_visible( new_menu_references["aa"].aa_state[v].roll,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v) 
        ui.set_visible(new_menu_references["aa"].aa_state[v].jway_counter,false)
        ui.set_visible(new_menu_references["aa"].aa_state[v].swaym, ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) == "sway")
        ui.set_visible(new_menu_references["aa"].aa_state[v].swaymx, ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) == "sway")
        ui.set_visible(new_menu_references["aa"].aa_state[v].swayspeed, ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) == "sway")

        if  v ~= "legit" and v ~= "manual" then
            ui.set_visible(new_menu_references["aa"].aa_state[v].yawaddleft, ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and (ui.get(new_menu_references["aa"].aa_state[v].yaw) == "jittery" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "delayed" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "l & r"))
            ui.set_visible(new_menu_references["aa"].aa_state[v].ticker_slider, ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yaw) == "delayed")
        end
        
        if v ~= "fakelag" and v ~= "legit" and v ~= "manual" then
            ui.set_visible(new_menu_references["aa"].aa_state[v].enabled_exploit,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v)
            ui.set_visible( new_menu_references["aa"].aa_state[v].enabled_defensive_force,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit)) 
            ui.set_visible( new_menu_references["aa"].aa_state[v].pitch_defensive,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit))
            ui.set_visible( new_menu_references["aa"].aa_state[v].pitch_custom_defensive,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].pitch_defensive) == "custom" and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit))
            ui.set_visible( new_menu_references["aa"].aa_state[v].yaw_defensive,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit)) 
            ui.set_visible( new_menu_references["aa"].aa_state[v].yawadd_defensive,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yaw_defensive) ~= "off" and ui.get(new_menu_references["aa"].aa_state[v].yaw_defensive) ~= "randomize" and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit)) 
            ui.set_visible( new_menu_references["aa"].aa_state[v].skitter_defensive,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit)) 
            ui.set_visible(new_menu_references["aa"].aa_state[v].skitter_slider_defensive,ui.get(tab_coded_by_chupeta) == "AA" and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].skitter_defensive) and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit))
        end

        ui.set_visible(new_menu_references["aa"].label_jitter_ways,ui.get(tab_coded_by_chupeta) == "AA2" and jitter_page and ui.get(new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].yawjitter) ~= "jitter ways")
        for i = 1, 12 do
            ui.set_visible( new_menu_references["aa"].aa_state[v].pedro_aas2[i]  ,ui.get(tab_coded_by_chupeta) == "AA2" and ui.get(new_menu_references["aa"].aa_state_menu) == v and i <= ui.get(new_menu_references["aa"].aa_state[v].jway_counter) and jitter_page and ui.get(new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].yawjitter) == "jitter ways")
            --print(new_menu_references["aa"].aa_state[v].slider[i])
        end
    end

    --aa2
    
    local keys = ui.get(new_menu_references["keys"].enable_key)
    ui.set_visible(new_menu_references["aa"].freestanding_disabler, ui.get(tab_coded_by_chupeta) == "AA2" and main_page)
    ui.set_visible(new_menu_references["aa"].freestanding_options, ui.get(tab_coded_by_chupeta) == "AA2" and main_page)
    ui.set_visible(jitter_add, ui.get(tab_coded_by_chupeta) == "AA2" and jitter_page and ui.get(new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].yawjitter) == "jitter ways" )
    ui.set_visible(jitter_remove, ui.get(tab_coded_by_chupeta) == "AA2" and jitter_page and ui.get(new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].yawjitter) == "jitter ways")
    ui.set_visible(new_menu_references["keys"].enable_key, ui.get(tab_coded_by_chupeta) == "AA2" and main_page)
    ui.set_visible(new_menu_references["keys"].manual_forward, ui.get(tab_coded_by_chupeta) == "AA2" and main_page and keys)
    ui.set_visible(new_menu_references["keys"].manual_left, ui.get(tab_coded_by_chupeta) == "AA2" and main_page and keys)
    ui.set_visible(new_menu_references["keys"].manual_right, ui.get(tab_coded_by_chupeta) == "AA2" and main_page and keys)
    ui.set_visible(new_menu_references["keys"].manual_reset, ui.get(tab_coded_by_chupeta) == "AA2" and main_page and keys)
    ui.set_visible(new_menu_references["keys"].global_fs, ui.get(tab_coded_by_chupeta) == "AA2" and main_page and keys)
    ui.set_visible(new_menu_references["aa"].anti_kniv, ui.get(tab_coded_by_chupeta) == "AA2" and main_page)
    ui.set_visible(new_menu_references["aa"].safe_dangerous, ui.get(tab_coded_by_chupeta) == "AA2" and main_page)
   

    for h = 1, 4 do
       
        ui.set_visible(new_menu_references["bruteforce"][h],ui.get(tab_coded_by_chupeta) == "AA2" and bruteforce_page)
    end

    --visuals
    --ui.set_visible(new_menu_references["visuals"].visual_label,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].zeus,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].enable_indicators,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].draw_logs,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].indicator_color,ui.get(tab_coded_by_chupeta) == "Visuals" and ui.get(new_menu_references["visuals"].enable_indicators) ~= "off")
    ui.set_visible(new_menu_references["visuals"].scoped_animation,ui.get(tab_coded_by_chupeta) == "Visuals" )
    ui.set_visible(new_menu_references["visuals"].indicator_manual_color,ui.get(tab_coded_by_chupeta) == "Visuals" and ui.get(new_menu_references["visuals"].enable_manual) ~= "off")
    ui.set_visible(new_menu_references["visuals"].enable_manual,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].enable_min_dmg_ovrrd,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].enable_desync_indicator,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].enable_velocity_adaptive, ui.get(tab_coded_by_chupeta) == "Visuals" and ui.get(new_menu_references["visuals"].enable_manual) ~= "off")
    ui.set_visible(new_menu_references["visuals"].enable_defensive_indicator,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].slow_indicator,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].indicator_desync_color,ui.get(tab_coded_by_chupeta) == "Visuals" and ui.get(new_menu_references["visuals"].enable_desync_indicator))
    ui.set_visible(new_menu_references["visuals"].indicator_defensive_color,ui.get(tab_coded_by_chupeta) == "Visuals" and ui.get(new_menu_references["visuals"].enable_defensive_indicator))
    ui.set_visible(new_menu_references["visuals"].indicator_slow_color,ui.get(tab_coded_by_chupeta) == "Visuals" and ui.get(new_menu_references["visuals"].slow_indicator))
    ui.set_visible(new_menu_references["visuals"].aim_logs_label, ui.get(tab_coded_by_chupeta) == "Visuals" and ui.get(new_menu_references["visuals"].aimer_legs))
    ui.set_visible(new_menu_references["visuals"].aim_logs_outline_color, ui.get(tab_coded_by_chupeta) == "Visuals" and ui.get(new_menu_references["visuals"].aimer_legs))
    ui.set_visible(new_menu_references["visuals"].watermark_color, ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].watermark_label, ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].extra_visuals,ui.get(tab_coded_by_chupeta) == "Visuals")
    ui.set_visible(new_menu_references["visuals"].noti_timer,ui.get(tab_coded_by_chupeta) == "Visuals" and (ui.get(new_menu_references["visuals"].aimer_legs) or ui.get(new_menu_references["visuals"].whatsappi)))
    ui.set_visible(new_menu_references["visuals"].noti_padding,ui.get(tab_coded_by_chupeta) == "Visuals" and  ui.get(new_menu_references["visuals"].whatsappi))
    
    --misc
    --ui.set_visible(new_menu_references["misc"].misc_label,ui.get(tab_coded_by_chupeta) == "Misc")
    ui.set_visible(new_menu_references["misc"].enable_clan_tag,ui.get(tab_coded_by_chupeta) == "Misc")
    ui.set_visible(new_menu_references["misc"].enable_kill_say,ui.get(tab_coded_by_chupeta) == "Misc")
    ui.set_visible(new_menu_references["misc"].enable_sun_rise,ui.get(tab_coded_by_chupeta) == "Misc")
    ui.set_visible(new_menu_references["misc"].enable_nigthermode,ui.get(tab_coded_by_chupeta) == "Misc")
    ui.set_visible(new_menu_references["misc"].enable_local_animations,ui.get(tab_coded_by_chupeta) == "Misc")
    ui.set_visible(new_menu_references["misc"].safe_point,ui.get(tab_coded_by_chupeta) == "Misc" and table_contains(ui.get(new_menu_references["misc"].debug_ragebot),"safe point enhancer") and (obex_data.build == "private" or obex_data.build == "Private"))
    ui.set_visible(new_menu_references["misc"].debug_ragebot,ui.get(tab_coded_by_chupeta) == "Misc" and (obex_data.build == "private" or obex_data.build == "Private"))

    --config
    --ui.set_visible(new_menu_references.config.config_label,ui.get(tab_coded_by_chupeta) == "Config")
    ui.set_visible(new_menu_references.config.export_file,ui.get(tab_coded_by_chupeta) == "Config")
    ui.set_visible(new_menu_references.config.import_config,ui.get(tab_coded_by_chupeta) == "Config")
end

client.set_event_callback("player_death",function(ent)

    if client.userid_to_entindex(ent.userid) == entity.get_local_player() then
        brute_stage.last_miss = 0
        for k,v in ipairs(aa.aa_states) do

            if ui.get(new_menu_references["aa"].aa_state[v].yaw) == "l & r" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "delayed" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "jittery" then
                break
            end
          
            if ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) == "anti bruteforce" and not brute_stage.to_reset then
                brute_stage.brute[v].missed_bullets = 0
                print("Anti bruteforce angles were resetted due to death")
                brute_stage.to_reset = true
            end
        end
    end

    if ui.get(new_menu_references["misc"].enable_kill_say) ~= "Disabled" and client.userid_to_entindex(ent.attacker) == entity.get_local_player() and entity.get_prop(client.userid_to_entindex(ent.userid),"m_iTeamNum") ~= entity.get_prop(entity.get_local_player(),"m_iTeamNum") then
       
        client.exec("say " .. misc_functions.kill_say[ui.get(new_menu_references["misc"].enable_kill_say)][client.random_int(1, #misc_functions.kill_say[ui.get(new_menu_references["misc"].enable_kill_say)])])
    end
end)


client.set_event_callback("round_end",function(e)
   brute_stage.round_starting = true  
end)

client.set_event_callback("round_start",function(ent)
    if brute_stage.round_starting == true and brute_stage.to_reset == false then
       
        for k,v in ipairs(aa.aa_states) do

            if ui.get(new_menu_references["aa"].aa_state[v].yaw) == "l & r" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "delayed" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "jittery" then
                break
            end

            if ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) == "anti bruteforce" then
                
                brute_stage.brute[v].missed_bullets = 0
                print("Anti bruteforce angles were resetted due to round start")
                brute_stage.round_starting = false
            end
        end
        
    end

    miss_sp = {}
    brute_stage.to_reset = false
    aa_functions.bomb_was_bombed = false
    aa_functions.bomb_was_defused = false
end)


function misc_functions:local_animations()

    if not entity.is_alive(entity.get_local_player()) then
        misc_functions.end_time = 0
        misc_functions.ground_ticks = 0
        return
    end

    if table_contains(ui.get(new_menu_references["misc"].enable_local_animations),"pitch 0") then

        
        local on_ground = bit.band(entity.get_prop(entity.get_local_player(), "m_fFlags"), 1)

        if on_ground == 1 then
            misc_functions.ground_ticks = misc_functions.ground_ticks + 1
        else
            misc_functions.ground_ticks = 0
            misc_functions.end_time = globals.curtime() + 1
        end

        if  misc_functions.ground_ticks > 5 and misc_functions.end_time + 0.5 > globals.curtime() then
            entity.set_prop(entity.get_local_player(), "m_flPoseParameter", 0.5, 12)
        end
    end

    if table_contains(ui.get(new_menu_references["misc"].enable_local_animations),"reversed legs") then
        local math_randomized = math.random(1,2)

        ui.set(menu_reference.leg_movement, math_randomized == 1 and "Always slide" or "Never slide")
        entity.set_prop(entity.get_local_player(), "m_flPoseParameter", 8, 0)
    end

    if table_contains(ui.get(new_menu_references["misc"].enable_local_animations),"static legs") then
        entity.set_prop(entity.get_local_player(), "m_flPoseParameter", 1, 6) 
    end

    if table_contains(ui.get(new_menu_references["misc"].enable_local_animations),"moonwalk") then
       

        local me = ent.get_local_player()
        local m_fFlags = me:get_prop("m_fFlags")
        local is_onground = bit.band(m_fFlags, 1) ~= 0
        if not is_onground then
            local my_animlayer = me:get_anim_overlay(6) 
           
            my_animlayer.weight = 1
        else
            ui.set(menu_reference.leg_movement,"Off")
            entity.set_prop(entity.get_local_player(), "m_flPoseParameter", 0, 7)
        end
    end

    if table_contains(ui.get(new_menu_references["misc"].enable_local_animations),"blind") then

        local not_nigganigga = ent.get_local_player() 
        local not_anim_layer = not_nigganigga:get_anim_overlay(9) 
        not_anim_layer.weight = 1
        not_anim_layer.sequence = 224
    end

    if table_contains(ui.get(new_menu_references["misc"].enable_local_animations),"t-pose") then

        local not_nigganigga = ent.get_local_player() 
        local not_anim_layer = not_nigganigga:get_anim_overlay(0)
        not_anim_layer.sequence = 11
    end
  
   
end

client.set_event_callback("bullet_impact", aa_functions.anti_brute_bullet_impact)

client.set_event_callback("pre_render", function()
    misc_functions:local_animations()
end)

local aim_logs = {}
local reason = "spread"

local hitgroup_names = {'Generic', 'Head', 'Chest', 'Stomach', 'Left arm', 'Right arm', 'Left leg', 'Right leg', 'Neck', '?', 'Gear'}

local player_hp_on_fire = 100
client.set_event_callback("aim_fire",function(ent)
    player_hp_on_fire = entity.get_prop(ent.target,"m_iHealth")
    visual_functions.in_fire = true

    visual_functions.chance = math.floor(ent.hit_chance)
    visual_functions.bt = globals.tickcount() - ent.tick
    visual_functions.predicted_damage = ent.damage
    visual_functions.predicted_hitgroup = ent.hitgroup
end)

local random_resolver_value = {"B","SBY","SBAY","BY","SE","SB","SBM","S"}

local miss_sp = {}

client.set_event_callback("aim_miss",function(ent)

    local group = hitgroup_names[ent.hitgroup + 1] or "?"
    local name = entity.get_player_name(ent.target)
    local hp_left = entity.get_prop(ent.target, "m_iHealth")
    local js = panorama.open()
    local persona_api = js.MyPersonaAPI
    local username = persona_api.GetName()  
    local targetname = name;
    local hitbox = group;
    local hc = visual_functions.chance;
    local backtrack = visual_functions.bt;

    if ent.reason == "?" then
        reason = "unknown"
    else
        reason = ent.reason
    end

    if ent ~= nil then
        miss_sp[#miss_sp + 1] = 
        {
            nigga = ent.target,
            hp = hp_left,
        }
    end
   
    aim_logs[#aim_logs + 1] = 
    {
        text = string.format("Missed \aFF0032FF%s\aFFFFFFFF in the \aFF0032FF%s\aFFFFFFFF shot due to \aFF0032FF%s\aFFFFFFFF",name,string.lower(hitbox),string.lower(reason)),
        timer = globals.tickcount() * globals.tickinterval(),
        alpha = 255,
        hit = false,
    }

    if ui.get(new_menu_references["visuals"].draw_logs) then
        print(string.format("Missed shot due to %s",reason))
    end


    if table_contains(ui.get(new_menu_references["visuals"].extra_visuals),"beta logs") then
      
        if ent.target ~= nil or ent ~= nil then
             if get_velocity(ent.target) > 2 then
                visual_functions.move = 1
            else
                visual_functions.move = 0
            end
        end

        local beta_string =  client.color_log(255,130,120, string.format("[-] Missed %s's %s for %s damage (%s) due to %s bt=%dms (%s) [2:1:27⁺:16⁺] %s move=%s t=%s boneyaw=%s.%s%s%s",name,hitbox,visual_functions.predicted_damage,hc .. "%",reason, tonumber(totime(backtrack) * 1000),backtrack,random_resolver_value[client.random_int(1,#random_resolver_value)]
    ,visual_functions.move,client.random_int(0,30),client.random_int(-100,100),client.random_int(00,99),client.random_int(00,99),client.random_int(00,99)));
    end
end)

client.set_event_callback("aim_hit",function(ent)

   local left_hp = player_hp_on_fire - ent.damage 

   local group = hitgroup_names[ent.hitgroup + 1] or "?"
   local name = entity.get_player_name(ent.target)
   local damage = ent.damage
   local hp_left = entity.get_prop(ent.target, "m_iHealth")
   local js = panorama.open()
   local persona_api = js.MyPersonaAPI
   local username = persona_api.GetName()  
   local targetname = name
   local hitbox = group
   local dmg = damage
   local hc = visual_functions.chance
   local backtrack = visual_functions.bt;
   local predicted_group = hitgroup_names[visual_functions.predicted_hitgroup + 1] or "?"

   if left_hp < 0 then
    left_hp = 0
   end

    aim_logs[#aim_logs + 1] = 
    {
        text = string.format("Hit \a96C83CFF%s\aFFFFFFFF in the \a96C83CFF%s\aFFFFFFFF for \a96C83CFF%s\aFFFFFFFF damage (\a96C83CFF%s\aFFFFFFFF health remaining)",entity.get_player_name(ent.target),string.lower(hitgroup_names[ent.hitgroup +  1]),ent.damage,left_hp),
        timer = globals.tickcount() * globals.tickinterval(),
        alpha = 255,
        state = true,
    }

    if ui.get(new_menu_references["visuals"].draw_logs) then
        print(string.format("Hit %s in the %s for %s damage (%s health remaining)",entity.get_player_name(ent.target),hitgroup_names[ent.hitgroup +  1],ent.damage,left_hp))
    end

    if table_contains(ui.get(new_menu_references["visuals"].extra_visuals),"beta logs") then
        if visual_functions.predicted_damage > damage then
            visual_functions.calc_dmg = visual_functions.predicted_damage - damage
            visual_functions.damage_predict_string_calc = "-" .. tostring(visual_functions.calc_dmg)
        elseif visual_functions.predicted_damage < damage then
            visual_functions.calc_dmg = damage - visual_functions.predicted_damage
            visual_functions.damage_predict_string_calc = "+" .. tostring(visual_functions.calc_dmg)
        elseif visual_functions.predicted_damage == damage then
            visual_functions.damage_predict_string_calc = "+0"
        end

        if get_velocity(ent.target) > 2 then
            visual_functions.move = 1
        else
            visual_functions.move = 0
        end


        local beta_string =  client.color_log(160,180,100, string.format("[+] Hit %s's %s for %s (%s) damage (%s) bt=%dms (%s) [2:1:27⁺:16⁺] %s move=%s t=%s boneyaw=%s.%s%s%s",name,hitbox,damage,visual_functions.damage_predict_string_calc,hc .. "%", tonumber(totime(backtrack) * 1000),backtrack,random_resolver_value[client.random_int(1,#random_resolver_value)]
    ,visual_functions.move,client.random_int(0,30),client.random_int(-100,100),client.random_int(00,99),client.random_int(00,99),client.random_int(00,99)));
    end
end)

local function right_alpha(condition,alpha1,alpha2)
    if condition == true then
        return alpha2
    end

    return alpha1
end

function visual_functions:notifcation()


    if ui.get(new_menu_references["visuals"].aimer_legs) then

        local w,h = client.screen_size()
        for i = 1,#aim_logs do
    
            if aim_logs[i] == nil then 
                break
            end
    
            if not aim_logs[i].init then 
                aim_logs[i].pos_animation = w + 50
                aim_logs[i].x_animation = 0
                aim_logs[i].init = true
            end

            aim_logs[i].pos_animation = lerp(aim_logs[i].pos_animation,(h/ 2 + (h / 2 * 0.75)) - i * 35,globals.frametime() * 10)
    
            local measure = { renderer.measure_text("c", aim_logs[i].text) }

            local outlinez_color = { ui.get(new_menu_references["visuals"].aim_logs_outline_color) }
    

            renderer.circle_outline((w / 2)  - measure[1]/2,math.ceil(aim_logs[i].pos_animation)-1,outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4],6, 180, 0.25, 2)
            renderer.circle_outline((w / 2)  + measure[1]/2,math.ceil(aim_logs[i].pos_animation)-1,outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4],6, 270, 0.25, 2)
            renderer.circle_outline((w / 2)  - measure[1]/2,math.ceil(aim_logs[i].pos_animation)-1+15,outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4],6, 90, 0.25, 2)
            renderer.circle_outline((w / 2)  + measure[1]/2,math.ceil(aim_logs[i].pos_animation)-1+15,outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4],6, 0, 0.25, 2)

            renderer.gradient((w / 2) - measure[1]/2,math.ceil(aim_logs[i].pos_animation)-7, measure[1]/4, 1, outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4], outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(outlinez_color[4]<25,25,outlinez_color[4]), true)
            renderer.gradient((w / 2) - measure[1]/2,math.ceil(aim_logs[i].pos_animation)+19, measure[1]/4, 1, outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4], outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(outlinez_color[4]<25,25,outlinez_color[4]), true)
            renderer.gradient((w / 2)+measure[1]/2-measure[1]/3+1,math.ceil(aim_logs[i].pos_animation)-7, measure[1]/3, 1, outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(outlinez_color[4]<25,25,outlinez_color[4]), outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4], true)
            renderer.gradient((w / 2) + measure[1]/2-measure[1]/3+1,math.ceil(aim_logs[i].pos_animation)+19, measure[1]/3, 1, outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(outlinez_color[4]<25,25,outlinez_color[4]), outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4], true)

            renderer.gradient((w / 2) - measure[1]/2-6,math.ceil(aim_logs[i].pos_animation)-1, 1, 10, outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4], 0, 0, 0, 0, false)
            renderer.gradient((w / 2) + measure[1]/2+5,math.ceil(aim_logs[i].pos_animation)-1, 1, 10, outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4], 0, 0, 0, 0, false)

            renderer.gradient((w / 2) - measure[1]/2-6,math.ceil(aim_logs[i].pos_animation)+6, 1, 10, 0, 0, 0, 0, outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4], false)
            renderer.gradient((w / 2) + measure[1]/2+5,math.ceil(aim_logs[i].pos_animation)+6, 1, 10, 0, 0, 0, 0, outlinez_color[1], outlinez_color[2], outlinez_color[3], outlinez_color[4], false)
           

            rounded_rectangle((w / 2)  - measure[1]/2 - 5,math.ceil(aim_logs[i].pos_animation)-6, measure[1] + 10,25,12,12,12,255,6,15)
            --renderer.rectangle((w / 2)  - measure[1]/2 - 5,math.ceil(aim_logs[i].pos_animation)-6, measure[1] + 10,25,12,12,12,255)
            renderer.text(w/ 2,math.ceil(aim_logs[i].pos_animation) + 5,255,255,255,255,"c",nil,aim_logs[i].text)
            aim_logs[i].timer = aim_logs[i].timer - 0.5

            if globals.tickcount() * globals.tickinterval() >= aim_logs[i].timer + ui.get(new_menu_references["visuals"].noti_timer) then
                table.remove(aim_logs,i)
                break
            end

            if aim_logs[i].pos_animation < h / 2 + 125 then
                table.remove(aim_logs,1)
                break
            end
        end
    end
end

function visual_functions:whatsapp_notifications()
    local w,h = client.screen_size()

    for i=1,#aim_logs do

        if not aim_logs[i].init then 
            aim_logs[i].pos_animation = -50
            aim_logs[i].x_animation = 0
            aim_logs[i].init = true
        end

        if what_noti_image == nil then break end

        aim_logs[i].pos_animation = lerp(aim_logs[i].pos_animation,10 + i * 45,globals.frametime() * 10)

        local actual_string = nil
        if aim_logs[i].state then
            actual_string = string.sub(aim_logs[i].text,5,#aim_logs[i].text)
          else
              actual_string = string.sub(aim_logs[i].text,8,#aim_logs[i].text)
          end   

        local measure = { renderer.measure_text("c", actual_string) }

        local not_x = ui.get(new_menu_references["visuals"].noti_padding)
        
        rounded_rectangle(w / 2 - measure[1]/2 - 7,math.ceil(aim_logs[i].pos_animation) - 37 + not_x, measure[1] + 50,40,50,50,50,200,6,15)
        rounded_rectangle(w / 2 - measure[1]/2 - 10,math.ceil(aim_logs[i].pos_animation) - 40 + not_x, measure[1] + 50,40,0,0,0,255,6,15)
        renderer.rectangle(w / 2 - measure[1]/2,math.ceil(aim_logs[i].pos_animation) - 40 + not_x, measure[1] + 30,40,0,0,0,255)

        renderer.text(w/ 2 - measure[1]/2 + 30,math.ceil(aim_logs[i].pos_animation) - 32 + not_x,220,220,220,255,"",nil, aim_logs[i].state == true and "Starlight ~ \a96C83CFFHit\aFFFFFFFF" or "Starlight ~ \aFF0032FFMiss\aFFFFFFFF")
        

        renderer.text(w/ 2 - measure[1]/2 + 30,math.ceil(aim_logs[i].pos_animation) - 20 + not_x,220,220,220,255,"",nil, actual_string)

        what_noti_image:draw(w / 2 - measure[1]/2 - 5, math.ceil(aim_logs[i].pos_animation) - 35 + not_x,30,30,255,255,255,255,true,nil)

        if globals.tickcount() * globals.tickinterval() >= aim_logs[i].timer + ui.get(new_menu_references["visuals"].noti_timer) then
            table.remove(aim_logs,i)
            break
        end

        if i > 4 then
            table.remove(aim_logs,1)
            break
        end
    end
end

local all_players = {}
local function get_bots_players()

    for k,v in ipairs(entity.get_players(true)) do 
        table.insert(all_players,{index=v,old_pos=0,timeframe=entity.get_prop(v, "m_flSimulationTime") / globals.tickinterval(),wjitter=false,sjitter=false,loop=0})
       
        local was_found = true
        local times_found = 0
        for i,n in ipairs(all_players) do 
            if entity.get_player_name(n.index) == entity.get_player_name(entity.get_local_player()) then 
                table.remove(all_players,i)
                break 
            end

            if n.index == v then
                times_found = times_found + 1
                was_found = false
                if times_found >= 2 then
                    was_found = true 
                    table.remove(all_players,i)
                    break
                end
            else
                was_found = false
            end
        end
    end
end

local atimer = 60
local is_hover_logs = false
local is_hover_logs_2 = false
local lerp_alpha2 = 0
local lerp_alpha3 = 0
function visual_functions:negros()

    is_hover_logs = false
    local outlinez_color = { ui.get(new_menu_references["visuals"].aim_logs_outline_color) }

    if not ui.get(new_menu_references["visuals"].aimer_legs) then
        if ui.is_menu_open() then
            lerp_alpha2 = lerp(lerp_alpha2,130,globals.frametime() * 15)
        else
            lerp_alpha2 = lerp(lerp_alpha2,0,globals.frametime() * 10)

            if lerp_alpha2 <= 1 then return end
        end
        aim_logs = {}
    else
        if ui.is_menu_open() then
            lerp_alpha2 = lerp(lerp_alpha2,255,globals.frametime() * 15)
        else
            lerp_alpha2 = lerp(lerp_alpha2,0,globals.frametime() * 10)
        end
    end

    local w,h = client.screen_size()
    local mpos = { ui.mouse_position() }
    local measure = { renderer.measure_text("c", "Hit \a96C83CFFraz\aFFFFFFFF in the \a96C83CFFhead\aFFFFFFFF for \a96C83CFF69\aFFFFFFFF damage (\a96C83CFF0\aFFFFFFFF health remaining)") }

    if mpos[1] > (w / 2)  - measure[1]/2-5 and mpos[1] < (w / 2) + measure[1]/2+10 and mpos[2] > (h/ 2 + (h / 2 * 0.75)) + 45 and mpos[2] <(h/ 2 + (h / 2 * 0.75)) + 65 then
        --print("hi")
        is_hover_logs = true
        if client.key_state(0x1) and atimer > 70 then
            if ui.is_menu_open() then
               ui.set(new_menu_references["visuals"].aimer_legs,not ui.get(new_menu_references["visuals"].aimer_legs))
               ui.set(new_menu_references["visuals"].whatsappi,false)
            end
            atimer = 0
        end
    end


    local negga = (h/ 2 + (h / 2 * 0.75)) + 45
    
    renderer.rectangle((w / 2)  - measure[1]/2 - 4,negga-6, measure[1] + 8,25,12,12,12,right_alpha(lerp_alpha2<255,255,lerp_alpha2))
    renderer.circle_outline((w / 2)  - measure[1]/2,negga-1,outlinez_color[1], outlinez_color[2], outlinez_color[3],   right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2),6, 180, 0.25, 2)
    renderer.circle_outline((w / 2)  + measure[1]/2,negga-1,outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2),6, 270, 0.25, 2)
    renderer.circle_outline((w / 2)  - measure[1]/2,negga-1+15,outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2),6, 90, 0.25, 2)
    renderer.circle_outline((w / 2)  + measure[1]/2,negga-1+15,outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2),6, 0, 0.25, 2)

    renderer.gradient((w / 2) - measure[1]/2,negga-7, measure[1]/4, 1, outlinez_color[1], outlinez_color[2], outlinez_color[3],  right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2), outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(lerp_alpha2<13,outlinez_color[4] <= 13 and outlinez_color[4] or 13,lerp_alpha2), true)
    renderer.gradient((w / 2) - measure[1]/2,negga+19, measure[1]/4, 1, outlinez_color[1], outlinez_color[2], outlinez_color[3],  right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2), outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(lerp_alpha2<13,outlinez_color[4] <= 13 and outlinez_color[4] or 13,lerp_alpha2), true)
    renderer.gradient((w / 2)+measure[1]/2-measure[1]/3+1,negga-7, measure[1]/3, 1, outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(lerp_alpha2<13,outlinez_color[4] <= 13 and outlinez_color[4] or 13,lerp_alpha2), outlinez_color[1], outlinez_color[2], outlinez_color[3],  right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2), true)
    renderer.gradient((w / 2) + measure[1]/2-measure[1]/3+1,negga+19, measure[1]/3, 1, outlinez_color[1], outlinez_color[2], outlinez_color[3], right_alpha(lerp_alpha2<13,outlinez_color[4] <= 13 and outlinez_color[4] or 13,lerp_alpha2), outlinez_color[1], outlinez_color[2], outlinez_color[3],  right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2), true)

    renderer.gradient((w / 2) - measure[1]/2-6,negga-1, 1, 10, outlinez_color[1], outlinez_color[2], outlinez_color[3],  right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2), 0, 0, 0, 0, false)
    renderer.gradient((w / 2) + measure[1]/2+5,negga-1, 1, 10, outlinez_color[1], outlinez_color[2], outlinez_color[3],  right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2), 0, 0, 0, 0, false)

    renderer.gradient((w / 2) - measure[1]/2-6,negga+6, 1, 10, 0, 0, 0, 0, outlinez_color[1], outlinez_color[2], outlinez_color[3],  right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2), false)
    renderer.gradient((w / 2) + measure[1]/2+5,negga+6, 1, 10, 0, 0, 0, 0, outlinez_color[1], outlinez_color[2], outlinez_color[3],  right_alpha(lerp_alpha2<outlinez_color[4],outlinez_color[4],lerp_alpha2), false)
   

    --renderer.rectangle((w / 2)  - measure[1]/2 - 5,negga-6, measure[1] + 10,25,12,12,12,255)
    renderer.text(w/ 2,negga + 5,255,255,255,right_alpha(lerp_alpha2<255,255,lerp_alpha2),"c",nil,"Hit raz in the head for 69 damage (0 health remaining)")
end

function visual_functions:NIGGASSSSSS()

    is_hover_logs_2 = false

    local is_on = false

    if not ui.get(new_menu_references["visuals"].whatsappi) then
        is_on = false
        if ui.is_menu_open() then
            lerp_alpha3 = math.ceil(lerp(lerp_alpha3,25 + ui.get(new_menu_references["visuals"].noti_padding),globals.frametime() * 15))
        else
            lerp_alpha3 = math.ceil(lerp(lerp_alpha3,-90,globals.frametime() * 10))

            if lerp_alpha3 <= -40 then return end
        end
        aim_logs = {}
    else
        is_on = true
        if ui.is_menu_open() then
            lerp_alpha3 = math.ceil(lerp(lerp_alpha3,25 + ui.get(new_menu_references["visuals"].noti_padding),globals.frametime() * 15))
        else
            lerp_alpha3 = math.ceil(lerp(lerp_alpha3,-90,globals.frametime() * 10))
            if lerp_alpha3 <= -40 then return end
        end
    end

    local w,h = client.screen_size()
    local mpos = { ui.mouse_position() }
    local measure = { renderer.measure_text("c", "Hit \a96C83CFFraz\aFFFFFFFF in the \a96C83CFFhead\aFFFFFFFF for \a96C83CFF69\aFFFFFFFF damage (\a96C83CFF0\aFFFFFFFF health remaining)") }

    if mpos[1] > (w / 2)  - measure[1]/2-15 and mpos[1] < (w / 2) + measure[1]/2+50 and mpos[2] > lerp_alpha3 - 10 and mpos[2] <lerp_alpha3 - 10 + 50 then
        
        is_hover_logs_2 = true
        if client.key_state(0x1) and atimer > 70 then
            if ui.is_menu_open() then
               ui.set(new_menu_references["visuals"].whatsappi,not ui.get(new_menu_references["visuals"].whatsappi))
               ui.set(new_menu_references["visuals"].aimer_legs,false)
            end
            atimer = 0
        end
    end


    if what_noti_image == nil then return end

    
    renderer.rectangle(w / 2 - measure[1]/2 ,lerp_alpha3 - 10, measure[1] + 15,40,0,0,0,255)
    renderer.rectangle(w / 2 - measure[1]/2 - 10,lerp_alpha3  , 10,20,0,0,0,255)
    renderer.circle(w / 2 - measure[1]/2,lerp_alpha3, 0,0,0,255, 10, 180, 0.25)
    renderer.circle(w / 2 - measure[1]/2,lerp_alpha3 + 20, 0,0,0,255, 10, 270, 0.25)

    renderer.rectangle(w / 2 + measure[1]/2 + 12,lerp_alpha3  , 10,20,0,0,0,255)
    renderer.circle(w / 2 + measure[1]/2 + 12,lerp_alpha3, 0,0,0,255, 10, 90, 0.25)
    renderer.circle(w / 2 + measure[1]/2 + 12,lerp_alpha3 + 20, 0,0,0,255, 10, 0, 0.25)
    

    renderer.text(w/ 2 - measure[1]/2 + 35,lerp_alpha3 + 8 - 10,220,220,220,255,"",nil,"Starlight ~ " .. string.format("%s",is_on == true and "\a96C83CFFNotification\aFFFFFFFF" or "\aFF0032FFNotification\aFFFFFFFF"))
    

    renderer.text(w/ 2 - measure[1]/2 + 35,lerp_alpha3 + 20 - 10,220,220,220,255,"",nil, "Hit \a96C83CFFpuwpl\aFFFFFFFF in the \a96C83CFFhead\aFFFFFFFF for \a96C83CFF99\aFFFFFFFF (\a96C83CFF0\aFFFFFFFF health remaining)")

    what_noti_image:draw(w / 2 - measure[1]/2 - 5,lerp_alpha3 + 5 - 10,30,30,255,255,255,255,true,nil)
    
  
   
end

client.register_esp_flag("FS",255,255,255, function(ent)
    if plist.get(ent,"Override safe point") == "On" and (obex_data.build == "private" or obex_data.build == "Private") then return "FS" end
end)

local intro = {}

function visual_functions:welcome_to_starlight()
   local w,h = client.screen_size()
    intro[#intro + 1] ={
        message = "Welcome to starlight, ",
        username = obex_data.username .. '.',
        alpha = 255,
        timer = 600,
        x = w / 2 - 150,
        y = h + h / 2,
    }
end

visual_functions.welcome_to_starlight()

function visual_functions:start_intro()

    if obex_data.username == "mini" or has_intro == "has" then return end

    local w,h = client.screen_size()
    for i = 1,#intro do

        if intro[i] == nil then break end

        renderer.rectangle(0, 0, w, h, 12, 12, 12, intro[i].alpha)
        renderer.text(w / 2, h / 2,255,255,255,intro[i].alpha,"c+",0,intro[i].message .. intro[i].username)
        renderer.text(w / 2, h / 2 + 25,101,130,190,intro[i].alpha,"c+",0,"build " .. string.lower(obex_data.build))

        local size = intro[i].timer * 1 / 600
        renderer.circle_outline(w / 2, h / 2 + 50,101,130,190,intro[i].alpha,10,0,size,2)

        if intro[i].timer < 255 then
            intro[i].alpha = intro[i].alpha - 1
        end
        

        intro[i].timer = intro[i].timer - 1 

        if intro[i].timer < 1 then
            table.remove(intro,#intro)
        end
    end
end


client.set_event_callback("paint",function()
    get_bots_players()
    local scoped = entity.get_prop(entity.get_local_player(),"m_bIsScoped") == 1 and true or false
    local scoped_and_box = ui.get(new_menu_references["visuals"].scoped_animation) and scoped
    visual_functions.offset = lerp(visual_functions.offset,scoped_and_box and 30 or 0,globals.frametime() * 15)

    --aa_functions.can_defensive = false
    if visual_functions.ticks <= -1 and aa_functions.to_start == false and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled_exploit) then
        aa_functions.can_defensive = true
    end
    
    entity_override()
    local screen = vector(client.screen_size())
   
    if entity.is_alive(entity.get_local_player()) then

        visual_functions.slow_indicator()
        if ui.get(new_menu_references["visuals"].enable_indicators) == "default" then
            visual_functions.indicators()
        elseif ui.get(new_menu_references["visuals"].enable_indicators) == "minimal" then
            visual_functions.indicators2()
        elseif ui.get(new_menu_references["visuals"].enable_indicators) == "tonka" then
            visual_functions.indicators3()
        end
        
        visual_functions.zeus_indicator()
        visual_functions.zeus_nigga()
        visual_functions.min_dmg_indicator()
        visual_functions.desync_indicator()
        visual_functions.manual_indicator()

        if table_contains(ui.get(new_menu_references["visuals"].extra_visuals),"beta dt indicator") then
            visual_functions.green_dt_skeet_beta()
        end
    end


    misc_functions.sunset()
    visual_functions.defensive_indicator()

    if ui.get(new_menu_references["visuals"].aimer_legs) then 
        visual_functions.notifcation()
    elseif ui.get(new_menu_references["visuals"].whatsappi) then
     visual_functions.whatsapp_notifications()
    end
    
    --
    misc_functions.global_counter()
    visual_functions.watermark()
end)

function misc_functions:safe_point()

    if obex_data.build ~= "private" and obex_data.build ~= "Private" then return end

    if table_contains(ui.get(new_menu_references["misc"].debug_ragebot),"safe point enhancer") then
       
    end
end

local debug_resolver = false
function aa_functions:resolver()

    if obex_data.build ~= "private" and obex_data.build ~= "Private" then return end

    if table_contains(ui.get(new_menu_references["misc"].debug_ragebot),"defensive aa resolver (exprimental)") then
       
    end

end

client.set_event_callback("net_update_end", misc_functions.safe_point)

client.set_event_callback("setup_command",function(cmd)
    aa_functions:setup(cmd)
    aa_functions:resolver()


    if is_hover_logs or ui_menu.is_hovered or is_hover_logs_2 then
        cmd.in_attack = false
    end

    visual_functions.is_in_attack = cmd.in_attack == 1 and true or false
end)

client.set_event_callback("paint_ui", function()

    if ui.get(new_menu_references["aa"].aa_state_menu) == "legit" and (ui.get(new_menu_references["aa"].aa_state["legit"].yaw) == "jittery" or ui.get(new_menu_references["aa"].aa_state["legit"].yaw) == "delayed")then
        ui.set(new_menu_references["aa"].aa_state[9].yaw,"180")
    end
    
    visual_functions.negros()
    visual_functions.NIGGASSSSSS()
    if atimer < 71 then
        atimer = atimer + 1
    end
    visual_functions.start_intro()
    if ui.is_menu_open() then
        hide_default_aa(false)
        new_menu_visibility()
    end
end)


client.set_event_callback("shutdown", function()
  
    database.write("has_intro_starlight", "has")
    hide_default_aa(true)
end)

client.set_event_callback("bomb_exploded",function()
    aa_functions.bomb_was_bombed = true
end)

client.set_event_callback("bomb_defused",function()
    aa_functions.bomb_was_defused = true
end)