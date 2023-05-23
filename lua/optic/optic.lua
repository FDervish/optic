clua_version = 2.056

-- Modules
local glue = require "glue"
local deepcopy = glue.deepcopy
local harmony = require "mods.harmony"
local optic = harmony.optic
local blam = require "blam"
local json = require "json"
local glue = require "glue"
local createSprites = require "optic.sprites"
-- Constants
local opticVersion = "3.1.0"
-- Switches
DebugMode = false

-- Controlled by optic.json config file, do not edit on the script!
local configuration = {
    enableSound = true,
    hitmarker = true,
    hudMessages = true,
    style = "halo_4",
    volume = 50
}

local function dprint(message)
    if (DebugMode) then
        console_out(message)
    end
end

local events = {
    fallingDead = "falling dead",
    guardianKill = "guardian kill",
    vehicleKill = "vehicle kill",
    playerKill = "player kill",
    betrayed = "betrayed",
    suicide = "suicide",
    localKilledPlayer = "local killed player",
    localDoubleKill = "local double kill",
    localTripleKill = "local triple kill",
    localKilltacular = "local killtacular",
    localKillingSpree = "local killing spree",
    localRunningRiot = "local running riot",
    localCtfScore = "local ctf score",
    ctfEnemyScore = "ctf enemy score",
    ctfAllyScore = "ctf ally score",
    ctfEnemyStoleFlag = "ctf enemy stole flag",
    ctfEnemyReturnedFLag = "ctf enemy returned flag",
    ctfAllyStoleFlag = "ctf ally stole flag",
    ctfAllyReturnedFlag = "ctf ally returned flag",
    ctfFriendlyFlagIdleReturned = "ctf friendly flag idle returned",
    ctfEnemyFlagIdleReturned = "ctf enemy flag idle returned"
}

local soundsEvents = {hitmarker = "ting"}

local imagesPath = "%s/images/%s.png"
local soundsPath = "%s/sounds/%s.mp3"
local opticStylePath = "%s/sprites.style"
local playerData = {
    deaths = 0,
    kills = 0,
    noKillSinceDead = false,
    killingSpreeCount = 0,
    dyingSpreeCount = 0,
    multiKillCount = 0,
    multiKillTimestamp = nil,
    flagCaptures = 0
}
local defaultPlayerData = deepcopy(playerData)

local screenWidth = read_word(0x637CF2)
local screenHeight = read_word(0x637CF0)
-- FIXME There should be a better way to scale this, I just did simple math to obtain this value
-- local defaultMedalSize = (screenHeight * 0.065) - 1
local defaultMedalSize = (screenHeight / 15) - 1
local medalsLoaded = false

---@class sprite
---@field name string Name of the image file name of the sprite
---@field width number Width of the sprite image
---@field height number Height of sprite image
---@field renderGroup string Alternative render group for the sprite, medal group by default
---@field hasAudio boolean

--- Create and format paths for sprite images
--- This is helpful to avoid hardcoding sprite absolute paths
local function image(spriteName)
    return imagesPath:format(configuration.style, spriteName)
end

--- Create and format paths for sprite images
-- This is helpful to avoid hardcoding sprite absolute paths
local function audio(spriteName)
    return soundsPath:format(configuration.style, spriteName)
end

local sprites
local sounds
local medalsQueue = {}
local harmonySprites = {}
local harmonySounds = {}

local function loadOpticStyle()
    local styleFile = read_file(opticStylePath:format(configuration.style))
    if (styleFile) then
        local style = json.decode(styleFile)
        if (style) then
            defaultMedalSize = (screenHeight / style.medalSizeFactor) - 1
            return true
        end
    end
    console_out("Error, Optic style does not have a style.json file!")
    return false
end

local function loadOpticConfiguration()
    dprint("Loading optic configuration...")
    local opticConfiguration = read_file("optic.json")
    if (opticConfiguration) then
        configuration = glue.update(configuration, json.decode(opticConfiguration))
        dprint("Success, configuration loaded correctly.")
        loadOpticStyle()
        return true
    end
    dprint("Warning, unable to load optic configuration.")
    return false
end

