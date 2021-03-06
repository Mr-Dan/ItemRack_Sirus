ItemRack.Docking = {} -- temporary table for current docking potential

ItemRack.BracketInfo = { ["TOP"] = {36,12,.25,.75,0,.25}, -- bracket construction info
					["BOTTOM"] = {36,12,.25,.75,.75,1}, -- cx,cy,left,right,top,bottom
					["LEFT"] = {12,36,0,.25,.25,.75},
					["RIGHT"] = {12,36,.75,1,.25,.75},
					["TOPLEFT"] = {12,12,0,.25,0,.25},
					["TOPRIGHT"] = {12,12,.75,1,0,.25},
					["BOTTOMLEFT"] = {12,12,0,.25,.75,1},
					["BOTTOMRIGHT"] = {12,12,.75,1,.75,1}
				  }

ItemRack.ReflectClicked = {} -- buttons clicked (checked)
ItemRack.LockedButtons = {} -- buttons locked (desaturated)

ItemRack.NewAnchor = nil

function ItemRack.InitButtons()
	ItemRackUser.Buttons = ItemRackUser.Buttons or {}

	ItemRack.oldPaperDollItemSlotButton_OnModifiedClick = PaperDollItemSlotButton_OnModifiedClick
	PaperDollItemSlotButton_OnModifiedClick = ItemRack.newPaperDollItemSlotButton_OnModifiedClick

	ItemRack.oldCharacterAmmoSlot_OnClick = CharacterAmmoSlot:GetScript("OnClick")
	CharacterAmmoSlot:SetScript("OnClick",ItemRack.newCharacterAmmoSlot_OnClick)

	ItemRack.oldCharacterModelFrame_OnMouseUp = CharacterModelFrame_OnMouseUp
	CharacterModelFrame_OnMouseUp = ItemRack.newCharacterModelFrame_OnMouseUp

	local button
	for i=0,20 do
		button = getglobal("ItemRackButton"..i)
		if i<20 then
			button:SetAttribute("type","item")
			button:SetAttribute("slot",i)
		else
			button:SetAttribute("shift-slot*",ATTRIBUTE_NOOP)
			button:SetAttribute("alt-slot*",ATTRIBUTE_NOOP)
		end
		button:RegisterForDrag("LeftButton","RightButton")
		button:RegisterForClicks("LeftButtonUp","RightButtonUp")
--		button:SetAttribute("alt-slot*",ATTRIBUTE_NOOP)
--		button:SetAttribute("shift-slot*",ATTRIBUTE_NOOP)
		ItemRack.MenuMouseoverFrames["ItemRackButton"..i]=1
	end

	ItemRack.CreateTimer("ButtonsDocking",ItemRack.ButtonsDocking,.2,1) -- (repeat) on while buttons docking
	ItemRack.CreateTimer("MenuDocking",ItemRack.MenuDocking,.2,1) -- (repeat) on while menu docking

	ItemRackMenuFrame:SetScript("OnMouseDown",ItemRack.MenuFrameOnMouseDown)
	ItemRackMenuFrame:SetScript("OnMouseUp",ItemRack.MenuFrameOnMouseUp)
	ItemRackMenuFrame:EnableMouse(1)

	ItemRack.CreateTimer("ReflectClickedUpdate",ItemRack.ReflectClickedUpdate,.2,1)		

	ItemRackFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	
	ItemRackFrame:RegisterEvent("ITEM_LOCK_CHANGED")
	ItemRackFrame:RegisterEvent("UPDATE_BINDINGS")
	ItemRack.ReflectMainScale()
	ItemRack.ConstructLayout()
	

	ItemRack.ReflectCooldownFont()
	ItemRack.KeyBindingsChanged()
	
end



function ItemRack.newPaperDollItemSlotButton_OnModifiedClick(button)
	if IsAltKeyDown() then
		ItemRack.ToggleButton(this:GetID())
	else
		ItemRack.oldPaperDollItemSlotButton_OnModifiedClick(button)
	end
end

function ItemRack.newCharacterAmmoSlot_OnClick()
	if IsAltKeyDown() then
		ItemRack.newPaperDollItemSlotButton_OnModifiedClick()
	elseif arg1=="LeftButton" then
		-- only call old function if LeftButton. We never UseInventoryItem(0) (in theory)
		ItemRack.oldCharacterAmmoSlot_OnClick()
	end
end

