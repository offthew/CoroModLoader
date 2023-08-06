local modLoaderApi= {}
local fileHelper = require("resources.mods.modLoader.modApi.fileHelper")
modLoaderApi.modsActivated = {}
local path = "resources/mods/modLoader/modApi/"
local requirePath = "resources.mods.modLoader.modApi."
function modLoaderApi:getActivatedMod(modName)
    for index, value in ipairs(modLoaderApi.modList) do
        if value["name"] == modName then
            return value["activated"]
        end
    end
end
function modLoaderApi:setActivatedMod(modName,isActivated)
    for index, value in ipairs(modLoaderApi.modList) do
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
                modRequire = "resources.mods."..file..".main"
                if(fileHelper:file_exists(f..'/main.lua') and fileHelper:file_exists(f..'/config.json')) then
                  if has_value (modLoaderApi.modList, file) then
                    modLoaderApi.log:write(file.." already in mods.json")
                  else
                    local modConfig = json.decode(fileHelper:read(f..'/config.json'))
                    modLoaderApi.log:write("Adding "..file.." to the modList")
                    --require(modRequire)
                    modConfig["name"]= file
                    modConfig["require"] = modRequire
                    modConfig["activated"] = false
                    
                    table.insert(modLoaderApi.modList,modConfig)
                  end
                end
            end
        end
    end
end
function modLoaderApi:start()
  app.version = app.version.." CML 0.1"
  modLoaderApi.log = require(requirePath.."logHelper")
  modLoaderApi.log:write("Getting Modlist","logs.log","w")
  modLoaderApi.modList = fileHelper:read("resources/mods/mods.json")
  if(modLoaderApi.modList) then modLoaderApi.modList = json.decode(modLoaderApi.modList) else modLoaderApi.modList = {} end
  modLoaderApi.log:write("Getting Mods")
  getMods("Resources/mods")
  modLoaderApi.log:write("Writing Mods")
  fileHelper:write(json.encode(modLoaderApi.modList),"Resources/mods/mods.json","w")
  activateMods(modLoaderApi.modList)

end
function modLoaderApi:load()
  modLoaderApi.monster = require(requirePath.."monster")
  require("resources.mods.modLoader.interface.menuBuilder")
  modLoaderApi.pauseMenuScreen = require(requirePath.."pauseMenuScreen")
  --modLoaderApi.titleScreen = require("resources.mods.modLoader.titleScreen")
  --activateMods(modLoaderApi.modList)
  activateModsLoad(modLoaderApi.modsActivated)

end

return modLoaderApi