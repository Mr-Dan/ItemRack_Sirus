ItemRackOpt = {
	Icons = {}, -- list of all icons possible for a set
	Inv = {}, -- 0-19 currently chosen items per slot
	HoldInv = {}, -- 0-19 ItemRackOpt.Inv held when picking set
	SetList = {}, -- numerically-indexed list of set names
	selectedIcon = 0,
	prevFrame = nil, -- previous subframe a frame should return to (ItemRackOptSubFrame1-x)
	numSubFrames = 8, -- number of subframes
	slotOrder = {1,2,3,15,5,4,19,9,16,17,18,0,14,13,12,11,8,7,6,10,6,7,8,11,12,13,14,0,18,17,16,9,19,4,5,15,3,2},
	currentMarquee = 1,
}

ItemRack.CheckButtonLabels = {
	["ItemRackOptItemStatsPriorityText"] = "Приоритет",
	["ItemRackOptSetsHideCheckButtonText"] = "Спрятать",
	["ItemRackOptEventEditBuffAnyMountText"] = "Любая установка",
	["ItemRackOptEventEditBuffUnequipText"] = "Снять когда баф спадает",
	["ItemRackOptEventEditBuffNotInPVPText"] = "За исключением случаев PVP",
	["ItemRackOptEventEditStanceUnequipText"] = "Снять когда покидаешь стойку",
	["ItemRackOptEventEditZoneUnequipText"] = "Снять когда уходите из зоны",
	["ItemRackOptEventEditStanceNotInPVPText"] = "За исключением случаев PVP",
	["ItemRackOptSetsBDCheckButtonText"] = "ЧБ",
}

function ItemRackOpt.InvOnEnter()
	local id = this:GetID()
	if ItemRack.IsTimerActive("SlotMarquee") then
		getglobal("ItemRackOptInv"..id.."Icon"):SetVertexColor(1,1,1,1)
		return
	end
	local menuDock,mainDock,menuOrient = "TOPRIGHT","TOPLEFT","HORIZONTAL"
	if id==0 or (id>=16 and id<=18) then
		menuDock,mainDock,menuOrient = "TOPLEFT","BOTTOMLEFT","VERTICAL"
	elseif id>=6 and id<=14 and id~=9 then
		menuDock,mainDock = "TOPLEFT","TOPRIGHT"
	end
	ItemRack.DockWindows(menuDock,getglobal("ItemRackOptInv"..id),mainDock,menuOrient)
	ItemRack.BuildMenu(id,ItemRackSettings.EquipOnSetPick=="OFF" and 1)
	ItemRack.IDTooltip(ItemRackOpt.Inv[id].id)
end

function ItemRackOpt.InvOnLeave()
	ItemRack.ClearTooltip()
	if ItemRack.IsTimerActive("SlotMarquee") then
		getglobal("ItemRackOptInv"..this:GetID().."Icon"):SetVertexColor(.25,.25,.25,1)
	end
end

function ItemRackOpt.OnLoad()
	table.insert(UISpecialFrames,"ItemRackOptFrame")
	ItemRackOptInv0:SetScale(.8)
	for i=0,19 do
		ItemRackOpt.Inv[i] = {}
		ItemRackOpt.HoldInv[i] = {}
	end
	ItemRackOpt.PopulateInitialIcons()
	
	ItemRackOptSetsCurrentSet:EnableMouse(0)

	ItemRackOptFrameTitle:SetText("Днюша")

	-- OptInfo: this table drives the scrollable options. must be defined after xml defined (so buttons are non-nil)
	-- type = "label", "check", "number", "slider", "button" : what type of option element
	-- optset = ItemRackUser or ItemRackSettings : which table setting exists in
	-- variable = "Var" : index of the optset. ie, ItemRackUser.Locked is optset ItemRackUser, variable "Locked"
	-- depend = "Var" : option depends on optset["Var"]=="ON"
	-- label = "string" : text of option
	-- tooltip = "string" : tooltip shown on option
	-- button = frame : reference to the button shown on the option (editbox, slider or actual button)
	-- combatlock = 1/nil : whether option can be changed in combat (key bindings, hide when ooc, etc)
	ItemRackOpt.OptInfo = {
		{type="label",label=(UnitName("player")).." Настройки"},
		{type="check",optset=ItemRackUser,variable="Locked",label="Кнопки блокировки",tooltip="Заблокировать перемещение кнопок."},
		{type="number",optset=ItemRackUser,variable="ButtonSpacing",button=ItemRackOptButtonSpacing,label="Расстояние от кнопок",tooltip="Расстояние между кнопками.",combatlock=1},
		{type="slider",button=ItemRackOptButtonSpacingSlider,variable="ButtonSpacing",label="Расстояние от кнопок",tooltip="Расстояние между кнопками.", min=0, max=24, step=1, form="%d",combatlock=1},
		{type="number",optset=ItemRackUser,variable="Alpha",button=ItemRackOptAlpha,label="Прозрачность",tooltip="Прозрачность  кнопок и меню."},
		{type="slider",button=ItemRackOptAlphaSlider,variable="Alpha",label="Прозрачность",tooltip="Прозрачность кнопок и меню.", min=.1, max=1, step=.05, form="%.2f"},
		{type="number",optset=ItemRackUser,variable="MainScale",button=ItemRackOptMainScale,label="Размер кнопок",tooltip="Размеры кнопок элементов.",combatlock=1},
		{type="slider",button=ItemRackOptMainScaleSlider,variable="MainScale",label="Размер кнопок",tooltip="Размеры кнопок элементов.", min=.5, max=2, step=.05, form="%.2f",combatlock=1},

		{type="number",optset=ItemRackUser,variable="MenuScale",button=ItemRackOptMenuScale,label="Размер для меню",tooltip="Масштаб меню по отношению к кнопке, к которой оно пристыковано."},
		{type="slider",button=ItemRackOptMenuScaleSlider,variable="MenuScale",label="Размер для меню",tooltip="Размеры меню.", min=.5, max=2, step=.05, form="%.2f"},

		{type="check",optset=ItemRackUser,variable="SetMenuWrap",label="Обёртывание меню",tooltip="Отметьте этот флажок, чтобы установить фиксированное значение при обертывании меню в новую строку.  Снимите флажок, чтобы позволить ItemRack принять свое решение."},

		{type="number",optset=ItemRackUser,variable="SetMenuWrapValue",depend="SetMenuWrap",button=ItemRackOptSetMenuWrapValue,label="Когда обернуть",tooltip="Если установлен флажок 'Установить обертку меню', это количество пунктов меню перед оберткой в новую строку/столбец."},
		{type="slider",optset=ItemRackUser,button=ItemRackOptSetMenuWrapValueSlider,depend="SetMenuWrap",variable="SetMenuWrapValue",label="Когда обернуть",tooltip="Когда отмечен флажок 'Установить обертку меню', это количество пунктов меню перед оберткой в новую строку/столбец..", min=1, max=30, step=1, form="%d"},

		{type="label",label="Глобальные настройки"},
		{type="check",optset=ItemRackSettings,variable="ShowTooltips",label="Показать подсказки",tooltip="Показывать подсказки."},
		{type="check",optset=ItemRackSettings,variable="TinyTooltips",depend="ShowTooltips",label="Крошечные подсказки",tooltip="Уменьшите подсказки для отображения только имени."},
		{type="check",optset=ItemRackSettings,variable="TooltipFollow",depend="ShowTooltips",label="Подсказки рядом с указателем",tooltip="Показывать подсказки рядом с мышью."},
		{type="check",optset=ItemRackSettings,variable="AllowEmpty",label="Разрешить пустые слоты",tooltip="Добавление пустых слотов в меню надетых предметов."},
		{type="check",optset=ItemRackSettings,variable="AllowHidden",label="Скрытые комплекты",tooltip="Нажмите Alt+ ЛКМ, чтобы скрыть/показать их в меню. Удерживайте клавишу Alt при входе в меню, чтобы показать все пункты."},
		{type="check",optset=ItemRackSettings,variable="ShowMinimap",label="Показать кнопку миникарты",tooltip="Показать кнопку миникарты, чтобы получить доступ к параметрам или изменить набор"},
		{type="check",optset=ItemRackSettings,variable="SquareMinimap",depend="ShowMinimap",label="Квадратная миникарта",tooltip="Если вы используете квадратную миникарту"},
		{type="check",optset=ItemRackSettings,variable="MinimapTooltip",depend="ShowMinimap",label="Показать всплывающую подсказку на миникарте",tooltip="Показывает, набор команд рядом с кнопкой на миникарте"},
		{type="check",optset=ItemRackSettings,variable="EquipToggle",label="Переключение набора экипировки",tooltip="Если набор экипирован, то при нажатие на этот же комплект, будет экипирован прошлый комплект."},
		{type="check",optset=ItemRackSettings,variable="EquipOnSetPick",label="Снарядить в настройках",tooltip="Отметьте этот флажок, чтобы снарядить комплекты или отдельную экипировку при выборе слота в настройках или из выпадающего списка в вкладке комплекты."},
		{type="label",label=""},
		{type="button",button=ItemRackOptResetBar,label="Кнопка сброса",tooltip="Удалить все кнопки и восстановить интерфейс по умолчанию.",combatlock=1},
		
		{type="button",button=ItemRackOptResetEverything,label="Сбросить все",tooltip="Сотрите все настройки, наборы, чтобы восстановить аддон до состояния по умолчанию.",combatlock=1},
	}

	ItemRackOpt.InitializeSliders()
	ItemRackOpt.TabOnClick(1) -- start at tab 1 (config)

	ItemRackOptBindFrame:EnableMouseWheel(1)

	ItemRack.CreateTimer("SlotMarquee",ItemRackOpt.SlotMarquee,.1,1)

	for i in pairs(ItemRack.CheckButtonLabels) do
		getglobal(i):SetText(ItemRack.CheckButtonLabels[i])
		getglobal(i):SetTextColor(1,1,1,1)
	end

	
	