function ItemRack.newCharacterModelFrame_OnMouseUp(button)
	if IsAltKeyDown() then
		ItemRack.ToggleButton(20)
	else
		ItemRack.oldCharacterModelFrame_OnMouseUp(button)
	end
end

function ItemRack.AddButton(id)
	ItemRackUser.Buttons[id] = {}
	local button = getglobal("ItemRackButton"..id)
	button:ClearAllPoints()
	if ItemRack.NewAnchor and ItemRackUser.Buttons[ItemRack.NewAnchor] then
		ItemRackUser.Buttons[id].Side = "LEFT"
		ItemRackUser.Buttons[id].DockTo = ItemRack.NewAnchor
		local dockinfo = ItemRack.DockInfo[ItemRackUser.Buttons[id].Side]
		button:SetPoint("LEFT","ItemRackButton"..ItemRack.NewAnchor,"RIGHT",dockinfo.xoff*(ItemRackUser.ButtonSpacing or 4),dockinfo.yoff*(ItemRackUser.ButtonSpacing or 4))
	else
		button:SetPoint("CENTER",UIParent,"CENTER")
	end
	ItemRack.NewAnchor = id
	getglobal("ItemRackButton"..id.."Icon"):SetTexture(ItemRack.GetTextureBySlot(id))
	button:Show()
	
	if id==20 then
		ItemRack.UpdateCurrentSet()
		
	end
end

function ItemRack.RemoveButton(id)
	if InCombatLockdown() then
		ItemRack.Print("Sorry, you can't add or remove buttons during combat.")
		return
	end
	local child,xpos,ypos
	local dockedTo = ItemRackUser.Buttons[id].DockedTo
	for i in pairs(ItemRackUser.Buttons) do
		if ItemRackUser.Buttons[i].DockTo == id then
			ItemRackUser.Buttons[i].DockTo = nil
			ItemRackUser.Buttons[i].Side = nil
			child = getglobal("ItemRackButton"..i)
			xpos,ypos = child:GetLeft(),child:GetTop()
			child:ClearAllPoints()
			child:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",xpos,ypos)
			ItemRackUser.Buttons[i].Left = xpos
			ItemRackUser.Buttons[i].Top = ypos
		end
	end
	ItemRack.NewAnchor = nil
	ItemRackUser.Buttons[id] = nil
	getglobal("ItemRackButton"..id):Hide()
end

function ItemRack.ToggleButton(id)
	if InCombatLockdown() then
		ItemRack.Print("Sorry, you can't add or remove buttons during combat.")
	elseif ItemRackUser.Buttons[id] then
		ItemRack.RemoveButton(id)
	else
		ItemRack.AddButton(id)
	end
end

--[[ Button Movement ]]

function ItemRack.Near(v1,v2)
	if v1 and v2 and math.abs(v1-v2)<12 then
		return 1
	end
end

-- which: Main/Menu, side="LEFT"/"TOPRIGHT"/etc, relativeTo=button, corner="TOPLEFT"/"TOPRIGHT"/etc
-- shapes ItemRackMainBracket or ItemRackMenuBracket to a side and draws it there
function ItemRack.MoveBracket(which,side,relativeTo,corner)
	local bracket = getglobal("ItemRack"..which.."Bracket")
	if bracket then
		local texture = getglobal("ItemRack"..which.."BracketTexture")
		local info = ItemRack.BracketInfo[side]
		bracket:SetWidth(info[1])
		bracket:SetHeight(info[2])
		texture:SetTexCoord(info[3],info[4],info[5],info[6])
		bracket:ClearAllPoints()
		bracket:SetPoint(corner,relativeTo,corner)
		bracket:SetParent(relativeTo)
		bracket:SetAlpha(1)
		bracket:Show()
	end
end

function ItemRack.HideBrackets()
	ItemRackMainBracket:Hide()
	ItemRackMenuBracket:Hide()
	ItemRack.Docking.Side = nil
	ItemRack.Docking.From = nil
	ItemRack.Docking.To = nil
end

-- returns true if candidate is not already docked to button in a docking chain
function ItemRack.LegalDock(button,candidate)
	while ItemRackUser.Buttons[candidate].DockTo do
		if ItemRackUser.Buttons[candidate].DockTo==button then
			return nil -- candidate is already docked somehow to this button
		end
		candidate = ItemRackUser.Buttons[candidate].DockTo
	end
	return 1
end

