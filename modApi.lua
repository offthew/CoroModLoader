local modLoaderApi= {}
local fileHelper = require("Resources.coroModLoader.modLoader.modApi.fileHelper")
modLoaderApi.modsActivated = {}
local path = "Resources/coroModLoader/modLoader/modApi/"
local requirePath = "Resources.coroModLoader.modLoader.modApi."
function modLoaderApi:getActivatedMod(modName)
  modLoaderApi.log:write("Getting activated mods")
    for index, value in ipairs(modLoaderApi.modList) do
        if value["name"] == modName then
            return value["activated"]
        end
    end
end
function modLoaderApi:setActivatedMod(modName,isActivated)
  modLoaderApi.log:write("Setting activated mods")
    for index, value in ipairs(modLoaderApi.modList) do
        if value["name"] == modName then
            value["activated"] = isActivated
            fileHelper:write(json.encode(modLoaderApi.modList),"Resources/coroModLoader/mods.json","w")
        end
    end
end

--Was used before for checking if a mod was already in mods.json but isn't used in this implementation
--[[
local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value["name"] == val then
            return true
        end
    end

    return false
end
--]]

local function activateMods(tab)
  modLoaderApi.log:write("Activating Mods after require_core")
  for index,value in ipairs(tab) do
    if value["activated"] then
      table.insert(modLoaderApi.modsActivated,require(value["require"]))
    end
  end
  modLoaderApi.log:write("Mods activated")
end
local function activateModsLoad(tab)
  modLoaderApi.log:write("Activating Mods after require_specific")
  for index,value in ipairs(tab) do
    value:load()
  end
  modLoaderApi.log:write("Mods Loaded")
end
local function getMods(path)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            modLoaderApi.log:write("Path: "..f)
            local attr = lfs.attributes (f)
            if attr.mode == "directory" then
                modRequire = "mods."..file..".main"
                if(fileHelper:file_exists(f..'/main.lua') and fileHelper:file_exists(f..'/config.json')) then
                  --Removed if statement that checked if modLoaderApi.modlist contained the current mod being checked
                  local modConfig = json.decode(fileHelper:read(f..'/config.json'))
                  modLoaderApi.log:write("Adding "..file.." to the modList")
                  --require(modRequire)
                  modConfig["name"]= file
                  modConfig["require"] = modRequire

                  --Determines if mod was used in last launch and passes over it's activated state
                  local modFound = false
                  for index, value in ipairs(modLoaderApi.lastUsedMods) do
                    if value["name"] == file then
                      modFound = true
                      modConfig["activated"] = value["activated"]
                      break
                    end
                  end
                  if (not modFound) then modConfig["activated"] = false end
                    
                  table.insert(modLoaderApi.modList,modConfig)
                end
            end
        end
    end
end
function modLoaderApi:start()
  app.version = app.version.." CML 0.1"
  modLoaderApi.log = require(requirePath.."logHelper")
  modLoaderApi.log:write("Getting Modlist","logs.log","w")
  --Redoing how the modList is generated
  --Essentially rewrites the modList each launch but preserves the activated status with modLoaderApi.lastUsedMods
  modLoaderApi.modList = {}
  modLoaderApi.lastUsedMods = fileHelper:read("Resources/coroModLoader/mods.json")
  if(modLoaderApi.lastUsedMods) then modLoaderApi.lastUsedMods = json.decode(modLoaderApi.lastUsedMods) else modLoaderApi.lastUsedMods = {} end
  --modLoaderApi.modList = fileHelper:read("resources/mods/mods.json")
  --if(modLoaderApi.modList) then modLoaderApi.modList = json.decode(modLoaderApi.modList) else modLoaderApi.modList = {} end
  modLoaderApi.log:write("Getting Mods")
  getMods("mods")
  modLoaderApi.log:write("Writing Mods")
  fileHelper:write(json.encode(modLoaderApi.modList),"Resources/coroModLoader/mods.json","w")
  activateMods(modLoaderApi.modList)
end
function modLoaderApi:load()
  modLoaderApi.monster = require(requirePath.."monster")
  require("Resources.coroModLoader.modLoader.interface.menuBuilder")
  modLoaderApi.pauseMenuScreen = require(requirePath.."pauseMenuScreen")
  --modLoaderApi.titleScreen = require("resources.mods.modLoader.titleScreen")
  --activateMods(modLoaderApi.modList)
  activateModsLoad(modLoaderApi.modsActivated)
end

return modLoaderApi