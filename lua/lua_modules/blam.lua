------------------------------------------------------------------------------
-- Blam! library for Chimera/SAPP Lua scripting
-- Sledmine, JerryBrick
-- Easier memory handle and provides standard functions for scripting
------------------------------------------------------------------------------
local blam = {_VERSION = "1.6.0"}

------------------------------------------------------------------------------
-- Useful functions for internal usage
------------------------------------------------------------------------------

-- From legacy glue library!
--- String or number to hex
local function tohex(s, upper)
    if type(s) == "number" then
        return (upper and "%08.8X" or "%08.8x"):format(s)
    end
    if upper then
        return (s:sub(".", function(c)
            return ("%02X"):format(c:byte())
        end))
    else
        return (s:gsub(".", function(c)
            return ("%02x"):format(c:byte())
        end))
    end
end

--- Hex to binary string
local function fromhex(s)
    if #s % 2 == 1 then
        return fromhex("0" .. s)
    end
    return (s:gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function split(s, sep)
    if (sep == nil or sep == "") then
        return 1
    end
    local position, array = 0, {}
    for st, sp in function()
        return string.find(s, sep, position, true)
    end do
        table.insert(array, string.sub(s, position, st - 1))
        position = sp + 1
    end
    table.insert(array, string.sub(s, position))
    return array
end

------------------------------------------------------------------------------
-- Blam! engine data
------------------------------------------------------------------------------

-- Engine address list
local addressList = {
    tagDataHeader = 0x40440000,
    cameraType = 0x00647498, -- from giraffe
    gamePaused = 0x004ACA79,
    gameOnMenus = 0x00622058,
    joystickInput = 0x64D998, -- from aLTis
    firstPerson = 0x40000EB8, -- from aLTis
    objectTable = 0x400506B4,
    deviceGroupsTable = 0x00816110,
    widgetsInstance = 0x6B401C
}

-- Server side addresses adjustment
if (api_version or server_type == "sapp") then
    addressList.deviceGroupsTable = 0x006E1C50
end

-- Tag classes values
---@enum tagClasses
local tagClasses = {
    actorVariant = "actv",
    actor = "actr",
    antenna = "ant!",
    biped = "bipd",
    bitmap = "bitm",
    cameraTrack = "trak",
    colorTable = "colo",
    continuousDamageEffect = "cdmg",
    contrail = "cont",
    damageEffect = "jpt!",
    decal = "deca",
    detailObjectCollection = "dobc",
    deviceControl = "ctrl",
    deviceLightFixture = "lifi",
    deviceMachine = "mach",
    device = "devi",
    dialogue = "udlg",
    effect = "effe",
    equipment = "eqip",
    flag = "flag",
    fog = "fog ",
    font = "font",
    garbage = "garb",
    gbxmodel = "mod2",
    globals = "matg",
    glow = "glw!",
    grenadeHudInterface = "grhi",
    hudGlobals = "hudg",
    hudMessageText = "hmt ",
    hudNumber = "hud#",
    itemCollection = "itmc",
    item = "item",
    lensFlare = "lens",
    lightVolume = "mgs2",
    light = "ligh",
    lightning = "elec",
    materialEffects = "foot",
    meter = "metr",
    modelAnimations = "antr",
    modelCollisiionGeometry = "coll",
    model = "mode",
    multiplayerScenarioDescription = "mply",
    object = "obje",
    particleSystem = "pctl",
    particle = "part",
    physics = "phys",
    placeHolder = "plac",
    pointPhysics = "pphy",
    preferencesNetworkGame = "ngpr",
    projectile = "proj",
    scenarioStructureBsp = "sbsp",
    scenario = "scnr",
    scenery = "scen",
    shaderEnvironment = "senv",
    shaderModel = "soso",
    shaderTransparentChicagoExtended = "scex",
    shaderTransparentChicago = "schi",
    shaderTransparentGeneric = "sotr",
    shaderTransparentGlass = "sgla",
    shaderTransparentMeter = "smet",
    shaderTransparentPlasma = "spla",
    shaderTransparentWater = "swat",
    shader = "shdr",
    sky = "sky ",
    soundEnvironment = "snde",
    soundLooping = "lsnd",
    soundScenery = "ssce",
    sound = "snd!",
    spheroid = "boom",
    stringList = "str#",
    tagCollection = "tagc",
    uiWidgetCollection = "Soul",
    uiWidgetDefinition = "DeLa",
    unicodeStringList = "ustr",
    unitHudInterface = "unhi",
    unit = "unit",
    vehicle = "vehi",
    virtualKeyboard = "vcky",
    weaponHudInterface = "wphi",
    weapon = "weap",
    weatherParticleSystem = "rain",
    wind = "wind"
}

-- Blam object classes values
---@enum objectClasses
local objectClasses = {
    biped = 0,
    vehicle = 1,
    weapon = 2,
    equipment = 3,
    garbage = 4,
    projectile = 5,
    scenery = 6,
    machine = 7,
    control = 8,
    lightFixture = 9,
    placeHolder = 10,
    soundScenery = 11
}

-- Camera types
---@enum cameraTypes
local cameraTypes = {
    scripted = 1, -- 22192
    firstPerson = 2, -- 30400
    devcam = 3, -- 30704
    thirdPerson = 4, -- 31952
    deadCamera = 5 -- 23776
}

-- Netgame flag classes
---@enum netgameFlagClasses
local netgameFlagClasses = {
    ctfFlag = 0,
    ctfVehicle = 1,
    ballSpawn = 2,
    raceTrack = 3,
    raceVehicle = 4,
    vegasBank = 5,
    teleportFrom = 6,
    teleportTo = 7,
    hillFlag = 8
}

-- Game type classes
---@enum gameTypeClasses
local gameTypeClasses = {
    none = 0,
    ctf = 1,
    slayer = 2,
    oddball = 3,
    koth = 4,
    race = 5,
    terminator = 6,
    stub = 7,
    ignored1 = 8,
    ignored2 = 9,
    ignored3 = 10,
    ignored4 = 11,
    allGames = 12,
    allExceptCtf = 13,
    allExceptRaceCtf = 14
}

-- Multiplayer team classes
---@enum multiplayerTeamClasses
local multiplayerTeamClasses = {red = 0, blue = 1}

-- Unit team classes
---@enum unitTeamClasses
local unitTeamClasses = {
    defaultByUnit = 0,
    player = 1,
    human = 2,
    covenant = 3,
    flood = 4,
    sentinel = 5,
    unused6 = 6,
    unused7 = 7,
    unused8 = 8,
    unused9 = 9
}

-- Standard console colors
local consoleColors = {
    success = {1, 0.235, 0.82, 0},
    warning = {1, 0.94, 0.75, 0.098},
    error = {1, 1, 0.2, 0.2},
    unknown = {1, 0.66, 0.66, 0.66}
}

-- Offset input from the joystick game data
local joystickInputs = {
    -- No zero values also pressed time until maxmimum byte size
    button1 = 0, -- Triangle
    button2 = 1, -- Circle
    button3 = 2, -- Cross
    button4 = 3, -- Square
    leftBumper = 4,
    rightBumper = 5,
    leftTrigger = 6,
    rightTrigger = 7,
    backButton = 8,
    startButton = 9,
    leftStick = 10,
    rightStick = 11,
    -- Multiple values on the same offset, check dPadValues table
    dPad = 96,
    -- Non zero values
    dPadUp = 100,
    dPadDown = 104,
    dPadLeft = 106,
    dPadRight = 102,
    dPadUpRight = 101,
    dPadDownRight = 103,
    dPadUpLeft = 107,
    dPadDownLeft = 105
    -- TODO Add joys axis
    -- rightJoystick = 30,
}

-- Values for the possible dPad values from the joystick inputs
local dPadValues = {
    noButton = 1020,
    upRight = 766,
    downRight = 768,
    upLeft = 772,
    downLeft = 770,
    left = 771,
    right = 767,
    down = 769,
    up = 765
}

-- Global variables

---	This is the current gametype that is running. If no gametype is running, this will be set to nil
---, possible values are: ctf, slayer, oddball, king, race.
---@type string | nil
gametype = gametype
---This is the index of the local player. This is a value between 0 and 15, this value does not
---match with player index in the server and is not instantly assigned after joining.
---@type number | nil
local_player_index = local_player_index
---This is the name of the current loaded map.
---@type string
map = map
---Return if the map has protected tags data.
---@type boolean
map_is_protected = map_is_protected
---This is the name of the script. If the script is a global script, it will be defined as the
---filename of the script. Otherwise, it will be the name of the map.
---@type string
script_name = script_name
---This is the script type, possible values are global or map.
---@type string
script_type = script_type
---@type '"none"' | '"local"' | '"dedicated"' | '"sapp"'
server_type = server_type
---Return whether or not the script is sandboxed. See Sandoboxed Scripts for more information.
---@deprecated
---@type boolean
sandboxed = sandboxed ---@diagnostic disable-line: deprecated

local backupFunctions = {}

backupFunctions.console_is_open = _G.console_is_open
backupFunctions.console_out = _G.console_out
backupFunctions.execute_script = _G.execute_script
backupFunctions.get_global = _G.get_global
-- backupFunctions.set_global = _G.set_global
backupFunctions.get_tag = _G.get_tag
backupFunctions.set_callback = _G.set_callback

backupFunctions.spawn_object = _G.spawn_object
backupFunctions.delete_object = _G.delete_object
backupFunctions.get_object = _G.get_object
backupFunctions.get_dynamic_player = _G.get_dynamic_player

backupFunctions.hud_message = _G.hud_message

backupFunctions.create_directory = _G.create_directory
backupFunctions.remove_directory = _G.remove_directory
backupFunctions.directory_exists = _G.directory_exists
backupFunctions.list_directory = _G.list_directory
backupFunctions.write_file = _G.write_file
backupFunctions.read_file = _G.read_file
backupFunctions.delete_file = _G.delete_file
backupFunctions.file_exists = _G.file_exists

------------------------------------------------------------------------------
-- Chimera API auto completion
-- EmmyLua autocompletion for some functions!
-- Functions below do not have a real implementation and are not supossed to be imported
------------------------------------------------------------------------------

---Attempt to spawn an object given tag class, tag path and coordinates.
---Given a tag id is also accepted.
---@overload fun(tagId: number, x: number, y: number, z: number):number
---@param tagClass tagClasses Type of the tag to spawn
---@param tagPath string Path of object to spawn
---@param x number
---@param y number
---@param z number
---@return number? objectId
function spawn_object(tagClass, tagPath, x, y, z)
end

---Attempt to get the address of a player unit object given player index, returning nil on failure.<br>
---If no argument is given, the address to the local player’s unit object is returned, instead.
---@param playerIndex? number
---@return number? objectAddress
function get_dynamic_player(playerIndex)
end

spawn_object = backupFunctions.spawn_object
get_dynamic_player = backupFunctions.get_dynamic_player

------------------------------------------------------------------------------
-- SAPP API bindings
------------------------------------------------------------------------------

---Write content to a text file given file path
---@param path string Path to the file to write
---@param content string Content to write into the file
---@return boolean, string? result True if successful otherwise nil, error
function write_file(path, content)
    local file, error = io.open(path, "w")
    if (not file) then
        return false, error
    end
    local success, err = file:write(content)
    file:close()
    if (not success) then
        os.remove(path)
        return false, err
    else
        return true
    end
end

---Read the contents from a file given file path.
---@param path string Path to the file to read
---@return boolean, string? content string if successful otherwise nil, error
function read_file(path)
    local file, error = io.open(path, "r")
    if (not file) then
        return false, error
    end
    local content, error = file:read("*a")
    if (content == nil) then
        return false, error
    end
    file:close()
    return content
end

---Attempt create a directory with the given path.
---
---An error will occur if the directory can not be created.
---@param path string Path to the directory to create
---@return boolean
function create_directory(path)
    local success, error = os.execute("mkdir " .. path)
    if (not success) then
        return false
    end
    return true
end

---Attempt to remove a directory with the given path.
---
---An error will occur if the directory can not be removed.
---@param path string Path to the directory to remove
---@return boolean
function remove_directory(path)
    local success, error = os.execute("rmdir -r " .. path)
    if (not success) then
        return false
    end
    return true
end

---Verify if a directory exists given directory path
---@param path string
---@return boolean
function directory_exists(path)
    print("directory_exists", path)
    return os.execute("dir \"" .. path .. "\" > nul") == 0
end

---List the contents from a directory given directory path
---@param path string
---@return nil | integer | table
function list_directory(path)
    -- TODO This needs a way to separate folders from files
    if (path) then
        local command = "dir \"" .. path .. "\" /B"
        local pipe = io.popen(command, "r")
        if pipe then
            local output = pipe:read("*a")
            if (output) then
                local items = split(output, "\n")
                for index, item in pairs(items) do
                    if (item and item == "") then
                        items[index] = nil
                    end
                end
                return items
            end
        end
    end
    return nil
end

---Delete a file given file path
---@param path string
---@return boolean
function delete_file(path)
    return os.remove(path)
end

---Return if a file exists given file path.
---@param path string
---@return boolean
function file_exists(path)
    local file = io.open(path, "r")
    if (file) then
        file:close()
        return true
    end
    return false
end

---Return the memory address of a tag given tagId or tagClass and tagPath
---@param tagIdOrTagType string | number
---@param tagPath? string
---@return number?
function get_tag(tagIdOrTagType, tagPath)
    if (not tagPath) then
        return lookup_tag(tagIdOrTagType)
    else
        return lookup_tag(tagIdOrTagType, tagPath)
    end
end

---Execute a custom Halo script.
---
---A script can be either a standalone Halo command or a Lisp-formatted Halo scripting block.
---@param command string
function execute_script(command)
    return execute_command(command)
end

---Return the address of the object memory given object id
---@param objectId number
---@return number?
function get_object(objectId)
    if (objectId) then
        local object_memory = get_object_memory(objectId)
        if (object_memory ~= 0) then
            return object_memory
        end
    end
    return nil
end

---Despawn an object given objectId. An error will occur if the object does not exist.
---@param objectId number
function delete_object(objectId)
    destroy_object(objectId)
end

---Output text to the console, optional text colors in decimal format.<br>
---Avoid sending console messages if console_is_open() is true to avoid annoying the player.
---@param message string
---@param red? number
---@param green? number
---@param blue? number
function console_out(message, red, green, blue)
    -- TODO Add color printing to this function on SAPP
    cprint(message)
end

---Return true if the player has the console open, always returns true on SAPP.
---@return boolean
function console_is_open()
    return true
end

---Get the value of a Halo scripting global.\
---An error will be triggered if the global is not found
---@param name string Name of the global variable to get from hsc
---@return boolean | number
function get_global(name)
    error("SAPP can not retrieve global variables as Chimera does.. yet!")
end

---Print message to player HUD.\
---Messages will be printed to console if SAPP uses this function
---@param message string
function hud_message(message)
    cprint(message)
end

---Set the callback for an event game from the game events available on Chimera
---@param event '"command"' | '"frame"' | '"preframe"' | '"map_load"' | '"precamera"' | '"rcon message"' | '"tick"' | '"pretick"' | '"unload"'
---@param callback string global function name to call when the event is triggered
function set_callback(event, callback)
    error("Chimera events can not be used on SAPP, use register_callback instead.")
end

if (api_version) then
    -- Provide global server type variable on SAPP
    server_type = "sapp"
    print("Compatibility with Chimera Lua API has been loaded!")
else
    console_is_open = backupFunctions.console_is_open
    console_out = backupFunctions.console_out
    execute_script = backupFunctions.execute_script
    get_global = backupFunctions.get_global
    -- set_global = -- backupFunctions.set_global
    get_tag = backupFunctions.get_tag
    set_callback = backupFunctions.set_callback
    spawn_object = backupFunctions.spawn_object
    delete_object = backupFunctions.delete_object
    get_object = backupFunctions.get_object
    get_dynamic_player = backupFunctions.get_dynamic_player
    hud_message = backupFunctions.hud_message
    create_directory = backupFunctions.create_directory
    remove_directory = backupFunctions.remove_directory
    directory_exists = backupFunctions.directory_exists
    list_directory = backupFunctions.list_directory
    write_file = backupFunctions.write_file
    read_file = backupFunctions.read_file
    delete_file = backupFunctions.delete_file
    file_exists = backupFunctions.file_exists
end

------------------------------------------------------------------------------
-- Generic functions
------------------------------------------------------------------------------

--- Verify if the given variable is a number
---@param var any
---@return boolean
local function isNumber(var)
    return (type(var) == "number")
end

--- Verify if the given variable is a string
---@param var any
---@return boolean
local function isString(var)
    return (type(var) == "string")
end

--- Verify if the given variable is a boolean
---@param var any
---@return boolean
local function isBoolean(var)
    return (type(var) == "boolean")
end

--- Verify if the given variable is a table
---@param var any
---@return boolean
local function isTable(var)
    return (type(var) == "table")
end

--- Remove spaces and tabs from the beginning and the end of a string
---@param str string
---@return string
local function trim(str)
    return str:match("^%s*(.*)"):match("(.-)%s*$")
end

--- Verify if the value is valid
---@param var any
---@return boolean
local function isValid(var)
    return (var and var ~= "" and var ~= 0)
end

------------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------------

--- Convert tag class int to string
---@param tagClassInt number
---@return string?
local function tagClassFromInt(tagClassInt)
    if (tagClassInt) then
        local tagClassHex = tohex(tagClassInt)
        local tagClass = ""
        if (tagClassHex) then
            local byte = ""
            for char in string.gmatch(tagClassHex, ".") do
                byte = byte .. char
                if (#byte % 2 == 0) then
                    tagClass = tagClass .. string.char(tonumber(byte, 16))
                    byte = ""
                end
            end
        end
        return tagClass
    end
    return nil
end

--- Return the current existing objects in the current map, ONLY WORKS FOR CHIMERA!!!
---@return table
function blam.getObjects()
    local currentObjectsList = {}
    for i = 0, 2047 do
        if (get_object(i)) then
            currentObjectsList[#currentObjectsList + 1] = i
        end
    end
    return currentObjectsList
end

-- Local reference to the original console_out function
local original_console_out = console_out

--- Print a console message. It also supports multi-line messages!
---@param message string
local function consoleOutput(message, ...)
    -- Put the extra arguments into a table
    local args = {...}

    if (message == nil or #args > 5) then
        consoleOutput(debug.traceback("Wrong number of arguments on console output function", 2),
                      consoleColors.error)
    end

    -- Output color
    local colorARGB = {1, 1, 1, 1}

    -- Get the output color from arguments table
    if (isTable(args[1])) then
        colorARGB = args[1]
    elseif (#args == 3 or #args == 4) then
        colorARGB = args
    end

    -- Set alpha channel if not set
    if (#colorARGB == 3) then
        table.insert(colorARGB, 1, 1)
    end

    if message then
        if (isString(message)) then
            -- Explode the string!!
            for line in message:gmatch("([^\n]+)") do
                -- Trim the line
                local trimmedLine = trim(line)

                -- Print the line
                original_console_out(trimmedLine, table.unpack(colorARGB))
            end
        else
            original_console_out(message, table.unpack(colorARGB))
        end
    end
end

--- Convert booleans to bits and bits to booleans
---@param bitOrBool number
---@return boolean | number
local function b2b(bitOrBool)
    if (bitOrBool == 1) then
        return true
    elseif (bitOrBool == 0) then
        return false
    elseif (bitOrBool == true) then
        return 1
    elseif (bitOrBool == false) then
        return 0
    end
    error("B2B error, expected boolean or bit value, got " .. tostring(bitOrBool) .. " " ..
              type(bitOrBool))
end

------------------------------------------------------------------------------
-- Data manipulation and binding
------------------------------------------------------------------------------

local typesOperations

local function readBit(address, propertyData)
    return b2b(read_bit(address, propertyData.bitLevel))
end

local function writeBit(address, propertyData, propertyValue)
    return write_bit(address, propertyData.bitLevel, b2b(propertyValue))
end

local function readByte(address)
    return read_byte(address)
end

local function writeByte(address, propertyData, propertyValue)
    return write_byte(address, propertyValue)
end

local function readShort(address)
    return read_short(address)
end

local function writeShort(address, propertyData, propertyValue)
    return write_short(address, propertyValue)
end

local function readWord(address)
    return read_word(address)
end

local function writeWord(address, propertyData, propertyValue)
    return write_word(address, propertyValue)
end

local function readInt(address)
    return read_int(address)
end

local function writeInt(address, propertyData, propertyValue)
    return write_int(address, propertyValue)
end

local function readDword(address)
    return read_dword(address)
end

local function writeDword(address, propertyData, propertyValue)
    return write_dword(address, propertyValue)
end

local function readFloat(address)
    return read_float(address)
end

local function writeFloat(address, propertyData, propertyValue)
    return write_float(address, propertyValue)
end

local function readChar(address)
    return read_char(address)
end

local function writeChar(address, propertyData, propertyValue)
    return write_char(address, propertyValue)
end

local function readString(address)
    return read_string(address)
end

local function writeString(address, propertyData, propertyValue)
    return write_string(address, propertyValue)
end

--- Return the string of a unicode string given address
---@param address number
---@param rawRead? boolean
---@return string
function blam.readUnicodeString(address, rawRead)
    local stringAddress
    if (rawRead) then
        stringAddress = address
    else
        stringAddress = read_dword(address)
    end
    local length = stringAddress / 2
    local output = ""
    -- TODO Refactor this to support full unicode char size
    for i = 1, length do
        local char = read_string(stringAddress + (i - 1) * 0x2)
        if (char == "") then
            break
        end
        output = output .. char
    end
    return output
end

--- Writes a unicode string in a given address
---@param address number
---@param newString string
---@param forced? boolean
function blam.writeUnicodeString(address, newString, forced)
    local stringAddress
    if (forced) then
        stringAddress = address
    else
        stringAddress = read_dword(address)
    end
    -- Allow cancelling writing when the new string is a boolean false value
    if newString == false then
        return
    end
    -- TODO Refactor this to support writing ASCII and Unicode strings
    for i = 1, #newString do
        write_string(stringAddress + (i - 1) * 0x2, newString:sub(i, i))
        if (i == #newString) then
            write_byte(stringAddress + #newString * 0x2, 0x0)
        end
    end
    if #newString == 0 then
        write_string(stringAddress, "")
    end
end

local function readPointerUnicodeString(address, propertyData)
    return blam.readUnicodeString(address)
end

local function readUnicodeString(address, propertyData)
    return blam.readUnicodeString(address, true)
end

local function writePointerUnicodeString(address, propertyData, propertyValue)
    return blam.writeUnicodeString(address, propertyValue)
end

local function writeUnicodeString(address, propertyData, propertyValue)
    return blam.writeUnicodeString(address, propertyValue, true)
end

local function readList(address, propertyData)
    local operation = typesOperations[propertyData.elementsType]
    local elementCount = read_word(address - 0x4)
    local addressList = read_dword(address) + 0xC
    if (propertyData.noOffset) then
        addressList = read_dword(address)
    end
    local list = {}
    for currentElement = 1, elementCount do
        list[currentElement] = operation.read(addressList +
                                                  (propertyData.jump * (currentElement - 1)))
    end
    return list
end

local function writeList(address, propertyData, propertyValue)
    local operation = typesOperations[propertyData.elementsType]
    local elementCount = read_word(address - 0x4)
    local addressList
    if (propertyData.noOffset) then
        addressList = read_dword(address)
    else
        addressList = read_dword(address) + 0xC
    end
    for currentElement = 1, elementCount do
        local elementValue = propertyValue[currentElement]
        if (elementValue) then
            -- Check if there are problems at sending property data here due to missing property data
            operation.write(addressList + (propertyData.jump * (currentElement - 1)), propertyData,
                            elementValue)
        else
            if (currentElement > #propertyValue) then
                break
            end
        end
    end
end

local function readTable(address, propertyData)
    local table = {}
    local elementsCount = read_byte(address - 0x4)
    local firstElement = read_dword(address)
    for elementPosition = 1, elementsCount do
        local elementAddress = firstElement + ((elementPosition - 1) * propertyData.jump)
        table[elementPosition] = {}
        for subProperty, subPropertyData in pairs(propertyData.rows) do
            local operation = typesOperations[subPropertyData.type]
            table[elementPosition][subProperty] = operation.read(elementAddress +
                                                                     subPropertyData.offset,
                                                                 subPropertyData)
        end
    end
    return table
end

local function writeTable(address, propertyData, propertyValue)
    local elementCount = read_byte(address - 0x4)
    local firstElement = read_dword(address)
    for currentElement = 1, elementCount do
        local elementAddress = firstElement + (currentElement - 1) * propertyData.jump
        if (propertyValue[currentElement]) then
            for subProperty, subPropertyValue in pairs(propertyValue[currentElement]) do
                local subPropertyData = propertyData.rows[subProperty]
                if (subPropertyData) then
                    local operation = typesOperations[subPropertyData.type]
                    operation.write(elementAddress + subPropertyData.offset, subPropertyData,
                                    subPropertyValue)
                end
            end
        else
            if (currentElement > #propertyValue) then
                break
            end
        end
    end
end

local function readTagReference(address)
    -- local tagClass = read_dword(address)
    -- local tagPathPointer = read_dword(address = 0x4)
    local tagId = read_dword(address + 0xC)
    return tagId
end

local function writeTagReference(address, propertyData, propertyValue)
    write_dword(address + 0xC, propertyValue)
end

-- Data types operations references
typesOperations = {
    bit = {read = readBit, write = writeBit},
    byte = {read = readByte, write = writeByte},
    short = {read = readShort, write = writeShort},
    word = {read = readWord, write = writeWord},
    int = {read = readInt, write = writeInt},
    dword = {read = readDword, write = writeDword},
    float = {read = readFloat, write = writeFloat},
    char = {read = readChar, write = writeChar},
    string = {read = readString, write = writeString},
    -- TODO This is not ok, a pointer type with subtyping should be implemented
    pustring = {read = readPointerUnicodeString, write = writePointerUnicodeString},
    ustring = {read = readUnicodeString, write = writeUnicodeString},
    list = {read = readList, write = writeList},
    table = {read = readTable, write = writeTable},
    tagref = {read = readTagReference, write = writeTagReference}
}

-- Magic luablam metatable
local dataBindingMetaTable = {
    __newindex = function(object, property, propertyValue)
        -- Get all the data related to property field
        local propertyData = object.structure[property]
        if (propertyData) then
            local operation = typesOperations[propertyData.type]
            local propertyAddress = object.address + propertyData.offset
            operation.write(propertyAddress, propertyData, propertyValue)
        else
            local errorMessage = "Unable to write an invalid property ('" .. property .. "')"
            error(debug.traceback(errorMessage, 2))
        end
    end,
    __index = function(object, property)
        local objectStructure = object.structure
        local propertyData = objectStructure[property]
        if (propertyData) then
            local operation = typesOperations[propertyData.type]
            local propertyAddress = object.address + propertyData.offset
            return operation.read(propertyAddress, propertyData)
        else
            local errorMessage = "Unable to read an invalid property ('" .. property .. "')"
            error(debug.traceback(errorMessage, 2))
        end
    end
}

------------------------------------------------------------------------------
-- Object functions
------------------------------------------------------------------------------

--- Create a blam object
---@param address number
---@param struct table
---@return table
local function createObject(address, struct)
    -- Create object
    local object = {}

    -- Set up legacy values
    object.address = address
    object.structure = struct

    -- Set mechanisim to bind properties to memory
    setmetatable(object, dataBindingMetaTable)

    return object
end

--- Return a dump of a given LuaBlam object
---@param object table
---@return table
local function dumpObject(object)
    local dump = {}
    for k, v in pairs(object.structure) do
        dump[k] = object[k]
    end
    return dump
end

--- Return a extended parent structure with another given structure
---@param parent table
---@param structure table
---@return table
local function extendStructure(parent, structure)
    local extendedStructure = {}
    for k, v in pairs(parent) do
        extendedStructure[k] = v
    end
    for k, v in pairs(structure) do
        extendedStructure[k] = v
    end
    return extendedStructure
end

------------------------------------------------------------------------------
-- Object structures
------------------------------------------------------------------------------

---@class dataTable
---@field name string
---@field maxElements number
---@field elementSize number
---@field capacity number
---@field size number
---@field nextElementId number
---@field firstElementAddress number

local dataTableStructure = {
    name = {type = "string", offset = 0},
    maxElements = {type = "word", offset = 0x20},
    elementSize = {type = "word", offset = 0x22},
    -- padding1 = {size = 0x0A, offset = 0x24},
    capacity = {type = "word", offset = 0x2E},
    size = {type = "word", offset = 0x30},
    nextElementId = {type = "word", offset = 0x32},
    firstElementAddress = {type = "dword", offset = 0x34}
}

local deviceGroupsTableStructure = {
    name = {type = "string", offset = 0},
    maxElements = {type = "word", offset = 0x20},
    elementSize = {type = "word", offset = 0x22},
    firstElementAddress = {type = "dword", offset = 0x34}
}

---@class blamObject
---@field address number
---@field tagId number Object tag ID
---@field isGhost boolean Set object in some type of ghost mode
---@field isOnGround boolean Is the object touching ground
---@field ignoreGravity boolean Make object to ignore gravity
---@field isInWater boolean Is the object touching on water
---@field dynamicShading boolean Enable disable dynamic shading for lightmaps
---@field isNotCastingShadow boolean Enable/disable object shadow casting
---@field isFrozen boolean Freeze/unfreeze object existence
---@field isOutSideMap boolean Is object outside/inside bsp
---@field isCollideable boolean Enable/disable object collision, does not work with bipeds or vehicles
---@field hasNoCollision boolean Enable/disable object collision, causes animation problems
---@field model number Gbxmodel tag ID
---@field health number Current health of the object
---@field shield number Current shield of the object
---@field redA number Red color channel for A modifier
---@field greenA number Green color channel for A modifier
---@field blueA number Blue color channel for A modifier
---@field x number Current position of the object on X axis
---@field y number Current position of the object on Y axis
---@field z number Current position of the object on Z axis
---@field xVel number Current velocity of the object on X axis
---@field yVel number Current velocity of the object on Y axis
---@field zVel number Current velocity of the object on Z axis
---@field vX number Current x value in first rotation vector
---@field vY number Current y value in first rotation vector
---@field vZ number Current z value in first rotation vector
---@field v2X number Current x value in second rotation vector
---@field v2Y number Current y value in second rotation vector
---@field v2Z number Current z value in second rotation vector
---@field yawVel number Current velocity of the object in yaw
---@field pitchVel number Current velocity of the object in pitch
---@field rollVel number Current velocity of the object in roll
---@field locationId number Current id of the location in the map
---@field boundingRadius number Radius amount of the object in radians
---@field class objectClasses Object type
---@field team number Object multiplayer team
---@field nameIndex number Index of object name in the scenario tag
---@field playerId number Current player id if the object
---@field parentId number Current parent id of the object
---//@field isHealthEmpty boolean Is the object health depleted, also marked as "dead"
---@field isApparentlyDead boolean Is the object apparently dead
---@field isSilentlyKilled boolean Is the object really dead
---@field animationTagId number Current animation tag ID
---@field animation number Current animation index
---@field animationFrame number Current animation frame
---@field isNotDamageable boolean Make the object undamageable
---@field regionPermutation1 number
---@field regionPermutation2 number
---@field regionPermutation3 number
---@field regionPermutation4 number
---@field regionPermutation5 number
---@field regionPermutation6 number
---@field regionPermutation7 number
---@field regionPermutation8 number

-- blamObject structure
local objectStructure = {
    tagId = {type = "dword", offset = 0x0},
    isGhost = {type = "bit", offset = 0x10, bitLevel = 0},
    isOnGround = {type = "bit", offset = 0x10, bitLevel = 1},
    ignoreGravity = {type = "bit", offset = 0x10, bitLevel = 2},
    isInWater = {type = "bit", offset = 0x10, bitLevel = 3},
    isStationary = {type = "bit", offset = 0x10, bitLevel = 5},
    hasNoCollision = {type = "bit", offset = 0x10, bitLevel = 7},
    dynamicShading = {type = "bit", offset = 0x10, bitLevel = 14},
    isNotCastingShadow = {type = "bit", offset = 0x10, bitLevel = 18},
    isFrozen = {type = "bit", offset = 0x10, bitLevel = 20},
    -- FIXME Deprecated property, should be erased at a major release later
    frozen = {type = "bit", offset = 0x10, bitLevel = 20},
    isOutSideMap = {type = "bit", offset = 0x12, bitLevel = 5},
    isCollideable = {type = "bit", offset = 0x10, bitLevel = 24},
    model = {type = "dword", offset = 0x34},
    health = {type = "float", offset = 0xE0},
    shield = {type = "float", offset = 0xE4},
    redA = {type = "float", offset = 0x1B8},
    greenA = {type = "float", offset = 0x1BC},
    blueA = {type = "float", offset = 0x1C0},
    x = {type = "float", offset = 0x5C},
    y = {type = "float", offset = 0x60},
    z = {type = "float", offset = 0x64},
    xVel = {type = "float", offset = 0x68},
    yVel = {type = "float", offset = 0x6C},
    zVel = {type = "float", offset = 0x70},
    vX = {type = "float", offset = 0x74},
    vY = {type = "float", offset = 0x78},
    vZ = {type = "float", offset = 0x7C},
    v2X = {type = "float", offset = 0x80},
    v2Y = {type = "float", offset = 0x84},
    v2Z = {type = "float", offset = 0x88},
    -- FIXME Some order from this values is probaby wrong, expected order is pitch, yaw, roll
    yawVel = {type = "float", offset = 0x8C},
    pitchVel = {type = "float", offset = 0x90},
    rollVel = {type = "float", offset = 0x94},
    locationId = {type = "dword", offset = 0x98},
    boundingRadius = {type = "float", offset = 0xAC},
    ---@deprecated
    type = {type = "word", offset = 0xB4},
    class = {type = "word", offset = 0xB4},
    team = {type = "word", offset = 0xB8},
    nameIndex = {type = "word", offset = 0xBA},
    playerId = {type = "dword", offset = 0xC0},
    parentId = {type = "dword", offset = 0xC4},
    isHealthEmpty = {type = "bit", offset = 0x106, bitLevel = 2},
    isApparentlyDead = {type = "bit", offset = 0x106, bitLevel = 2},
    isSilentlyKilled = {type = "bit", offset = 0x106, bitLevel = 5},
    animationTagId = {type = "dword", offset = 0xCC},
    animation = {type = "word", offset = 0xD0},
    animationFrame = {type = "word", offset = 0xD2},
    isNotDamageable = {type = "bit", offset = 0x106, bitLevel = 11},
    regionPermutation1 = {type = "byte", offset = 0x180},
    regionPermutation2 = {type = "byte", offset = 0x181},
    regionPermutation3 = {type = "byte", offset = 0x182},
    regionPermutation4 = {type = "byte", offset = 0x183},
    regionPermutation5 = {type = "byte", offset = 0x184},
    regionPermutation6 = {type = "byte", offset = 0x185},
    regionPermutation7 = {type = "byte", offset = 0x186},
    regionPermutation8 = {type = "byte", offset = 0x187}
}

---@class biped : blamObject
---@field invisible boolean Biped invisible state
---@field noDropItems boolean Biped ability to drop items at dead
---@field ignoreCollision boolean Biped ignores collisiion
---@field flashlight boolean Biped has flaslight enabled
---@field cameraX number Current position of the biped  X axis
---@field cameraY number Current position of the biped  Y axis
---@field cameraZ number Current position of the biped  Z axis
---@field crouchHold boolean Biped is holding crouch action
---@field jumpHold boolean Biped is holding jump action
---@field actionKeyHold boolean Biped is holding action key
---@field actionKey boolean Biped pressed action key
---@field meleeKey boolean Biped pressed melee key
---@field reloadKey boolean Biped pressed reload key
---@field weaponPTH boolean Biped is holding primary weapon trigger
---@field weaponSTH boolean Biped is holding secondary weapon trigger
---@field flashlightKey boolean Biped pressed flashlight key
---@field grenadeHold boolean Biped is holding grenade action
---@field crouch number Is biped crouch
---@field shooting number Is biped shooting, 0 when not, 1 when shooting
---@field weaponSlot number Current biped weapon slot
---@field zoomLevel number Current biped weapon zoom level, 0xFF when no zoom, up to 255 when zoomed
---@field invisibleScale number Opacity amount of biped invisiblity
---@field primaryNades number Primary grenades count
---@field secondaryNades number Secondary grenades count
---@field landing number Biped landing state, 0 when landing, stays on 0 when landing hard, null otherwise
---@field bumpedObjectId number Object ID that the biped is bumping, vehicles, bipeds, etc, keeps the previous value if not bumping a new object
---@field vehicleSeatIndex number Current vehicle seat index of this biped
---@field vehicleObjectId number Current vehicle objectId of this object
---@field walkingState number Biped walking state, 0 = not walking, 1 = walking, 2 = stoping walking, 3 = stationary
---@field motionState number Biped motion state, 0 = standing , 1 = walking , 2 = jumping/falling
---@field mostRecentDamagerPlayer number Id of the player that caused the most recent damage to this biped

-- Biped structure (extends object structure)
local bipedStructure = extendStructure(objectStructure, {
    invisible = {type = "bit", offset = 0x204, bitLevel = 4},
    noDropItems = {type = "bit", offset = 0x204, bitLevel = 20},
    ignoreCollision = {type = "bit", offset = 0x4CC, bitLevel = 3},
    flashlight = {type = "bit", offset = 0x204, bitLevel = 19},
    cameraX = {type = "float", offset = 0x230},
    cameraY = {type = "float", offset = 0x234},
    cameraZ = {type = "float", offset = 0x238},
    crouchHold = {type = "bit", offset = 0x208, bitLevel = 0},
    jumpHold = {type = "bit", offset = 0x208, bitLevel = 1},
    actionKeyHold = {type = "bit", offset = 0x208, bitLevel = 14},
    actionKey = {type = "bit", offset = 0x208, bitLevel = 6},
    meleeKey = {type = "bit", offset = 0x208, bitLevel = 7},
    reloadKey = {type = "bit", offset = 0x208, bitLevel = 10},
    weaponPTH = {type = "bit", offset = 0x208, bitLevel = 11},
    weaponSTH = {type = "bit", offset = 0x208, bitLevel = 12},
    flashlightKey = {type = "bit", offset = 0x208, bitLevel = 4},
    grenadeHold = {type = "bit", offset = 0x208, bitLevel = 13},
    crouch = {type = "byte", offset = 0x2A0},
    shooting = {type = "float", offset = 0x284},
    weaponSlot = {type = "byte", offset = 0x2A1},
    zoomLevel = {type = "byte", offset = 0x320},
    invisibleScale = {type = "byte", offset = 0x37C},
    primaryNades = {type = "byte", offset = 0x31E},
    secondaryNades = {type = "byte", offset = 0x31F},
    landing = {type = "byte", offset = 0x508},
    bumpedObjectId = {type = "dword", offset = 0x4FC},
    vehicleObjectId = {type = "dword", offset = 0x11C},
    vehicleSeatIndex = {type = "word", offset = 0x2F0},
    walkingState = {type = "char", offset = 0x503},
    motionState = {type = "byte", offset = 0x4D2},
    mostRecentDamagerPlayer = {type = "dword", offset = 0x43C}
})

-- Tag data header structure
local tagDataHeaderStructure = {
    array = {type = "dword", offset = 0x0},
    scenario = {type = "dword", offset = 0x4},
    count = {type = "word", offset = 0xC}
}

---@class tag
---@field class number Type of the tag
---@field index number Tag Index
---@field id number Tag ID
---@field path string Path of the tag
---@field data number Address of the tag data
---@field indexed boolean Is tag indexed on an external map file

-- Tag structure
local tagHeaderStructure = {
    class = {type = "dword", offset = 0x0},
    index = {type = "word", offset = 0xC},
    id = {type = "dword", offset = 0xC},
    path = {type = "dword", offset = 0x10},
    data = {type = "dword", offset = 0x14},
    indexed = {type = "dword", offset = 0x18}
}

---@class tagCollection
---@field count number Number of tags in the collection
---@field tagList table List of tags

-- tagCollection structure
local tagCollectionStructure = {
    count = {type = "byte", offset = 0x0},
    tagList = {type = "list", offset = 0x4, elementsType = "dword", jump = 0x10}
}

---@class unicodeStringList
---@field count number Number of unicode strings
---@field stringList table List of unicode strings

-- UnicodeStringList structure
local unicodeStringListStructure = {
    count = {type = "byte", offset = 0x0},
    stringList = {type = "list", offset = 0x4, elementsType = "pustring", jump = 0x14}
}

---@class bitmapSequence
---@field name string
---@field firtBitmapIndex number
---@field bitmapCount number

---@class bitmap
---@field type number
---@field format number
---@field usage number
---@field usageFlags number
---@field detailFadeFactor number
---@field sharpenAmount number
---@field bumpHeight number
---@field spriteBudgetSize number
---@field spriteBudgetCount number
---@field colorPlateWidth number
---@field colorPlateHeight number 
---@field compressedColorPlate string
---@field processedPixelData string
---@field blurFilterSize number
---@field alphaBias number
---@field mipmapCount number
---@field spriteUsage number
---@field spriteSpacing number
---@field sequencesCount number
---@field sequences bitmapSequence[]
---@field bitmapsCount number
---@field bitmaps table

-- Bitmap structure
local bitmapStructure = {
    type = {type = "word", offset = 0x0},
    format = {type = "word", offset = 0x2},
    usage = {type = "word", offset = 0x4},
    usageFlags = {type = "word", offset = 0x6},
    detailFadeFactor = {type = "dword", offset = 0x8},
    sharpenAmount = {type = "dword", offset = 0xC},
    bumpHeight = {type = "dword", offset = 0x10},
    spriteBudgetSize = {type = "word", offset = 0x14},
    spriteBudgetCount = {type = "word", offset = 0x16},
    colorPlateWidth = {type = "word", offset = 0x18},
    colorPlateHeight = {type = "word", offset = 0x1A},
    -- compressedColorPlate = {offset = 0x1C},
    -- processedPixelData = {offset = 0x30},
    blurFilterSize = {type = "float", offset = 0x44},
    alphaBias = {type = "float", offset = 0x48},
    mipmapCount = {type = "word", offset = 0x4C},
    spriteUsage = {type = "word", offset = 0x4E},
    spriteSpacing = {type = "word", offset = 0x50},
    -- padding1 = {size = 0x2, offset = 0x52},
    sequencesCount = {type = "byte", offset = 0x54},
    sequences = {
        type = "table",
        offset = 0x58,
        jump = 0x40,
        rows = {
            name = {type = "string", offset = 0x0},
            firstBitmapIndex = {type = "word", offset = 0x20},
            bitmapCount = {type = "word", offset = 0x22}
            -- padding = {size = 0x10, offset = 0x24},
            --[[
            sprites = {
                type = "table",
                offset = 0x34,
                jump = 0x20,
                rows = {
                    bitmapIndex = {type = "word", offset = 0x0},
                    --padding1 = {size = 0x2, offset = 0x2},
                    --padding2 = {size = 0x4, offset = 0x4},
                    left = {type = "float", offset = 0x8},
                    right = {type = "float", offset = 0xC},
                    top = {type = "float", offset = 0x10},
                    bottom = {type = "float", offset = 0x14},
                    registrationX = {type = "float", offset = 0x18},
                    registrationY = {type = "float", offset = 0x1C}
                }
            }
            ]]
        }
    },
    bitmapsCount = {type = "byte", offset = 0x60},
    bitmaps = {
        type = "table",
        offset = 0x64,
        jump = 0x30,
        rows = {
            class = {type = "dword", offset = 0x0},
            width = {type = "word", offset = 0x4},
            height = {type = "word", offset = 0x6},
            depth = {type = "word", offset = 0x8},
            type = {type = "word", offset = 0xA},
            format = {type = "word", offset = 0xC},
            flags = {type = "word", offset = 0xE},
            x = {type = "word", offset = 0x10},
            y = {type = "word", offset = 0x12},
            mipmapCount = {type = "word", offset = 0x14},
            -- padding1 = {size = 0x2, offset = 0x16},
            pixelOffset = {type = "dword", offset = 0x18}
            -- padding2 = {size = 0x4, offset = 0x1C},
            -- padding3 = {size = 0x4, offset = 0x20},
            -- padding4 = {size = 0x4, offset= 0x24},
            -- padding5 = {size = 0x8, offset= 0x28}
        }
    }
}

---@class uiWidgetDefinitionChild
---@field widgetTag number Child uiWidgetDefinition reference
---@field name number Child widget name
---@field customControllerIndex number Custom controller index for this child widget
---@field verticalOffset number Offset in Y axis of this child, relative to the parent
---@field horizontalOffset number Offset in X axis of this child, relative to the parent

---@class uiWidgetDefinitionEventHandler
---@field eventType number Type of the event
---@field gameFunction number Game function of this event
---@field widgetTag number uiWidgetDefinition tag id of the event
---@field script string Name of the script function assigned to this event

---@class uiWidgetDefinition
---@field type number Type of widget
---@field controllerIndex number Index of the player controller
---@field name string Name of the widget
---@field boundsY number Top bound of the widget
---@field boundsX number Left bound of the widget
---@field height number Bottom bound of the widget
---@field width number Right bound of the widget
---@field backgroundBitmap number Tag ID of the background bitmap
---@field eventHandlers uiWidgetDefinitionEventHandler[] tag ID list of the child widgets
---@field unicodeStringListTag number Tag ID of the unicodeStringList from this widget
---@field fontTag number Tag ID of the font from this widget
---@field justification number Text justification of the text from this widget
---@field stringListIndex number Text index from the unicodeStringList tag from this widget
---@field textHorizontalOffset number Text offset in X axis from this widget
---@field textVerticalOffset number Text offset in Y axis from this widget
---@field childWidgetsCount number Number of child widgets
---@field childWidgets uiWidgetDefinitionChild[] List of the child widgets

local uiWidgetDefinitionStructure = {
    type = {type = "word", offset = 0x0},
    controllerIndex = {type = "word", offset = 0x2},
    name = {type = "string", offset = 0x4},
    boundsY = {type = "short", offset = 0x24},
    boundsX = {type = "short", offset = 0x26},
    height = {type = "short", offset = 0x28},
    width = {type = "short", offset = 0x2A},
    backgroundBitmap = {type = "word", offset = 0x44},
    eventHandlers = {
        type = "table",
        offset = 0x54,
        jump = 0x48,
        rows = {
            -- TODO Add real flags support, or a subtyping of table instead
            -- flags = {type = "number", offset = 0x0},
            eventType = {type = "word", offset = 0x4},
            gameFunction = {type = "word", offset = 0x6},
            widgetTag = {type = "tagref", offset = 0x8},
            soundEffectTag = {type = "tagref", offset = 0x18},
            script = {type = "string", offset = 0x28}
        }
    },
    unicodeStringListTag = {type = "tagref", offset = 0xEC},
    fontTag = {type = "tagref", offset = 0xFC},
    -- TODO Add color support for hex and rgb values
    -- textColor = {type = "realargbcolor", offset = 0x10C},
    justification = {type = "word", offset = 0x11C},
    stringListIndex = {type = "short", offset = 0x12E},
    textHorizontalOffset = {type = "short", offset = 0x130},
    textVerticalOffset = {type = "short", offset = 0x132},
    ---@deprecated
    eventType = {type = "byte", offset = 0x03F0},
    ---@deprecated
    tagReference = {type = "word", offset = 0x400},
    childWidgetsCount = {type = "dword", offset = 0x03E0},
    ---@deprecated
    childWidgetsList = {type = "list", offset = 0x03E4, elementsType = "dword", jump = 0x50},
    childWidgets = {
        type = "table",
        offset = 0x03E4,
        jump = 0x50,
        rows = {
            widgetTag = {type = "tagref", offset = 0x0},
            name = {type = "string", offset = 0x10},
            -- flags = {type = "integer", offset = 0x30},
            customControllerIndex = {type = "short", offset = 0x34},
            verticalOffset = {type = "short", offset = 0x36},
            horizontalOffset = {type = "short", offset = 0x38}
        }
    }
}

---@class uiWidgetCollection
---@field count number Number of widgets in the collection
---@field tagList table Tag ID list of the widgets

-- uiWidgetCollection structure
local uiWidgetCollectionStructure = {
    count = {type = "byte", offset = 0x0},
    tagList = {type = "list", offset = 0x4, elementsType = "dword", jump = 0x10}
}

---@class crosshairOverlay
---@field x number
---@field y number
---@field widthScale number
---@field heightScale number
---@field defaultColorA number
---@field defaultColorR number
---@field defaultColorG number
---@field defaultColorB number
---@field sequenceIndex number

---@class crosshair
---@field type number
---@field mapType number
---@field bitmap number
---@field overlays crosshairOverlay[]

---@class weaponHudInterface
---@field childHud number
---@field totalAmmoCutOff number
---@field loadedAmmoCutOff number
---@field heatCutOff number
---@field ageCutOff number
---@field crosshairs crosshair[]

-- Weapon HUD Interface structure
local weaponHudInterfaceStructure = {
    childHud = {type = "dword", offset = 0xC},
    -- //TODO Check if this property should be moved to a nested property type
    usingParentHudFlashingParameters = {type = "bit", offset = "word", bitLevel = 1},
    -- padding1 = {type = "word", offset = 0x12},
    totalAmmoCutOff = {type = "word", offset = 0x14},
    loadedAmmoCutOff = {type = "word", offset = 0x16},
    heatCutOff = {type = "word", offset = 0x18},
    ageCutOff = {type = "word", offset = 0x1A},
    -- padding2 = {size = 0x20, offset = 0x1C},
    -- screenAlignment = {type = "word", },
    -- padding3 = {size = 0x2, offset = 0x3E},
    -- padding4 = {size = 0x20, offset = 0x40},
    crosshairs = {
        type = "table",
        offset = 0x88,
        jump = 0x68,
        rows = {
            type = {type = "word", offset = 0x0},
            mapType = {type = "word", offset = 0x2},
            -- padding1 = {size = 0x2, offset = 0x4},
            -- padding2 = {size = 0x1C, offset = 0x6},
            bitmap = {type = "dword", offset = 0x30},
            overlays = {
                type = "table",
                offset = 0x38,
                jump = 0x6C,
                rows = {
                    x = {type = "word", offset = 0x0},
                    y = {type = "word", offset = 0x2},
                    widthScale = {type = "float", offset = 0x4},
                    heightScale = {type = "float", offset = 0x8},
                    defaultColorB = {type = "byte", offset = 0x24},
                    defaultColorG = {type = "byte", offset = 0x25},
                    defaultColorR = {type = "byte", offset = 0x26},
                    defaultColorA = {type = "byte", offset = 0x27},
                    sequenceIndex = {type = "byte", offset = 0x46}
                }
            }
        }
    }
}

---@class spawnLocation
---@field x number
---@field y number
---@field z number
---@field rotation number
---@field type number
---@field teamIndex number

---@class cutsceneFlag
---@field name string
---@field x number
---@field y number
---@field z number
---@field vX number
---@field vY number

---@class scenario
---@field sceneryPaletteCount number Number of sceneries in the scenery palette
---@field sceneryPaletteList table Tag ID list of scenerys in the scenery palette
---@field spawnLocationCount number Number of spawns in the scenario
---@field spawnLocationList spawnLocation[] List of spawns in the scenario
---@field vehicleLocationCount number Number of vehicles locations in the scenario
---@field vehicleLocationList table List of vehicles locations in the scenario
---@field netgameEquipmentCount number Number of netgame equipments
---@field netgameEquipmentList table List of netgame equipments
---@field netgameFlagsCount number Number of netgame equipments
---@field netgameFlagsList table List of netgame equipments
---@field objectNamesCount number Count of the object names in the scenario
---@field objectNames string[] List of all the object names in the scenario
---@field cutsceneFlagsCount number Count of all the cutscene flags in the scenario
---@field cutsceneFlags cutsceneFlag[] List of all the cutscene flags in the scenario

-- Scenario structure
local scenarioStructure = {
    sceneryPaletteCount = {type = "byte", offset = 0x021C},
    sceneryPaletteList = {type = "list", offset = 0x0220, elementsType = "dword", jump = 0x30},
    spawnLocationCount = {type = "byte", offset = 0x354},
    spawnLocationList = {
        type = "table",
        offset = 0x358,
        jump = 0x34,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8},
            rotation = {type = "float", offset = 0xC},
            teamIndex = {type = "byte", offset = 0x10},
            bspIndex = {type = "short", offset = 0x12},
            type = {type = "byte", offset = 0x14}
        }
    },
    vehicleLocationCount = {type = "byte", offset = 0x240},
    vehicleLocationList = {
        type = "table",
        offset = 0x244,
        jump = 0x78,
        rows = {
            type = {type = "word", offset = 0x0},
            nameIndex = {type = "word", offset = 0x2},
            x = {type = "float", offset = 0x8},
            y = {type = "float", offset = 0xC},
            z = {type = "float", offset = 0x10},
            yaw = {type = "float", offset = 0x14},
            pitch = {type = "float", offset = 0x18},
            roll = {type = "float", offset = 0x1C}
        }
    },
    netgameFlagsCount = {type = "byte", offset = 0x378},
    netgameFlagsList = {
        type = "table",
        offset = 0x37C,
        jump = 0x94,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8},
            rotation = {type = "float", offset = 0xC},
            type = {type = "byte", offset = 0x10},
            teamIndex = {type = "word", offset = 0x12}
        }
    },
    netgameEquipmentCount = {type = "byte", offset = 0x384},
    netgameEquipmentList = {
        type = "table",
        offset = 0x388,
        jump = 0x90,
        rows = {
            levitate = {type = "bit", offset = 0x0, bitLevel = 0},
            type1 = {type = "word", offset = 0x4},
            type2 = {type = "word", offset = 0x6},
            type3 = {type = "word", offset = 0x8},
            type4 = {type = "word", offset = 0xA},
            teamIndex = {type = "byte", offset = 0xC},
            spawnTime = {type = "word", offset = 0xE},
            x = {type = "float", offset = 0x40},
            y = {type = "float", offset = 0x44},
            z = {type = "float", offset = 0x48},
            facing = {type = "float", offset = 0x4C},
            itemCollection = {type = "dword", offset = 0x5C}
        }
    },
    objectNamesCount = {type = "dword", offset = 0x204},
    objectNames = {
        type = "list",
        offset = 0x208,
        elementsType = "string",
        jump = 36,
        noOffset = true
    },
    cutsceneFlagsCount = {type = "dword", offset = 0x4E4},
    cutsceneFlags = {
        type = "table",
        offset = 0x4E8,
        jump = 92,
        rows = {
            name = {type = "string", offset = 0x4},
            x = {type = "float", offset = 0x24},
            y = {type = "float", offset = 0x28},
            z = {type = "float", offset = 0x2C},
            vX = {type = "float", offset = 0x30},
            vY = {type = "float", offset = 0x34}
        }
    }
}

---@class scenery
---@field model number
---@field modifierShader number

-- Scenery structure
local sceneryStructure = {
    model = {type = "word", offset = 0x28 + 0xC},
    modifierShader = {type = "word", offset = 0x90 + 0xC}
}

---@class collisionGeometry
---@field vertexCount number Number of vertex in the collision geometry
---@field vertexList table List of vertex in the collision geometry

-- Collision Model structure
local collisionGeometryStructure = {
    vertexCount = {type = "byte", offset = 0x408},
    vertexList = {
        type = "table",
        offset = 0x40C,
        jump = 0x10,
        rows = {
            x = {type = "float", offset = 0x0},
            y = {type = "float", offset = 0x4},
            z = {type = "float", offset = 0x8}
        }
    }
}

---@class animationClass
---@field name string Name of the animation
---@field type number Type of the animation
---@field frameCount number Frame count of the animation
---@field nextAnimation number Next animation id of the animation
---@field sound number Sound id of the animation

---@class modelAnimations
---@field fpAnimationCount number Number of first-person animations
---@field fpAnimationList number[] List of first-person animations
---@field animationCount number Number of animations of the model
---@field animationList animationClass[] List of animations of the model

-- Model Animation structure
local modelAnimationsStructure = {
    fpAnimationCount = {type = "byte", offset = 0x90},
    fpAnimationList = {
        type = "list",
        offset = 0x94,
        noOffset = true,
        elementsType = "byte",
        jump = 0x2
    },
    animationCount = {type = "byte", offset = 0x74},
    animationList = {
        type = "table",
        offset = 0x78,
        jump = 0xB4,
        rows = {
            name = {type = "string", offset = 0x0},
            type = {type = "word", offset = 0x20},
            frameCount = {type = "byte", offset = 0x22},
            nextAnimation = {type = "byte", offset = 0x38},
            sound = {type = "byte", offset = 0x3C}
        }
    }
}

---@class weapon : blamObject
---@field pressedReloadKey boolean Is weapon trying to reload
---@field isWeaponPunching boolean Is weapon playing melee or grenade animation

local weaponStructure = extendStructure(objectStructure, {
    pressedReloadKey = {type = "bit", offset = 0x230, bitLevel = 3},
    isWeaponPunching = {type = "bit", offset = 0x230, bitLevel = 4}
})

---@class weaponTag
---@field model number Tag ID of the weapon model

-- Weapon structure
local weaponTagStructure = {model = {type = "dword", offset = 0x34}}

-- @class modelMarkers
-- @field name string
-- @field nodeIndex number
-- TODO Add rotation fields, check Guerilla tag
-- @field x number
-- @field y number
-- @field z number

---@class modelRegion
---@field permutationCount number
-- @field markersList modelMarkers[]

---@class modelNode
---@field x number
---@field y number
---@field z number

---@class gbxModel
---@field nodeCount number Number of nodes
---@field nodeList modelNode[] List of the model nodes
---@field regionCount number Number of regions
---@field regionList modelRegion[] List of regions

-- Model structure
local modelStructure = {
    nodeCount = {type = "dword", offset = 0xB8},
    nodeList = {
        type = "table",
        offset = 0xBC,
        jump = 0x9C,
        rows = {
            x = {type = "float", offset = 0x28},
            y = {type = "float", offset = 0x2C},
            z = {type = "float", offset = 0x30}
        }
    },
    regionCount = {type = "dword", offset = 0xC4},
    regionList = {
        type = "table",
        offset = 0xC8,
        jump = 76,
        rows = {
            permutationCount = {type = "dword", offset = 0x40}
            --[[permutationsList = {
                type = "table",
                offset = 0x16C,
                jump = 0x0,
                rows = {
                    name = {type = "string", offset = 0x0},
                    markersList = {
                        type = "table",
                        offset = 0x4C,
                        jump = 0x0,
                        rows = {
                            name = {type = "string", offset = 0x0},
                            nodeIndex = {type = "word", offset = 0x20}
                        }
                    }
                }
            }]]
        }
    }
}

---@class projectile : blamObject
---@field action number Enumeration of denotation action
---@field attachedToObjectId number Id of the attached object
---@field armingTimer number PENDING
---@field xVel number Velocity in x direction
---@field yVel number Velocity in y direction
---@field zVel number Velocity in z direction
---@field yaw number Rotation in yaw direction
---@field pitch number Rotation in pitch direction
---@field roll number Rotation in roll direction

-- Projectile structure
local projectileStructure = extendStructure(objectStructure, {
    action = {type = "word", offset = 0x230},
    attachedToObjectId = {type = "dword", offset = 0x11C},
    armingTimer = {type = "float", offset = 0x248},
    --[[xVel = {type = "float", offset = 0x254},
    yVel = {type = "float", offset = 0x258},
    zVel = {type = "float", offset = 0x25C},]]
    pitch = {type = "float", offset = 0x264},
    yaw = {type = "float", offset = 0x268},
    roll = {type = "float", offset = 0x26C}
})

---@class player
---@field id number Get playerId of this player
---@field host number Check if player is host, 0 when host, null when not
---@field name string Name of this player
---@field team number Team color of this player, 0 when red, 1 when on blue team
---@field objectId number Return the objectId associated to this player
---@field color number Color of the player, only works on "Free for All" gametypes
---@field index number Local index of this player 0-15
---@field speed number Current speed of this player
---@field ping number Ping amount from server of this player in milliseconds
---@field kills number Kills quantity done by this player
---@field assists number Assists count of this player
---@field betraysAndSuicides number Betrays plus suicides count of this player
---@field deaths number Deaths count of this player
---@field suicides number Suicides count of this player

local playerStructure = {
    id = {type = "word", offset = 0x0},
    host = {type = "word", offset = 0x2},
    name = {type = "ustring", forced = true, offset = 0x4},
    team = {type = "byte", offset = 0x20},
    objectId = {type = "dword", offset = 0x34},
    color = {type = "word", offset = 0x60},
    index = {type = "byte", offset = 0x67},
    speed = {type = "float", offset = 0x6C},
    ping = {type = "dword", offset = 0xDC},
    kills = {type = "word", offset = 0x9C},
    assists = {type = "word", offset = 0XA4},
    betraysAndSuicides = {type = "word", offset = 0xAC},
    deaths = {type = "word", offset = 0xAE},
    suicides = {type = "word", offset = 0XB0}
}

---@class firstPersonInterface
---@field firstPersonHands number

---@class multiplayerInformation
---@field flag number Tag ID of the flag object used for multiplayer games
---@field unit number Tag ID of the unit object used for multiplayer games

---@class globalsTag
---@field multiplayerInformation multiplayerInformation[]
---@field firstPersonInterface firstPersonInterface[]

local globalsTagStructure = {
    multiplayerInformation = {
        type = "table",
        jump = 0x0,
        offset = 0x168,
        rows = {flag = {type = "dword", offset = 0xC}, unit = {type = "dword", offset = 0x1C}}
    },
    firstPersonInterface = {
        type = "table",
        jump = 0x0,
        offset = 0x180,
        rows = {firstPersonHands = {type = "dword", offset = 0xC}}
    }
}

---@class firstPerson
---@field weaponObjectId number Weapon Id from the first person view

local firstPersonStructure = {weaponObjectId = {type = "dword", offset = 0x10}}

---@class bipedTag
---@field disableCollision number Disable collision of this biped tag

local bipedTagStructure = {disableCollision = {type = "bit", offset = 0x2F4, bitLevel = 5}}

---@class deviceMachine : blamObject
---@field powerGroupIndex number Power index from the device groups table
---@field power number Position amount of this device machine
---@field powerChange number Power change of this device machine
---@field positonGroupIndex number Power index from the device groups table
---@field position number Position amount of this device machine
---@field positionChange number Position change of this device machine
local deviceMachineStructure = extendStructure(objectStructure, {
    powerGroupIndex = {type = "word", offset = 0x1F8},
    power = {type = "float", offset = 0x1FC},
    powerChange = {type = "float", offset = 0x200},
    positonGroupIndex = {type = "word", offset = 0x204},
    position = {type = "float", offset = 0x208},
    positionChange = {type = "float", offset = 0x20C}
})

---@class hudGlobals
---@field anchor number
---@field x number
---@field y number
---@field width number
---@field height number
---@field upTime number
---@field fadeTime number
---@field iconColorA number
---@field iconColorR number
---@field iconColorG number
---@field iconColorB number
---@field textSpacing number

local hudGlobalsStructure = {
    anchor = {type = "word", offset = 0x0},
    x = {type = "word", offset = 0x24},
    y = {type = "word", offset = 0x26},
    width = {type = "float", offset = 0x28},
    height = {type = "float", offset = 0x2C},
    upTime = {type = "float", offset = 0x68},
    fadeTime = {type = "float", offset = 0x6C},
    iconColorA = {type = "float", offset = 0x70},
    iconColorR = {type = "float", offset = 0x74},
    iconColorG = {type = "float", offset = 0x78},
    iconColorB = {type = "float", offset = 0x7C},
    textColorA = {type = "float", offset = 0x80},
    textColorR = {type = "float", offset = 0x84},
    textColorG = {type = "float", offset = 0x88},
    textColorB = {type = "float", offset = 0x8C},
    textSpacing = {type = "float", offset = 0x90}
}

------------------------------------------------------------------------------
-- LuaBlam globals
------------------------------------------------------------------------------

-- Provide with public blam! data tables
blam.addressList = addressList
blam.tagClasses = tagClasses
blam.objectClasses = objectClasses
blam.joystickInputs = joystickInputs
blam.dPadValues = dPadValues
blam.cameraTypes = cameraTypes
blam.consoleColors = consoleColors
blam.netgameFlagClasses = netgameFlagClasses
blam.gameTypeClasses = gameTypeClasses
blam.multiplayerTeamClasses = multiplayerTeamClasses
blam.unitTeamClasses = unitTeamClasses

---@class tagDataHeader
---@field array any
---@field scenario string
---@field count number

---@type tagDataHeader
blam.tagDataHeader = createObject(addressList.tagDataHeader, tagDataHeaderStructure)

------------------------------------------------------------------------------
-- LuaBlam API
------------------------------------------------------------------------------

-- Add utilities to library
blam.dumpObject = dumpObject
blam.consoleOutput = consoleOutput

--- Get if a value equals a null value in game terms
---@return boolean
function blam.isNull(value)
    if (value == 0xFF or value == 0xFFFF or value == 0xFFFFFFFF or value == nil) then
        return true
    end
    return false
end

---Return if game instance is host
---@return boolean
function blam.isGameHost()
    return server_type == "local"
end

---Return if game instance is single player
---@return boolean
function blam.isGameSinglePlayer()
    return server_type == "none"
end

---Return if the game instance is running on a dedicated server or connected as a "network client"
---@return boolean
function blam.isGameDedicated()
    return server_type == "dedicated"
end

---Return if the game instance is a SAPP server
---@return boolean
function blam.isGameSAPP()
    return server_type == "sapp" or api_version
end

---Get the current game camera type
---@return number?
function blam.getCameraType()
    local camera = read_word(addressList.cameraType)
    if (camera) then
        if (camera == 22192) then
            return cameraTypes.scripted
        elseif (camera == 30400) then
            return cameraTypes.firstPerson
        elseif (camera == 30704) then
            return cameraTypes.devcam
            -- FIXME Validate this value, it seems to be wrong!
        elseif (camera == 21952) then
            return cameraTypes.thirdPerson
        elseif (camera == 23776) then
            return cameraTypes.deadCamera
        end
    end
    return nil
end

--- Get input from joystick assigned in the game
---@param joystickOffset number Offset input from the joystick data, use blam.joystickInputs
---@return boolean | number Value of the joystick input
function blam.getJoystickInput(joystickOffset)
    -- Based on aLTis controller method
    -- TODO Check if it is better to return an entire table with all input values 
    joystickOffset = joystickOffset or 0
    -- Nothing is pressed by default
    ---@type boolean | number
    local inputValue = false
    -- Look for every input from every joystick available
    for controllerId = 0, 3 do
        local inputAddress = addressList.joystickInput + controllerId * 0xA0
        if (joystickOffset >= 30 and joystickOffset <= 38) then
            -- Sticks
            inputValue = inputValue + read_long(inputAddress + joystickOffset)
        elseif (joystickOffset > 96) then
            -- D-pad related
            local tempValue = read_word(inputAddress + 96)
            if (tempValue == joystickOffset - 100) then
                inputValue = true
            end
        else
            inputValue = inputValue + read_byte(inputAddress + joystickOffset)
        end
    end
    return inputValue
end

--- Create a tag object from a given address, this object can't write data to game memory
---@param address integer
---@return tag?
function blam.tag(address)
    if (address and address ~= 0) then
        -- Generate a new tag object from class
        local tag = createObject(address, tagHeaderStructure)

        -- Get all the tag info
        local tagInfo = dumpObject(tag)

        -- Set up values
        tagInfo.address = address
        tagInfo.path = read_string(tagInfo.path)
        tagInfo.class = tagClassFromInt(tagInfo.class --[[@as number]])

        return tagInfo
    end
    return nil
end

--- Return a tag object given tagPath and tagClass or just tagId
---@param tagIdOrTagPath string | number
---@param tagClass? string
---@return tag?
function blam.getTag(tagIdOrTagPath, tagClass, ...)
    local tagId
    local tagPath

    -- Get arguments from table
    if (isNumber(tagIdOrTagPath)) then
        tagId = tagIdOrTagPath
    elseif (isString(tagIdOrTagPath)) then
        tagPath = tagIdOrTagPath
    elseif (not tagIdOrTagPath) then
        return nil
    end

    if (...) then
        consoleOutput(debug.traceback("Wrong number of arguments on get tag function", 2),
                      consoleColors.error)
    end

    local tagAddress

    -- Get tag address
    if (tagId) then
        if (tagId < 0xFFFF) then
            -- Calculate tag id
            tagId = read_dword(blam.tagDataHeader.array + (tagId * 0x20 + 0xC))
        end
        tagAddress = get_tag(tagId)
    elseif (tagClass and tagPath) then
        tagAddress = get_tag(tagClass, tagPath --[[@as string]] )
    end

    if tagAddress then
        return blam.tag(tagAddress)
    end
end

--- Create a player object given player entry table address
---@return player?
function blam.player(address)
    if (isValid(address)) then
        return createObject(address, playerStructure)
    end
    return nil
end

--- Create a blamObject given address
---@param address number
---@return blamObject?
function blam.object(address)
    if (isValid(address)) then
        return createObject(address, objectStructure)
    end
    return nil
end

--- Create a Projectile object given address
---@param address number
---@return projectile?
function blam.projectile(address)
    if (isValid(address)) then
        return createObject(address, projectileStructure)
    end
    return nil
end

--- Create a Biped object from a given address
---@param address number
---@return biped?
function blam.biped(address)
    if (isValid(address)) then
        return createObject(address, bipedStructure)
    end
    return nil
end

--- Create a biped tag from a tag path or id
---@param tag string | number
---@return bipedTag?
function blam.bipedTag(tag)
    if (isValid(tag)) then
        local bipedTag = blam.getTag(tag, tagClasses.biped)
        if (bipedTag) then
            return createObject(bipedTag.data, bipedTagStructure)
        end
    end
    return nil
end

--- Create a Unicode String List object from a tag path or id
---@param tag string | number
---@return unicodeStringList?
function blam.unicodeStringList(tag)
    if (isValid(tag)) then
        local unicodeStringListTag = blam.getTag(tag, tagClasses.unicodeStringList)
        if (unicodeStringListTag) then
            return createObject(unicodeStringListTag.data, unicodeStringListStructure)
        end
    end
    return nil
end

--- Create a bitmap object from a tag path or id
---@param tag string | number
---@return bitmap?
function blam.bitmap(tag)
    if (isValid(tag)) then
        local bitmapTag = blam.getTag(tag, tagClasses.bitmap)
        if (bitmapTag) then
            return createObject(bitmapTag.data, bitmapStructure)
        end
    end
end

--- Create a UI Widget Definition object from a tag path or id
---@param tag string | number
---@return uiWidgetDefinition?
function blam.uiWidgetDefinition(tag)
    if (isValid(tag)) then
        local uiWidgetDefinitionTag = blam.getTag(tag, tagClasses.uiWidgetDefinition)
        if (uiWidgetDefinitionTag) then
            return createObject(uiWidgetDefinitionTag.data, uiWidgetDefinitionStructure)
        end
    end
    return nil
end

--- Create a UI Widget Collection object from a tag path or id
---@param tag string | number
---@return uiWidgetCollection?
function blam.uiWidgetCollection(tag)
    if (isValid(tag)) then
        local uiWidgetCollectionTag = blam.getTag(tag, tagClasses.uiWidgetCollection)
        if (uiWidgetCollectionTag) then
            return createObject(uiWidgetCollectionTag.data, uiWidgetCollectionStructure)
        end
    end
    return nil
end

--- Create a Tag Collection object from a tag path or id
---@param tag string | number
---@return tagCollection?
function blam.tagCollection(tag)
    if (isValid(tag)) then
        local tagCollectionTag = blam.getTag(tag, tagClasses.tagCollection)
        if (tagCollectionTag) then
            return createObject(tagCollectionTag.data, tagCollectionStructure)
        end
    end
    return nil
end

--- Create a Weapon HUD Interface object from a tag path or id
---@param tag string | number
---@return weaponHudInterface?
function blam.weaponHudInterface(tag)
    if (isValid(tag)) then
        local weaponHudInterfaceTag = blam.getTag(tag, tagClasses.weaponHudInterface)
        if (weaponHudInterfaceTag) then
            return createObject(weaponHudInterfaceTag.data, weaponHudInterfaceStructure)
        end
    end
    return nil
end

--- Create a Scenario object from a tag path or id
---@param tag? string | number
---@return scenario?
function blam.scenario(tag)
    local scenarioTag = blam.getTag(tag or 0, tagClasses.scenario)
    if (scenarioTag) then
        return createObject(scenarioTag.data, scenarioStructure)
    end
end

--- Create a Scenery object from a tag path or id
---@param tag string | number
---@return scenery?
function blam.scenery(tag)
    if (isValid(tag)) then
        local sceneryTag = blam.getTag(tag, tagClasses.scenery)
        if (sceneryTag) then
            return createObject(sceneryTag.data, sceneryStructure)
        end
    end
    return nil
end

--- Create a Collision Geometry object from a tag path or id
---@param tag string | number
---@return collisionGeometry?
function blam.collisionGeometry(tag)
    if (isValid(tag)) then
        local collisionGeometryTag = blam.getTag(tag, tagClasses.collisionGeometry)
        if (collisionGeometryTag) then
            return createObject(collisionGeometryTag.data, collisionGeometryStructure)
        end
    end
    return nil
end

--- Create a Model Animations object from a tag path or id
---@param tag string | number
---@return modelAnimations?
function blam.modelAnimations(tag)
    if (isValid(tag)) then
        local modelAnimationsTag = blam.getTag(tag, tagClasses.modelAnimations)
        if (modelAnimationsTag) then
            return createObject(modelAnimationsTag.data, modelAnimationsStructure)
        end
    end
    return nil
end

--- Create a Weapon object from the given object address
---@param address number
---@return weapon?
function blam.weapon(address)
    if (isValid(address)) then
        return createObject(address, weaponStructure)
    end
    return nil
end

--- Create a Weapon tag object from a tag path or id
---@param tag string | number
---@return weaponTag?
function blam.weaponTag(tag)
    if (isValid(tag)) then
        local weaponTag = blam.getTag(tag, tagClasses.weapon)
        if (weaponTag) then
            return createObject(weaponTag.data, weaponTagStructure)
        end
    end
    return nil
end

--- Create a model (gbxmodel) object from a tag path or id
---@param tag string | number
---@return gbxModel?
function blam.model(tag)
    if (isValid(tag)) then
        local modelTag = blam.getTag(tag, tagClasses.model)
        if (modelTag) then
            return createObject(modelTag.data, modelStructure)
        end
    end
    return nil
end
-- Alias
blam.gbxmodel = blam.model

--- Create a Globals tag object from a tag path or id, default globals path by default
---@param tag? string | number
---@return globalsTag?
function blam.globalsTag(tag)
    local tag = tag or "globals\\globals"
    if (isValid(tag)) then
        local globalsTag = blam.getTag(tag, tagClasses.globals)
        if (globalsTag) then
            return createObject(globalsTag.data, globalsTagStructure)
        end
    end
    return nil
end

--- Create a First person object from a given address, game known address by default
---@param address? number
---@return firstPerson
function blam.firstPerson(address)
    return createObject(address or addressList.firstPerson, firstPersonStructure)
end

--- Create a Device Machine object from a given address
---@param address number
---@return deviceMachine?
function blam.deviceMachine(address)
    if (isValid(address)) then
        return createObject(address, deviceMachineStructure)
    end
    return nil
end

--- Create a HUD Globals tag object from a given address
---@param tag string | number
---@return hudGlobals?
function blam.hudGlobals(tag)
    if (isValid(tag)) then
        local hudGlobals = blam.getTag(tag, tagClasses.hudGlobals)
        if (hudGlobals) then
            return createObject(hudGlobals.data, hudGlobalsStructure)
        end
    end
    return nil
end

--- Return a blam object given object index or id.
--- Also returns objectId when given an object index.
---@param idOrIndex number
---@return blamObject?, number?
function blam.getObject(idOrIndex)
    local objectId
    local objectAddress

    -- Get object address
    if (idOrIndex) then
        -- Get object ID
        if (idOrIndex < 0xFFFF) then
            local index = idOrIndex

            -- Get objects table
            local table = createObject(addressList.objectTable, dataTableStructure)
            if (index > table.capacity) then
                return nil
            end

            -- Calculate object ID (this may be invalid, be careful)
            objectId =
                (read_word(table.firstElementAddress + index * table.elementSize) * 0x10000) + index
        else
            objectId = idOrIndex
        end

        objectAddress = get_object(objectId)

        if objectAddress then
            return blam.object(objectAddress), objectId
        end
    end
    return nil
end

--- Return an element from the device machines table
---@param index number
---@return number?
function blam.getDeviceGroup(index)
    -- Get object address
    if (index) then
        -- Get objects table
        local table = createObject(read_dword(addressList.deviceGroupsTable),
                                   deviceGroupsTableStructure)
        -- Calculate object ID (this may be invalid, be careful)
        local itemOffset = table.elementSize * index
        local item = read_float(table.firstElementAddress + itemOffset + 0x4)
        return item
    end
    return nil
end

---@class blamRequest
---@field requestString string
---@field timeout number
---@field callback function<boolean, string>
---@field sentAt number

---@type table<number, blamRequest>
local requestQueue = {}
local requestId = -1
local requestPathMaxLength = 60
---Send a server request to current server trough rcon
---@param method '"GET"' | '"SEND"'
---@param url string Path or name of the resource we want to get
---@param timeout number Time this request will wait for a response, 120ms by default
---@param callback function<boolean, string> Callback function to call when this response returns
---@param retry boolean Retry this request if timeout reaches it's limit
---@param params table<string, any> Optional parameters to send in the request, careful, this will create two requests, one for the resource and another one for the parameters
---@return boolean success
function blam.request(method, url, timeout, callback, retry, params)
    if (server_type ~= "dedicated") then
        console_out("Warning, requests only work while connected to a dedicated server.")
    end
    if (params) then
        console_out("Warning, request params are not supported yet.")
    end
    if (url and url:len() <= requestPathMaxLength) then
        if (method == "GET") then
            requestId = requestId + 1
            local rconRequest = ("rcon blam ?%s?%s"):format(requestId, url)
            requestQueue[requestId] = {
                requestString = rconRequest,
                timeout = timeout or 120,
                callback = callback
            }
            console_out(rconRequest)
            -- execute_script(request)
            return true
        end
    end
    error("Error, url can not contain more than " .. requestPathMaxLength .. " chars.")
    return false
end

--- Find the path, index and id of a tag given partial tag path and tag type
---@param partialTagPath string
---@param searchTagType string
---@return tag? tag
function blam.findTag(partialTagPath, searchTagType)
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tag = blam.getTag(tagIndex)
        if (tag and tag.path:find(partialTagPath, 1, true) and tag.class == searchTagType) then
            return tag
        end
    end
    return nil
end

--- Find the path, index and id of a list of tags given partial tag path and tag type
---@param partialTagPath string
---@param searchTagType string
---@return tag[] tag
function blam.findTagsList(partialTagPath, searchTagType)
    local tagsList
    for tagIndex = 0, blam.tagDataHeader.count - 1 do
        local tag = blam.getTag(tagIndex)
        if (tag and tag.path:find(partialTagPath, 1, true) and tag.class == searchTagType) then
            if (not tagsList) then
                tagsList = {}
            end
            tagsList[#tagsList + 1] = tag
        end
    end
    return tagsList
end

return blam
