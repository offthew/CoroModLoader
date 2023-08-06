local Obj = {}
local basePopupBuilder = require("classes.interface.overlays.basePopupBuilder")
local baseOverlayBuilder = require("classes.interface.overlays.baseOverlayBuilder")
local SaveslotMetadataContainer = require("classes.interface.SaveslotMetadataContainer")
local MessagePopup = require("classes.interface.overlays.MessagePopup")
local confirmPopupBuilder = require("classes.interface.overlays.confirmPopupBuilder")
local slideViewBuilder = require("classes.modules.interface.slideViewBuilder")
local StyleCrystalShopScreenModeActionMenuOverlay = require("classes.interface.overlays.StyleCrystalShopScreenModeActionMenuOverlay")
local modFileHelper = require("resources.mods.modLoader.modApi.fileHelper")

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


function Obj:new(_saveslotClustersPerDeviceId, _onGoBackToTitleScreen, _onStartOrLoadGame)

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
        pauseMenu:addOnAfterCloseFunction(function()
          timer.resume("titleScreen")
        end)
        pauseMenu:showScreen(settingsScreen:getScreenForTitleScreen())
      end)
    end)
  end))
  --Loop Here in the future
  moddingButton = UIContainerBuilder:new(overlayContentGroup, UIContainerStyle.blue_withShadow, 22, 24)
  magnet:topLeft(moddingButton, gameSettings:getSafeHorizontalInsetOrAtleast((26)+26), 2)
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
  if not gameSettings:getEnableOnlineSavesSetting() and not app:isDemoBuild() then
    local onlineSavesDisabled = imageHelper:new(overlayContentGroup, "images/interface/screens/titleScreen/onlineSavesDisabled.png")
    magnet:atRightCenter(onlineSavesDisabled, 2, -1, settingsButton)
    parentGroup.onlineSavesDisabled = onlineSavesDisabled
  end
  if device.isTvOS and GameCenter:isEnabled() then
    local accessPointNavigation = navigationBuilder:new()
    accessPointNavigation:setOnObtainFocus(function()
      focusArrow.alpha = 0
      GameCenter:setAccessPointFocused(true)
    end)
    accessPointNavigation:setOnRemoveFocus(function()
      focusArrow.alpha = 1
      GameCenter:setAccessPointFocused(false)
    end)
    topButtonsNavigation:add(accessPointNavigation)
  elseif not device.isIOS and not device.isTvOS and not device.isSwitch then
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
    height = 71,
    direction = "horizontal",
    mode = "lazy",
    speed = 2,
    selectedSlide = 1,
    disableTouch = #_saveslotClustersPerDeviceId == 1
  })
  magnet:bottomCenter(saveslotsForDeviceIdSlideView, 0, 2)
  local currentlyFocusedSaveslotSlideNavigation
  local saveslotSlidesNavigation = horizontalNavigationBuilder:new()
  saveslotsForDeviceIdSlideView:setCanCreateSlide(function(_index)
    return math.between(_index, 1, #_saveslotClustersPerDeviceId)
  end)
  saveslotsForDeviceIdSlideView:setOnCreateSlide(function(_index, _container)
    local saveslotSlide = rectHelper:newContainerObject(nil, {
      width = saveslotsForDeviceIdSlideView.width,
      height = saveslotsForDeviceIdSlideView.height
    })
    local saveslotSlideNavigation = verticalNavigationBuilder:new()
    saveslotSlideNavigation:setOnObtainFocus(function(_obj)
      local wasFocusingOnDeviceStyleCrystalButton = currentlyFocusedSaveslotSlideNavigation and currentlyFocusedSaveslotSlideNavigation:getSelectedIndex() == 1 or false
      currentlyFocusedSaveslotSlideNavigation = saveslotSlideNavigation
      focusArrow.alpha = 0
      saveslotsForDeviceIdSlideView:jumpToSlide(_index, function()
        focusArrow.alpha = 1
        if debugSettings.showStyleCrystals then
          saveslotSlideNavigation:setSelectedIndex(wasFocusingOnDeviceStyleCrystalButton and 1 or 2)
        end
        if saveslotSlideNavigation:getCurrentChild() then
          saveslotSlideNavigation:getCurrentChild():reloadFocus()
        end
      end)
    end)
    saveslotSlidesNavigation:add(saveslotSlideNavigation)
    if debugSettings.showStyleCrystals and OnlineInventoryData:getAmountOfStyleCrystals() then
      do
        local deviceStyleCrystalsButtonString = localise("overlay.titleScreenSaveslotsOverlayBuilder.availableStyleCrystalsText", {
          amountOfStyleCrystals = OnlineInventoryData:getAmountOfStyleCrystals()
        })
        local deviceStyleCrystalsButtonTextPrepared = textHelper:newPrepared("outline_8", deviceStyleCrystalsButtonString)
        local deviceStyleCrystalsButton = UIContainerBuilder:new(saveslotSlide, UIContainerStyle.blue_round_shadowPop, deviceStyleCrystalsButtonTextPrepared.width + 12, 20)
        magnet:topCenter(deviceStyleCrystalsButton, 0, 0, saveslotSlide)
        local deviceStyleCrystalsButtonText = textHelper:spawnPrepared(deviceStyleCrystalsButton, deviceStyleCrystalsButtonTextPrepared)
        magnet:center(deviceStyleCrystalsButtonText, 0, -1, deviceStyleCrystalsButton)
        saveslotSlideNavigation:add(navigations:createUseButtonNavigation(deviceStyleCrystalsButton, function(_obj)
          focusArrow:setSequence("left")
          magnet:atRightCenter(focusArrow, -6, 0, _obj)
        end))
        inputHelper:addTouchable(deviceStyleCrystalsButton, inputHelper:onReleaseWithinBounds(function(event)
          inputHelper:blockInput()
          soundHelper:playSound("menuSoftSelect")
          transition.smallPress(event.target, function()
            inputHelper:unblockInput()
            StyleCrystalShopScreenModeActionMenuOverlay:new(deviceStyleCrystalsButton, false, function(_onComplete)
              playerMonsters:onLoadSaveslotData({})
              playerSettings:onLoadSaveslotData({
                settings = {
                  CHARACTER_HAIR = "player_other_2_k",
                  WEARABLE_ITEMUIDS = {
                    skintone = "SKINTONE_2",
                    clothing = "CLOTHING_PLAYER_BOY_6_D"
                  }
                }
              })
              parentGroup:close(function()
                timer.pause("titleScreen")
                pauseMenu:createInstance()
                pauseMenu:addOnAfterCloseFunction(function()
                  playerMonsters:destroy()
                  playerSettings:destroy()
                  timer.resume("titleScreen")
                end)
                _onComplete()
              end)
            end):open()
          end)
        end))
      end
    end
    local saveslotMetadataContainersNavigation = horizontalNavigationBuilder:new()
    saveslotSlideNavigation:addAndSetSelected(saveslotMetadataContainersNavigation)
    local saveslotClustersForDeviceId = _saveslotClustersPerDeviceId[_index]
    for saveslotIndex = 1, #saveslotClustersForDeviceId do
      local saveslotCluster = saveslotClustersForDeviceId[saveslotIndex]
      local saveslotForPreview = saveslotCluster.offlineManual or saveslotCluster.onlineManual or saveslotCluster.offlineAuto or saveslotCluster.onlineAuto
      local saveslotMetadata = saveslotForPreview and saveslotForPreview.metadata or nil
      local saveslotMetadataContainer = SaveslotMetadataContainer:new(saveslotSlide, _index, saveslotIndex, saveslotMetadata, saveslotForPreview == nil, true)
      magnet:bottomCenter(saveslotMetadataContainer, -72 + (saveslotIndex - 1) * 72, 1, saveslotSlide)
      local saveslotMetadataContainerNavigation = navigations:createUseButtonNavigation(saveslotMetadataContainer)
      saveslotMetadataContainerNavigation:setOnObtainFocus(function(_obj)
        focusArrow:setSequence("left")
        magnet:atRightCenter(focusArrow, -6, 0, _obj)
      end)
      saveslotMetadataContainersNavigation:add(saveslotMetadataContainerNavigation)
      inputHelper:addTouchable(saveslotMetadataContainer, inputHelper:getTouchListener({
        onMove = touches.passFocusAfterMoveX(5, saveslotsForDeviceIdSlideView),
        onHoldDuration = 5000,
        onHold = function(event)
          local saveslotData = system.getPreference("app", "saveslot_self_" .. saveslotIndex)
          local autoSaveslotData = system.getPreference("app", "saveslot_self_" .. saveslotIndex .. "_auto")
          if saveslotData and saveslotData ~= "null" or autoSaveslotData and autoSaveslotData ~= "null" then
            if not device.isSwitch then
              local saveslotDataAttachments = {}
              if saveslotData and saveslotData ~= "null" then
                if device.isDesktop then
                  fileHelper:saveToUserResources("coromon_saveslot_" .. saveslotIndex .. ".txt", json.decode(saveslotData).encryptedData)
                end
                if device.isSimulator then
                  Pasteboard:copy("string", json.decode(saveslotData).encryptedData)
                end
                fileHelper:saveToTemporaryResources("coromon_saveslot_" .. saveslotIndex .. ".txt", json.decode(saveslotData).encryptedData)
                saveslotDataAttachments[#saveslotDataAttachments + 1] = {
                  baseDir = system.TemporaryDirectory,
                  filename = "coromon_saveslot_" .. saveslotIndex .. ".txt",
                  type = "text/plain"
                }
              end
              if autoSaveslotData and autoSaveslotData ~= "null" then
                if device.isDesktop then
                  fileHelper:saveToUserResources("coromon_saveslot_" .. saveslotIndex .. "_auto.txt", json.decode(autoSaveslotData).encryptedData)
                end
                fileHelper:saveToTemporaryResources("coromon_saveslot_" .. saveslotIndex .. "_auto.txt", json.decode(autoSaveslotData).encryptedData)
                saveslotDataAttachments[#saveslotDataAttachments + 1] = {
                  baseDir = system.TemporaryDirectory,
                  filename = "coromon_saveslot_" .. saveslotIndex .. "_auto.txt",
                  type = "text/plain"
                }
              end
              if device.isMobile then
                native.showPopup("mail", {
                  to = {
                    "admin@tragsoft.com"
                  },
                  subject = "Saveslot export request (" .. string.random(8) .. ")",
                  body = "I would like to export my saveslot.",
                  attachment = saveslotDataAttachments
                })
              end
            end
          else
            keyboardOverlayBuilder:new("Enter saveslot import code", true, {
              onAfterComplete = function(_text)
                inputHelper:blockInput()
                network.request("https://file.io/" .. _text, "GET", timer.atleast(1000, function(networkEvent)
                  if not networkEvent.isError then
                    local importedSaveslotData = encryptionHelper:decryptOld(networkEvent.response)
                    importedSaveslotData = (type(importedSaveslotData) == "table" and importedSaveslotData) or encryptionHelper:decrypt(networkEvent.response)
                    if type(importedSaveslotData) ~= "table" then
                      soundHelper:playSound("saveslotImport_fail")
                    else
                      soundHelper:playSound("saveslotImport_success")
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
            SaveslotFacade:setCachedSaveslotClustersForDeviceId(saveslotClustersForDeviceId)
            local possiblyDeletedFirstSaveslot = saveslotCluster.offlineManual or saveslotCluster.onlineManual or saveslotCluster.offlineAuto or saveslotCluster.onlineAuto
            if not possiblyDeletedFirstSaveslot then
              inputHelper:blockInput()
              GameCenter:hideAccessPoint()
              _onStartOrLoadGame(saveslotCluster, saveslotIndex, nil, nil, function()
                inputHelper:unblockInput()
              end)
            else
              GameCenter:hideAccessPoint()
              SaveslotClusterPopup:new(saveslotCluster, saveslotIndex, function(_saveslot, _saveslotData)
                local updatedSaveslotData = saveslotDataHelper:updateDataToNewestVersion(_saveslotData, saveslotIndex)
                if updatedSaveslotData == "incompatible" then
                  MessagePopup:new(localise("menu.titleScreen.messagePopup.saveslotVersionTooHigh"))
                else
                  local saveslotChangedNotificationMessages = updatedSaveslotData and updatedSaveslotData.saveslotChangedNotificationMessages or {}
                  functionHelper:forEachOnComplete(saveslotChangedNotificationMessages, function(_message, _onMessageComplete)
                    MessagePopup:new(_message, _onMessageComplete)
                  end, function()
                    inputHelper:blockInput()
                    parentGroup:handleRemoveFocus()
                    gameSettings:saveSettings()
                    GameCenter:hideAccessPoint()
                    _onStartOrLoadGame(saveslotCluster, saveslotIndex, _saveslot, updatedSaveslotData, function()
                      inputHelper:unblockInput()
                    end)
                  end)
                end
              end, function()
                inputHelper:blockInput()
                saveslotMetadataContainer:transitionToEmptyState(function()
                  inputHelper:unblockInput()
                end)
              end):addOnClose(function(_isCancel)
                if _isCancel then
                  GameCenter:showAccessPoint("topTrailing", false)
                end
              end):open()
            end
          end)
        end
      }))
    end
    return saveslotSlide
  end)
  local scrollIndicatorOffsetFromEdge = math.floor((device.width - 244) * 0.5)
  local scrollIndicatorLeft, scrollIndicatorRight = UIScrollIndicatorBuilder:newHorizontalBig(overlayBottomGroup, saveslotsForDeviceIdSlideView, saveslotsForDeviceIdSlideView, scrollIndicatorOffsetFromEdge, 11)
  scrollIndicatorLeft.isHitTestable = true
  inputHelper:addTouchable(scrollIndicatorLeft, inputHelper:onReleaseWithinBounds(function(event)
    if scrollIndicatorLeft.isVisible then
      saveslotsForDeviceIdSlideView:previousSlide()
    end
    return true
  end))
  scrollIndicatorRight.isHitTestable = true
  inputHelper:addTouchable(scrollIndicatorRight, inputHelper:onReleaseWithinBounds(function(event)
    if scrollIndicatorRight.isVisible then
      saveslotsForDeviceIdSlideView:nextSlide()
    end
    return true
  end))
  eventManager:listen(saveslotsForDeviceIdSlideView, "drag", function(event)
    scrollIndicatorLeft.alpha = 0
    scrollIndicatorRight.alpha = 0
  end)
  eventManager:listen(saveslotsForDeviceIdSlideView, "transitionStart", function(event)
    scrollIndicatorLeft.alpha = 0
    scrollIndicatorRight.alpha = 0
    inputHelper:blockInput()
    parentGroup:handleRemoveFocus()
  end)
  eventManager:listen(saveslotsForDeviceIdSlideView, "transitionEnd", function(event)
    scrollIndicatorLeft.alpha = 1
    scrollIndicatorRight.alpha = 1
    inputHelper:unblockInput()
    parentGroup:handleObtainFocus()
  end)
  parentGroup:addGamepadNavigation(navigations:createShowNavigation(focusArrow))
  parentGroup:addGamepadNavigation(navigations:createVerticalNavigationWithLastSelected({topButtonsNavigation, saveslotSlidesNavigation}))
  local numericCharacterTouchNavigation = navigationBuilder:new()
  numericCharacterTouchNavigation:setOnKeyEvent(function(event)
    local numberOfKeyOrNumpadKey = keys:parseNumberOfKeyOrNumpadKey(event.keyName)
    if numberOfKeyOrNumpadKey then
      local numberOfKeyOrNumpadKey = numberOfKeyOrNumpadKey
      local saveslotMetadataContainersNavigation = saveslotSlidesNavigation:getCurrentChild():getChildren()[debugSettings.showStyleCrystals and 2 or 1]
      local saveslotMetadataContainer = saveslotMetadataContainersNavigation:getChildObjects()[numberOfKeyOrNumpadKey]
      if saveslotMetadataContainer then
        navigations.doMapKeyEventToTouch(event, saveslotMetadataContainer)
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
      transition.fromTopOrFadeIn(parentGroup.quitButton, 225, outQuad)
    end
    transition.fromTopOrFadeIn(settingsButton, 225, outQuad)
    if parentGroup.onlineSavesDisabled then
      transition.fromTopOrFadeIn(parentGroup.onlineSavesDisabled, 225, outQuad)
    end
    scrollIndicatorLeft.alpha = 0
    scrollIndicatorRight.alpha = 0
    transition.fromBottomOrFadeIn(saveslotsForDeviceIdSlideView, 225, outQuad, function()
      scrollIndicatorLeft.alpha = 1
      scrollIndicatorRight.alpha = 1
      _onComplete()
    end)
  end)
  parentGroup:addOutTransition(function(_onComplete)
    display.removeAll(scrollIndicatorLeft, scrollIndicatorRight)
    if parentGroup.quitButton then
      transition.toTopOrFadeOut(parentGroup.quitButton, 225, outQuad)
    end
    transition.toTopOrFadeOut(settingsButton, 225, outQuad)
    if parentGroup.onlineSavesDisabled then
      transition.toTopOrFadeOut(parentGroup.onlineSavesDisabled, 225, outQuad)
    end
    transition.toBottomOrFadeOut(saveslotsForDeviceIdSlideView, 225, outQuad, _onComplete)
  end)
  return parentGroup
end
return Obj