end

function ItemRackOpt.InitializeSliders()
	local opt,button
	for i=1,#(ItemRackOpt.OptInfo) do
		opt = ItemRackOpt.OptInfo[i]
		if opt.type=="slider" then
			opt.button:SetMinMaxValues(opt.min,opt.max)
			opt.button:SetValueStep(opt.step)
			opt.button:SetValue(ItemRackUser[opt.variable])
			getglobal(opt.button:GetName().."Min"):SetText(string.format(opt.form,opt.min))
			getglobal(opt.button:GetName().."Max"):SetText(string.format(opt.form,opt.max))
			opt.button.form = opt.form
			opt.button.min = opt.min
			opt.button.max = opt.max
			ItemRackOpt.UpdateSlider(opt.variable)
		end
	end
end

function ItemRackOpt.OnShow(setname)
	for i=0,19 do
		ItemRackOpt.Inv[i].id = ItemRack.GetID(i)
	end
	if ItemRackUser.CurrentSet and ItemRackUser.Sets[ItemRackUser.CurrentSet] then
		ItemRackOptSetsName:SetText(ItemRackUser.CurrentSet)
		ItemRackOpt.selectedIcon = ItemRackUser.Sets[ItemRackUser.CurrentSet].icon
		for i=0,19 do
			ItemRackOpt.Inv[i].selected = ItemRackUser.Sets[ItemRackUser.CurrentSet].equip[i] and 1 or nil
		end
	else
		ItemRackOptSetsName:SetText("")
		ItemRackOpt.selectedIcon = ItemRackOpt.Icons[math.random(#(ItemRackOpt.Icons)-20)+20]
	end
	ItemRackOpt.UpdateInv()
	ItemRackOptSubFrame5:Hide()
	ItemRackOpt.ListScrollFrameUpdate()
end

function ItemRackOpt.ChangeEditingSet()
	local setname = ItemRackUser.CurrentSet
	if setname and ItemRackUser.Sets[setname] then
		local set = ItemRackUser.Sets[setname].equip
		for i=0,19 do
			if set[i] then
				ItemRackOpt.Inv[i].id = set[i]
				ItemRackOpt.Inv[i].selected = 1
			else
				ItemRackOpt.Inv[i].selected = nil
				ItemRackOpt.Inv[i].id = ItemRack.GetID(i)
			end
		end
		ItemRackOptSetsName:SetText(setname)
		ItemRackOpt.selectedIcon = ItemRackUser.Sets[setname].icon
		ItemRackOpt.UpdateInv()
		ItemRackOptSubFrame5:Hide()
	end
end

function ItemRackOpt.UpdateInv()
	if ItemRack.IsTimerActive("SlotMarquee") then return end
	local icon,texture,border,item
	for i=0,19 do
		icon = getglobal("ItemRackOptInv"..i.."Icon")
		border = getglobal("ItemRackOptInv"..i.."Border")
		border:Hide()
		if ItemRackOpt.Inv[i].id~=0 then
			_,texture = ItemRack.GetInfoByID(ItemRackOpt.Inv[i].id)
			if ItemRackOpt.Inv[i].selected and ItemRack.GetCountByID(ItemRackOpt.Inv[i].id)==0 then
				if ItemRack.FindInBank(ItemRackOpt.Inv[i].id) then
					border:SetVertexColor(.3,.5,1)
				else
					border:SetVertexColor(1,.1,.1)
				end
				getglobal("ItemRackOptInv"..i.."Border"):Show()
			end
		else
			_,texture = GetInventorySlotInfo(ItemRack.SlotInfo[i].name)
		end
		icon:SetTexture(texture)
		item = getglobal("ItemRackOptInv"..i)
		item:UnlockHighlight()
		if ItemRackOpt.Inv[i].selected then
			icon:SetVertexColor(1,1,1)
			if ItemRackOpt.Inv[i].id==0 then
				item:LockHighlight()
			end
		else
			icon:SetVertexColor(.25,.25,.25)
		end
	end
	ItemRackOpt.PopulateInvIcons()
	ItemRackOpt.ValidateSetButtons()
	ItemRackOptSetsCurrentSetIcon:SetTexture(ItemRackOpt.selectedIcon)
end

function ItemRackOpt.ToggleInvSelect()
	local id = this:GetID()
	this:SetChecked(0)
	if ItemRack.IsTimerActive("SlotMarquee") or ItemRackOptSubFrame4:IsVisible() then
		if ItemRackOptSubFrame6:IsVisible() then
			ItemRackOpt.BindSlot(id)
		else
			ItemRackOpt.SetupQueue(id)
		end
	elseif IsShiftKeyDown() then
		ItemRack.ChatLinkID(ItemRackOpt.Inv[id].id)
	else
		ItemRackOpt.Inv[id].selected = not ItemRackOpt.Inv[id].selected
		ItemRackOpt.UpdateInv()
	end
end

-- central function for handling the buttons throughout options UI
function ItemRackOpt.ButtonOnClick()

	local button = this:GetName()

	if button=="ItemRackOptToggleInvAll" then
		local state = not ItemRackOpt.Inv[1].selected
		for i=0,19 do
			ItemRackOpt.Inv[i].selected = state
		end
		ItemRackOpt.UpdateInv()
	elseif button=="ItemRackOptClose" then
		ItemRackOptFrame:Hide()
	elseif button=="ItemRackOptSetsSaveButton" then
		ItemRackOpt.SaveSet()
	elseif button=="ItemRackOptSetsDeleteButton" then
		ItemRackOpt.DeleteSet()
		ItemRackOpt.ValidateSetButtons()
	elseif button=="ItemRackOptSetsBindButton" then
		ItemRackOpt.BindSet()
	elseif button=="ItemRackOptSetsDropDownButton" then
		ItemRackOptSubFrame5:Show()
	elseif button=="ItemRackOptSetListClose" then
		ItemRackOptSubFrame5:Hide()
	elseif button=="ItemRackOptSlotBindCancel" then
		ItemRackOptSubFrame6:Hide()
	elseif button=="ItemRackOptBindCancel" then
		ItemRackOptBindFrame:Hide()
	elseif button=="ItemRackOptBindUnbind" then
		ItemRackOpt.UnbindKey()
		ItemRackOptBindFrame:Hide()
	elseif button=="ItemRackOptSortListClose" then
		ItemRackOptSubFrame7:Hide()
	elseif button=="ItemRackOptResetBar" then
		ItemRack.ResetButtons()
	elseif button=="ItemRackOptResetEverything" then
		ItemRack.ResetEverything()

	
	elseif button=="ItemRackFloatingEditorTest" then
		RunScript(ItemRackFloatingEditorEditBox:GetText())
	elseif button=="ItemRackFloatingEditorUndo" then
		ItemRackFloatingEditorEditBox:SetText(ItemRackOptEventEditScriptEditBox:GetText())
	end
end

--[[ Icon choices ]]

function ItemRackOpt.PopulateInvIcons()
	local texture
	for i=0,19 do
		if ItemRackOpt.Inv[i].id and ItemRackOpt.Inv[i].id~=0 then
			_,texture = ItemRack.GetInfoByID(ItemRackOpt.Inv[i].id)
		else
			_,texture = GetInventorySlotInfo(ItemRack.SlotInfo[i].name)
		end
		ItemRackOpt.Icons[i+1] = texture
	end
	ItemRackOpt.SetsIconScrollFrameUpdate()
end

function ItemRackOpt.PopulateInitialIcons()
	ItemRackOpt.Icons = {}
	for i=0,19 do
		table.insert(ItemRackOpt.Icons,"Interface\\Icons\\INV_Misc_QuestionMark")
	end
	ItemRackOpt.PopulateInvIcons()
	table.insert(ItemRackOpt.Icons,"Interface\\Icons\\INV_Banner_02")
	table.insert(ItemRackOpt.Icons,"Interface\\Icons\\INV_Banner_03")
	for i=1,GetNumMacroIcons() do
		table.insert(ItemRackOpt.Icons,GetMacroIconInfo(i))
	end
end

function ItemRackOpt.SetsIconScrollFrameUpdate()

	local item, texture, idx
	local offset = FauxScrollFrame_GetOffset(ItemRackOptSetsIconScrollFrame)

	FauxScrollFrame_Update(ItemRackOptSetsIconScrollFrame, ceil(#(ItemRackOpt.Icons)/5),5,28)
	
	for i=1,25 do
		item = getglobal("ItemRackOptSetsIcon"..i)
		idx = (offset*5) + i
		if idx<=#(ItemRackOpt.Icons) then
			texture = ItemRackOpt.Icons[idx]
			getglobal("ItemRackOptSetsIcon"..i.."Icon"):SetTexture(texture)
			item:Show()
			if texture==ItemRackOpt.selectedIcon then
				item:LockHighlight()
			else
				item:UnlockHighlight()
			end
		else
			item:Hide()
		end

	end
end

function ItemRackOpt.SetsIconOnClick()
	local idx = this:GetID() + FauxScrollFrame_GetOffset(ItemRackOptSetsIconScrollFrame)*5
	ItemRackOpt.selectedIcon = ItemRackOpt.Icons[idx]
	ItemRackOptSetsCurrentSetIcon:SetTexture(ItemRackOpt.selectedIcon)
	ItemRackOpt.SetsIconScrollFrameUpdate()
end

function ItemRackOpt.SaveSet()
	ItemRackOptSetsName:ClearFocus()
	local setname = ItemRackOptSetsName:GetText()
	ItemRackUser.Sets[setname] = ItemRackUser.Sets[setname] or {}
	local set = ItemRackUser.Sets[setname]
	set.icon = ItemRackOpt.selectedIcon
	set.oldset = nil
	set.old = {}
	set.equip = {}
	for i=0,19 do
		if ItemRackOpt.Inv[i].selected then
			set.equip[i] = ItemRackOpt.Inv[i].id
		end
	end
	ItemRackOpt.ValidateSetButtons()
end

function ItemRackOpt.ValidateSetButtons()
	ItemRackOptSetsSaveButton:Disable()
	ItemRackOptSetsBindButton:Disable()
	ItemRackOptSetsDeleteButton:Disable()
	ItemRackOptSetsHideCheckButton:Disable()
	ItemRackOptSetsHideCheckButtonText:SetTextColor(.5,.5,.5,1)
	ItemRackOptSetsHideCheckButton:SetChecked(0)
	ItemRackOptSetsBDCheckButton:Disable()
	ItemRackOptSetsBDCheckButtonText:SetTextColor(.5,.5,.5,1)
	ItemRackOptSetsBDCheckButton:SetChecked(0)
	
	
	
	
	local setname = ItemRackOptSetsName:GetText()
	if string.len(setname)>0 then
		for i=0,19 do
			if ItemRackOpt.Inv[i].selected then
				ItemRackOptSetsSaveButton:Enable()
				break
			end
		end
	end
	if ItemRackUser.Sets[setname] then
		ItemRackOptSetsDeleteButton:Enable()
		ItemRackOptSetsBindButton:Enable()
		ItemRackOptSetsHideCheckButton:Enable()
		ItemRackOptSetsHideCheckButtonText:SetTextColor(1,1,1,1)
		ItemRackOptSetsHideCheckButton:SetChecked(ItemRack.IsHidden(setname))
		ItemRackOptSetsCurrentSetIcon:SetTexture(ItemRackUser.Sets[setname].icon)
		ItemRackOptSetsBDCheckButton:Enable()
		ItemRackOptSetsBDCheckButtonText:SetTextColor(1,1,1,1)
		ItemRackOptSetsBDCheckButton:SetChecked(ItemRack.IsBD(setname))
		
		
		
		
	end
end

function ItemRackOpt.LoadSet()
	ItemRackOptSetsName:ClearFocus()
	local setname = ItemRackOptSetsName:GetText()
	if ItemRackUser.Sets[setname] then
		local set = ItemRackUser.Sets[setname].equip
		for i=0,19 do
			ItemRackOpt.Inv[i].selected = nil
			if set[i] then
				ItemRackOpt.Inv[i].id = set[i]
				ItemRackOpt.Inv[i].selected = 1
			end
		end
		ItemRackOpt.selectedIcon = ItemRackUser.Sets[setname].icon
		ItemRackOpt.UpdateInv()
	end
end

function ItemRackOpt.DeleteSet()
	ItemRackUser.Sets[ItemRackOptSetsName:GetText()] = nil
	ItemRackOpt.PopulateSetList()
	
	
end

function ItemRackOpt.BDSet()
	local setname = ItemRackOptSetsName:GetText()
	if setname and ItemRackUser.Sets[setname] then
		if ItemRackOptSetsBDCheckButton:GetChecked() then
			ItemRack.AddBD(setname)
		else
			ItemRack.RemoveBD(setname)
		end
	end
end

function ItemRackOpt.HideSet()
	local setname = ItemRackOptSetsName:GetText()
	if setname and ItemRackUser.Sets[setname] then
		if ItemRackOptSetsHideCheckButton:GetChecked() then
			ItemRack.AddHidden(setname)
		else
			ItemRack.RemoveHidden(setname)
		end
	end
end

function ItemRackOpt.MakeEscable(frame,add)
	local found
	for i in pairs(UISpecialFrames) do
		if UISpecialFrames[i]==frame then
			found = i
		end
	end
	if not found and add=="add" then
		table.insert(UISpecialFrames,frame)
	elseif found and add=="remove" then
		table.remove(UISpecialFrames,found)
	end
end

function ItemRackOpt.SaveInv()
	for i=0,19 do
		ItemRackOpt.HoldInv[i].id = ItemRackOpt.Inv[i].id
		ItemRackOpt.HoldInv[i].selected = ItemRackOpt.Inv[i].selected
	end
end

function ItemRackOpt.RestoreInv()
	for i=0,19 do
		ItemRackOpt.Inv[i].id = ItemRackOpt.HoldInv[i].id
		ItemRackOpt.Inv[i].selected = ItemRackOpt.HoldInv[i].selected
	end
	ItemRackOpt.UpdateInv()
end

-- when set chooser dropdown shown
function ItemRackOpt.PickSetOnShow()
  -- remove ItemRack_SetsFrame from UISpecialFrames and add ItemRack_Sets_SetSelect
	ItemRackOpt.MakeEscable("ItemRackOptSubFrame5","add")
	ItemRackOpt.MakeEscable("ItemRackOptFrame","remove")
	ItemRackOpt.HideCurrentSubFrame(5)
	ItemRackOpt.SaveInv()
	ItemRackOpt.PopulateSetList()
end

-- when set chooser dropdown hidden
function ItemRackOpt.PickSetOnHide()
	-- remove ItemRack_Sets_SetSelect from UISpecialFrames and add ItemRack_SetsFrame
	ItemRackOpt.MakeEscable("ItemRackOptSubFrame5","remove")
	ItemRackOpt.MakeEscable("ItemRackOptFrame","add")
	ItemRackOpt.ShowPrevSubFrame()

	if ItemRackOpt.EventSelected and ItemRackOpt.prevFrame==ItemRackOptSubFrame3 then
		local event = ItemRackOpt.EventList[ItemRackOpt.EventSelected][1]
		-- if going back to events frame and selected event is enabled with no set, unenable it
		if not ItemRackUser.Events.Set[event] then
			ItemRackUser.Events.Enabled[event] = nil
			
--			ItemRack.Print("That event can't be enabled without choosing a set.")
		end
	end

	ItemRackOpt.RestoreInv()
end

function ItemRackOpt.SetListOnEnter()
	getglobal(this:GetName().."Highlight"):Show()
	local set = ItemRackUser.Sets[ItemRackOpt.SetList[this:GetID()+FauxScrollFrame_GetOffset(ItemRackOptSetListScrollFrame)]].equip
	for i=0,19 do
		if set[i] then
			ItemRackOpt.Inv[i].id = set[i]
			ItemRackOpt.Inv[i].selected = 1
		else
			ItemRackOpt.Inv[i].id = ItemRackOpt.HoldInv[i].id
			ItemRackOpt.Inv[i].selected = nil
		end
	end
	ItemRackOpt.UpdateInv()
end

function ItemRackOpt.SetListScrollFrameUpdate()

	local item, texture, idx
	local offset = FauxScrollFrame_GetOffset(ItemRackOptSetListScrollFrame)

	FauxScrollFrame_Update(ItemRackOptSetListScrollFrame, #(ItemRackOpt.SetList), 10, 24)
	
	for i=1,10 do
		item = getglobal("ItemRackOptSetList"..i)
		idx = offset + i
		if idx<=#(ItemRackOpt.SetList) then
			getglobal("ItemRackOptSetList"..i.."Name"):SetText(ItemRackOpt.SetList[idx])
			getglobal("ItemRackOptSetList"..i.."Icon"):SetTexture(ItemRackUser.Sets[ItemRackOpt.SetList[idx]].icon)
			getglobal("ItemRackOptSetList"..i.."Key"):SetText(ItemRackUser.Sets[ItemRackOpt.SetList[idx]].key)
			if ItemRack.IsHidden(ItemRackOpt.SetList[idx]) then
				getglobal("ItemRackOptSetList"..i.."Name"):SetTextColor(.7,.7,.7,1)
			else
				getglobal("ItemRackOptSetList"..i.."Name"):SetTextColor(1,1,1,1)
			end
			item:Show()
		else
			item:Hide()
		end

	end
end

function ItemRackOpt.PopulateSetList()
	for i in pairs(ItemRackOpt.SetList) do
		ItemRackOpt.SetList[i] = nil
	end
	for i in pairs(ItemRackUser.Sets) do
		if not string.match(i,"^~") then
			table.insert(ItemRackOpt.SetList,i)
		end
	end
	table.sort(ItemRackOpt.SetList)
	ItemRackOpt.SetListScrollFrameUpdate()
end

-- when a set is chosen in the set list
function ItemRackOpt.SelectSetList()
	local setname = ItemRackOpt.SetList[this:GetID()+FauxScrollFrame_GetOffset(ItemRackOptSetListScrollFrame)]
	for i=0,19 do
		ItemRackOpt.HoldInv[i].id = ItemRackOpt.Inv[i].id
		ItemRackOpt.HoldInv[i].selected = ItemRackOpt.Inv[i].selected
	end

	if ItemRackOpt.prevFrame==ItemRackOptSubFrame3 then
		-- fill out event info if picking an event's set
		local event = ItemRackOpt.EventList[ItemRackOpt.EventSelected][1]
		if not ItemRackUser.Events.Set[event] then
			ItemRackUser.Events.Enabled[event] = 1
		end
		ItemRackUser.Events.Set[event] = setname
		
	else
		-- fill out set build info if picking a set (ItemRackOptSubFrame2)
		ItemRackOpt.selectedIcon = ItemRackUser.Sets[setname].icon
		ItemRackOptSetsName:SetText(setname)
		if ItemRackSettings.EquipOnSetPick=="ON" then
			ItemRack.EquipSet(setname)
			ItemRack.EquipSet(setname)
		end
	end

	ItemRackOptSubFrame5:Hide()
	ItemRackOpt.UpdateInv()
end	

--[[ Options list ]]

function ItemRackOpt.ListScrollFrameUpdate()
	local offset = FauxScrollFrame_GetOffset(ItemRackOptListScrollFrame)
	FauxScrollFrame_Update(ItemRackOptListScrollFrame, #(ItemRackOpt.OptInfo),11,24)

	for i=1,#(ItemRackOpt.OptInfo) do
		if ItemRackOpt.OptInfo[i].button then
			ItemRackOpt.OptInfo[i].button:SetFrameLevel(ItemRackOptList1:GetFrameLevel()+1)
			ItemRackOpt.OptInfo[i].button:Hide()
		end
	end

	local item,idx,opt,button,lock
	for i=1,11 do
		button = getglobal("ItemRackOptList"..i)
		getglobal("ItemRackOptList"..i.."Label"):Hide()
		getglobal("ItemRackOptList"..i.."CheckText"):Hide()
		getglobal("ItemRackOptList"..i.."CheckButton"):Hide()
		getglobal("ItemRackOptList"..i.."NumberLabel"):Hide()
		getglobal("ItemRackOptList"..i.."Underline"):Hide()
		idx = offset+i
		if idx<=#(ItemRackOpt.OptInfo) then
			opt = ItemRackOpt.OptInfo[idx]
			lock = ItemRack.inCombat and opt.combatlock
			button:SetAlpha(lock and .5 or 1)
			if opt.type=="label" then
				item = getglobal("ItemRackOptList"..i.."Label")
				item:SetText(opt.label)
				item:Show()
				if string.len(opt.label)>1 then
					getglobal("ItemRackOptList"..i.."Underline"):Show()
				end
			elseif opt.type=="check" then
				item = getglobal("ItemRackOptList"..i.."CheckText")
				item:SetWidth(opt.depend and 116 or 128)
				item:SetText(opt.label)
				if opt.depend and opt.optset[opt.depend]=="OFF" then
					item:SetTextColor(.5,.5,.5,1)
				else
					item:SetTextColor(1,1,1,1)
				end
				item:Show()
				item = getglobal("ItemRackOptList"..i.."CheckButton")
				item:SetChecked(opt.optset[opt.variable]=="ON" and 1 or 0)
				if lock or (opt.depend and opt.optset[opt.depend]=="OFF") then
					item:Disable()
				else
					item:Enable()
				end
				item:Show()
			elseif opt.type=="number" then
				item = getglobal("ItemRackOptList"..i.."NumberLabel")
				item:SetText(opt.label)
				if opt.depend and opt.optset[opt.depend]=="OFF" then
					item:SetTextColor(.5,.5,.5,1)
					opt.button:EnableMouse(0)
					opt.button:SetAlpha(.5)
				else
					item:SetTextColor(1,1,1,1)
					opt.button:EnableMouse(lock and 0 or 1)
					opt.button:SetAlpha(lock and .5 or 1)
				end
				item:Show()
				opt.button:SetPoint("LEFT",item,"RIGHT",16,-1)
				opt.button:Show()
			elseif opt.type=="slider" then
				opt.button:SetPoint("LEFT",button,"LEFT",32,4)
				if opt.depend and opt.optset[opt.depend]=="OFF" then
					opt.button:EnableMouse(0)
					opt.button:SetAlpha(.5)
				else
					opt.button:EnableMouse(lock and 0 or 1)
					opt.button:SetAlpha(lock and .5 or 1)
				end
				opt.button:Show()
			elseif opt.type=="button" then
				opt.button:SetPoint("LEFT",button,"LEFT",16,0)
				opt.button:EnableMouse(lock and 0 or 1)
				opt.button:SetAlpha(lock and .5 or 1)
				opt.button:Show()
			end
			button:Show()
		else
			button:Hide()
		end
	end

end

function ItemRackOpt.SliderValueChanged()
	local name = string.match(this:GetName(),"ItemRackOpt(.+)Slider")
	if ItemRackUser[name] and ItemRackOpt.OptInfo then
		ItemRackUser[name] = this:GetValue()
		ItemRackOpt.UpdateSlider(name)
	end
end

function ItemRackOpt.UpdateSlider(name)
	if ItemRackOpt.OptInfo then
		local slider = getglobal("ItemRackOpt"..name.."Slider")
		local value = ItemRackUser[name]
		local number = getglobal("ItemRackOpt"..name)
		if slider and value and number then
			number:SetText(string.format(slider.form or "%s",value))
			if name=="ButtonSpacing" then
				ItemRack.ConstructLayout()
			elseif name=="Alpha" then
				ItemRack.ReflectAlpha()
			elseif name=="MenuScale" then
				ItemRack.ReflectMenuScale()
			elseif name=="MainScale" then
				ItemRack.ReflectMainScale(1)
			end
		end
	end
end

function ItemRackOpt.NumberEditBoxOnEnter()
	this:ClearFocus()
	local name = string.match(this:GetName(),"ItemRackOpt(.+)")
	local newValue = tonumber(this:GetText())
	local slider = getglobal(this:GetName().."Slider")
	if newValue and newValue>=slider.min and newValue<=slider.max then
		ItemRackUser[name] = newValue
		slider:SetValue(newValue)
	end
	ItemRackOpt.UpdateSlider(name)
end

function ItemRackOpt.NumberEditBoxOnEscape()
	this:ClearFocus()
	ItemRackOpt.UpdateSlider(string.match(this:GetName(),"ItemRackOpt(.+)"))
end

function ItemRackOpt.OptListCheckButtonOnClick(override)
	local button = override and override or this
	local check = button:GetChecked() and "ON" or "OFF"
	local idx = button:GetParent():GetID() + FauxScrollFrame_GetOffset(ItemRackOptListScrollFrame)
	local opt = ItemRackOpt.OptInfo[idx]
	if opt and opt.variable then
		opt.optset[opt.variable] = check
	end
	

	if opt.variable=="ShowMinimap" or opt.variable=="SquareMinimap" then
		ItemRack.MoveMinimap()
	
	
	

	end
	ItemRackOpt.ListScrollFrameUpdate()
end

function ItemRackOpt.OptListOnEnter(id)
	if type(id)=="table" then
		for i=1,#(ItemRackOpt.OptInfo) do
			if ItemRackOpt.OptInfo[i].button==id then
				ItemRack.OnTooltip(ItemRackOpt.OptInfo[i].label,ItemRackOpt.OptInfo[i].tooltip)
				break
			end
		end
	elseif type(id)=="number" then
		local idx = id + FauxScrollFrame_GetOffset(ItemRackOptListScrollFrame)
		if ItemRackOpt.OptInfo[idx].tooltip then
			ItemRack.OnTooltip(ItemRackOpt.OptInfo[idx].label,ItemRackOpt.OptInfo[idx].tooltip)
		end
	end
end

function ItemRackOpt.OptListOnClick()
	local check = getglobal(this:GetName().."CheckButton")
	if check and check:IsVisible() and check:IsEnabled()==1 then
		check:SetChecked(not check:GetChecked())
		ItemRackOpt.OptListCheckButtonOnClick(check)
	end
end

--[[ Tabs ]]

function ItemRackOpt.TabOnClick(override)
	ItemRackOptBindFrame:Hide()
	for i=ItemRackOpt.numSubFrames,1,-1 do
		getglobal("ItemRackOptSubFrame"..i):Hide()
	end
	local which = override or this:GetID()
	local tab,frame
	for i=1,2 do
		tab = getglobal("ItemRackOptTab"..i)
		if which==i then
			tab:Disable()
			tab:EnableMouse(0)
			getglobal("ItemRackOptSubFrame"..i):Show()
		else
			tab:Enable()
			tab:EnableMouse(1)
		end
	end
end

--[[ Bindings frame ]]

-- hides currently shown subframes except one if passed (ie, ItemRackOpt.HideCurrentSubFrame(5) to hide all but set picker)
function ItemRackOpt.HideCurrentSubFrame(except)
	local frame,prev
	for i=ItemRackOpt.numSubFrames,1,-1 do
		if i~=except then
			frame = getglobal("ItemRackOptSubFrame"..i)
			if frame:IsVisible() then
				frame:Hide()
				prev = prev or frame
			end
		end
	end
	ItemRackOpt.prevFrame = prev
end

function ItemRackOpt.ShowPrevSubFrame()
	if ItemRackOpt.prevFrame then
		ItemRackOpt.prevFrame:Show()
	else
		ItemRackOptSubFrame1:Show()
	end
end

function ItemRackOpt.BindSet()
	local setname = ItemRackOptSetsName:GetText()
	ItemRackOpt.Binding = { type="Set", name="Установить \""..setname.."\"", buttonName="ItemRack"..UnitName("player")..GetRealmName()..setname }
	ItemRackOpt.Binding.button = getglobal(buttonName) or CreateFrame("Button",ItemRackOpt.Binding.buttonName,nil,"SecureActionButtonTemplate")
	ItemRackOptBindFrame:Show()	
end

function ItemRackOpt.BindFrameOnShow()
	if not ItemRackOpt.Binding then return end
	ItemRackOpt.HideCurrentSubFrame()
	ItemRackOpt.Binding.currentKey=GetBindingKey("CLICK "..ItemRackOpt.Binding.buttonName..":LeftButton") or "Не привязан"
	ItemRackOptBindFrameBindee:SetText(ItemRackOpt.Binding.name)
	ItemRackOptBindFrameCurrently:SetText("На данный момент: "..ItemRackOpt.Binding.currentKey)
end

function ItemRackOpt.BindFrameOnHide()
	ItemRackOpt.ShowPrevSubFrame()
	ItemRackOpt.ReconcileSetBindings()
	ItemRackOpt.Binding = nil
end

function ItemRackOpt.BindFrameOnKeyDown()
	if arg1=="ESCAPE" then
		this:Hide()
		return
	end
	local screenshotKey = GetBindingKey("SCREENSHOT");
	if ( screenshotKey and arg1 == screenshotKey ) then
		Screenshot();
		return;
	end
	local button
	-- Convert the mouse button names
	if ( arg1 == "LeftButton" ) then
		button = "BUTTON1"
	elseif ( arg1 == "RightButton" ) then
		button = "BUTTON2"
	elseif ( arg1 == "MiddleButton" ) then
		button = "BUTTON3"
	elseif ( arg1 == "Button4" ) then
		button = "BUTTON4"
	elseif ( arg1 == "Button5" ) then
		button = "BUTTON5"
	end
	local keyPressed
	if ( button ) then
		if ( button == "BUTTON1" or button == "BUTTON2" ) then
			return;
		end
		keyPressed = button;
	else
		keyPressed = arg1;
	end
	if keyPressed=="UNKNOWN" or keyPressed=="LSHIFT" or keyPressed=="RSHIFT" or keyPressed=="LCTRL" or keyPressed=="RCTRL" or keyPressed=="LALT" or keyPressed=="RALT" then
		return
	end
	if ( IsShiftKeyDown() ) then
		keyPressed = "SHIFT-"..keyPressed
	end
	if ( IsControlKeyDown() ) then
		keyPressed = "CTRL-"..keyPressed
	end
	if ( IsAltKeyDown() ) then
		keyPressed = "ALT-"..keyPressed
	end
	if keyPressed then
		ItemRackOpt.Binding.keyPressed = keyPressed
		local oldAction = GetBindingAction(keyPressed)
		if oldAction~="" and keyPressed~=ItemRackOpt.Binding.currentKey then
			StaticPopupDialogs["ItemRackCONFIRMBINDING"] = {
				text = NORMAL_FONT_COLOR_CODE..ItemRackOpt.Binding.keyPressed..FONT_COLOR_CODE_CLOSE.." в настоящее время обязан "..NORMAL_FONT_COLOR_CODE..(GetBindingText(oldAction,"BINDING_NAME_") or "")..FONT_COLOR_CODE_CLOSE.."\n\nВы хотите связать "..NORMAL_FONT_COLOR_CODE..keyPressed..FONT_COLOR_CODE_CLOSE.." to "..NORMAL_FONT_COLOR_CODE..ItemRackOpt.Binding.name..FONT_COLOR_CODE_CLOSE.."?",
				button1 = "Yes",
				button2 = "No",
				timeout = 0,
				hideOnEscape = 1,
				OnAccept = ItemRackOpt.SetKeyBinding,
				OnCancel = ItemRackOpt.ResetBindFrame
			}
			ItemRackOptBindFrame:EnableKeyboard(0) -- turn off keyboard catching
			ItemRackOptBindFrame:EnableMouse(0) -- and mouse
			ItemRackOptBindCancel:Disable()
			ItemRackOptBindUnbind:Disable()
			StaticPopup_Show("ItemRackCONFIRMBINDING")
		else
			ItemRackOpt.SetKeyBinding()
		end
	end
end

function ItemRackOpt.SetKeyBinding()
	if not InCombatLockdown() and ItemRackOpt.Binding.keyPressed then
		ItemRackOpt.UnbindKey()
		SetBindingClick(ItemRackOpt.Binding.keyPressed,ItemRackOpt.Binding.buttonName)
	else
		ItemRack.Print("Sorry, you can't bind keys while in combat.")
	end
	ItemRackOpt.ResetBindFrame()
	ItemRackOptBindFrame:Hide()
end

function ItemRackOpt.ResetBindFrame()
	ItemRackOptBindFrame:EnableKeyboard(1)
	ItemRackOptBindFrame:EnableMouse(1)
	ItemRackOptBindCancel:Enable()
	ItemRackOptBindUnbind:Enable()
end

function ItemRackOpt.UnbindKey()
	if not InCombatLockdown() and ItemRackOpt.Binding.buttonName then
		local action = "CLICK "..ItemRackOpt.Binding.buttonName..":LeftButton"
		while GetBindingKey(action) do
			SetBinding(GetBindingKey(action))
		end
	end
	if ItemRackOpt.prevFrame==ItemRackOptSubFrame6 then
		ItemRackOpt.prevFrame = nil
	end
end

function ItemRackOpt.ReconcileSetBindings()
	local buttonName,key
	for i in pairs(ItemRackUser.Sets) do
		ItemRackUser.Sets[i].key = nil
		buttonName = "ItemRack"..UnitName("player")..GetRealmName()..i
		if getglobal(buttonName) then
			key = GetBindingKey("CLICK "..buttonName..":LeftButton")
			if key and key~="" then
				ItemRackUser.Sets[i].key = key
			end
		end
	end
	ItemRack.SetSetBindings()
end

--[[ Slot bindings ]]

function ItemRackOpt.SlotBindFrameOnShow()
	ItemRackOpt.MakeEscable("ItemRackOptSubFrame6","add")
	ItemRackOpt.MakeEscable("ItemRackOptFrame","remove")
	ItemRackOpt.HideCurrentSubFrame(6)
	ItemRackOpt.StartMarquee()
end

function ItemRackOpt.SlotBindFrameOnHide()
	ItemRackOpt.MakeEscable("ItemRackOptSubFrame6","remove")
	ItemRackOpt.MakeEscable("ItemRackOptFrame","add")
	ItemRackOpt.ShowPrevSubFrame()
	ItemRackOpt.StopMarquee()
end

function ItemRackOpt.StartMarquee()
	ItemRackOpt.SaveInv()
	for i=0,19 do
		ItemRackOpt.Inv[i].selected = nil
	end
	ItemRackOptToggleInvAll:Hide()
	ItemRackOpt.UpdateInv()
	ItemRack.StartTimer("SlotMarquee")
end

function ItemRackOpt.StopMarquee()
	ItemRack.StopTimer("SlotMarquee")
	getglobal("ItemRackOptInv"..ItemRackOpt.slotOrder[ItemRackOpt.currentMarquee+1]):UnlockHighlight()
	ItemRackOpt.RestoreInv()
	ItemRackOptToggleInvAll:Show()
end

function ItemRackOpt.SlotMarquee()
	getglobal("ItemRackOptInv"..ItemRackOpt.slotOrder[ItemRackOpt.currentMarquee+1]):UnlockHighlight()
	ItemRackOpt.currentMarquee = mod(ItemRackOpt.currentMarquee+1,#(ItemRackOpt.slotOrder))
	getglobal("ItemRackOptInv"..ItemRackOpt.slotOrder[ItemRackOpt.currentMarquee+1]):LockHighlight()
end

function ItemRackOpt.BindSlot(slot)
	ItemRackOpt.Binding = { type="Slot", name=ItemRack.SlotInfo[slot].real, buttonName="ItemRackButton"..slot }
	ItemRackOpt.Binding.button = getglobal(buttonName)
	ItemRackOptBindFrame:Show()	
end

--[[ Auto queues ]]

function ItemRackOpt.QueuesFrameOnShow()
	ItemRackOpt.StartMarquee()
end

function ItemRackOpt.QueuesFrameOnHide()
	ItemRackOpt.StopMarquee()
end

function ItemRackOpt.SlotQueueFrameOnShow()
	ItemRackOpt.MakeEscable("ItemRackOptSubFrame7","add")
	ItemRackOpt.MakeEscable("ItemRackOptFrame","remove")
	ItemRackOpt.HideCurrentSubFrame(7)
	for i=0,19 do
		getglobal("ItemRackOptInv"..i):Hide()
	end
	ItemRackOptToggleInvAll:Hide()
end

function ItemRackOpt.SlotQueueFrameOnHide()
	ItemRackOpt.MakeEscable("ItemRackOptSubFrame7","remove")
	ItemRackOpt.MakeEscable("ItemRackOptFrame","add")
	ItemRackOpt.ShowPrevSubFrame()
	for i=0,19 do
		getglobal("ItemRackOptInv"..i):Show()
	end
	ItemRackOptToggleInvAll:Show()
end

function ItemRackOpt.SetupQueue(id)
	if not ItemRackUser.Queues[id] then
		ItemRackUser.Queues[id] = {}
	end
	ItemRackOpt.SelectedSlot = id
	ItemRackOpt.SortSelected = nil
	ItemRackOptSlotQueueName:SetText(ItemRack.SlotInfo[id].real)
	ItemRackOpt.PopulateSortList(id)
	ItemRackOpt.ValidateSortButtons()
	ItemRackOptSubFrame7:Show()
end

function ItemRackOpt.PopulateSortList(slot)
	local sortList = ItemRackUser.Queues[slot]
	ItemRack.DockWindows("TOPLEFT",ItemRackOptInv1,"TOPRIGHT")
	ItemRack.BuildMenu(slot,1) -- make a dummy menu to fetch all wearable items for that slot
	ItemRackMenuFrame:Hide()
	for i=1,#(ItemRack.Menu) do
		ItemRackOpt.AddToSortList(sortList,ItemRack.Menu[i]) -- insert new items from menu (in bags/inventory)
	end
	ItemRackOptSortListScrollFrameScrollBar:SetValue(0)
end

function ItemRackOpt.AddToSortList(sortList,id)
	local found
	for i=1,#(sortList) do
		found = found or sortList[i]==id
	end
	if not found then
		table.insert(sortList,id)
	end
end



function ItemRackOpt.LockHighlight(frame)
	if type(frame)=="string" then frame = getglobal(frame) end
	if not frame then return end
	frame.lockedHighlight = 1
	getglobal(frame:GetName().."Highlight"):Show()
end

function ItemRackOpt.UnlockHighlight(frame)
	if type(frame)=="string" then frame = getglobal(frame) end
	if not frame then return end
	frame.lockedHighlight = nil
	getglobal(frame:GetName().."Highlight"):Hide()
end

function ItemRackOpt.SortListOnClick()
	local idx = FauxScrollFrame_GetOffset(ItemRackOptSortListScrollFrame) + this:GetID()
	if ItemRackOpt.SortSelected == idx then
		ItemRackOpt.SortSelected = nil
	else
		ItemRackOpt.SortSelected = idx
	end
	
	ItemRackOpt.ValidateSortButtons()
end

function ItemRackOpt.ValidateSortButtons()
	local selected = ItemRackOpt.SortSelected
	local list = ItemRackUser.Queues[ItemRackOpt.SelectedSlot]
	ItemRackOptSortMoveTop:Enable()
	ItemRackOptSortMoveUp:Enable()
	ItemRackOptSortMoveDown:Enable()
	ItemRackOptSortMoveBottom:Enable()
	if not selected or #(list)<2 then -- none selected, disable all
		ItemRackOptSortMoveTop:Disable()
		ItemRackOptSortMoveUp:Disable()
		ItemRackOptSortMoveDown:Disable()
		ItemRackOptSortMoveBottom:Disable()
	elseif selected==1 then
		ItemRackOptSortMoveTop:Disable()
		ItemRackOptSortMoveUp:Disable()
	elseif selected == #(list) then
		ItemRackOptSortMoveDown:Disable()
		ItemRackOptSortMoveBottom:Disable()
	end
	local idx = FauxScrollFrame_GetOffset(ItemRackOptSortListScrollFrame)
	if selected and list[selected] and list[selected]~=0 then
		ItemRackOptSortMoveDelete:Enable()
		-- display delay/priority/etc
		ItemRackOptItemStatsFrame:Show()
		ItemRackOptSlotQueueName:Hide()
		local id = string.match(list[selected],"^(%d+)")
		ItemRackOptItemStatsPriority:SetChecked(ItemRackItems[id] and ItemRackItems[id].priority or 0)
		
		ItemRackOptItemStatsDelay:SetText((ItemRackItems[id] and ItemRackItems[id].delay) or 0)
	else
		ItemRackOptSortMoveDelete:Disable()
		ItemRackOptItemStatsFrame:Hide()
		ItemRackOptSlotQueueName:Show()
	end
	if not IsShiftKeyDown() and selected then -- keep selected visible on list, moving thumb as needed, unless shift is down
		local parent = ItemRackOptSortListScrollFrameScrollBar
		local offset
		if selected <= idx then
			offset = (selected==1) and 0 or (parent:GetValue() - (parent:GetHeight() / 2))
			parent:SetValue(offset)
			PlaySound("UChatScrollButton")
		elseif selected >= (idx+12) then
			offset = (selected==#(list)) and ItemRackOptSortListScrollFrame:GetVerticalScrollRange() or (parent:GetValue() + (parent:GetHeight() / 2))
			parent:SetValue(offset)
			PlaySound("UChatScrollButton");
		end
	end
end

function ItemRackOpt.SortMove()
	local dir = ((this==ItemRackOptSortMoveUp) and -1) or ((this==ItemRackOptSortMoveTop) and "top") or ((this==ItemRackOptSortMoveDown) and 1) or ((this==ItemRackOptSortMoveBottom) and "bottom")
	local list = ItemRackUser.Queues[ItemRackOpt.SelectedSlot]
	local idx1 = ItemRackOpt.SortSelected
	if dir then
		local idx2 = ((dir=="top") and 1) or ((dir=="bottom") and #(list)) or idx1+dir
		local temp = list[idx1]
		if tonumber(dir) then
			list[idx1] = list[idx2]
			list[idx2] = temp
		elseif dir=="top" then
			table.remove(list,idx1)
			table.insert(list,1,temp)
		elseif dir=="bottom" then
			table.remove(list,idx1)
			table.insert(list,temp)
		end
		ItemRackOpt.SortSelected = idx2
	elseif this==ItemRackOptSortMoveDelete then
		table.remove(list,idx1)
		ItemRackOpt.SortSelected = nil
	end
	ItemRackOpt.ValidateSortButtons()
	
end



function ItemRackOpt.SortListOnLeave()
	GameTooltip:Hide()
	if not this.lockedHighlight then
		getglobal(this:GetName().."Highlight"):Hide()
	end
end

-- if an ItemRackItems has no non-default values, remove the entry
function ItemRackOpt.ItemStatsCleanup(id)
	if ItemRackItems[id] then
		local item = ItemRackItems[id]
		if not item.delay and not item.priority and not item.keep then
			ItemRackItems[id] = nil
		end
	end
end

function ItemRackOpt.ItemStatsDelayOnTextChanged()
	local id = string.match(ItemRackUser.Queues[ItemRackOpt.SelectedSlot][ItemRackOpt.SortSelected],"^(%d+)")
	local value = tonumber(this:GetText() or "") or 0
	if value~=0 then
		if not ItemRackItems[id] then
			ItemRackItems[id] = {}
		end
		ItemRackItems[id].delay = value
	else
		if ItemRackItems[id] then
			ItemRackItems[id].delay = nil
		end
		ItemRackOpt.ItemStatsCleanup(id)
	end
end

function ItemRackOpt.ItemStatsCheckOnClick()
	local id = string.match(ItemRackUser.Queues[ItemRackOpt.SelectedSlot][ItemRackOpt.SortSelected],"^(%d+)")
	local value = this:GetChecked()
	local which = this==ItemRackOptItemStatsPriority and "priority" or "keep"
	if value then
		if not ItemRackItems[id] then
			ItemRackItems[id] = {}
		end
		ItemRackItems[id][which] = 1
	else
		if ItemRackItems[id] then
			ItemRackItems[id][which] = nil
		end
		ItemRackOpt.ItemStatsCleanup(id)
	end
end



--[[ Show/Hide/Ignore Helm/Cloak tristate checkbuttons ]]

-- sets the state of a checkbutton to nil, 0 or 1
function ItemRackOpt.TriStateCheckSetState(button,value)
	local label = getglobal(button:GetName().."Text")
	button.tristate = value
	if not value then
		button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		button:SetChecked(0)
		label:SetTextColor(.5,.5,.5)
	elseif value==0 then
		button:SetCheckedTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
		button:SetChecked(1)
		label:SetTextColor(1,1,1)
	elseif value==1 then
		button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		button:SetChecked(1)
		label:SetTextColor(1,1,1)
	end
end

-- rotates a checkbutton from indeterminate->unchecked->checked (for show helm/cloak)
function ItemRackOpt.TriStateCheckOnClick()
	local newstate
	if not this.tristate then
		newstate = 1 -- nil->1 (show)
	elseif this.tristate==0 then
		newstate = nil -- 0->nil (ignore)
	elseif this.tristate==1 then
		newstate = 0 -- 1->0 (hide)
	end
	ItemRackOpt.TriStateCheckSetState(this,newstate)
	local setname = ItemRackOptSetsName:GetText()
	if setname and ItemRackUser.Sets[setname] then
		
		ItemRackUser.Sets[setname][which] = newstate
	end
	
end