-- return button if it's not docked, or the original button of dock chain if docked
function ItemRack.FindParent(button)
	while ItemRackUser.Buttons[button].DockTo do
		if not ItemRackUser.Buttons[button].DockTo then
			return button
		end
		button = ItemRackUser.Buttons[button].DockTo
	end
	return button
end

-- while buttons drag, this function periodically lights up docking possibilities
function ItemRack.ButtonsDocking()

	local button,dock = ItemRack.ButtonMoving
	local buttonID = button:GetID()
	local near = ItemRack.Near
	if not button then
		ItemRack.StopTimer("ButtonsDocking")
		return
	end

	ItemRack.HideBrackets()

	for i in pairs(ItemRackUser.Buttons) do
		dock = getglobal("ItemRackButton"..i)
		if near(button:GetLeft(),dock:GetRight()) and (near(button:GetTop(),dock:GetTop()) or near(button:GetBottom(),dock:GetBottom())) and ItemRack.LegalDock(buttonID,i) then
			ItemRack.MoveBracket("Main","LEFT",button,"TOPLEFT")
			ItemRack.MoveBracket("Menu","RIGHT",dock,"TOPRIGHT")
			ItemRack.Docking.Side = "LEFT"
		elseif near(button:GetRight(),dock:GetLeft()) and (near(button:GetTop(),dock:GetTop()) or near(button:GetBottom(),dock:GetBottom())) and ItemRack.LegalDock(buttonID,i) then
			ItemRack.MoveBracket("Main","LEFT",dock,"TOPLEFT")
			ItemRack.MoveBracket("Menu","RIGHT",button,"TOPRIGHT")
			ItemRack.Docking.Side = "RIGHT"
		elseif near(button:GetTop(),dock:GetBottom()) and (near(button:GetLeft(),dock:GetLeft()) or near(button:GetRight(),dock:GetRight())) and ItemRack.LegalDock(buttonID,i) then
			ItemRack.MoveBracket("Main","TOP",button,"TOPLEFT")
			ItemRack.MoveBracket("Menu","BOTTOM",dock,"BOTTOMLEFT")
			ItemRack.Docking.Side = "TOP"
		elseif near(button:GetBottom(),dock:GetTop()) and (near(button:GetLeft(),dock:GetLeft()) or near(button:GetRight(),dock:GetRight())) and ItemRack.LegalDock(buttonID,i) then
			ItemRack.MoveBracket("Main","TOP",dock,"TOPLEFT")
			ItemRack.MoveBracket("Menu","BOTTOM",button,"BOTTOMLEFT")
			ItemRack.Docking.Side = "BOTTOM"
		end

		if ItemRack.Docking.Side then
			ItemRack.Docking.From = buttonID
			ItemRack.Docking.To = i
			break
		end
	end
end

function ItemRack.StartMovingButton()
	if ItemRackUser.Locked=="ON" then return end
	if IsShiftKeyDown() then
		ItemRack.ButtonMoving = this
	else
		ItemRack.ButtonMoving = getglobal("ItemRackButton"..ItemRack.FindParent(this:GetID()))
	end
	for i in pairs(ItemRackUser.Buttons) do -- highlight parent buttons
		if not ItemRackUser.Buttons[i].DockTo then
			getglobal("ItemRackButton"..i):LockHighlight()
		end
	end
	ItemRack.ButtonMoving:StartMoving()
	ItemRack.StartTimer("ButtonsDocking")
end

function ItemRack.StopMovingButton()
	if ItemRackUser.Locked=="ON" then return end
	ItemRack.StopTimer("ButtonsDocking")
	ItemRack.ButtonMoving:StopMovingOrSizing()
	ItemRack.NewAnchor = nil
	local buttonID = ItemRack.ButtonMoving:GetID()
	if ItemRack.Docking.Side then
		ItemRack.ButtonMoving:ClearAllPoints()
		local dockinfo = ItemRack.DockInfo[ItemRack.Docking.Side]
		ItemRack.ButtonMoving:SetPoint(ItemRack.Docking.Side,"ItemRackButton"..ItemRack.Docking.To,ItemRack.OppositeSide[ItemRack.Docking.Side],dockinfo.xoff*(ItemRackUser.ButtonSpacing or 4),dockinfo.yoff*(ItemRackUser.ButtonSpacing or 4))
		ItemRackUser.Buttons[buttonID].DockTo=ItemRack.Docking.To
		ItemRackUser.Buttons[buttonID].Side=ItemRack.Docking.Side
		ItemRackUser.Buttons[buttonID].Left = nil
		ItemRackUser.Buttons[buttonID].Top = nil
	else
		ItemRackUser.Buttons[buttonID].DockTo=nil
		ItemRackUser.Buttons[buttonID].Side=nil
		ItemRackUser.Buttons[buttonID].Left = ItemRack.ButtonMoving:GetLeft()
		ItemRackUser.Buttons[buttonID].Top = ItemRack.ButtonMoving:GetTop()
	end
	for i in pairs(ItemRackUser.Buttons) do
		getglobal("ItemRackButton"..i):UnlockHighlight()
	end
	ItemRack.HideBrackets()
