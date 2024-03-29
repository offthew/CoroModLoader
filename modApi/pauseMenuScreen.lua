local t= {}
local Screen = pauseMenuScreenBuilder:newSimpleBuilder("pauseMenuScreen")
local monsterButtonBuilder = require("classes.interface.monsterButtonBuilder")
local MessagePopup = require("classes.interface.overlays.MessagePopup")
local confirmPopupBuilder = require("classes.interface.overlays.confirmPopupBuilder")
local moveHoldItemPopupBuilder = require("classes.interface.overlays.moveHoldItemPopupBuilder")
local monsterButtonPopupBuilder = require("classes.interface.overlays.monsterButtonPopupBuilder")
local StyleCrystalShopScreenModeActionMenuOverlay = require("classes.interface.overlays.StyleCrystalShopScreenModeActionMenuOverlay")
local pauseMenuScreenMonsterActionMenuOverlayBuilder = require("classes.interface.overlays.pauseMenuScreenMonsterActionMenuOverlayBuilder")
local pauseButtons = {
}

function t:addPauseButton(id,requirePath,image)
  image = image or "coroModLoader/modLoader/img/pauseButtonBasic.png"
  local button = {
    id = id,
    isMod=true,
    image= image,
    require= requirePath
  }
  table.insert(pauseButtons,button)
end
function t:addToPauseMenu(navigationButtonConfigs,pauseButtons)
  modLoaderApi.log:write("Adding New Pause Buttons")
  for i=0, #pauseButtons do
  table.insert(navigationButtonConfigs,pauseButtons[i])
  end
  return navigationButtonConfigs
