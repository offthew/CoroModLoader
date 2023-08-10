local t = {}
local fileHelper = require("Resources.coroModLoader.modLoader.modApi.fileHelper")
function t:createCheckbox(modName,description,context)
  context = context or nil
  local datas = 
  {
    label = description,
    contextText = context,
    getValue = function()
      return modLoaderApi:getActivatedMod(modName)
    end,
    setValue = function(_boolean)
      modLoaderApi:setActivatedMod(modName,_boolean)
      fileHelper:write(json.encode(modLoaderApi.modList),"Resources/coroModLoader/mods.json","w")
      modListEdited = true
    end
  }
  
  local Obj = {}
  local AbstractCheckboxSetting = require("classes.interface.settingObjects.AbstractCheckboxSetting")
  function Obj:shouldBeRendered(_isFromTitleScreen)
    return true
  end
  function Obj:new(_parent, _settingsScrollView, _UID, _focusArrow, _options)
    local checkboxSetting, checkboxNavigation = AbstractCheckboxSetting:new(_parent,_settingsScrollView, modName.."Checkbox", _focusArrow, datas)
    return checkboxSetting, checkboxNavigation
  end
  return Obj
end
return t