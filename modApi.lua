local modApi= {}
local fileHelper = require("resources.mods.modLoader.modApi.fileHelper")
modApi.modsActivated = {}
local path = "resources/mods/modLoader/modApi/"
local requirePath = "resources.mods.modLoader.modApi."
function modApi:getActivatedMod(modName)
    for index, value in ipairs(modApi.modList) do
        if value["name"] == modName then
            return value["activated"]
        end
    end
end
function modApi:setActivatedMod(modName,isActivated)
    for index, value in ipairs(modApi.modList) do
        if value["name"] == modName then
            value["activated"] = isActivated
        end
    end
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value["name"] == val then
            return true
        end
    end

    return false
end
local function activateMods(tab)
  modApi.log:write("Activating Mods after require_core")
  for index,value in ipairs(tab) do
    if value["activated"] then
      table.insert(modApi.modsActivated,require(value["require"]))
    end
  end
  modApi.log:write("Mods activated")
end
local function activateModsLoad(tab)
  modApi.log:write("Activating Mods after require_specific")
  for index,value in ipairs(tab) do
    value:load()
  end
  modApi.log:write("Mods Activated")

end
local function getMods(path)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            modApi.log:write("Path: "..f)
            local attr = lfs.attributes (f)
            if attr.mode == "directory" then
                modRequire = "resources.mods."..file..".main"
                if(fileHelper:file_exists(f..'/main.lua') and fileHelper:file_exists(f..'/config.json')) then
                  if has_value (modApi.modList, file) then
                    modApi.log:write(file.." already in mods.json")
                  else
                    local modConfig = json.decode(fileHelper:read(f..'/config.json'))
                    modApi.log:write("Adding "..file.." to the modList")
                    modConfig["name"]= file
                    modConfig["require"] = modRequire
                    modConfig["activated"] = false
                    
                    table.insert(modApi.modList,modConfig)
                  end
                end
            end
        end
    end
end
function modApi:start()
  app.version = app.version.." CML 0.1"
  modApi.log = require(requirePath.."logHelper")
  modApi.log:write("Getting Modlist","logs.log","w")
  modApi.modList = fileHelper:read("resources/mods/mods.json")
  if(modApi.modList) then modApi.modList = json.decode(modApi.modList) else modApi.modList = {} end
  modApi.log:write("Getting Mods")
  getMods("Resources/mods")
  modApi.log:write("Writing Mods")
  fileHelper:write(json.encode(modApi.modList),"Resources/mods/mods.json","w")
  titleScreenModLoader = require("resources.mods.modLoader.titleScreenSaveslotsOverlayBuilder")
  activateMods(modApi.modList)
end
function modApi:load()
  modApi.monster = require(requirePath.."monster")
  modApi.pauseMenu = require(requirePath.."pauseMenuScreen")
  require("resources.mods.modLoader.interface.menuBuilder")
  activateModsLoad(modApi.modsActivated)
end

return modApi