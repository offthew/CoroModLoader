local Screen = {}
local titleScreenSaveslotsOverlayBuilder = require("resources.mods.modLoader.titleScreenSaveslotsOverlayBuilder")
local TitleScreenBackground = require("classes.sprites.TitleScreenBackground")
local CoromonLogo = require("classes.sprites.CoromonLogo")
local Bird = require("classes.sprites.Bird")
local confirmPopupBuilder = require("classes.interface.overlays.confirmPopupBuilder")
local MessagePopup = require("classes.interface.overlays.MessagePopup")
local gameSettingsMigrationTitleScreenMessages = {}
local gameSettingsMigrationTitleScreenOnCompleteFunctions = {}

function Screen:addGameSettingsMigrationTitleScreenMessage(_message)
  gameSettingsMigrationTitleScreenMessages[#gameSettingsMigrationTitleScreenMessages + 1] = _message
end
function Screen:addGameSettingsMigrationTitleScreenOnCompleteFunction(_onComplete)
  gameSettingsMigrationTitleScreenOnCompleteFunctions[#gameSettingsMigrationTitleScreenOnCompleteFunctions + 1] = _onComplete
end
function Screen:new(_onShow)

  local parentGroup = rectHelper:newContainerObject(displayGroups.titleScreen, {
    width = device.maxContentWidth,
    height = device.maxContentHeight
  })
  magnet:center(parentGroup, 0, 0)
  local parentGroupContentGroup = groupHelper:new(parentGroup)
  inputHelper:increaseInputLevel()
  inputHelper:setKeyEventShouldDetectUnknownGamepads(true)
  soundHelper:playMusic("sounds/backgroundMusic/titleScreen", {fadeOutTime = 0, fadeInTime = 500})
  local backgroundContainer = groupHelper:newContainer(parentGroupContentGroup, device.maxContentWidth, device.maxContentHeight)
  local background = TitleScreenBackground:new(backgroundContainer, "default")
  magnet:center(background, 0, 0)
  local sunbeamConfigsBySunbeamType = {
    {
      -20,
      180,
      320
    },
    {
      10,
      80,
      290
    },
    {
      -70,
      120,
      230
    }
  }
  for i = 1, #sunbeamConfigsBySunbeamType do
    local sunbeamConfigs = sunbeamConfigsBySunbeamType[i]
    for j = 1, #sunbeamConfigs do
      local sunbeamSprite = imageHelper:new(backgroundContainer, "images/interface/screens/titleScreen/sunbeam_" .. i .. ".png", {
        alpha = 0,
        isVisible = not isTakingUIScreenshots
      })
      magnet:topLeft(sunbeamSprite, sunbeamConfigs[j], 0, background)
      transition.wiggle(sunbeamSprite, {
        function(_next, _obj, _overtime)
          transition.show(_obj, 1500, outQuad, {
            overtime = _overtime,
            delay = math.random(100, 2500)
          }, _next)
        end,
        function(_next, _obj, _overtime)
          transition.fadeOut(_obj, 1500, inQuad, {
            delay = 500,
            overtime = _overtime,
            delay = math.random(100, 500)
          }, _next)
        end
      })
    end
  end
  local foreground = imageHelper:newObject(backgroundContainer, "images/interface/screens/titleScreen/foreground.png")
  magnet:bottomCenter(foreground, 0, -32)
  local function createBird(_xOffset, _yOffset, _deltaLimits)
    local bird = Bird:new(backgroundContainer, "titleScreen", transition, _deltaLimits)
    if isTakingUIScreenshots then
      bird.isVisible = false
    end
    local function doRandomActionAfterDelay()
      timer.performWithRandomDelay(3000, 5000, function()
        bird:tryRandomAction(function(_deltaTileX, _deltaTileY)
          if display:isDisplayObject(bird) then
            doRandomActionAfterDelay()
          end
        end)
      end, "titleScreen")
    end
    doRandomActionAfterDelay()
    magnet:bottomCenter(bird, _xOffset, _yOffset, foreground)
  end
  createBird(-70, 60, {
    left = math.floor(8.125),
    top = 4,
    right = math.floor(4.375),
    bottom = 2
  })
  createBird(-140, 80, {
    left = math.floor(3.75),
    top = 4,
    right = math.floor(8.75),
    bottom = 2
  })
  createBird(110, 80, {
    left = math.floor(6.875),
    top = 4,
    right = math.floor(5.625),
    bottom = 2
  })
  createBird(160, 100, {
    left = math.floor(10),
    top = 4,
    right = math.floor(2.5),
    bottom = 2
  })
  if not isTakingUIScreenshots then
    TitleScreenBackground:createRandomBirdAnimations(backgroundContainer, "titleScreen")
  end
  local logo = CoromonLogo:new(parentGroupContentGroup, {alpha = 0})
  magnet:center(logo, 0, -20)
  local swurmySequenceShuffleBag = math.newShuffleBag():addByAmountObjectArray({
    {4, "blink_2"},
    {2, "blink_1"},
    {2, "bite"},
    {1, "lookAway"}
  })
  local function playRandomSwurmySequences()
    logo:playSwurmySequence(swurmySequenceShuffleBag:roll(), function()
      timer.performWithRandomDelay(2000, 3000, function()
        playRandomSwurmySequences()
      end, "titleScreen")
    end)
  end
  if app:isDemoBuild() then
    local demoBuildText = textHelper:new(parentGroupContentGroup, "outline_8", "DEMO BUILD: V" .. app.version)
    magnet:topCenter(demoBuildText, 0, 0)
  elseif app:isDevelopBuild() then
    local devBuildText = textHelper:new(parentGroupContentGroup, "outline_8", "DEV BUILD: V" .. app.version)
    magnet:topCenter(devBuildText, 0, 0)
  end
  local continueText = textHelper:new(parentGroupContentGroup, "outline_8", {
    text = localise("menu.titleScreen.continueText." .. (device.isMobile and "mobile" or "other")),
    alpha = 0
  })
  magnet:atBottomCenter(continueText, 0, 3, logo)
  timer.untilObjectDestroyed(continueText, timer.performWithRepeatingDelayArray({2000, 1000}, timer.toggleVisibility(continueText)))
  eventManager:listenUntilObjectDestroyed(continueText, "languageCodeChanged", function()
    continueText.text = localise("menu.titleScreen.continueText." .. (device.isMobile and "mobile" or "other"))
    magnet:atBottomCenter(continueText, 0, 3, logo)
  end)
  if not device.isSwitch and not device.isAppleArcade then
    do
      local twitterButton = imageHelper:new(parentGroupContentGroup, "images/interface/screens/titleScreen/twitter.png")
      magnet:invalidateOnSafeAreaChangedEvent(twitterButton, function()
        magnet:bottomRight(twitterButton, gameSettings:getSafeHorizontalInsetOrAtleast(4), 2)
      end)
      parentGroup.twitterButton = twitterButton
      inputHelper:addTouchable(twitterButton, inputHelper:onReleaseWithinBounds(function(event)
        inputHelper:blockInput()
        transition.smallPress(event.target, function()
          inputHelper:unblockInput()
          system.openURL("https://twitter.com/CoromonTheGame")
        end)
      end))
      local facebookButton = imageHelper:new(parentGroupContentGroup, "images/interface/screens/titleScreen/facebook.png")
      magnet:invalidateOnSafeAreaChangedEvent(facebookButton, function()
        magnet:bottomRight(facebookButton, gameSettings:getSafeHorizontalInsetOrAtleast(4) + 28, 2)
      end)
      parentGroup.facebookButton = facebookButton
      inputHelper:addTouchable(facebookButton, inputHelper:onReleaseWithinBounds(function(event)
        inputHelper:blockInput()
        transition.smallPress(event.target, function()
          inputHelper:unblockInput()
          system.openURL("https://www.facebook.com/coromonthegame")
        end)
      end))
      local discordButton = imageHelper:new(parentGroupContentGroup, "images/interface/screens/titleScreen/discord.png")
      magnet:invalidateOnSafeAreaChangedEvent(discordButton, function()
        magnet:bottomRight(discordButton, gameSettings:getSafeHorizontalInsetOrAtleast(4) + 56, 2)
      end)
      parentGroup.discordButton = discordButton
      inputHelper:addTouchable(discordButton, inputHelper:onReleaseWithinBounds(function(event)
        inputHelper:blockInput()
        transition.smallPress(event.target, function()
          inputHelper:unblockInput()
          system.openURL("https://discord.gg/coromon")
        end)
      end))
    end
  end
  local inputNavigation = inputNavigationBuilder:new()
  local anyButtonNavigation = navigationBuilder:new(backgroundContainer)
  anyButtonNavigation:setOnKeyEvent(navigations.mapKeyEventToTouches(backgroundContainer))
  inputNavigation:add(anyButtonNavigation)
  local ajaxLoader = AjaxLoader:newPlaying(parentGroupContentGroup, {isVisible = false})
  magnet:center(ajaxLoader, 0, 12, parentGroup)
  local hasShownTitleScreenSaveslotOverlay = false
  local function transitionToTitleScreenSaveslotOverlay()
    GameCenter:showAccessPoint("topTrailing", not hasShownTitleScreenSaveslotOverlay)
    hasShownTitleScreenSaveslotOverlay = true
    if parentGroup.facebookButton then
      transition.fadeOut(parentGroup.facebookButton, 150, outQuad)
    end
    if parentGroup.twitterButton then
      transition.fadeOut(parentGroup.twitterButton, 150, outQuad)
    end
    if parentGroup.discordButton then
      transition.fadeOut(parentGroup.discordButton, 150, outQuad)
    end
    transition.fadeOut(continueText, 150, outQuad)
  end
  local function transitionToTitleScreen()
    GameCenter:hideAccessPoint()
    if parentGroup.facebookButton then
      transition.show(parentGroup.facebookButton, 150, outQuad)
    end
    if parentGroup.twitterButton then
      transition.show(parentGroup.twitterButton, 150, outQuad)
    end
    if parentGroup.discordButton then
      transition.show(parentGroup.discordButton, 150, outQuad)
    end
    transition.show(continueText, 150, outQuad)
    continueText.isVisible = false
  end
  inputHelper:addTouchable(backgroundContainer, inputHelper:onReleaseWithinBounds(function(event)
    inputHelper:blockInput()
    transitionToTitleScreenSaveslotOverlay()
    ajaxLoader.isVisible = true
    SaveslotFacade:getSaveslotClustersByDeviceId(function(_error, _saveslotClustersPerDeviceId)
      ajaxLoader.isVisible = false
      confirmPopupBuilder:newIf(_error ~= nil, {
        text = _error and localise("menu.titleScreen.confirmPopup.wantToLoadOfflineSaveslot.switch", {
          error = localise("global.OnlineError." .. _error)
        }) or nil,
        onNo = transitionToTitleScreen,
        createCustomContentFunction = function()
          return imageHelper:new(nil, "images/interface/screens/titleScreen/onlineSavesDisabled.png")
        end,
        onYes = function()
          transition.toDelta(logo, 225, outQuad, {y = -12})
          transition.toDelta(foreground, 225, outQuad, {y = -32})
          if _error ~= nil then
            gameSettings:setEnableOnlineSavesSetting(false)
            gameSettings:saveSettings()
          end
          local titleScreenSaveslotsOverlay
          titleScreenSaveslotsOverlay = titleScreenSaveslotsOverlayBuilder:new(_saveslotClustersPerDeviceId, function()
            transition.toDelta(logo, 225, outQuad, {y = 12})
            transition.toDelta(foreground, 225, outQuad, {y = 32})
            transitionToTitleScreen()
          end, function(_saveslotCluster, _saveslotIndex, _saveslot, _saveslotData, _onWorldLoaded)
            soundHelper:stopMusic(300)
            inputNavigation:handleRemoveFocus()
            worldTransitions:inTransition("fade", function()
              timer.cancel("titleScreen")
              display.remove(parentGroup)
              titleScreenSaveslotsOverlay:destroy()
              inputHelper:decreaseInputLevel()
              inputHelper:setKeyEventShouldDetectUnknownGamepads(false)
              if not _saveslotData then
                playerStateHelper:createNewGame(_saveslotIndex, _saveslotCluster, "fade", _onWorldLoaded)
              else
                local offlineAutoVersionId = _saveslotCluster.offlineAuto and _saveslotCluster.offlineAuto.versionId or nil
                local offlineManualVersionId = _saveslotCluster.offlineManual and _saveslotCluster.offlineManual.versionId or nil
                local onlineAutoVersionId = _saveslotCluster.onlineAuto and _saveslotCluster.onlineAuto.version or nil
                local onlineManualVersionId = _saveslotCluster.onlineManual and _saveslotCluster.onlineManual.version or nil
                local iCloudAutoVersionId = _saveslotCluster.iCloudAuto and _saveslotCluster.iCloudAuto.versionId or nil
                local iCloudManualVersionId = _saveslotCluster.iCloudManual and _saveslotCluster.iCloudManual.versionId or nil
                playerStateHelper:loadGame(_saveslotData, _saveslotCluster, onlineManualVersionId or offlineManualVersionId or iCloudManualVersionId, onlineAutoVersionId or offlineAutoVersionId or iCloudAutoVersionId, "fade", function()
                  _onWorldLoaded()
                  if device.isMobile and app:isDemoBuild() then
                    local requestPushNotificationPopupText = app:isDemoBuild() and localise("menu.titleScreen.confirmPopup.pushNotificationOnFullRelease") or localise("menu.titleScreen.confirmPopup.pushNotificationOnGameUpdates")
                    PushNotifications:trySubscribeToTopicOptionallyRequestingPermission("game", requestPushNotificationPopupText, function()
                      worldHelper:pause()
                    end, function()
                      worldHelper:resume()
                    end)
                  end
                end)
              end
            end)
          end):open()
        end
      })
    end)
  end))
  inputHelper:blockInput()
  transition.fadeIn(parentGroup, 350, outQuad, function()
    transition.to(logo, 500, inQuad, {alpha = 1}, {delay = 150})
    transition.to(continueText, 500, inQuad, {alpha = 1}, {delay = 150}, function()
      playRandomSwurmySequences()
      inputHelper:unblockInput()
      functionHelper:forEachOnComplete(gameSettingsMigrationTitleScreenMessages, function(_message, _onMessageComplete)
        MessagePopup:newImportant(_message, _onMessageComplete)
      end, function()
        gameSettingsMigrationTitleScreenMessages = {}
        functionHelper:forEachOnComplete(gameSettingsMigrationTitleScreenOnCompleteFunctions, function(_onCompleteFunction, _onCompleteFunctionComplete)
          _onCompleteFunction(_onCompleteFunctionComplete)
        end, function()
          gameSettingsMigrationTitleScreenOnCompleteFunctions = {}
          inputNavigation:handleObtainFocus()
          gameSettings:optionallyShowKeyboardControls(function()
            if _onShow then
              _onShow(parentGroup)
            end
          end)
        end)
      end)
    end)
  end)
end
return Screen
