local t = {}
local fileHelper = require("resources.mods.modLoader.modApi.fileHelper")
function t:createCheckbox(modName,description,context)
  context = context or nil
  local datas = 
  {
    label = description,
    contextText = context,
    getValue = function()
      return modApi:getActivatedMod(modName)
    end,
    setValue = function(_boolean)
      modApi:setActivatedMod(modName,_boolean)
      fileHelper:write(json.encode(modApi.modList),"resources/mods/mods.json","w")
      modListEdited = true
    end
  }
  
  local Obj = {}
  local AbstractCheckboxSetting = require("classes.interface.settingObjects.AbstractCheckboxSetting")
  function Obj:shouldBeRendered(_isFromTitleScreen)
    return true
  end
  function Obj:new(_parent, _focusArrow, _settingObjects, _gamepadNavigation, _settingObjectParentNavigation)
    local checkboxSetting, checkboxNavigation = AbstractCheckboxSetting:new(_parent, modName.."Checkbox", _focusArrow, datas)
    return checkboxSetting, checkboxNavigation
  end
  return Obj
end
return t