end

function ItemRack.ConstructLayout()

	if InCombatLockdown() then
		table.insert(ItemRack.RunAfterCombat,"ConstructLayout")
		return
	end
	local button,dockinfo

	-- flag all buttons to be drawn
	for i in pairs(ItemRackUser.Buttons) do
		ItemRackUser.Buttons[i].needsDrawn = 1
	end

	-- draw undocked buttons first
	for i in pairs(ItemRackUser.Buttons) do
		if ItemRackUser.Buttons[i].needsDrawn and not ItemRackUser.Buttons[i].DockTo then
--			button = ItemRack.CreateButton(ItemRackUser.Buttons[i].name,i,ItemRackUser.Buttons[i].type)
			button = getglobal("ItemRackButton"..i)
			ItemRackUser.Buttons[i].needsDrawn = nil
			button:ClearAllPoints()
			if ItemRackUser.Buttons[i].Left then
				button:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",ItemRackUser.Buttons[i].Left,ItemRackUser.Buttons[i].Top)
			else
				button:SetPoint("CENTER","UIParent","CENTER")
			end
			button:Show()
		end
	end
	local done
	-- iterate over docked buttons in the order they're docked
	while not done do
		done = 1
		for i in pairs(ItemRackUser.Buttons) do
			if ItemRackUser.Buttons[i].needsDrawn and not ItemRackUser.Buttons[ItemRackUser.Buttons[i].DockTo].needsDrawn then -- if this button's DockTo is already drawn
--				button = ItemRack.CreateButton(ItemRackUser.Buttons[i].name,i,ItemRackUser.Buttons[i].type)
				button = getglobal("ItemRackButton"..i)
				ItemRackUser.Buttons[i].needsDrawn = nil
				button:ClearAllPoints()
				dockinfo = ItemRack.DockInfo[ItemRackUser.Buttons[i].Side]
				button:SetPoint(ItemRackUser.Buttons[i].Side,"ItemRackButton"..ItemRackUser.Buttons[i].DockTo,ItemRack.OppositeSide[ItemRackUser.Buttons[i].Side],dockinfo.xoff*(ItemRackUser.ButtonSpacing or 4),dockinfo.yoff*(ItemRackUser.ButtonSpacing or 4))
				button:Show()
				done = nil
			end
		end
	end
	ItemRack.UpdateButtons()
end

function ItemRack.UpdateButtons()
	for i in pairs(ItemRackUser.Buttons) do
		if i<20 then
			getglobal("ItemRackButton"..i.."Icon"):SetTexture(ItemRack.GetTextureBySlot(i))
		end
		if i==0 then
			local id = ItemRack.GetID(0)
			if id~=0 then
				id = string.match(id,"(%d+)")
				ItemRackButton0Count:SetText(GetItemCount(id))
			else
				ItemRackButton0Count:SetText("")
			end
		end
	end
	ItemRack.UpdateCurrentSet()
	
end

--[[ Menu ]]

function ItemRack.DockMenuToButton(button)
	

	local parent = ItemRack.FindParent(button)
	-- get docking and orientation from parent of this button group, use defaults if none defined
	local menuDock = ItemRackUser.Buttons[parent].MenuDock or "BOTTOMLEFT"
	local mainDock = ItemRackUser.Buttons[parent].MainDock or "TOPLEFT"
	local menuOrient = ItemRackUser.Buttons[parent].MenuOrient or "VERTICAL"
	ItemRack.DockWindows(menuDock,getglobal("ItemRackButton"..button),mainDock,menuOrient,button)
end

function ItemRack.OnEnterButton()
	ItemRack.InventoryTooltip()
	
	local button = this:GetID()
	ItemRack.DockMenuToButton(button)
	ItemRack.BuildMenu(button)
end

--[[ Menu Docking ]]