local function saveOpticConfiguration()
    dprint("Saving optic configuration...")
    local configurationSavedSuccesfully = write_file("optic.json", json.encode(configuration))
    if (configurationSavedSuccesfully) then
        dprint("Success, configuration saved successfully.")
        return true
    end
    dprint("Warning, unable to save optic configuration.")
    return false
end

function OnScriptLoad()
    loadOpticConfiguration()

    sprites = createSprites(defaultMedalSize)

    sounds = {suicide = {name = "suicide"}, betrayal = {name = "betrayal"}}

    -- Create sprites
    for event, sprite in pairs(sprites) do
        if (sprite.name) then
            local medalImagePath = image(sprite.name)
            local medalSoundPath = audio(sprite.name)
            if not file_exists(medalImagePath) then
                medalImagePath = image(sprite.alias)
                medalSoundPath = audio(sprite.alias)
            end
            dprint("Loading sprite: " .. sprite.name)
            dprint("Image: " .. medalImagePath)
            if (file_exists(medalImagePath)) then
                if (file_exists(medalSoundPath)) then
                    dprint("Sound: " .. medalSoundPath)
                    harmonySprites[sprite.name] = optic.create_sprite(medalImagePath, sprite.width,
                                                                      sprite.height)
                    if configuration.enableSound then
                        harmonySounds[sprite.name] = optic.create_sound(medalSoundPath)
                        sprites[event].hasAudio = true
                    end
                else
                    -- dprint("Warning, there is no sound for this sprite!")
                    harmonySprites[sprite.name] = optic.create_sprite(medalImagePath, sprite.width,
                                                                      sprite.height)
                end
            end
        end
    end

    for event, sound in pairs(sounds) do
        if (sound.name) then
            local soundPath = audio(sound.name)
            dprint("Loading sound: " .. sound.name)
            dprint("Sound: " .. soundPath)
            if (file_exists(soundPath)) then
                harmonySounds[sound.name] = optic.create_sound(soundPath)
            end
        end
    end

    -- Fade in animation
    local fadeInAnimation = optic.create_animation(300)
    optic.set_animation_property(fadeInAnimation, "ease in", "position x", defaultMedalSize)
    optic.set_animation_property(fadeInAnimation, "ease in", "opacity", 255)

    -- Fade out animation
    local fadeOutAnimation = optic.create_animation(400)
    optic.set_animation_property(fadeOutAnimation, "ease out", "opacity", -255)

    -- Slide animation
    local slideAnimation = optic.create_animation(250)
    optic.set_animation_property(slideAnimation, 0.4, 0.0, 0.6, 1.0, "position x", defaultMedalSize)

    hitmarkerEnterAnimation = optic.create_animation(0)

    -- Hitmarker kill fade animation
    hitmarkerFadeAnimation = optic.create_animation(80)
    optic.set_animation_property(hitmarkerFadeAnimation, "linear", "opacity", -255)

    -- Create sprites render queue
    renderQueue = optic.create_render_queue(50, (screenHeight / 2) - (defaultMedalSize / 2), 255, 0,
                                            4000, 0, fadeInAnimation, fadeOutAnimation,
                                            slideAnimation)

    -- Create audio engine instance
    if configuration.enableSound then
        AudioEngine = optic.create_audio_engine()
        harmony.optic.set_audio_engine_gain(AudioEngine, configuration.volume or 50)
    end

    medalsLoaded = true

    -- Load medals callback
    harmony.set_callback("multiplayer sound", "OnMultiplayerSound")
    harmony.set_callback("multiplayer event", "OnMultiplayerEvent")

    dprint("Medals loaded!")
end

--- Normalize any map name or snake case name to a name with sentence case
---@param name string
local function toSentenceCase(name)
    return string.gsub(" " .. name:gsub("_", " "), "%W%l", string.upper):sub(2)
end

