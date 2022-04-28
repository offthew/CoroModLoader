local Obj = {}
local basePopupBuilder = require("classes.interface.overlays.basePopupBuilder")
function Obj:new(_options)
  local _text = _options.text
  local _onNo = _options.onNo
  local _autoCloseSeconds = _options.autoCloseSeconds
  local _autoCloseTextFunction = _options.autoCloseTextFunction
  local messageTextPrepared = textHelper:newPrepared("outline_10", {
    text = _text or _autoCloseTextFunction(_autoCloseSeconds),
    width = 184,
    align = "center"
  })
  local customContent = _options.createCustomContentFunction and _options.createCustomContentFunction()
  local popupBackgroundHeight = messageTextPrepared.height + 39 + (customContent and customContent.height + 4 or 0)
  local popupBackground = UIContainerBuilder:newGreyFancy(nil, 200, popupBackgroundHeight)
  local parentGroup = basePopupBuilder:new(popupBackground)
  parentGroup:setOpenSound("menuOverlayShow")
  parentGroup:setCloseSound("menuOverlayHide")
  local messageText = textHelper:spawnPrepared(popupBackground, messageTextPrepared)
  magnet:topCenter(messageText, 0, 7, popupBackground)
  local autoCloseTimer
  if _autoCloseSeconds then
    autoCloseTimer = timer.performWithDelay(1000, function(event)
      messageText.text = _autoCloseTextFunction(event.iterationsLeft)
      if event.iterationsLeft == 0 then
        parentGroup:close(_onNo)
      end
    end, _autoCloseSeconds)
  end
  if customContent then
    popupBackground:insert(customContent)
    magnet:atBottomCenter(customContent, 0, 4, messageText)
  end

  local noButton = UIContainerBuilder:new(popupBackground, UIContainerStyle.red_round_pop, 61, 19)
  magnet:bottomCenter(noButton, 0, 7, popupBackground)
  local noButtonLabel = textHelper:new(noButton, "plain_10_bold", "Cancel")
  magnet:center(noButtonLabel, 0, -2, noButton)
  inputHelper:addTouchable(noButton, inputHelper:onReleaseWithinBounds(function(event)
    inputHelper:blockInput()
    soundHelper:playSound("menuSoftSelect")
    transition.press(event.target, function()
      inputHelper:unblockInput()
      if autoCloseTimer then
        timer.cancel(autoCloseTimer)
      end
      parentGroup:close(_onNo)
    end)
  end))
  local focusArrow = focusArrowBuilder:new(popupBackground)
  parentGroup:addGamepadNavigation(navigations:createShowNavigation(focusArrow))
  local gamepadNavigation = navigations:createHorizontalButtonsNavigationWithLastSelected({noButton}, function(_obj)
    magnet:centerRight(focusArrow, -6, 0, _obj)
  end)
  parentGroup:addGamepadNavigation(gamepadNavigation)
  parentGroup:addGlobalNavigation(navigations:createBackButtonNavigation(noButton))
  parentGroup:addGlobalNavigation(navigations:createStartButtonNavigation(noButton))
  parentGroup:addGlobalNavigation(navigations:createNumericKeyTouchNavigation(gamepadNavigation:getChildObjects()))
  parentGroup:open()
  return parentGroup, popupBackground
end
return Obj