function ItemRack.MenuFrameOnMouseDown()
	if arg1=="LeftButton" then
		ItemRack.MenuDockingTo = ItemRack.menuMovable
		if ItemRack.MenuDockingTo then
			for i in pairs(ItemRackUser.Buttons) do
				if i~=ItemRack.MenuDockingTo then
					getglobal("ItemRackButton"..i):SetAlpha(ItemRackUser.Alpha/3)
				end
			end
			ItemRackMenuFrame:StartMoving()
			ItemRack.StartTimer("MenuDocking")
		end
	end
end

function ItemRack.MenuFrameOnMouseUp()
	if arg1=="LeftButton" and ItemRack.MenuDockingTo then
		ItemRack.StopTimer("MenuDocking")
		for i in pairs(ItemRackUser.Buttons) do
			getglobal("ItemRackButton"..i):SetAlpha(ItemRackUser.Alpha)
		end
		local parent = ItemRack.FindParent(ItemRack.MenuDockingTo)
		ItemRackUser.Buttons[parent].MenuDock = ItemRack.menuDock
		ItemRackUser.Buttons[parent].MainDock = ItemRack.mainDock
		ItemRack.DockMenuToButton(ItemRack.MenuDockingTo)
		ItemRack.BuildMenu()
		ItemRack.MenuDockingTo = nil
		ItemRackMenuFrame:StopMovingOrSizing()
		ItemRack.HideBrackets()
	elseif arg1=="RightButton" then
		if ItemRack.menuMovable then
			local parent = ItemRack.FindParent(ItemRack.menuMovable)
			local button = ItemRackUser.Buttons[parent]
			button.MenuOrient = (button.MenuOrient=="VERTICAL") and "HORIZONTAL" or "VERTICAL"
			ItemRack.DockMenuToButton(ItemRack.menuMovable)
			ItemRack.BuildMenu()
		end
	end
end

function ItemRack.MenuDocking()

	local main = getglobal("ItemRackButton"..ItemRack.MenuDockingTo)
	local menu = ItemRackMenuFrame
	local mainscale = main:GetEffectiveScale()
	local menuscale = menu:GetEffectiveScale()
	local near = ItemRack.Near

	if near(main:GetRight()*mainscale,menu:GetLeft()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetTop()*menuscale) then
			ItemRack.mainDock = "TOPRIGHT"
			ItemRack.menuDock = "TOPLEFT"
		elseif near(main:GetBottom()*mainscale,menu:GetBottom()*menuscale) then
			ItemRack.mainDock = "BOTTOMRIGHT"
			ItemRack.menuDock = "BOTTOMLEFT"
		end
	elseif near(main:GetLeft()*mainscale,menu:GetRight()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetTop()*menuscale) then
			ItemRack.mainDock = "TOPLEFT"
			ItemRack.menuDock = "TOPRIGHT"
		elseif near(main:GetBottom()*mainscale,menu:GetBottom()*menuscale) then
			ItemRack.mainDock = "BOTTOMLEFT"
			ItemRack.menuDock = "BOTTOMRIGHT"
		end
	elseif near(main:GetRight()*mainscale,menu:GetRight()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetBottom()*menuscale) then
			ItemRack.mainDock = "TOPRIGHT"
			ItemRack.menuDock = "BOTTOMRIGHT"
		elseif near(main:GetBottom()*mainscale,menu:GetTop()*menuscale) then
			ItemRack.mainDock = "BOTTOMRIGHT"
			ItemRack.menuDock = "TOPRIGHT"
		end
	elseif near(main:GetLeft()*mainscale,menu:GetLeft()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetBottom()*menuscale) then
			ItemRack.mainDock = "TOPLEFT"
			ItemRack.menuDock = "BOTTOMLEFT"
		elseif near(main:GetBottom()*mainscale,menu:GetTop()*menuscale) then
			ItemRack.mainDock = "BOTTOMLEFT"
			ItemRack.menuDock = "TOPLEFT"
		end
	end
	ItemRack.MoveBracket("Main",ItemRack.mainDock,main,ItemRack.mainDock)
	ItemRack.MoveBracket("Menu",ItemRack.menuDock,menu,ItemRack.menuDock)
end

--[[ Using buttons ]]

