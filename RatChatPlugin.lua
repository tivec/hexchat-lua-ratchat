local VERSION = "0.2"
hexchat.register('RatChat', VERSION, 'Custom sounds and highlights for the FuelRats!')
-- When you want to notice something, but not really get 'highlighted'

-- Default configuration
local CONFIG = {}
CONFIG['words'] = {}
CONFIG['mode'] = "loud"
CONFIG['channels'] = {}

local function nocase (s)
  s = string.gsub(s, "%a", function (c)
        return string.format("[%s%s]", string.lower(c),
                                       string.upper(c))
      end)
  return s
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

-- Compatibility: Lua-5.1
function string.split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(t,cap:trim())
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap:trim())
   end
   return t
end

function string.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local function ratchat_message(s)
    hexchat.print("\00320\002RATCHAT\002: \00399" .. s .. "\00399")
end

local function in_allowed_channel()
    local ch = hexchat.get_info("channel")
    for c, _ in pairs(CONFIG['channels']) do
        if c == ch then return true end
    end
    return false
end

local function isoneof(s, l)
    for _, word in ipairs(l) do
        if s == word then return true end
    end
    return false
end

local function get_sound(word)
    wd = CONFIG['words'][word]
    if wd ~= nil and wd['sound'] ~= nil then
        return wd['sound']
    end
    return nil
end

local function get_color(word)
    wd = CONFIG['words'][word]
    if wd ~= nil and wd['color'] ~= nil then
        return wd['color']
    end
    return "99"
end

local function get_bold(word)
    wd = CONFIG['words'][word]
    if wd ~= nil and wd['bold'] then
        return "\002"
    end
    return ""
end

local function word_display(word)
    wd = CONFIG['words'][word]
    if wd == nil then return end
    snd = ""
    if wd['sound'] ~= nil then
        snd = " ("..wd['sound']..")"
    end
    return get_bold(word).."\003"..get_color(word)..word..get_bold(word).."\00399"..snd
end

local function add_word(word, color, sound, bold, notify) 
    -- add to config table
    word = word:lower() -- make it lower case first.
    CONFIG['words'][word] = {}
    CONFIG['words'][word]['color'] = color
    CONFIG['words'][word]['bold'] = bold

    if sound ~= nil then
        if sound:ends(".wav") == false then
            sound = sound..".wav"
        end
        -- add to config table
        CONFIG['words'][word]['sound'] = sound
    end
    
    if notify then
        ratchat_message("Added a new word: " .. word_display(word))
    end

end

local function rem_word(word, notify)
    if CONFIG['words'][word] == nil then
        if notify then
            ratchat_message("No such word.")
        end
        return
    end

    if notify then
        ratchat_message("Removing word: " .. word_display(word))
    end
    CONFIG['words'][word] = nil
end


local function get_channel_list()

    local chans = {}
    local n=0
    
    for k,v in pairs(CONFIG['channels']) do
        n=n+1
        chans[n] = k
    end

    return chans
end

local function add_channel(chan, notify)

    if chan:starts("#") == false then
        chan = "#" .. chan
    end

    CONFIG['channels'][chan] = true
    
    if notify then
        ratchat_message("Added channel " .. chan)
        ratchat_message("Current list is: " .. table.concat(get_channel_list()," "))
    end
end

local function rem_channel(chan, notify)

    if chan:starts("#") == false then
        chan = "#" .. chan
    end

    if CONFIG['channels'][chan] == nil then
        if notify then
            ratchat_message("Invalid channel '"..chan.."'")
            ratchat_message("Current list is: " .. table.concat(get_channel_list()," "))
        end
        return
    end

    CONFIG['channels'][chan] = nil
    
    if notify then
        ratchat_message("Removed channel " .. chan)
        ratchat_message("Current list is: " .. table.concat(get_channel_list()," "))
    end
end

local function save_config()

    local f = io.open(hexchat.get_info("configdir").."\\addons\\ratchat_config.txt", "w")
    if f == nil then
        ratchat_message("Unable to open config file for writing.")
        return
    end

    for k, v in pairs(CONFIG) do
        if k == "words" then
            f:write(k..":\n")
            for w, data in pairs(v) do
                f:write("w: " .. w .. " " .. data['color'])
                if data['bold'] then
                    f:write(" BOLD")
                end
                if data['sound'] ~= nil then
                    f:write(" " .. data['sound'])
                end
                f:write("\n")
            end

        elseif k == "channels" then
            f:write(k..": " .. table.concat(get_channel_list()," ") .."\n")
        else
            f:write(k .. ": " .. v .. "\n")
        end
    end
    f:close()
end

local function set_mode(mode, notify)
    CONFIG['mode'] = mode
    if notify then
        ratchat_message("Mode set to " .. mode:upper())
    end
end

local function load_config()
    local f = io.open(hexchat.get_info("configdir").."\\addons\\ratchat_config.txt", "r")
    if f == nil then
        ratchat_message("Unable to load config file.")
        -- save_config()
        return
    end

    while true do
        local line = f:read()
        if line == nil then break end
        if line:starts("--") then 
            -- do nothing
        end

        --[[
        ****** LAST USED MODE ******
        ]]
        if line:starts("mode:") then

            local m = line:split(":")
            if tablelength(m) > 1 and isoneof(m[2], {"off","loud","silent"}) then
                set_mode(m[2])
            end
        end

        --[[
        ****** CHANNELS ******
        ]]
        if line:starts("channels:") then

            local c = line:split(":")
            for _, ch in ipairs(c[2]:split(" ")) do 
                add_channel(ch, false)
            end
        end

        --[[
        ****** WORD DEFINITIONS ******
        ]]
        if line:starts("words:") then
            local foundWords = {}
            continue = true
            while continue do
                line = f:read() -- read the next
                if line == nil then break end
                if line:starts("w:") == false then 
                    continue = false
                else
                    local wdata = line:split(" ")
                    local l = tablelength(wdata)
                    if l < 3 then
                        -- do nothing
                    else
                        if wdata[4] ~= nil and wdata[4]:lower() == "bold" then
                            add_word(wdata[2], wdata[3], wdata[5], true, false)
                        else
                            add_word(wdata[2], wdata[3], wdata[4], false, false)
                        end
                    end
                end
            end
        end
    end

    f:close()