end
function pauseMenuScreen:new(screenParams, screenContainer, centerContainer, horizontalCenterContainer, verticalCenterContainer, safeContainer)
  local parentGroup = pauseMenuScreenBuilder:new()
  parentGroup:addTopBarObject(outerTopBarQuitButtonBuilder:new())
  parentGroup:addTopBarObject(innerTopBarGold:getOrCreateInstance())
  local focusArrow = focusArrowBuilder:new(pauseMenu:getTopGroup())
  parentGroup:addGamepadNavigation(navigations:createShowNavigation(focusArrow))
  local squadNumericFunctionKeyParentNavigation = parentNavigationBuilder:new()
  parentGroup:addGlobalNavigation(squadNumericFunctionKeyParentNavigation)
  local showHoldItemSecondExtraButtonNavigation = navigationBuilder:new()
  parentGroup:addGlobalNavigation(showHoldItemSecondExtraButtonNavigation)
  local gamepadNavigation = horizontalNavigationBuilder:new()
  parentGroup:addGamepadNavigation(gamepadNavigation)
  local squadGamepadNavigation = verticalNavigationBuilder:new()
  gamepadNavigation:add(squadGamepadNavigation)
  local squadGamepadGridNavigation = gridNavigationBuilder:new():setGridWidth(3)
  squadGamepadGridNavigation:setSelectedIndex(screenParams.previousSquadNavigationXIndex or 3, screenParams.previousSquadNavigationYIndex or 1)
  squadGamepadNavigation:add(squadGamepadGridNavigation)
  local squadGamepadBottomButtonsNavigation = horizontalNavigationBuilder:new()
  squadGamepadNavigation:add(squadGamepadBottomButtonsNavigation)
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
    squadGamepadBottomButtonsNavigation:add(accessPointNavigation)
  end
  local squadGamepadHoldItemButtonParentNavigation = forcedParentNavigationBuilder:new()
  squadGamepadBottomButtonsNavigation:add(squadGamepadHoldItemButtonParentNavigation)
  local rightGamepadNavigation = verticalNavigationBuilder:new()
  rightGamepadNavigation:setSelectedIndex(screenParams.previousRightNavigationIndex or 1)
  gamepadNavigation:add(rightGamepadNavigation)
  if screenParams.previousRightNavigationIndex then
    gamepadNavigation:setSelected(rightGamepadNavigation)
  end
  screenParams.previousRightNavigationIndex, screenParams.previousSquadNavigationXIndex, screenParams.previousSquadNavigationYIndex = nil, nil, nil
  local itemScreenName, itemScreenScreenParams = itemScreen:getScreenForInventory(nil)
  local itemScreenScreenParamsOnHold = itemScreen:getScreenParamsForInventoryOnHold(nil)
  local milestoneScreenName = milestoneScreen:getScreenName()
  local worldMapScreenName, worldMapScreenScreenParams = worldMapScreen:getScreenForPauseMenu()
  local logbookScreenName = logbookScreen:getScreenName()
  local monsterDatabaseScreenName, monsterDatabaseScreenScreenParams = monsterDatabaseScreen:getScreen()
  local settingsScreenName, settingsScreenScreenParams = settingsScreen:getScreenForPauseMenuScreen()
  local settingsScreenScreenParamsOnHold = settingsScreen:getScreenParamsForPauseMenuScreenHold()
  local navigationButtonConfigs = {
    {
      id = itemScreenName,
      showScreenParams = itemScreenScreenParams,
      showScreenParamsOnHold = itemScreenScreenParamsOnHold
    },
    {id = milestoneScreenName},
    {id = worldMapScreenName, worldMapScreenScreenParams},
    {id = logbookScreenName},
    {id = monsterDatabaseScreenName, showScreenParams = monsterDatabaseScreenScreenParams},
    {
      id = settingsScreenName,
      showScreenParams = settingsScreenScreenParams,
      showScreenParamsOnHold = settingsScreenScreenParamsOnHold
    },
    {id = "save"}
  }
  if debugSettings.showStyleCrystals then
    array.insert(navigationButtonConfigs, 2, {
      id = "StyleCrystalShopScreen"
    })
  end
  navigationButtonConfigs = t:addToPauseMenu(navigationButtonConfigs,pauseButtons)
  local navigationButtonGroup = groupHelper:new(parentGroup)
  for i = 1, #navigationButtonConfigs do
    local navigationButtonConfig = navigationButtonConfigs[i]
    local navigationButtonId = navigationButtonConfig.id
    local navigationButtonShowScreenParams = navigationButtonConfig.showScreenParams
    local navigationButtonShowScreenParamsOnHold = navigationButtonConfig.showScreenParamsOnHold
    local navigationButtonHeight = debugSettings.showStyleCrystals and 17 or 19
    --Mod
    local navigationButtonIsMod = navigationButtonConfig.isMod
    local navigationButtonRequire = navigationButtonConfig.require
    local navigationButtonImage = navigationButtonConfig.image

    local navigationButton = UIContainerBuilder:new(navigationButtonGroup, UIContainerStyle.darkBlue_round, 73, navigationButtonHeight)
    magnet:centerRight(navigationButton, 1, magnet:evenlyDistributed(#navigationButtonConfigs, navigationButtonHeight - 1, i), centerContainer)
    if navigationButtonId == "milestoneScreen" and next(playerStats:getUnclaimedButAchievedMilestoneStages()) and not playerStats:hasReachedMaxLuxSolisRankExperience() then
      do
        local navigationButtonHighlight = UIContainerBuilder:new(navigationButton, UIContainerStyle.darkBlue_round_highlight, navigationButton.width, navigationButton.height, {alpha = 0})
        magnet:center(navigationButtonHighlight, 0, 0, navigationButton)
        transition.show(navigationButtonHighlight, 500, linear, {
          delay = 750,
          tag = "pauseMenuScreen"
        }, function()
          transition.wiggle(navigationButtonHighlight, {
            function(_next, _obj, _overtime)
              transition.to(_obj, 500, linear, {alpha = 0}, {overtime = _overtime}, _next)
            end,
            function(_next, _obj, _overtime)
              transition.to(_obj, 500, linear, {alpha = 1}, {delay = 2000, overtime = _overtime}, _next)
            end
          })
        end)
      end
    end

    --Mod showing mod text and icon on pause button, for the future think about crystal shop
    local navigationButtonLabel
    local navigationButtonIcon
    if(navigationButtonIsMod) then
      navigationButtonLabel = textHelper:new(navigationButton, "outline_8", navigationButtonId)
      navigationButtonIcon = imageHelper:new(navigationButton, navigationButtonImage)
    else
      navigationButtonLabel = textHelper:new(navigationButton, "outline_8", localise("menu.pauseMenuScreen." .. navigationButtonId))
      navigationButtonIcon = imageHelper:new(navigationButton, "images/interface/screens/pauseMenuScreen/tabIcons/" .. navigationButtonId .. ".png")
    end
    magnet:centerLeft(navigationButtonLabel, 6, -1, navigationButton)
    magnet:centerRight(navigationButtonIcon, 4, 0, navigationButton)
    
    local navigationButtonNavigation = navigations:createUseButtonNavigation(navigationButton, function(_obj)
      magnet:centerRight(focusArrow, -6, 0, _obj)
    end)
    rightGamepadNavigation:add(navigationButtonNavigation)
    inputHelper:addTouchable(navigationButton, inputHelper:getTouchListener({
      onHoldDuration = 600,
      onHold = navigationButtonShowScreenParamsOnHold and function(event)
        inputHelper:releaseWithinBounds(event.target)
      end,
      onReleaseWithinBounds = function(event)
        soundHelper:playSound("menuSelect")
        screenParams.previousRightNavigationIndex = i
        inputHelper:blockInput()
        transition.smallPress(event.target, function()
          inputHelper:unblockInput()
          if(navigationButtonIsMod) then
            pauseMenu:showScreenModloader(navigationButtonRequire)
          elseif navigationButtonId ~= "save" and navigationButtonId ~= "StyleCrystalShopScreen" then
            pauseMenu:showScreen(navigationButtonId, event.hasBeenHeld and navigationButtonShowScreenParamsOnHold or navigationButtonShowScreenParams)
          elseif navigationButtonId == "StyleCrystalShopScreen" then
            StyleCrystalShopScreenModeActionMenuOverlay:new(navigationButton, false):open()
          elseif playerStateHelper:isSaveBlocked() then
            MessagePopup:new(localise("menu.pauseMenuScreen.cantSaveNow"))
          else
            inputHelper:blockInput()
            UISaveBarBuilder:newForManualSave(function()
              inputHelper:unblockInput()
            end)
          end
        end)
      end
    }))
  end
  local squadContainerContainer = rectHelper:newContainerObject(parentGroup, {width = 170, height = 129})
  magnet:centerLeft(squadContainerContainer, 0, 0, centerContainer)
  local squadContainer, squadContainerContentGroup, squadContainerTopGroup = UIContainerBuilder:newGreySlimWithHeaderSpacing(squadContainerContainer, 170, 120)
  magnet:topCenter(squadContainer, 0, 2, squadContainerContainer)
  squadContainer:setHeaderText(localise("menu.pauseMenuScreen.squadContainer.headerText"))
  if device.isApple and device.height < 170 then
    squadContainerContainer:translate(0, debugSettings.showStyleCrystals and -7 or -6)
  end
  local showHoldItemButton
  local monsterButtons = {}
  local monsterButtonGroup = groupHelper:new(squadContainerContentGroup)
  local refreshMonsterButtons
  function refreshMonsterButtons()
    monsterButtons = {}
    groupHelper:clear(monsterButtonGroup)
    squadGamepadGridNavigation:clear()
    local squad = playerMonsters:getSquad()
    for i = 1, playerMonsters:getMaxSquadSize() do
      local xIndex, yIndex = gridHelper:indexToGrid(3, i)
      local currentMonster = squad[i]
      if not currentMonster then
        local emptyMonsterButton = monsterButtonBuilder:newEmpty(monsterButtonGroup, "hpAndSp", i, {alpha = 0.5})
        magnet:bottomLeft(emptyMonsterButton, 4 + (xIndex - 1) * 54, 7 + (2 - yIndex) * 50, squadContainer)
        squadGamepadGridNavigation:add(navigations:createNonFocusableNavigation(emptyMonsterButton))
      else
        do
          local currentMonsterButton = monsterButtonBuilder:new(monsterButtonGroup, "hpAndSp", currentMonster)
          magnet:bottomLeft(currentMonsterButton, 4 + (xIndex - 1) * 54, 7 + (2 - yIndex) * 50, squadContainer)
          local currentMonsterButtonNavigation = navigations:createUseButtonNavigation(currentMonsterButton, function(_obj)
            magnet:centerRight(focusArrow, -6, 0, _obj)
          end)
          squadGamepadGridNavigation:add(currentMonsterButtonNavigation)
          monsterButtons[#monsterButtons + 1] = currentMonsterButton
          local function onMonsterSwitch()
            monsterButtonPopupBuilder:newSilentClosable(playerMonsters:getSquad(), "hpAndSp", function(_monsterButton, _unblockInput, _closeMonsterButtonPopup)
              playerMonsters:swapWithinSquad(currentMonster, _monsterButton.monster)
              _closeMonsterButtonPopup(refreshMonsterButtons)
            end, {
              contextText = localise("menu.pauseMenuScreen.onMonsterSwitch.monsterButtonPopup.contextText", {
                monster = currentMonster:getDisplayName()
              }),
              shouldDisableMonsterButtonFunction = function(_monster)
                return _monster == currentMonster
              end
            })
          end
          local isDragging = false
          local dragHoveredMonsterButton
          local function setDragHoveredMonsterButton(_monsterButton)
            dragHoveredMonsterButton = _monsterButton
            _monsterButton:setSwapping(true)
            currentMonsterButton:setSwapping(true)
          end
          local function tryUnsetDragHoveredMonsterButton()
            if dragHoveredMonsterButton then
              local nonNilDragHoveredMonsterButton = dragHoveredMonsterButton
              nonNilDragHoveredMonsterButton:setSwapping(false)
              currentMonsterButton:setSwapping(false)
              dragHoveredMonsterButton = nil
            end
          end
          inputHelper:addTouchable(currentMonsterButton, inputHelper:getTouchListener({
            onHoldDuration = 400,
            onHold = function()
              if #playerMonsters:getSquad() > 1 then
                onMonsterSwitch()
              end
            end,
            onMove = touches.ifMovedAtLeast(5, function(event)
              isDragging = true
              local hoveredMonsterButtonInEvent = array.findByFunction(monsterButtons, function(_monsterButton)
                return display:isWithin(_monsterButton, event.x, event.y, {bottom = 2})
              end)
              if hoveredMonsterButtonInEvent == dragHoveredMonsterButton then
                return
              end
              if hoveredMonsterButtonInEvent and hoveredMonsterButtonInEvent ~= currentMonsterButton then
                tryUnsetDragHoveredMonsterButton()
                setDragHoveredMonsterButton(hoveredMonsterButtonInEvent)
              else
                tryUnsetDragHoveredMonsterButton()
              end
            end),
            onRelease = function(event)
              if isDragging then
                isDragging = false
                if not dragHoveredMonsterButton then
                  tryUnsetDragHoveredMonsterButton()
                else
                  playerMonsters:swapWithinSquad(currentMonster, dragHoveredMonsterButton.monster)
                  refreshMonsterButtons()
                end
              end
            end,
            onReleaseWithinBounds = function(event)
              soundHelper:playSound("menuSelect")
              screenParams.previousSquadNavigationXIndex, screenParams.previousSquadNavigationYIndex = xIndex, yIndex
              local function onMonsterSummary()
                pauseMenu:showScreen(monsterSummaryScreen:getScreenEditable(squad, currentMonster, function(_index)
                  screenParams.previousSquadNavigationXIndex, screenParams.previousSquadNavigationYIndex = gridHelper:indexToGrid(3, _index)
                end))
              end
              local function onMonsterGiveHoldItem()
                local holdItems = playerInventory:getItemArrayByInstanceOf("abstractHoldItem")
                if #holdItems == 0 then
                  MessagePopup:new(localise("menu.monsterSummaryScreen.monsterSummaryHoldItemTabDetails.holdItemButton.noHoldItems"))
                else
                  pauseMenu:showScreen(itemScreen:getScreenForSettingHoldItemOnMonster(holdItems, currentMonster))
                end
              end
              local function onMonsterRemoveHoldItem()
                confirmPopupBuilder:new({
                  text = localise("menu.pauseMenuScreen.onMonsterRemoveHoldItem.confirmPopup", {
                    monster = currentMonster:getDisplayName(),
                    item = currentMonster:getHoldItem():getName()
                  }),
                  createCustomContentFunction = function()
                    local itemIcon, _, _ = currentMonster:getHoldItem():createIcon()
                    return itemIcon
                  end,
                  onYes = function()
                    currentMonster:removeHoldItemAndSendToInventory()
                    refreshMonsterButtons()
                  end
                })
              end
              local function onMonsterMoveHoldItem()
                local currentMonsterHoldItemUID = currentMonster:getHoldItemUID()
                local currentMonsterHoldItem = itemList[currentMonsterHoldItemUID]
                monsterButtonPopupBuilder:newSilentClosable(playerMonsters:getSquad(), "hpAndSp", function(_monsterButton, _unblockInput, _closeMonsterButtonPopup)
                  local selectedMonsterHoldItemUID = _monsterButton.monster:getHoldItemUID()
                  if not selectedMonsterHoldItemUID then
                    currentMonster:removeHoldItem()
                    _monsterButton.monster:setHoldItemByUID(currentMonsterHoldItemUID)
                    _closeMonsterButtonPopup(refreshMonsterButtons)
                  else
                    moveHoldItemPopupBuilder:new(_monsterButton.monster, {
                      onAfterReplace = function()
                        currentMonster:removeHoldItem()
                        _monsterButton.monster:removeHoldItemAndSendToInventory()
                        _monsterButton.monster:setHoldItemByUID(currentMonsterHoldItemUID)
                        _closeMonsterButtonPopup(refreshMonsterButtons)
                      end,
                      onAfterSwap = function()
                        currentMonster:setHoldItemByUID(selectedMonsterHoldItemUID)
                        _monsterButton.monster:setHoldItemByUID(currentMonsterHoldItemUID)
                        _closeMonsterButtonPopup(refreshMonsterButtons)
                      end
                    })
                  end
                end, {
                  onBeforeMonsterButtonMessage = function(_monster)
                    return currentMonsterHoldItem:onBeforeMonsterUseMessage("holdItemUse", _monster)
                  end,
                  shouldDisableMonsterButtonFunction = function(_monster)
                    return _monster == currentMonster
                  end,
                  contextText = localise("menu.pauseMenuScreen.onMonsterMoveHoldItem.monsterButtonPopup.contextText", {
                    monster = currentMonster:getDisplayName(),
                    item = currentMonster:getHoldItem():getName()
                  })
                })
              end
              inputHelper:blockInput()
              transition.smallPress(event.target, function()
                inputHelper:unblockInput()
                pauseMenuScreenMonsterActionMenuOverlayBuilder:new(currentMonster, currentMonsterButton, onMonsterSummary, onMonsterSwitch, function()
                  monsterUtility:showMonsterNicknameKeyboardOverlay(currentMonster, refreshMonsterButtons)
                end, onMonsterGiveHoldItem, onMonsterMoveHoldItem, onMonsterRemoveHoldItem, function()
                  monsterUtility:showMonsterReleaseConfirmPopupWithByeByeMessage(localise("menu.pauseMenuScreen.areYouSureReleaseMonster", {
                    monster = currentMonster:getDisplayName()
                  }), currentMonster, function()
                    playerMonsters:releaseFromSquad(currentMonster)
                    refreshMonsterButtons()
                  end, nil)
                end):open()
              end)
            end
          }))
        end
      end
    end
    showHoldItemButton = display.remove(showHoldItemButton)
    local monsterWithHoldItem = array.findByFunction(squad, function(_monster)
      return _monster:getHoldItemUID()
    end)
    if playerSettings:getDifficultyObject():shouldDisableHoldItems() or not monsterWithHoldItem then
      showHoldItemSecondExtraButtonNavigation:setOnSecondExtra(nil)
      squadGamepadHoldItemButtonParentNavigation:setChild(nil)
    else
      showHoldItemButton = UIContainerBuilder:new(squadContainerContainer, UIContainerStyle.blue, 14, 14)
      magnet:bottomCenter(showHoldItemButton, 0, -7, squadContainer)
      local showHoldItemIcon = imageHelper:new(showHoldItemButton, "images/interface/icons/otherIcons/holdItemIndicatorIcon.png")
      magnet:center(showHoldItemIcon, 0, 0, showHoldItemButton)
      showHoldItemSecondExtraButtonNavigation:setOnSecondExtra(navigations.mapKeyEventToTouches(showHoldItemButton))
      squadGamepadHoldItemButtonParentNavigation:setChild(navigations:createUseButtonNavigation(showHoldItemButton, function(_obj)
        magnet:centerRight(focusArrow, -12, 2, _obj)
      end))
      inputHelper:addTouchable(showHoldItemButton, inputHelper:getTouchListener({
        onPress = function()
          showHoldItemButton:setStyle(UIContainerStyle.blueSelected)
          array.forEach(monsterButtons, function(_monsterButton)
            _monsterButton:convertHoldItemIndicatorToIcon()
          end)
        end,
        onRelease = function()
          showHoldItemButton:setStyle(UIContainerStyle.blue)
          array.forEach(monsterButtons, function(_monsterButton)
            _monsterButton:convertHoldItemIconToIndicator()
          end)
        end
      }))
    end
    squadGamepadNavigation:reloadFocus()
    squadNumericFunctionKeyParentNavigation:setChild(navigations:createNumericFunctionKeyTouchNavigation(squadGamepadGridNavigation:getChildObjects()))
  end
  refreshMonsterButtons()
  parentGroup:addGlobalNavigation(navigations:createNumericKeyTouchNavigation(rightGamepadNavigation:getChildObjects()))
  parentGroup:setTitle(playerSettings:getPlayerName())
  function parentGroup:inTransition(_onComplete)
    GameCenter:showAccessPoint("bottomLeading", false)
    transition.fromRightOrFadeIn(navigationButtonGroup, 100, outQuad, {
      delay = gameSettings:shouldReduceMotion() and 0 or 100
    })
    transition.fromLeftOrFadeIn(squadContainerContainer, 200, outQuad, _onComplete)
  end
  function parentGroup:outTransition(_isBackwards, _onComplete)
    GameCenter:hideAccessPoint()
    transition.cancel("pauseMenuScreen")
    transition.toRightOrFadeOut(navigationButtonGroup, 150, outQuad)
    transition.toLeftOrFadeOut(squadContainerContainer, 150, outQuad, _onComplete)
  end
  return parentGroup
end
return t