---@param sprite sprite
local function medal(sprite)
    if (medalsLoaded) then
        medalsQueue[#medalsQueue + 1] = sprite.name
        local renderGroup = sprite.renderGroup
        local harmonySprite = harmonySprites[sprite.name]
        if harmonySprite then
            -- TODO Add render group discrimination
            if (renderGroup) then
                -- Crosshair sprite
                if sprite.name == "hitmarker" then
                    optic.render_sprite(harmonySprite,
                                        (screenWidth - sprites.hitmarkerHit.width) / 2,
                                        (screenHeight - sprites.hitmarkerHit.height) / 2, 255, 0,
                                        200)
                else
                    optic.render_sprite(harmonySprite,
                                        (screenWidth - sprites.hitmarkerKill.width) / 2,
                                        (screenHeight - sprites.hitmarkerKill.height) / 2, 255, 0,
                                        200, hitmarkerEnterAnimation, hitmarkerFadeAnimation)
                end
            else
                optic.render_sprite(harmonySprite, renderQueue)
                if sprite.hasAudio and configuration.enableSound then
                    local harmonyAudio = harmonySounds[sprite.name]
                    optic.play_sound(harmonyAudio, AudioEngine)
                end
            end
            if (configuration.hudMessages) then
                if (not sprite.name:find("hitmarker")) then
                    hud_message(toSentenceCase(sprite.name))
                end
            end
        end
    else
        console_out("Error, medals were not loaded properly!")
    end
end

local function sound(sound)
    if harmonySounds[sound.name] and configuration.enableSound then
        optic.play_sound(harmonySounds[sound.name], AudioEngine)
    else
        dprint("Warning, sound " .. sound.name .. " was not loaded!")
    end
end

function OnMultiplayerSound(soundEventName)
    dprint("sound: " .. soundEventName)
    if (soundEventName == soundsEvents.hitmarker) then
        if (configuration.hitmarker) then
            medal(sprites.hitmarkerHit)
        end
    end
    -- Cancel default sounds that are using medals sounds
    if (soundEventName:find("kill") or soundEventName:find("running")) then
        dprint("Cancelling sound...")
        return false
    end
    return true
end

local function isPreviousMedalKillVariation()
    local lastMedal = medalsQueue[#medalsQueue]
    if (lastMedal and lastMedal:find("kill") and lastMedal ~= "normal_kill") then
        medalsQueue[#medalsQueue] = nil
        return true
    end
    return false
end

function OnMultiplayerEvent(eventName, localId, killerId, victimId)
    dprint("event: " .. eventName)
    dprint("localId: " .. tostring(localId))
    dprint("killerId: " .. tostring(killerId))
    dprint("victimId: " .. tostring(victimId))
    if eventName == events.localKilledPlayer then
        local player = blam.biped(get_dynamic_player())
        local victim = blam.biped(victimId)
        if victim then
            dprint("Victim is alive!")
        end
        if player then
            local firstPerson = blam.firstPerson()
            if firstPerson then
                local weapon = blam.weapon(get_object(firstPerson.weaponObjectId))
                if weapon then
                    local tag = blam.getTag(weapon.tagId)
                    if (tag and blam.isNull(player.vehicleObjectId)) then
                        if (tag.path:find("sniper")) then
                            -- FIXME Check if there is a way to tell how our victim died
                            if (blam.isNull(player.zoomLevel) and player.weaponPTH) then
                                medal(sprites.snapshot)
                            end
                        elseif tag.path:find("rocket") then
                            medal(sprites.rocketKill)
                        elseif tag.path:find("needler") then
                            medal(sprites.supercombine)
                        end
                    end
                end
            end
            local localPlayer = blam.player(get_player())
            local allServerKills = 0
            for playerIndex = 0, 15 do
                local playerData = blam.player(get_player(playerIndex))
                if (playerData and playerData.index ~= localPlayer.index) then
                    allServerKills = allServerKills + playerData.kills
                end
            end
            dprint("All server kills: " .. allServerKills)
            if (allServerKills == 0 and localPlayer.kills == 1) then
                medal(sprites.firstStrike)
            end
            if player.health <= 0.25 then
                medal(sprites.closeCall)
            end
            if (not isPreviousMedalKillVariation()) then
                medal(sprites.kill)
            end
            if (configuration.hitmarker) then
                medal(sprites.hitmarkerKill)
            end

            -- Bump up killing spree count
            if localId == killerId then
                playerData.killingSpreeCount = playerData.killingSpreeCount + 1

                -- Killing spree medals
                if (playerData.killingSpreeCount == 5) then
                    medal(sprites.killingSpree)
                elseif (playerData.killingSpreeCount == 10) then
                    medal(sprites.killingFrenzy)
                elseif (playerData.killingSpreeCount == 15) then
                    medal(sprites.runningRiot)
                elseif (playerData.killingSpreeCount == 20) then
                    medal(sprites.rampage)
                elseif (playerData.killingSpreeCount == 25) then
                    medal(sprites.untouchable)
                elseif (playerData.killingSpreeCount == 30) then
                    medal(sprites.invincible)
                elseif (playerData.killingSpreeCount == 35) then
                    medal(sprites.inconceivable)
                elseif (playerData.killingSpreeCount == 40) then
                    medal(sprites.unfriggenbelievable)
                end

                -- Comeback kill medal
                if (playerData.dyingSpreeCount <= -3) then
                    playerData.dyingSpreeCount = 0
                    medal(sprites.comebackKill)
                end

                -- Multikill medals
                if not playerData.multiKillTimestamp then
                    playerData.multiKillTimestamp = harmony.time.set_timestamp()
                    playerData.multiKillCount = 1
                else
                    playerData.multiKillCount = playerData.multiKillCount + 1

                    -- Check if the 4.5 seconds have already elapsed
                    local timeSinceLastMultiKill = harmony.time.get_elapsed_milliseconds(playerData.multiKillTimestamp)
                    if timeSinceLastMultiKill < 4500 then
                        if (playerData.multiKillCount == 2) then
                            medal(sprites.doubleKill)
                        elseif (playerData.multiKillCount == 3) then
                            medal(sprites.tripleKill)
                        elseif (playerData.multiKillCount == 4) then
                            medal(sprites.overkill)
                        elseif (playerData.multiKillCount == 5) then
                            medal(sprites.killtacular)
                        elseif (playerData.multiKillCount == 6) then
                            medal(sprites.killtrocity)
                        elseif (playerData.multiKillCount == 7) then
                            medal(sprites.killimanjaro)
                        elseif (playerData.multiKillCount == 8) then
                            medal(sprites.killtastrophe)
                        elseif (playerData.multiKillCount == 9) then
                            medal(sprites.killpocalypse)
                        elseif (playerData.multiKillCount == 10) then
                            medal(sprites.killionaire)
                        end

                        if(playerData.multiKillCount < 10) then
                            playerData.multiKillTimestamp = harmony.time.set_timestamp()
                        else
                            playerData.multiKillTimestamp = nil
                            playerData.multiKillCount = 0
                        end
                    else
                        playerData.multiKillTimestamp = harmony.time.set_timestamp()
                        playerData.multiKillCount = 1
                    end
                end
            end
        else
            dprint("Player is dead!")
            medal(sprites.fromTheGrave)
        end
    end

    -- CTF medals
    if eventName == events.localCtfScore then
        playerData.flagCaptures = playerData.flagCaptures + 1
        medal(sprites.flagCaptured)
        if (playerData.flagCaptures == 2) then
            medal(sprites.flagRunner)
        elseif (playerData.flagCaptures == 3) then
            medal(sprites.flagChampion)
        end
    end

    -- Suicide sound
    if (eventName == events.suicide and localId == victimId) then
        playerData.killingSpreeCount = 0
        playerData.dyingSpreeCount = playerData.dyingSpreeCount - 1
        sound(sounds.suicide)
    end

    -- Betrayal sound
    if (eventName == events.betrayed and localId == victimId) then
        sound(sounds.betrayal)
    end

    if eventName == events.playerKill then
        -- Count player dead
        if (localId == killerId) then
            dprint("Local player died!")
            playerData.killingSpreeCount = 0
            playerData.dyingSpreeCount = playerData.dyingSpreeCount - 1
            playerData.multiKillCount = 0
            playerData.multiKillTimestamp = nil
        end
    end
end

function OnCommand(command)
    if (command == "optic_test" or command == "otest") then
        medal(sprites.firstStrike)
        medal(sprites.doubleKill)
        medal(sprites.tripleKill)
        medal(sprites.overkill)
        if (configuration.hitmarker) then
            medal(sprites.hitmarkerHit)
            medal(sprites.hitmarkerKill)
        end
        return false
    elseif (command == "optic_debug" or command == "odebug") then
        DebugMode = not DebugMode
        console_out("Debug Mode: " .. tostring(DebugMode))
        return false
    elseif (command == "optic_version" or command == "oversion") then
        console_out(opticVersion)
        return false
    elseif (command == "optic_reload" or command == "oreload") then
        loadOpticConfiguration()
        return false
    elseif (command:find "optic_style") then
        local params = glue.string.split(command, " ")
        local style = params[2]
        if (style and directory_exists(style)) then
            configuration.style = style
            console_out("Success, optic style loaded")
            saveOpticConfiguration()
            loadOpticConfiguration()
            return false
        end
        console_out("Error at loading optic style")
        return false
    elseif command:find "optic_volume" or command:find "ovolume" then
        local params = glue.string.split(command, " ")
        local volume = tonumber(params[2]) or 1
        configuration.volume = volume
        harmony.optic.set_audio_engine_gain(AudioEngine, configuration.volume)
        console_out("Optic volume set to " .. volume)
        saveOpticConfiguration()
        return false
    elseif command == "optic_sound" or command == "osound" then
        configuration.enableSound = not configuration.enableSound
        console_out("Optic sound: " .. tostring(configuration.enableSound))
        saveOpticConfiguration()
        return false
    end
end

function OnMapLoad()
    melee_anim_parser()
    loadOpticConfiguration()
    if (not medalsLoaded) then
        console_out("Error, medals were not loaded properly!")
    end

    -- Reset player state
    playerData = deepcopy(defaultPlayerData)
end

game_state_address = 0x400002E8
fp_anim_address = 0x40000EB8

kills = 0
killStreak = 0
killTime = 0
casualties = {}
fp = {}
here = false

targets = {
    {"characters\\marine_armored\\marine_armored", 1},
    {"characters\\jackal\\jackal",                 1},
    {"characters\\jackal\\jackal major",           1},
    {"characters\\elite\\elite",                   1},
    {"characters\\elite\\elite special",           1},
    {"characters\\grunt\\grunt",                   1},
    {"characters\\hunter\\hunter",                 nil},
    {"characters\\sentinel\\sentinel",             nil},
    {"characters\\marine\\marine",                 1},
}

targets_instanced = {}

function OnTick()
    game_time = read_word(game_state_address + 12)
    if blam.isGameSinglePlayer() then
        melee_anim_split()
        kill_counter()
    end
end

function kill_counter()
	local object_table = read_dword(read_dword(0x401194))
    local object_count = read_word(object_table + 0x2E)
    local first_object = read_dword(object_table + 0x34)
    for i=0,object_count-1 do
        local object = read_dword(first_object + i * 0xC + 0x8)
        if(object ~= 0 and object ~= 0xFFFFFFFF) then
			local object_type = read_word(object + 0xB4)
            if(object_type == 0) then
                isDead = read_bit(object + 0x106, 2) -- true when object is dead
                health = read_float(object + 0xE0)
                for k, v in pairs(targets) do
                    if v[1] == GetName(object) then
                        head_region_offset = v[2]
                        for k, v in pairs(targets_instanced) do
                            if v[2] ~= object then
                                here = false
                            else 
                                here = true
                                index = k
                                break
                            end
                        end
                        if not here then
                            if head_region_offset == nil then
                                region_health = nil
                            else
                                region_health = read_byte(object + 0x178 + head_region_offset)
                            end
                            table.insert(targets_instanced, {GetName(object),object,region_health,0})
                        else
                            if targets_instanced[index][3] == nil then
                                targets_instanced[index][4] = nil
                            else
                                region_health_last_tick = targets_instanced[index][3]
                                targets_instanced[index][3] = read_byte(object + 0x178 + head_region_offset)
                                if targets_instanced[index][3] ~= region_health_last_tick then
                                    targets_instanced[index][4] = game_time
                                end
                            end
                        end
                    end
                    if (isDead == 1 or health <= 0) and targets[k][1] == GetName(object) and table_contains(casualties, object) == false then
                        killTimer = game_time
                        killerId = read_word(object + 0x40C) -- the most recent object ID to do damage to this object
                        if not blam.isNull(killerId) then
                            killerName = GetName(read_dword(first_object + killerId * 0xC + 0x8)) -- the name of the object that did the damage
                            team = read_dword(object + 0xB8) -- object team : 4294901760 = none, 4294901761 = player, 4294901762 = human, 4294901763 = covenant, 4294901764 = flood, 4294901765 = sentinel,  4294901766 = unused6, 4294901767 = unused7, 4294901768 = unused8, 4294901769 = unused9 ("unused" teams are still valid)
                            if not blam.isNull(killerName) and killerName == "characters\\cyborg\\cyborg" and team ~= 4294901762 and team  ~= 4294901761 then -- hardcoded for the moment, will eventually update it to be more dynamic
                                execute_script("cls")
                                if read_word(fp_anim_address + 30) == melee_anim_id and read_word(fp_anim_address + 32) < 10 then
                                    if math.abs(read_float(object + 0x74) - read_float(get_dynamic_player() + 0x74)) < math.abs(0.1) then
                                        medal(sprites.back_smack)
                                    else
                                        medal(sprites.melee)
                                    end
                                end
                                if game_time - killTime < 150 then
                                    killStreak = killStreak + 1
                                    dprint("Kill Streak: "..killStreak)
                                    if (killStreak == 2) then
                                        medal(sprites.doubleKill)
                                    elseif (killStreak == 3) then
                                        medal(sprites.tripleKill)
                                    elseif (killStreak == 4) then
                                        medal(sprites.overkill)
                                    elseif (killStreak == 5) then
                                        medal(sprites.killtacular)
                                    elseif (killStreak == 6) then
                                        medal(sprites.killtrocity)
                                    elseif (killStreak == 7) then
                                        medal(sprites.killimanjaro)
                                    elseif (killStreak == 8) then
                                        medal(sprites.killtastrophe)
                                    elseif (killStreak == 9) then
                                        medal(sprites.killpocalypse)
                                    elseif (killStreak == 10) then
                                        medal(sprites.killionaire)
                                    end
                                else
                                    killStreak = 1
                                end
                                for k, v in pairs(targets_instanced) do
                                    if v[2] == object then
                                        index = k
                                        break
                                    end
                                end
                                if targets_instanced[index][4] ~= nil and killTimer == targets_instanced[index][4] then
                                    medal(sprites.snipe)
                                end
                                table.insert(casualties, object)
                                kills = kills + 1
                                dprint("Kills: "..kills)
                                killTime = game_time
                            end
                        end
                        table.remove(targets_instanced, index)
                    end
                end
			end
		end
	end
end

function GetName(object)
    if object ~= nil then
        local tag_addr = get_tag(read_dword(object))
        local tag_path_addr = read_dword(tag_addr + 0x10)
        return read_string(tag_path_addr)
    end
end

function table_contains(table, element)
    for _, value in pairs(table) do
      if value == element then
        return true
      end
    end
    return false
end

function split(source, sep)
    local result, i = {}, 1
    while true do
        local a, b = source:find(sep)
        if not a then break end
        local candidat = source:sub(1, a - 1)
        if candidat ~= "" then 
            result[i] = candidat
        end i=i+1
        source = source:sub(b + 1)
    end
    if source ~= "" then 
        result[i] = source
    end
    return result
end

function melee_anim_parser()
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tempTag = blam.getTag(tagIndex)
        if (tempTag and tempTag.class == blam.tagClasses.modelAnimations) then
            if (tempTag.path and tempTag.path:find("fp")) then
                local animationsTag = blam.modelAnimations(tagIndex)
                if (blam.modelAnimations(tagIndex)) then
                    for animationIndex, animation in pairs(animationsTag.animationList) do
                        if animationsTag.fpAnimationList[14] ~= nil then
                            table.insert(fp, {tempTag.path, animationsTag.fpAnimationList[14]})
                            break
                        end
                    end
                end
            end
        end
    end
end

function melee_anim_split()
    for k, v in pairs(fp) do
        name = GetName(get_object(read_dword(fp_anim_address + 16)))
        name = split(name, "\\")
        name = name[#name]
        if v[1]:find(name) then
            melee_anim_id = v[2]
            break
        end
    end
end

melee_anim_parser()

set_callback("command", "OnCommand")
set_callback("map load", "OnMapLoad")
set_callback("tick", "OnTick")

OnScriptLoad()