end

local function replace_word (message, word)

    local actword = message:match("("..nocase(word)..")")
    if actword ~= nil then
        return message:gsub(nocase(word), get_bold(word) .. "\003"..get_color(word)..actword..get_bold(word) .. "\00399"), get_sound(word)
    end

    return nil, nil
end

local event_edited = false
local function on_message (args, event_type)
    if event_edited then
        return -- Ignore own events
    end

    if CONFIG['mode'] == "off" then
        return
    end
    if in_allowed_channel() == false then
        return
    end

    local message = args[2]
    local sound = nil

    local words = CONFIG['words']
    for word, _ in pairs(words) do
        m, s = replace_word (message, word)
        if m ~= nil then
            message = m
            sound = s
        end
    end

    if message ~= args[2] then
        event_edited = true
        args[2] = message
        
        hexchat.emit_print(event_type, unpack(args))
        if sound ~= nil and CONFIG['mode'] == "loud" then
            hexchat.command("splay " .. sound)
        end
        
        event_edited = false
        hexchat.command('gui color 3')
        return hexchat.EAT_ALL
    end

end

local function list_words()
    for k,_ in pairs(CONFIG['words']) do
        b = "no"
        if get_bold(k) == "\002" then
            b = "yes"
        end

        ratchat_message((string.format("%-20s | color: %2s, bold: %-3s | %s",k, get_color(k), b, word_display(k))))
    end
end

local function ratchat_help()
    ratchat_message("Current channel: " .. hexchat.get_info("channel"))
    ratchat_message("-------------------------------------------------")
    ratchat_message("Version " .. VERSION)
    ratchat_message("Commands:")
    ratchat_message(" OFF            : Switches plugin off")
    ratchat_message(" SILENT         : Turn sounds off")
    ratchat_message(" LOUD           : Turn sounds on")
    ratchat_message(" ADD            : See /RATCHAT ADD")
    ratchat_message(" REM            : See /RATCHAT REM")
    ratchat_message(" CHANNELS       : See /RATCHAT CHANNELS")
    ratchat_message(" LIST           : Lists all registered words")
    ratchat_message("-------------------------------------------------")
end

local function ratchat(word, word_eol, userdata)
    -- mode options
    if word[2] == nil then
        ratchat_help()
        return
    end

    if isoneof(word[2]:lower(), {"off","loud","silent"}) then
        set_mode(word[2]:lower(),true)
        save_config()
        return
    end

    if word[2]:lower() == "add" then
        -- add a new word to the listener
        if word[3] == nil or word[4] == nil then
            ratchat_message("RATCHAT ADD <word> <color> [BOLD] [soundfile]:")
            ratchat_message(" * Words are case-insensitive (i.e. 'Hello' is treated the same as 'hello'")
            ratchat_message(" * Existing words will be replaced.")
            ratchat_message(" * Color is a number, see Settings->Preferences->Interface->Colors for a list")
            ratchat_message(" * If BOLD is specified, the text will be presented in bold")
            ratchat_message(" * Soundfile is optional. specify the name of the file (must be in .wav format!).")
            ratchat_message(" * The sound files are found in " .. hexchat.get_info("configdir") .. "\\sounds")
            return
        end

        if word[5] and word[5]:lower() == "bold" then
            add_word(word[3], word[4], word[6], true, true)
        else
            add_word(word[3], word[4], word[5], false, true)
        end

        save_config()
        return
    end

    if word[2]:lower() == "rem" then
        if word[3] == nil then
            ratchat_message("RATCHAT REM <word>:")
            ratchat_message(" * Remove the specified word.")
        end

        rem_word(word[3], true)
        save_config()
        return
    end
    if word[2]:lower() == "list" then
        if CONFIG['words'] == {} then
            ratchat_message("No known words.")
            return
        end
        ratchat_message("Current words:")
        list_words()
        return
    end

    if word[2]:lower() == "channels" then
        if word[3] == nil then
            ratchat_message("RATCHAT CHANNELS ADD/REM <channel>:")
            ratchat_message(" * Add or remove a channel the plugin is allowed to run on.") 
            ratchat_message("Current channels:")
            for ch,_ in pairs(CONFIG['channels']) do
                ratchat_message(" " .. ch)
            end
            return
        end

        if word[3]:lower() == "add" then
            add_channel(word[4], true)
            save_config()
        elseif word[3]:lower() == "rem" then
            rem_channel(word[4], true)
            save_config()
        end

        return
    end

    if word[2]:lower() == "status" then
        ratchat_message("Mode is " .. CONFIG['mode']:upper())
        ratchat_message("Current words:")
        list_words()
        ratchat_message("Current channels:")
        for ch,_ in pairs(CONFIG['channels']) do
            ratchat_message(" " .. ch)
        end
        return
    end
    

    ratchat_help()
end

-- Load configuration
load_config()
save_config() -- to make sure everything is proper.

for _, event in ipairs({'Channel Action', 'Channel Message', 'Your Message'}) do
    hexchat.hook_print(event, function (args)
        return on_message (args, event)
    end, hexchat.PRI_HIGH)
end

hexchat.hook_command("RATCHAT", ratchat)