function ItemRack.ButtonPostClick()
	this:SetChecked(0)
	local id = this:GetID()

	if IsShiftKeyDown() then
		if id<20 then
			if ChatFrameEditBox:IsVisible() then
				ChatFrameEditBox:Insert(GetInventoryItemLink("player",id))
			end
		elseif ItemRackUser.CurrentSet then
			ItemRack.UnequipSet(ItemRackUser.CurrentSet)
		end
	elseif IsAltKeyDown() then
	
			if not ItemRackUser.Queues[id] then
				LoadAddOn("ItemRackOptions")
				ItemRackOptFrame:Show()
				ItemRackOpt.TabOnClick(4)
				ItemRackOpt.SetupQueue(id)
			end
			ItemRackUser.QueuesEnabled[id] = not ItemRackUser.QueuesEnabled[id] and 1 or nil
		
			
		
			
		end
	if id<20 then
		ItemRack.ReflectItemUse(id)
	elseif id==20 then
		if arg1=="LeftButton" and ItemRackUser.CurrentSet then
			if ItemRackSettings.EquipToggle=="ON" then
				ItemRack.ToggleSet(ItemRackUser.CurrentSet)
			else
				ItemRack.EquipSet(ItemRackUser.CurrentSet)
				ItemRack.EquipSet(ItemRackUser.CurrentSet)

			end
		else
			ItemRack.ToggleOptions(2) -- summon set options
		end
	end
end

function ItemRack.ReflectClickedUpdate()
	local reflect = ItemRack.ReflectClicked
	local found
	for i in pairs(reflect) do
		reflect[i] = reflect[i] - .2
		if reflect[i]<0 then
			getglobal("ItemRackButton"..i):SetChecked(0)
			reflect[i] = nil
		end
		found = 1
	end
	if not found then
		ItemRack.StopTimer("ReflectClickedUpdate")
	end
end




function ItemRack.UpdateButtonLocks()
	local isLocked
	for i in pairs(ItemRackUser.Buttons) do
		if i<20 then
			isLocked = IsInventoryItemLocked(i)
			alreadyLocked = ItemRack.LockedButtons[i]
			if isLocked and not alreadyLocked then
				getglobal("ItemRackButton"..i.."Icon"):SetDesaturated(1)
				ItemRack.LockedButtons[i] = 1
			elseif not isLocked and alreadyLocked then
				getglobal("ItemRackButton"..i.."Icon"):SetDesaturated(0)
				ItemRack.LockedButtons[i] = nil
			end
		end
	end
end

--[[ Button menu ]]

function ItemRack.ButtonMenuOnClick()

	if this==ItemRackButtonMenuClose then
		ItemRack.RemoveButton(ItemRack.menuOpen)
	elseif this==ItemRackButtonMenuOptions then
		ItemRack.ToggleOptions()
	elseif this==ItemRackButtonMenuLock then
		ItemRackUser.Locked = ItemRackUser.Locked=="ON" and "OFF" or "ON"
		ItemRack.ReflectLock()

	end
end

function ItemRack.ReflectMainScale(changing)
	if InCombatLockdown() then
		table.insert(ItemRack.RunAfterCombat,"ReflectMainScale")
		return
	end
	local scale = ItemRackUser.MainScale or 1
	local button
	for i=0,20 do
		button = ItemRackUser.Buttons[i]
		if not changing or not button or not button.Left then
			getglobal("ItemRackButton"..i):SetScale(scale)
		else
			local frame = getglobal("ItemRackButton"..i)
			local oldscale = frame:GetScale() or 1
			local framex = frame:GetLeft()*oldscale
			local framey = frame:GetTop()*oldscale
			frame:SetScale(scale)
			frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",framex/scale,framey/scale)
			ItemRackUser.Buttons[i].Left = framex/scale -- frame:GetLeft()
			ItemRackUser.Buttons[i].Top = framey/scale -- frame:GetTop()
		end
	end
end







--[[ Key binding display ]]

function ItemRack.KeyBindingsChanged()
	local key
	for i in pairs(ItemRackUser.Buttons) do
		
			getglobal("ItemRackButton"..i.."HotKey"):SetText("")
		
	end
end

function ItemRack.ResetButtons()
	for i in pairs(ItemRackUser.Buttons) do
		ItemRack.RemoveButton(i)
	end
	ItemRackUser.Alpha = 1
	ItemRackUser.Locked = "OFF"
	ItemRackUser.MainScale = 1
	ItemRackUser.MenuScale = .85
	if ItemRackOpt then
		ItemRackOpt.UpdateSlider("Alpha")
		ItemRackOpt.UpdateSlider("MenuScale")
		ItemRackOpt.UpdateSlider("MainScale")
	end
end
