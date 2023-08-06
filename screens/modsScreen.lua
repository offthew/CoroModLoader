local Screen = {}
local modListContent = {}
modListEdited = false

for index, value in ipairs(modLoaderApi.modList) do
  mod = {}
  mod["category"] = value["name"]
  mod["builders"] = {}
  local checkbox=require("resources.mods.modLoader.checkbox")
  table.insert(mod["builders"],checkbox:createCheckbox(value["name"],value["description"],value["secondDescription"]))
  table.insert(modListContent,mod)
end


local scrollViewBuilder = require("classes.modules.interface.scrollViewBuilder")
local SettingObjectHelper = require("classes.interface.settingObjects.SettingObjectHelper")
function Screen:new(screenParams, screenContainer, centerContainer, horizontalCenterContainer, verticalCenterContainer, safeContainer)

  local parentGroup = pauseMenuScreenBuilder:new()
  local _isFromTitleScreen = screenParams.isFromTitleScreen
  local _hasTransition = screenParams.hasTransition
  local originalHideDirectionalInputSetting = gameSettings:getHideDirectionalInputSetting()
  local originalDirectionalInputMethod = gameSettings:getDirectionalInputMethod()
  local settingsScrollViewContainer = UIContainerBuilder:new(parentGroup, UIContainerStyle.greyFancy, 184, screenContainer.height - 8)
  magnet:center(settingsScrollViewContainer, 0, 0, screenContainer)
  local settingsScrollView = scrollViewBuilder:new({
    parent = settingsScrollViewContainer,
    mode = "vertical",
    width = settingsScrollViewContainer.width - 10,
    height = settingsScrollViewContainer.height - 10,
    topPadding = -2,
    bottomPadding = 2,
    friction = 0.94
  })
  magnet:topCenter(settingsScrollView, 0, 5, settingsScrollViewContainer)
  UIFadeBuilder:newVertical(settingsScrollView)
  local gamepadNavigation, focusArrow = SettingObjectHelper:renderForScrollView(settingsScrollView, modListContent, function(_parent, _focusArrow, _settingObjects, _gamepadNavigation, _settingObjectParentNavigation, _builder)
    return _builder:new(_parent, _focusArrow, _settingObjects, _gamepadNavigation, _settingObjectParentNavigation)
  end, function(_builder)
    return isTakingUIScreenshots or _builder:shouldBeRendered(_isFromTitleScreen, _didHoldSettingsButton)
  end)
  local settingsScrollViewScrollBarBackground = UIScrollBarBackgroundBuilder:new(settingsScrollViewContainer, settingsScrollView.height - 8)
  magnet:atLeftTop(settingsScrollViewScrollBarBackground, 0, 2, settingsScrollView)
  settingsScrollView:setScrollBar(settingsScrollViewScrollBarBackground, function(_parent, _height)
    return UIScrollBarBuilder:new(_parent, _height)
  end)
  parentGroup:addGamepadNavigation(gamepadNavigation)
  parentGroup:setTitle(localise("menu.settingsScreen.title"))
  function parentGroup:inTransition(_onComplete)
    if(_hasTransition) then
      transition.fromRight(settingsScrollViewContainer, 350, outQuad, _onComplete)
    end
  end
  function parentGroup:outTransition(_isBackwards, _onComplete)
    if(modListEdited) then
      native.requestExit()
    end
    if gameSettings:getDirectionalInputMethod() ~= originalDirectionalInputMethod or gameSettings:getHideDirectionalInputSetting() ~= originalHideDirectionalInputSetting then
      eventManager:dispatch("directionalInputSettingChanged")
    end
    if(_hasTransition) then
      transition.toRight(settingsScrollViewContainer, 350, outQuad, _onComplete)
    end
  end
  return parentGroup
end



return Screen
