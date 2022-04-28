local t = {}
local cancelPopupBuilder = require("resources.mods.modLoader.cancelPopupBuilder")
local AbstractButtonSetting = require("classes.interface.settingObjects.AbstractButtonSetting")
local messagePopupBuilder = require("classes.interface.overlays.messagePopupBuilder")
local cancelButton
function networkListener()
  print("yo")
end
function t:createButton(name,buttonLabel)
  writeJsonToFile(userInfos,"resources/mods/logs/inch.json")
  local datas = 
  {
      label = name,
      buttonLabel = buttonLabel,
      onReleaseWithinBounds = function()
      userInfos["otherUsername"] = name
      local body = {username= userInfos["username"],secretKey = userInfos["secretKey"], otherUsername=name,isOtherReady=0,acceptTrade=0}
      local headers = {}
      headers["Content-Type"] = "application/json"
      local params = {}
      params.headers= headers
      params.body = json.encode(body)
      network.request( "http://localhost:3000/trades", "POST", networkListener,params)
      timer.pause( "getOnlineUsers" )
      timer.resume("otherAcceptTradeInvitation")
      cancelButton =cancelPopupBuilder:new({
        text = "Invitation Sent. Wait for other user to accept trade.",
        onNo = function()
          userInfos["otherUsername"] = nil
          timer.resume("getOnlineUsers")
          timer.pause("otherAcceptTradeInvitation")
          network.request( "http://localhost:3000/trades", "DELETE", networkListener,params)
        end
      })
      
      end
    }
  local Obj = {}
  function Obj:shouldBeRendered(_isFromTitleScreen)
    return device.isWindowsRelease or device.isSimulator
  end
  function Obj:new(_parent, _focusArrow, _settingObjects, _gamepadNavigation, _settingObjectParentNavigation)
    local buttonSetting, buttonNavigation = AbstractButtonSetting:new(_parent, name.."Button", _focusArrow, datas)
    return buttonSetting, buttonNavigation
  end

  return Obj
end
function t:closeCancel()
  cancelButton:close(function() print("hi") end)
end
return t

