menu = require("classes.modules.interface.menuBuilder")
function menu:new()
  local menu = groupHelper:new(nil)
  local menuBottomGroup = groupHelper:new(menu)
  local menuScreenGroup = groupHelper:new(menu)
  local menuTopGroup = groupHelper:new(menu)
  local currentScreenScreenParams, currentScreenObject, currentScreenName, newScreenScreenParams, newScreenName
  local history = {}
  function menu:getHistory()
    return history
  end
  local defaultScreenParams
  function menu:setDefaultScreenParams(...)
    defaultScreenParams = {
      ...
    }
  end
  function menu:getCurrentScreenScreenParams()
    return currentScreenScreenParams
  end
  function menu:getCurrentScreenObject()
    return currentScreenObject
  end
  function menu:getCurrentScreenName()
    return currentScreenName
  end
  function menu:getNewOrCurrentScreenScreenParams()
    return newScreenScreenParams or currentScreenScreenParams
  end
  function menu:getNewOrCurrentScreenName()
    return newScreenName or currentScreenName
  end
  function menu:getBottomGroup()
    return menuBottomGroup
  end
  function menu:getScreenGroup()
    return menuScreenGroup
  end
  function menu:getTopGroup()
    return menuTopGroup
  end
  local function unloadCurrentScreen(_isBackwards, _onComplete)
    if not currentScreenObject then
      _onComplete()
    else
      menu:onUnloadScreen()
      nextFrame(function()
        currentScreenObject:outTransition(_isBackwards, function()
          nextFrame(function()
            currentScreenName = nil
            currentScreenScreenParams = nil
            currentScreenObject = display.remove(currentScreenObject)
            _onComplete()
          end)
        end)
      end)
    end
  end
  function menu:onUnloadScreen()
  end
  function menu:showScreen(_screenName, _screenParams, _extraParams)
    local _screenParams = _screenParams or {}
    local _extraParams = _extraParams or {}
    local _onShow = _extraParams.onShow
    local _isBackwards = _extraParams.isBackwards or false
    local _history = _extraParams.history
    newScreenName = _screenName
    newScreenScreenParams = _screenParams
    local _screenClass = require("classes.interface.screens." .. _screenName)
    local newScreenObject = _screenClass:new(_screenParams, unpack(defaultScreenParams))
    newScreenObject.isVisible = false
    menuScreenGroup:insert(newScreenObject)
    if _history then
      history = _history
    elseif not _isBackwards then
      history[#history + 1] = {screenName = _screenName, screenParams = _screenParams}
    end
    menu:onShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
    unloadCurrentScreen(_isBackwards, function()
      menu:onBetweenShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
      newScreenObject.isVisible = true
      newScreenObject:inTransition(function()
        newScreenName = nil
        newScreenScreenParams = nil
        currentScreenName = _screenName
        currentScreenObject = newScreenObject
        currentScreenScreenParams = _screenParams
        menu:onAfterShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
        if _onShow then
          _onShow(currentScreenObject)
        end
      end)
    end)
  end
  function menu:showScreenModloader(_screenName, _screenParams, _extraParams)
    local _screenParams = _screenParams or {}
    local _extraParams = _extraParams or {}
    local _onShow = _extraParams.onShow
    local _isBackwards = _extraParams.isBackwards or false
    local _history = _extraParams.history
    newScreenName = _screenName
    newScreenScreenParams = _screenParams
    local _screenClass = require("mods." .. _screenName)
    local newScreenObject = _screenClass:new(_screenParams, unpack(defaultScreenParams))
    newScreenObject.isVisible = false
    menuScreenGroup:insert(newScreenObject)
    if _history then
      history = _history
    elseif not _isBackwards then
      history[#history + 1] = {screenName = _screenName, screenParams = _screenParams}
    end
    menu:onShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
    unloadCurrentScreen(_isBackwards, function()
      menu:onBetweenShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
      newScreenObject.isVisible = true
      newScreenObject:inTransition(function()
        newScreenName = nil
        newScreenScreenParams = nil
        currentScreenName = _screenName
        currentScreenObject = newScreenObject
        currentScreenScreenParams = _screenParams
        menu:onAfterShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
        if _onShow then
          _onShow(currentScreenObject)
        end
      end)
    end)
  end
  function menu:showScreenModMenu(_screenName, _screenParams, _extraParams)
    local _screenParams = _screenParams or {}
    local _extraParams = _extraParams or {}
    local _onShow = _extraParams.onShow
    local _isBackwards = _extraParams.isBackwards or false
    local _history = _extraParams.history
    newScreenName = _screenName
    newScreenScreenParams = _screenParams
    local _screenClass = require("Resources.coroModLoader." .. _screenName)
    local newScreenObject = _screenClass:new(_screenParams, unpack(defaultScreenParams))
    newScreenObject.isVisible = false
    menuScreenGroup:insert(newScreenObject)
    if _history then
      history = _history
    elseif not _isBackwards then
      history[#history + 1] = {screenName = _screenName, screenParams = _screenParams}
    end
    menu:onShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
    unloadCurrentScreen(_isBackwards, function()
      menu:onBetweenShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
      newScreenObject.isVisible = true
      newScreenObject:inTransition(function()
        newScreenName = nil
        newScreenScreenParams = nil
        currentScreenName = _screenName
        currentScreenObject = newScreenObject
        currentScreenScreenParams = _screenParams
        menu:onAfterShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
        if _onShow then
          _onShow(currentScreenObject)
        end
      end)
    end)
  end
  function menu:onShowScreen(_screenName, _screenParams, _screenObject, _isBackwards)
  end
  function menu:onBetweenShowScreen(_screenName, _screenParams, _screenObject, _isBackwards)
  end
  function menu:onAfterShowScreen(_screenName, _screenParams, _screenObject, _isBackwards)
  end
  function menu:onBack()
  end
  function menu:back()
    if #history == 1 then
      menu:close()
    else
      local currentScreenHistoryObject = array.remove(history)
      local previousScreenHistoryObject = array.last(history)
      menu:onBack()
      menu:showScreen(previousScreenHistoryObject.screenName, previousScreenHistoryObject.screenParams, {isBackwards = true})
    end
  end
  function menu:close(_onComplete)
    unloadCurrentScreen(true, function()
      if _onComplete then
        _onComplete()
      end
    end)
  end
  return menu
end
return t
