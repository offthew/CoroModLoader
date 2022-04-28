titleScreen = require("classes.interface.overlays.titleScreenSaveslotsOverlayBuilder")
local baseOverlayBuilder = require("classes.interface.overlays.baseOverlayBuilder")
local SaveslotMetadataContainer = require("classes.interface.SaveslotMetadataContainer")
local messagePopupBuilder = require("classes.interface.overlays.messagePopupBuilder")
local confirmPopupBuilder = require("classes.interface.overlays.confirmPopupBuilder")
local slideViewBuilder = require("classes.modules.interface.slideViewBuilder")

function modInstance()
  function instance:showScreenMod(_screenName,_screenParams, _extraParams)
    _screenParams = _screenParams or {}
    _extraParams = _extraParams or {}
    local _onShow = _extraParams.onShow
    local _isBackwards = _extraParams.isBackwards
    local _screenClass = require("Resources.mods.modLoader.".. _screenName)
    local newScreenObject = _screenClass:new(_screenParams, unpack(defaultScreenParams))
    newScreenObject.isVisible = false
    menuScreenGroup:insert(newScreenObject)
    if not newScreenObject:isHistoryDisabled() and not _isBackwards then
      history[#history + 1] = {screenName = _screenName, screenParams = _screenParams}
    end
    menu:onShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
    unloadCurrentScreen(_isBackwards, function()
      menu:onBetweenShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
      newScreenObject.isVisible = true
      newScreenObject:inTransition(function()
        currentScreenName = _screenName
        currentScreenObject = newScreenObject
        menu:onAfterShowScreen(_screenName, _screenParams, newScreenObject, _isBackwards)
        if _onShow then
          _onShow(currentScreenObject)
        end
      end)
    end)
  end
end

function titleScreen:new(_saveslotClustersPerDeviceId, _onGoBackToTitleScreen, _onStartOrLoadGame)
  local parentGroup = baseOverlayBuilder:new()
  parentGroup:setCloseOnBackButton()
  parentGroup:setCloseOnBackgroundTouch()
  parentGroup:setOpenSound("menuOverlayShow")
  parentGroup:setCloseSound("menuOverlayHide")
  local overlayTopGroup = parentGroup:getTopGroup()
  local overlayContentGroup = parentGroup:getContentGroup()
  local overlayBottomGroup = parentGroup:getBottomGroup()
  local topButtonsNavigation = horizontalNavigationBuilder:new()
  local focusArrow = focusArrowBuilder:new(overlayTopGroup)
  local settingsButton = UIContainerBuilder:new(overlayContentGroup, UIContainerStyle.blue_withShadow, 22, 24)
  magnet:topLeft(settingsButton, gameSettings:getSafeHorizontalInsetOrAtleast(2), 2)
  local settingsButtonIcon = imageHelper:new(settingsButton, "images/interface/screens/pauseMenuScreen/tabIcons/settingsScreen.png")
  magnet:center(settingsButtonIcon, 0, -2, settingsButton)
  local settingsButtonNavigation = navigations:createUseButtonNavigation(settingsButton)
  settingsButtonNavigation:setOnObtainFocus(function(_obj)
    focusArrow:setSequence("left")
    magnet:atRightCenter(focusArrow, -6, 0, _obj)
  end)
  topButtonsNavigation:add(settingsButtonNavigation)
  inputHelper:addTouchable(settingsButton, inputHelper:onReleaseWithinBounds(function(event)
    inputHelper:blockInput()
    transition.smallPress(event.target, function()
      inputHelper:unblockInput()
      parentGroup:close(function()
        timer.pause("titleScreen")
        pauseMenu:createInstance()
        pauseMenu:showScreen(settingsScreen:getScreenForTitleScreen())
        pauseMenu:addOnAfterCloseFunction(function()
          timer.resume("titleScreen")
        end)
      end)
    end)
  end))
  --Loop Here in the future
  moddingButton = UIContainerBuilder:new(overlayContentGroup, UIContainerStyle.blue_withShadow, 22, 24)
  magnet:topLeft(moddingButton, gameSettings:getSafeHorizontalInsetOrAtleast((i*26)+26), 2)
  local moddingButtonIcon = imageHelper:new(moddingButton, "mods/modLoader/img/moddingScreen.png")
  magnet:center(moddingButtonIcon, 0, -2, moddingButton)
  local moddingButtonNavigation = navigations:createUseButtonNavigation(moddingButton)
  settingsButtonNavigation:setOnObtainFocus(function(_obj)
    focusArrow:setSequence("left")
    magnet:atRightCenter(focusArrow, -6, 0, _obj)
  end)
  topButtonsNavigation:add(moddingButtonNavigation)
  inputHelper:addTouchable(moddingButton, inputHelper:onReleaseWithinBounds(function(event)
    inputHelper:blockInput()
    transition.smallPress(event.target, function()
      inputHelper:unblockInput()
      parentGroup:close(function()
        timer.pause("titleScreen")
        pauseMenu:createInstance()

        pauseMenu:showScreenModloader("modLoader.screens.modsScreen", {isFromTitleScreen = true,hasTransition = true})     
        pauseMenu:addOnAfterCloseFunction(function()
          timer.resume("titleScreen")
        end)
      end)
    end)
  end))
  if gameSettings:getDisableOnlineSavesSetting() then
    local onlineSavesDisabled = imageHelper:new(overlayContentGroup, "images/interface/screens/titleScreen/onlineSavesDisabled.png")
    magnet:atRightCenter(onlineSavesDisabled, 2, -1, settingsButton)
    parentGroup.onlineSavesDisabled = onlineSavesDisabled
  end
  if not device.isIOS and not device.isSwitch then
    local quitButton = UIContainerBuilder:new(overlayContentGroup, UIContainerStyle.red_withShadow, 22, 24)
    magnet:topRight(quitButton, gameSettings:getSafeHorizontalInsetOrAtleast(2), 2)
    local quitButtonIcon = imageHelper:new(quitButton, "images/interface/icons/otherIcons/quitIcon.png")
    magnet:center(quitButtonIcon, 0, -1, quitButton)
    parentGroup.quitButton = quitButton
    local quitButtonNavigation = navigations:createUseButtonNavigation(quitButton)
    quitButtonNavigation:setOnObtainFocus(function(_obj)
      focusArrow:setSequence("right")
      magnet:atLeftCenter(focusArrow, -6, 0, _obj)
    end)
    topButtonsNavigation:add(quitButtonNavigation)
    inputHelper:addTouchable(quitButton, inputHelper:onReleaseWithinBounds(function(event)
      inputHelper:blockInput()
      transition.smallPress(event.target, function()
        inputHelper:unblockInput()
        confirmPopupBuilder:new({
          text = localise("menu.titleScreen.confirmPopup"),
          onYes = native.requestExit
        })
      end)
    end))
  end
  local saveslotsForDeviceIdSlideView = slideViewBuilder:new({
    parent = overlayContentGroup,
    width = device.width,
    height = 54,
    direction = "horizontal",
    mode = "lazy",
    speed = 2,
    selectedSlide = 1,
    disableTouch = #_saveslotClustersPerDeviceId == 1
  })
  magnet:bottomCenter(saveslotsForDeviceIdSlideView, 0, 2)
  local saveslotMetadataContainersNavigation = horizontalNavigationBuilder:new()
  saveslotsForDeviceIdSlideView:setCanCreateSlide(function(_index)
    return math.between(_index, 1, #_saveslotClustersPerDeviceId)
  end)
  saveslotsForDeviceIdSlideView:setOnCreateSlide(function(_index, _container)
    local saveslotClustersForDeviceId = _saveslotClustersPerDeviceId[_index]
    local saveslotSlide = rectHelper:newContainerObject({
      width = saveslotsForDeviceIdSlideView.width,
      height = saveslotsForDeviceIdSlideView.height
    })
    for saveslotIndex = 1, #saveslotClustersForDeviceId do
      local saveslotCluster = saveslotClustersForDeviceId[saveslotIndex]
      local firstSaveslot = saveslotCluster.offlineManual or saveslotCluster.onlineManual or saveslotCluster.offlineAuto or saveslotCluster.offlineAuto
      local saveslotMetadata = firstSaveslot and firstSaveslot.metadata or nil
      local saveslotMetadataContainer = SaveslotMetadataContainer:new(saveslotSlide, _index, saveslotIndex, saveslotMetadata, firstSaveslot == nil, true)
      magnet:center(saveslotMetadataContainer, -72 + (saveslotIndex - 1) * 72, 2, saveslotSlide)
      local saveslotMetadataContainerNavigation = navigations:createUseButtonNavigation(saveslotMetadataContainer)
      saveslotMetadataContainerNavigation:setOnObtainFocus(function(_obj)
        focusArrow.alpha = 0
        saveslotsForDeviceIdSlideView:jumpToSlide(_index, function()
          focusArrow.alpha = 1
          focusArrow:setSequence("left")
          magnet:atRightCenter(focusArrow, -6, 0, _obj)
        end)
      end)
      saveslotMetadataContainersNavigation:add(saveslotMetadataContainerNavigation)
      inputHelper:addTouchable(saveslotMetadataContainer, inputHelper:getTouchListener({
        onMove = touches.passFocusAfterMoveX(5, saveslotsForDeviceIdSlideView),
        onHoldDuration = 5000,
        onHold = function(event)
          local saveslotData = system.getPreference("app", "saveslot_self_" .. saveslotIndex)
          local autoSaveslotData = system.getPreference("app", "saveslot_self_" .. saveslotIndex .. "_auto")
          if saveslotData and saveslotData ~= "null" or autoSaveslotData and autoSaveslotData ~= "null" then
            if device.isMobile then
              local saveslotDataAttachments = {}
              if saveslotData then
                fileHelper:saveToTemporaryResources("coromon_saveslot_" .. saveslotIndex .. ".txt", saveslotData)
                saveslotDataAttachments[#saveslotDataAttachments + 1] = {
                  baseDir = system.TemporaryDirectory,
                  filename = "coromon_saveslot_" .. saveslotIndex .. ".txt",
                  type = "text/plain"
                }
              end
              if autoSaveslotData then
                fileHelper:saveToTemporaryResources("coromon_saveslot_" .. saveslotIndex .. "_auto.txt", autoSaveslotData)
                saveslotDataAttachments[#saveslotDataAttachments + 1] = {
                  baseDir = system.TemporaryDirectory,
                  filename = "coromon_saveslot_" .. saveslotIndex .. "_auto.txt",
                  type = "text/plain"
                }
              end
              native.showPopup("mail", {
                to = {
                  "admin@tragsoft.com"
                },
                subject = "Saveslot export request (" .. string.random(8) .. ")",
                body = "I would like to export my saveslot.",
                attachment = saveslotDataAttachments
              })
            end
          elseif not device.isSwitch then
            keyboardOverlayBuilder:new("Enter saveslot import code", true, {
              onAfterComplete = function(_text)
                inputHelper:blockInput()
                network.request("https://file.io/" .. _text, "GET", timer.atleast(1000, function(networkEvent)
                  if not networkEvent.isError then
                    local importedSaveslotData = encryptionHelper:decryptOld(networkEvent.response)
                    importedSaveslotData = importedSaveslotData or encryptionHelper:decrypt(networkEvent.response)
                    if importedSaveslotData then
                      importedSaveslotData.selectedSaveslotIndex = saveslotIndex
                      system.setPreferences("app", {
                        ["saveslot_self_" .. saveslotIndex] = json.encode({
                          encryptedData = saveslotDataHelper:encrypt(importedSaveslotData),
                          metadata = saveslotDataHelper:createMetadata(importedSaveslotData),
                          versionId = "converted"
                        })
                      })
                    end
                  end
                  parentGroup:close()
                end), {
                  timeout = 15,
                  headers = {
                    Referer = "https://www.file.io/download?fileId=" .. _text
                  }
                })
              end
            })
          end
        end,
        onReleaseWithinBounds = function(event)
          soundHelper:playSound("menuSoftSelect")
          inputHelper:blockInput()
          transition.smallPress(event.target, function()
            inputHelper:unblockInput()
            local possiblyDeletedFirstSaveslot = saveslotCluster.offlineManual or saveslotCluster.onlineManual or saveslotCluster.offlineAuto or saveslotCluster.offlineAuto
            if not possiblyDeletedFirstSaveslot then
              inputHelper:blockInput()
              _onStartOrLoadGame(saveslotCluster, saveslotIndex, nil, nil, function()
                inputHelper:unblockInput()
              end)
            else
              SaveslotClusterPopup:new(saveslotCluster, saveslotIndex, function(_saveslot, _saveslotData)
                local updatedSaveslotData = saveslotDataHelper:updateDataToNewestVersion(_saveslotData, saveslotIndex)
                local saveslotChangedNotificationMessages = updatedSaveslotData and updatedSaveslotData.saveslotChangedNotificationMessages or {}
                functionHelper:forEachOnComplete(saveslotChangedNotificationMessages, function(_message, _onMessageComplete)
                  messagePopupBuilder:new(_message, _onMessageComplete)
                end, function()
                  inputHelper:blockInput()
                  parentGroup:handleRemoveFocus()
                  _onStartOrLoadGame(saveslotCluster, saveslotIndex, _saveslot, updatedSaveslotData, function()
                    inputHelper:unblockInput()
                  end)
                end)
              end, function()
                inputHelper:blockInput()
                saveslotMetadataContainer:transitionToEmptyState(function()
                  inputHelper:unblockInput()
                end)
              end):open()
            end
          end)
        end
      }))
    end
    return saveslotSlide
  end)
  UIScrollIndicatorBuilder:newHorizontal(overlayBottomGroup, saveslotsForDeviceIdSlideView, math.floor((device.width - 228) * 0.5))
  eventManager:listen(saveslotsForDeviceIdSlideView, "transitionStart", function(event)
    inputHelper:blockInput()
    parentGroup:handleRemoveFocus()
  end)
  eventManager:listen(saveslotsForDeviceIdSlideView, "transitionEnd", function(event)
    inputHelper:unblockInput()
    parentGroup:handleObtainFocus()
  end)
  parentGroup:addGamepadNavigation(navigations:createShowNavigation(focusArrow))
  parentGroup:addGamepadNavigation(navigations:createVerticalNavigationWithLastSelected({topButtonsNavigation, saveslotMetadataContainersNavigation}))
  local numericCharacterTouchNavigation = navigationBuilder:new()
  numericCharacterTouchNavigation:setOnKeyEvent(function(event)
    local numberOfKeyOrNumpadKey = keys:parseNumberOfKeyOrNumpadKey(event.keyName)
    if numberOfKeyOrNumpadKey then
      local objectToTouch = saveslotMetadataContainersNavigation:getChildObjects()[(saveslotsForDeviceIdSlideView:getCurrentSlideNumber() - 1) * 3 + numberOfKeyOrNumpadKey]
      if objectToTouch then
        navigations.doMapKeyEventToTouch(event, objectToTouch)
      end
    end
  end)
  parentGroup:addGlobalNavigation(numericCharacterTouchNavigation)
  parentGroup:addGlobalNavigation(navigations:createFirstExtraButtonNavigation(settingsButton))
  if parentGroup.quitButton then
    parentGroup:addGlobalNavigation(navigations:createStartButtonNavigation(parentGroup.quitButton))
  end
  function parentGroup:onBeforeClose()
    _onGoBackToTitleScreen()
  end
  parentGroup:addInTransition(function(_onComplete)
    if parentGroup.quitButton then
      transition.fromTop(parentGroup.quitButton, 250, outQuad)
    end
    transition.fromTop(settingsButton, 250, outQuad)
    if parentGroup.onlineSavesDisabled then
      transition.fromTop(parentGroup.onlineSavesDisabled, 250, outQuad)
    end
    transition.fromBottom(saveslotsForDeviceIdSlideView, 250, outQuad, _onComplete)
  end)
  parentGroup:addOutTransition(function(_onComplete)
    if parentGroup.quitButton then
      transition.toTop(parentGroup.quitButton, 250, outQuad)
    end
    transition.toTop(settingsButton, 250, outQuad)
    if parentGroup.onlineSavesDisabled then
      transition.toTop(parentGroup.onlineSavesDisabled, 250, outQuad)
    end
    transition.toBottom(saveslotsForDeviceIdSlideView, 250, outQuad, _onComplete)
  end)
  return parentGroup
end