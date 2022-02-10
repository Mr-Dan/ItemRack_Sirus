ItemRack = {}

local disable_delayed_swaps = nil -- temporary. change nil to 1 to stop attempting to delay set swaps while casting

ItemRack.Version = 2.243

ItemRackUser = {
	Sets = {}, -- user's sets
	ItemsUsed = {}, -- items that have been used (for notify purposes)
	Hidden = {}, -- items the user chooses to hide in menus
	Queues = {}, -- item auto queue sorts
	QueuesEnabled = {}, -- which queues are enabled
	Locked = "OFF", -- buttons locked
	ButtonSpacing = 4, -- padding between docked buttons
	Alpha = 1, -- alpha of buttons
	MainScale = 1, -- scale of the dockable buttons
	MenuScale = .85, -- scale of the menu in relation to docked buttons
	SetMenuWrap = "OFF", -- whether user defines when to wrap the menu
	SetMenuWrapValue = 3, -- when to wrap the menu if user defined
	BD = {}, -- Black diamonds
}

ItemRackSettings = {
	
	
	ShowTooltips = "ON", -- show all itemrack tooltips
	
	TinyTooltips = "OFF", -- whether to condense tooltips to most important info
	TooltipFollow = "OFF", -- whether tooltip follows pointer
	

	AllowEmpty = "ON", -- allow empty slot as a choice in menus
	
	AllowHidden = "ON", -- allow the ability to hide items/sets in the menu with alt+click
	ShowMinimap = "ON", -- whether to show the minimap button
	SquareMinimap = "OFF", -- whether to position minimap button as if on a square minimap
	
	AnotherOther = "OFF", -- whether to dock the merged trinket menu to bottom trinket
	EquipToggle = "OFF", -- whether to toggle equipping a set when choosing to equip it
	
	
	EquipOnSetPick = "OFF", -- whether to equip a set when picked in the set tab of options
	MinimapTooltip = "ON", -- whether to display the minimap button tooltip to explain clicks
	
}

-- these are default items with non-standard behavior
--   keep = 1/nil whether to suspend auto queue while equipped
--   priority = 1/nil whether to equip as it comes off cooldown even if equipped is off cooldown waiting to be used
--   delay = time(seconds) after use before swapping out
ItemRackItems = {
	["11122"] = { keep=1 }, -- carrot on a stick
	["13209"] = { keep=1 }, -- seal of the dawn
	["19812"] = { keep=1 }, -- rune of the dawn
	["12846"] = { keep=1 }, -- argent dawn commission
	["25653"] = { keep=1 }, -- riding crop
}

ItemRack.NoTitansGrip = {
	["Polearms"] = 1,
	["Fishing Poles"] = 1,
	["Staves"] = 1
}

ItemRack.Menu = {}
ItemRack.LockList = {} -- index -2 to 11, flag whether item is tagged already for swap
ItemRack.BankSlots = { -1,5,6,7,8,9,10,11 }
ItemRack.KnownItems = {} -- cache of known item locations for fast lookup

ItemRack.SlotInfo = {
	[0] = { name="AmmoSlot", real="Боеприпасы", swappable=1, INVTYPE_AMMO=1 },
	[1] = { name="HeadSlot", real="Голова", INVTYPE_HEAD=1 },
	[2] = { name="NeckSlot", real="Шея", INVTYPE_NECK=1 },
	[3] = { name="ShoulderSlot", real="Плечо", INVTYPE_SHOULDER=1 },
	[4] = { name="ShirtSlot", real="Рубашка", INVTYPE_BODY=1 },
	[5] = { name="ChestSlot", real="Грудь", INVTYPE_CHEST=1, INVTYPE_ROBE=1 },
	[6] = { name="WaistSlot", real="Пояс", INVTYPE_WAIST=1 },
	[7] = { name="LegsSlot", real="Ноги", INVTYPE_LEGS=1 },
	[8] = { name="FeetSlot", real="Ступни", INVTYPE_FEET=1 },
	[9] = { name="WristSlot", real="Запястье", INVTYPE_WRIST=1 },
	[10] = { name="HandsSlot", real="Руки", INVTYPE_HAND=1 },
	[11] = { name="Finger0Slot", real="Верхний палец", INVTYPE_FINGER=1, other=12 },
	[12] = { name="Finger1Slot", real="Нижний палец", INVTYPE_FINGER=1, other=11 },
	[13] = { name="Trinket0Slot", real="Верхний аксессуар", INVTYPE_TRINKET=1, other=14 },
	[14] = { name="Trinket1Slot", real="Нижний аксессуар", INVTYPE_TRINKET=1, other=13 },
	[15] = { name="BackSlot", real="Плащ", INVTYPE_CLOAK=1 },
	[16] = { name="MainHandSlot", real="Главная рука", swappable=1, INVTYPE_WEAPONMAINHAND=1, INVTYPE_2HWEAPON=1, INVTYPE_WEAPON=1, other=17 },
	[17] = { name="SecondaryHandSlot", real="Левая рука", swappable=1, INVTYPE_WEAPON=1, INVTYPE_WEAPONOFFHAND=1, INVTYPE_SHIELD=1, INVTYPE_HOLDABLE=1, other=16 },
	[18] = { name="RangedSlot", real="Дальний бой", swappable=1, INVTYPE_RANGED=1, INVTYPE_THROWN=1, INVTYPE_RANGEDRIGHT=1, INVTYPE_RELIC=1 },
	[19] = { name="TabardSlot", real="Накидка", INVTYPE_TABARD=1 },
}

ItemRack.DockInfo = {  -- docking-dependent values
	LEFT = { xoff=1, yoff=0, menuSide="TOP", menuDir="TOP", orient="VERT", xadd=40, yadd=0 },
	RIGHT = { xoff=-1, yoff=0, menuSide="TOP", menuDir="TOP", orient="VERT", xadd=40, yadd=0 },
	TOP = { xoff=0, yoff=-1, menuSide="LEFT", menuDir="LEFT", orient="HORZ", xadd=0, yadd=40 },
	BOTTOM = { xoff=0, yoff=1, menuSide="LEFT", menuDir="LEFT", orient="HORZ", xadd=0, yadd=40 },
	TOPRIGHTTOPLEFT = { xoff=0, yoff=8,  xdir=1,  ydir=-1, xstart=8,   ystart=-8 },
	BOTTOMRIGHTBOTTOMLEFT = { xoff=0, yoff=-8,  xdir=1,  ydir=1,  xstart=8,   ystart=44 },
	TOPLEFTTOPRIGHT = { xoff=0,  yoff=8,  xdir=-1, ydir=-1, xstart=-44, ystart=-8 },
	BOTTOMLEFTBOTTOMRIGHT = { xoff=0,  yoff=-8,  xdir=-1, ydir=1,  xstart=-44, ystart=44 },
	TOPRIGHTBOTTOMRIGHT = { xoff=8,  yoff=0, xdir=-1, ydir=1,  xstart=-44,  ystart=44 },
	BOTTOMRIGHTTOPRIGHT = { xoff=8,  yoff=0, xdir=-1, ydir=-1, xstart=-44,  ystart=-8 },
	TOPLEFTBOTTOMLEFT =	{ xoff=-8,  yoff=0, xdir=1,  ydir=1,  xstart=8,   ystart=44 },
	BOTTOMLEFTTOPLEFT =	{ xoff=-8,  yoff=0,  xdir=1,  ydir=-1, xstart=8,   ystart=-8 },
}
ItemRack.OppositeSide = { LEFT="RIGHT", RIGHT="LEFT", TOP="BOTTOM", BOTTOM="TOP" }

ItemRack.MenuMouseoverFrames = {PaperDollFrame=1,CharacterTrinket1Slot=1} -- frames besides ItemRackMenuFrame that can keep menu open on mouseover

ItemRack.CombatQueue = {} -- items waiting to swap in
ItemRack.RunAfterCombat = {} -- functions to run when player drops out of combat

-- miscellaneous tooltips ElementName, Line1, Line2
ItemRack.TooltipInfo = {
	{"ItemRackButtonMenuLock","Кнопки блокировки","Переключение в заблокированное состояние для предотвращения перемещения кнопок/меню, а также для скрытия границ и кнопок управления. \n\nДержите ALT, пока открываете меню для доступа к этим кнопкам управления в заблокированном состоянии."},
	{"ItemRackButtonMenuOptions","Опции","Открыть окно настройки для изменения настроек или настройки наборов."},
	{"ItemRackButtonMenuClose","Удалить","Удалить слот, из которого открывается это меню."},
	{"ItemRackOptSetsHideCheckButton","Спрятать комплект ","Проверь это, чтобы скрыть набор в меню"},
	{"ItemRackOptItemStatsPriority","Приоритет","Проверьте это, чтобы сделать этот пункт автоматического оснащения, когда он выходит из холодильника, даже если оборудованный пункт выключен холодильник и ждет, чтобы использоваться."},
	{"ItemRackOptSetsHideCheckButton","Спрятать","Спрячь этот набор в меню. (Эквивалент от нажатия Alt+ в меню)."},
	{"ItemRackOptSetsSaveButton","Сохранить комплект","Сохранить этот набор. Некоторые настройки, такие как привязка клавиш, видимость маскировки/шлема и скрытость, могут быть изменены только на сохраненный набор."},
	{"ItemRackOptSetsDeleteButton","Удалить комплект","Удалите это определение набора. Если вы хотите удалить его из меню и, возможно, захотите удалить его снова в будущем, установите флажок 'Скрыть' слева."},
	{"ItemRackOptSetsBindButton","Привязать клавишу к комплекту","Это позволит вам привязать клавишу или комбинацию клавиш для оснащения набора."},
	{"ItemRackOptEventNew","Новое событие","Создать новое событие."},
	{"ItemRackOptEventDelete","Удалить событие","Если это событие включено или имеет связанный с ним набор, то он удалит теги и бросит его в список.  Если это событие является немаркированным, оно удалит его полностью."},
	{"ItemRackOptSetsBDCheckButton","Черные бриллианты","Переставлять черные бриллианты в этот комплект при его надевании"},
	
	{"ItemRackOptEventEditBuffAnyMount","Любое крепление","При этом проверяется, активен ли какой-либо крепеж вместо определенного буфера."},
	{"ItemRackOptEventEditExpand","Редактирование в редакторе","Это отсоединит окно редактирования скрипта выше к текстовому редактору с возможностью изменения размера."},
	{"ItemRackFloatingEditorUndo","Отменить","Переверните текст в его последнее сохраненное состояние."},
	{"ItemRackFloatingEditorTest","Тест","Запустите текст ниже в виде скрипта, чтобы убедиться в отсутствии синтаксических ошибок. (Ошибки сценария в настройках интерфейса должны быть включены, чтобы увидеть any)\nNote: Этот тест не может симулировать любое условие или тест на ожидаемое поведение, кроме возможности запуска."},
	{"ItemRackFloatingEditorSave","Сохранить событие","Сохраните изменения в этом событии и вернитесь к списку событий.."},
	{"ItemRackOptToggleInvAll","Переключить все","Это переключит между выбором всех слотов и выбором без слотов."}
}

ItemRack.BankOpen = nil -- 1 if bank is open, nil if not

ItemRack.LastCurrentSet = nil -- last known current set

function ItemRack.OnLoad()
	ItemRack.InitTimers()
	ItemRack.CreateTimer("OnLogin",ItemRack.OnPlayerLogin,1)
	ItemRack.StartTimer("OnLogin")
	-- run ItemRack.OnPlayerLogin 1 second after player in world
end

ItemRack.EventHandlers = {}

function ItemRack.OnEvent()
	ItemRack.EventHandlers[event]()
end

function ItemRack.OnPlayerLogin()
	local handler = ItemRack.EventHandlers
	handler.ITEM_LOCK_CHANGED = ItemRack.OnItemLockChanged
	
	handler.UNIT_INVENTORY_CHANGED = ItemRack.OnUnitInventoryChanged
	handler.UPDATE_BINDINGS = ItemRack.KeyBindingsChanged
	handler.PLAYER_REGEN_ENABLED = ItemRack.OnLeavingCombatOrDeath
	handler.PLAYER_UNGHOST = ItemRack.OnLeavingCombatOrDeath
	handler.PLAYER_ALIVE = ItemRack.OnLeavingCombatOrDeath
	handler.PLAYER_REGEN_DISABLED = ItemRack.OnEnteringCombat
	handler.BANKFRAME_CLOSED = ItemRack.OnBankClose
	handler.BANKFRAME_OPENED = ItemRack.OnBankOpen
	handler.UNIT_SPELLCAST_START = ItemRack.OnCastingStart
	handler.UNIT_SPELLCAST_STOP = ItemRack.OnCastingStop
	handler.UNIT_SPELLCAST_SUCCEEDED = ItemRack.OnCastingStop
	handler.UNIT_SPELLCAST_INTERRUPTED = ItemRack.OnCastingStop
	handler.CHARACTER_POINTS_CHANGED = ItemRack.UpdateClassSpecificStuff

	ItemRack.InitCore()
	ItemRack.InitButtons()
	
end

function ItemRack.OnCastingStart()
	if arg1=="player" then
		local _,_,_,_,startTime,endTime = UnitCastingInfo("player")
		if endTime-startTime>0 then
			ItemRack.NowCasting = 1
		end
	end
end

function ItemRack.OnCastingStop()
	if arg1=="player" then
		if not ItemRack.NowCasting then
			return
		else
			ItemRack.NowCasting = nil
			if #(ItemRack.SetsWaiting)>0 and not ItemRack.AnythingLocked() then
				ItemRack.ProcessSetsWaiting()
			end
		end
	end
end

function ItemRack.OnItemLockChanged()
	ItemRack.StartTimer("LocksChanged")
	ItemRack.LocksHaveChanged = 1
end

function ItemRack.OnUnitInventoryChanged()
	if arg1=="player" then
		ItemRack.UpdateButtons()
		if ItemRackMenuFrame:IsVisible() then
			ItemRack.BuildMenu()
		end
		if ItemRackOptFrame and ItemRackOptFrame:IsVisible() then
			for i=0,19 do
				if not ItemRackOpt.Inv[i].selected then
					ItemRackOpt.Inv[i].id = ItemRack.GetID(i)
				end
			end
			ItemRackOpt.UpdateInv()
		end
	end
end

function ItemRack.OnLeavingCombatOrDeath()
	if not ItemRack.IsPlayerReallyDead() and next(ItemRack.CombatQueue) then
		local combat = ItemRackUser.Sets["~CombatQueue"].equip
		local queue = ItemRack.CombatQueue
		for i in pairs(combat) do
			combat[i] = nil
		end
		for i in pairs(queue) do
			combat[i] = queue[i]
			queue[i] = nil
		end
		ItemRackUser.Sets["~CombatQueue"].oldset = ItemRack.CombatSet
		ItemRack.UpdateCombatQueue()
		ItemRack.EquipSet("~CombatQueue")
	end
	if event=="PLAYER_REGEN_ENABLED" then
		ItemRack.inCombat = nil
		if ItemRackOptFrame and ItemRackOptFrame:IsVisible() then
			ItemRackOpt.ListScrollFrameUpdate()
			ItemRackOptSetsBindButton:Enable()
		end
		
		if next(ItemRack.RunAfterCombat) then
			for i=1,#(ItemRack.RunAfterCombat) do
				ItemRack[ItemRack.RunAfterCombat[i]]()
			end
			for i=1,#(ItemRack.RunAfterCombat) do
				table.remove(ItemRack.RunAfterCombat,i)
			end
		end
	end
end

function ItemRack.OnEnteringCombat()
	ItemRack.inCombat = 1
	if ItemRackOptFrame and ItemRackOptFrame:IsVisible() then
		ItemRackOpt.ListScrollFrameUpdate()
		ItemRackOptSetsBindButton:Disable()
	end
	
end

function ItemRack.OnBankClose()
	ItemRack.BankOpen = nil
	ItemRackMenuFrame:Hide()
end

function ItemRack.OnBankOpen()
	ItemRack.BankOpen = 1
end

function ItemRack.UpdateClassSpecificStuff()

	local _,class = UnitClass("player")

	if class=="WARRIOR" or class=="ROGUE" or class=="HUNTER" or class=="DEATHKNIGHT" then
		ItemRack.CanWearOneHandOffHand = 1
	end

	if class=="WARRIOR" then
		if select(5,GetTalentInfo(2,26))>0 then
			ItemRack.HasTitansGrip = 1
			ItemRack.SlotInfo[17].INVTYPE_2HWEAPON = 1
		else
			ItemRack.HasTitansGrip = nil
			ItemRack.SlotInfo[18].INVTYPE_2HWEAPON = nil
		end
	end

	if class=="SHAMAN" then
		ItemRack.CanWearOneHandOffHand = select(5,GetTalentInfo(2,18))>0 and 1 or nil
	end
end

function ItemRack.InitCore()
	ItemRackUser.Sets["~Unequip"] = { equip={} }
	ItemRackUser.Sets["~CombatQueue"] = { equip={} }

	ItemRack.UpdateClassSpecificStuff()

	ItemRack.DURABILITY_PATTERN = string.match(DURABILITY_TEMPLATE,"(.+) .+/.+") or ""
	ItemRack.REQUIRES_PATTERN = string.gsub(ITEM_MIN_SKILL,"%%.",".+")

	-- pattern splitter by Maldivia http://forums.worldofwarcraft.com/thread.html?topicId=6441208576
	local function split(str, t)
	    local start, stop, single, plural = str:find("\1244(.-):(.-);")
	    if start then
	        split(str:sub(1, start - 1) .. single .. str:sub(stop + 1), t)
	        split(str:sub(1, start - 1) .. plural .. str:sub(stop + 1), t)
	    else
	        tinsert(t, (str:gsub("%%d","%%d+")))
	    end
	    return t
	end
	ItemRack.CHARGES_PATTERNS = {}
	split(ITEM_SPELL_CHARGES,ItemRack.CHARGES_PATTERNS)
	tinsert(ItemRack.CHARGES_PATTERNS,ITEM_SPELL_CHARGES_NONE)
	-- for enUS, ItemRack.CHARGES_PATTERNS now {"%d+ Charge","%d+ Charges","No Charges"}

	ItemRack.CreateTimer("MenuMouseover",ItemRack.MenuMouseover,.25,1)
	ItemRack.CreateTimer("TooltipUpdate",ItemRack.TooltipUpdate,1,1)
	
	ItemRack.CreateTimer("MinimapDragging",ItemRack.MinimapDragging,0,1)
	ItemRack.CreateTimer("LocksChanged",ItemRack.LocksChanged,.2)
	ItemRack.CreateTimer("MinimapShine",ItemRack.MinimapShineUpdate,0,1)

	for i=-2,11 do
		ItemRack.LockList[i] = {}
	end

	hooksecurefunc("UseInventoryItem",ItemRack.newUseInventoryItem)
	hooksecurefunc("UseAction",ItemRack.newUseAction)
	hooksecurefunc("UseItemByName",ItemRack.newUseItemByName)
	hooksecurefunc("PaperDollFrame_OnShow",ItemRack.newPaperDollFrame_OnShow)

	this:RegisterEvent("PLAYER_REGEN_ENABLED")
	this:RegisterEvent("PLAYER_REGEN_DISABLED")
	this:RegisterEvent("PLAYER_UNGHOST")
	this:RegisterEvent("PLAYER_ALIVE")
	this:RegisterEvent("BANKFRAME_CLOSED")
	this:RegisterEvent("BANKFRAME_OPENED")
	this:RegisterEvent("CHARACTER_POINTS_CHANGED")
	if not disable_delayed_swaps then
		-- in the event delayed swaps while casting don't work well,
		-- make disable_delayed_swaps=1 at top of this file to disable it
		this:RegisterEvent("UNIT_SPELLCAST_START")
		this:RegisterEvent("UNIT_SPELLCAST_STOP")
		this:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		this:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	end
	
	ItemRack.MoveMinimap()
	ItemRack.ReflectAlpha()
	ItemRack.SetSetBindings()

	SlashCmdList["ItemRack"] = ItemRack.SlashHandler
	SLASH_ItemRack1 = "/itemrack"

	EquipSet = ItemRack.EquipSet -- for convenience in macros/events, shorter names
	ToggleSet = ItemRack.ToggleSet
	UnequipSet = ItemRack.UnequipSet
	IsSetEquipped = ItemRack.IsSetEquipped

	-- new option defaults to pre-existing settings here
	
	ItemRackSettings.EquipOnSetPick = ItemRackSettings.EquipOnSetPick or "OFF" -- 2.21
	ItemRackUser.SetMenuWrap = ItemRackUser.SetMenuWrap or "OFF" -- 2.21
	ItemRackUser.SetMenuWrapValue = ItemRackUser.SetMenuWrapValue or 3 -- 2.21
	ItemRackSettings.MinimapTooltip = ItemRackSettings.MinimapTooltip or "ON" -- 2.21
	
end

function ItemRack.Print(msg)
	if msg then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFCCCCCCItemRack: |cFFFFFFFF"..msg)
	end
end

function ItemRack.UpdateCurrentSet()
	local texture = ItemRack.GetTextureBySlot(20)
	local setname = ItemRackUser.CurrentSet or ""
	if ItemRackButton20 and ItemRackUser.Buttons[20] then
		ItemRackButton20Icon:SetTexture(texture)
		ItemRackButton20Name:SetText(setname)
	end
	ItemRackMinimapIcon:SetTexture(texture)
	if setname ~= ItemRack.LastCurrentSet then
		ItemRack.MinimapShineFadeIn()
		ItemRack.LastCurrentSet = setname
	end
end

--[[ Item info gathering ]]

function ItemRack.GetTextureBySlot(slot)
	if slot==20 then
		if ItemRackUser.CurrentSet and ItemRackUser.Sets[ItemRackUser.CurrentSet] then
			return ItemRackUser.Sets[ItemRackUser.CurrentSet].icon
		else
			return "Interface\\AddOns\\ItemRack\\ItemRackIcon"
		end
	else
		local texture = GetInventoryItemTexture("player",slot)
		if texture then
			return texture
		else
			_,texture = GetInventorySlotInfo(ItemRack.SlotInfo[slot].name)
			return texture
		end
	end
end

-- returns an ItemRack-style ID (1234:0:0:0:0:0) if an item exists, or 0 for none
-- bag,nil = inventory slot; bag,slot = container slot
function ItemRack.GetID(bag,slot)
	local itemLink
	if slot then
		itemLink = GetContainerItemLink(bag,slot)
	else
		itemLink = GetInventoryItemLink("player",bag)
	end
-- hallelujah ammo slot has a link now! can remove this if no adverse effects
--	if bag==0 and not slot and GetInventoryItemTexture("player",0) then
--		ItemRackTooltip:SetInventoryItem("player",0)
--		_,itemLink = GetItemInfo(ItemRackTooltipTextLeft1:GetText() or 0)
--	end
	return string.match(itemLink or "","item:(.+):%-?%d+") or 0
end

function ItemRack.SameID(id1,id2)
	id1 = string.match(id1 or "","^(%-?%d+)")
	id2 = string.match(id2 or "","^(%-?%d+)")
	return id1==id2
end

function ItemRack.GetInfoByID(id)
	local name,texture,equip,quality
	if id and id~=0 then
		local itemID = string.match(id,"^(%-?%d+)")
		name,_,quality,_,_,_,_,_,equip,texture = GetItemInfo(itemID)
	else
		name,texture,quality = "(пусто)","Interface\\Icons\\INV_Misc_QuestionMark",0
	end
	return name,texture,equip,quality
end

function ItemRack.GetCountByID(id)
	return tonumber(GetItemCount(string.match(id or "","^(%-?%d+)") or 0))
end

-- returns inv,bag,slot of an item id (1234:0:0:0:0:0:0)
-- or the base id (1234) if specific id not found
function ItemRack.FindItem(id,lock)

	local locklist, getid = ItemRack.LockList, ItemRack.GetID

	-- look for item in known items cache first
	local knownID = ItemRack.KnownItems[id]
	if knownID then
		local bag,slot = math.floor(knownID/100),mod(knownID,100)
		if bag<0 and not slot then
			bag = bag*-1
			if id==getid(bag) and (not lock or not locklist[-2][bag]) then
				if lock then locklist[-2][bag]=1 end
				return bag
			end
		else
			if id==getid(bag,slot) and (not lock or not locklist[bag][slot]) then
				if lock then locklist[bag][slot]=1 end
				return nil,bag,slot
			end
		end
	end

	-- search bags
	for i=4,0,-1 do
		for j=1,GetContainerNumSlots(i) do
			if id==getid(i,j) and (not lock or not locklist[i][j]) then
				if lock then locklist[i][j]=1 end
				return nil,i,j
			end
		end
	end
	-- search inventory
	for i=0,19 do
		if id==getid(i) and (not lock or not locklist[-2][i]) then
			if lock then locklist[-2][i]=1 end
			return i
		end
	end
	-- search bags for base id matches
	for i=4,0,-1 do
		for j=1,GetContainerNumSlots(i) do
			if ItemRack.SameID(id,getid(i,j)) and (not lock or not locklist[i][j]) then
				if lock then locklist[i][j]=1 end
				return nil,i,j
			end
		end
	end
	-- search inventory for base id matches
	for i=0,19 do
		if ItemRack.SameID(id,getid(i)) and (not lock or not locklist[-2][i]) then
			if lock then locklist[-2][i]=1 end
			return i
		end
	end
end

function ItemRack.FindInBank(id,lock)
	if ItemRack.BankOpen then
		for _,i in pairs(ItemRack.BankSlots) do
			if ItemRack.ValidBag(i) then
				for j=1,GetContainerNumSlots(i) do
					if id==ItemRack.GetID(i,j) and (not lock or ItemRack.LockList[i][j]) then
						if lock then ItemRack.LockList[i][j]=1 end
						return i,j
					end
				end
			end
		end
		for _,i in pairs(ItemRack.BankSlots) do
			if ItemRack.ValidBag(i) then
				for j=1,GetContainerNumSlots(i) do
					if ItemRack.SameID(id,ItemRack.GetID(i,j)) and (not lock or not ItemRack.LockList[i][j]) then
						if lock then ItemRack.LockList[i][j]=1 end
						return i,j
					end
				end
			end
		end
	end
end

-- returns true if the bagid (0-4) is a normal "Container", as opposed to quivers and ammo pouches
function ItemRack.ValidBag(bagid)
	local linkid,bagtype
	if bagid==0 or bagid==-1 then
		return 1
	else
		local invID = ContainerIDToInventoryID(bagid)
		linkid = string.match(GetInventoryItemLink("player",invID) or "","item:(%-?%d+)")
		if GetItemFamily(linkid)==0 then
			return 1
		end
--		if linkid then
--			_,_,_,_,_,_,bagtype = GetItemInfo(linkid)
--			if bagtype=="Bag" or bagtype=="Conteneur" or bagtype=="Beh\195\164lter" then
--				return 1
--			end
--		end
	end
end

function ItemRack.ClearLockList()
	for i=-2,11 do
		for j in pairs(ItemRack.LockList[i]) do
			ItemRack.LockList[i][j] = nil
		end
	end
	if ItemRack.LocksHaveChanged then
		ItemRack.LocksHaveChanged = nil
		ItemRack.PopulateKnownItems()
	end
end

function ItemRack.FindSpace()
	for i=4,0,-1 do
		if ItemRack.ValidBag(i) then
			for j=1,GetContainerNumSlots(i) do
				if not GetContainerItemLink(i,j) and not ItemRack.LockList[i][j] then
					ItemRack.LockList[i][j] = 1
					return i,j
				end
			end
		end
	end
end

function ItemRack.FindBankSpace()
	if not ItemRack.BankOpen then return end
	for _,i in pairs(ItemRack.BankSlots) do
		if ItemRack.ValidBag(i) then
			for j=1,GetContainerNumSlots(i) do
				if not GetContainerItemLink(i,j) and not ItemRack.LockList[i][j] then
					ItemRack.LockList[i][j] = 1
					return i,j
				end
			end
		end
	end
end

function ItemRack.IsRed(which)
	local r,g,b = getglobal("ItemRackTooltipText"..which):GetTextColor()
	if r>.9 and g<.2 and b<.2 then
		return 1
	end
end

function ItemRack.PlayerCanWear(invslot,bag,slot)
	local found,lines,txt = false

	local i=1
	while getglobal("ItemRackTooltipTextLeft"..i) do
		-- ClearLines doesn't remove colors, manually remove them
		getglobal("ItemRackTooltipTextLeft"..i):SetTextColor(0,0,0)
		getglobal("ItemRackTooltipTextRight"..i):SetTextColor(0,0,0)
		i=i+1
	end
	ItemRackTooltip:SetBagItem(bag,slot)

	for i=2,ItemRackTooltip:NumLines() do
		txt = getglobal("ItemRackTooltipTextLeft"..i):GetText()
		-- if either left or right text is red and this isn't a Durability x/x line, this item can't be worn
		if (ItemRack.IsRed("Left"..i) or ItemRack.IsRed("Right"..i)) and not string.find(txt,ItemRack.DURABILITY_PATTERN) and not string.match(txt,ItemRack.REQUIRES_PATTERN) then
			return nil
		end
	end

	local _,_,itemType = ItemRack.GetInfoByID(ItemRack.GetID(bag,slot))
	if itemType=="INVTYPE_WEAPON" and invslot==17 and not ItemRack.CanWearOneHandOffHand then
		-- if this is a One-Hand going to offhand, and player can't wear one-hand offhands, this item can't be worn
		return nil
	end

	-- the gammut was run, this item can be worn
	return 1
end

function ItemRack.IsSoulbound(bag,slot)
	ItemRackTooltip:SetBagItem(bag,slot)
	for i=2,5 do
		text = getglobal("ItemRackTooltipTextLeft"..i):GetText()
		if text==ITEM_SOULBOUND or text==ITEM_BIND_QUEST or text==ITEM_CONJURED then
			return 1
		end
	end
end

-- function happens .2 seconds after last ITEM_LOCK_CHANGE
function ItemRack.LocksChanged()
	ItemRack.UpdateButtonLocks()
	if ItemRack.SetSwapping then
		ItemRack.LockChangedDuringSetSwap()
	elseif ItemRackMenuFrame:IsVisible() and ItemRack.BankOpen and not ItemRack.AnythingLocked() then
		ItemRackMenuFrame:Hide()
		ItemRack.BuildMenu()
	elseif #(ItemRack.SetsWaiting)>0 and not ItemRack.AnythingLocked() then
		ItemRack.ProcessSetsWaiting()
	end
end

function ItemRack.PopulateKnownItems()
	local known = ItemRack.KnownItems
	for i in pairs(known) do
		known[i] = nil
	end
	local id
	local getid = ItemRack.GetID
	for i=0,19 do
		id = getid(i)
		if id~=0 then
			known[id] = i*-1
		end
	end
	for i=0,4 do
		for j=1,GetContainerNumSlots(i) do
			id = getid(i,j)
			if id~=0 then
				if IsEquippableItem(string.match(id,"^(%d+)")) then
					known[id] = i*100+j
				end
			end
		end
	end
end

--[[ Timers ]]

function ItemRack.InitTimers()
	ItemRack.TimerPool = {}
	ItemRack.Timers = {}
end

-- ItemRack.CreateTimer(name,func,delay,rep)

-- name = arbitrary name to identify this timer
-- func = function to run when the delay finishes
-- delay = time (in seconds) after the timer is started before func is run
-- rep = nil or 1, whether to repeat the delay once it's reached
-- 
-- The standard use is to create a timer, and then ItemRack.StartTimer
-- when you want to run the delayed function.
--
-- You can do /script ItemRack.TimerDebug() anytime to see all timer status

function ItemRack.CreateTimer(name,func,delay,rep)
	ItemRack.TimerPool[name] = { func=func,delay=delay,rep=rep,elapsed=delay }
end

function ItemRack.IsTimerActive(name)
	for i,j in ipairs(ItemRack.Timers) do
		if j==name then
			return i
		end
	end
	return nil
end

function ItemRack.StartTimer(name,delay)
	ItemRack.TimerPool[name].elapsed = delay or ItemRack.TimerPool[name].delay
	if not ItemRack.IsTimerActive(name) then
		table.insert(ItemRack.Timers,name)
		ItemRackFrame:Show()
	end
end

function ItemRack.StopTimer(name)
	local idx = ItemRack.IsTimerActive(name)
	if idx then
		table.remove(ItemRack.Timers,idx)
		if table.getn(ItemRack.Timers)<1 then
			ItemRackFrame:Hide()
		end
	end
end

function ItemRack.OnUpdate(self,elapsed)
	local timerPool
	for _,name in ipairs(ItemRack.Timers) do
		timerPool = ItemRack.TimerPool[name]
		timerPool.elapsed = timerPool.elapsed - elapsed
		if timerPool.elapsed < 0 then
			timerPool.func()
			if timerPool.rep then
				timerPool.elapsed = timerPool.delay
			else
				ItemRack.StopTimer(name)
			end
		end
	end
end

function ItemRack.TimerDebug()
	local on = "|cFF00FF00On"
	local off = "|cFFFF0000Off"
	DEFAULT_CHAT_FRAME:AddMessage("|cFF44AAFFItemRackFrame is "..(ItemRackFrame:IsVisible() and on or off))
	for i in pairs(ItemRack.TimerPool) do
		DEFAULT_CHAT_FRAME:AddMessage(i.." is "..(ItemRack.IsTimerActive(i) and on or off))
	end
end

--[[ Menu ]]

function ItemRack.DockWindows(menuDock,relativeTo,mainDock,menuOrient,movable)
	ItemRackMenuFrame:ClearAllPoints()
	ItemRack.currentDock = mainDock..menuDock
	ItemRackMenuFrame:SetPoint(menuDock,relativeTo,mainDock,ItemRack.DockInfo[ItemRack.currentDock].xoff,ItemRack.DockInfo[ItemRack.currentDock].yoff)
	ItemRackMenuFrame:SetParent(relativeTo)
	ItemRackMenuFrame:SetFrameStrata("HIGH")
	ItemRack.mainDock = mainDock
	ItemRack.menuDock = menuDock
	ItemRack.menuOrient = menuOrient
	ItemRack.menuMovable = movable
	ItemRack.menuDockedTo = relativeTo:GetName()
	ItemRack.MenuMouseoverFrames[relativeTo:GetName()] = 1 -- add frame to mouseover candidates
	ItemRack.ReflectLock(not ItemRack.menuMovable)
	ItemRack.ReflectMenuScale()
end

function ItemRack.AlreadyInMenu(id)
	for i=1,#(ItemRack.Menu) do
		if ItemRack.Menu[i]==id then
			return 1
		end
	end
end

function ItemRack.AddToMenu(itemID)
	if ItemRackSettings.AllowHidden=="OFF" or (IsAltKeyDown() or not ItemRack.IsHidden(itemID)) then
		table.insert(ItemRack.Menu,itemID)
	end
end

-- builds a popout menu for slots or set button
-- id = 0-19 for inventory slots, or 20 for set, or nil for last defined slot/set menu (ItemRack.menuOpen)
-- before calling ItemRack.BuildMenu, you should call ItemRack.DockWindows
-- if menuInclude, then also include the worn item(s) in the menu
function ItemRack.BuildMenu(id,menuInclude)
	if id then
		ItemRack.menuOpen = id
		ItemRack.menuInclude = menuInclude
	else
		id = ItemRack.menuOpen
		menuInclude = ItemRack.menuInclude
	end

	local showButtonMenu = (ItemRackButtonMenu and ItemRack.menuMovable) and (IsAltKeyDown() or ItemRackUser.Locked=="OFF")

	for i in pairs(ItemRack.Menu) do
		ItemRack.Menu[i] = nil
	end

	local itemLink,itemID,itemName,equipSlot,itemTexture

	if id<20 then
		if menuInclude then
			itemID = ItemRack.GetID(id)
			if itemID~=0 then
				ItemRack.AddToMenu(itemID)
			end
			if ItemRack.SlotInfo[id].other then
				itemID = ItemRack.GetID(ItemRack.SlotInfo[id].other)
				if itemID~=0 then
					ItemRack.AddToMenu(itemID)
				end
			end
		end
		for i=0,4 do
			for j=1,GetContainerNumSlots(i) do
				itemID = ItemRack.GetID(i,j)
				itemName,itemTexture,equipSlot = ItemRack.GetInfoByID(itemID)
				if ItemRack.SlotInfo[id][equipSlot] and ItemRack.PlayerCanWear(id,i,j) and (ItemRack.IsSoulbound(i,j)) then
					if id~=0 or not ItemRack.AlreadyInMenu(itemID) then
						ItemRack.AddToMenu(itemID)
					end
				end
			end
		end
		if ItemRack.BankOpen then
			for _,i in pairs(ItemRack.BankSlots) do
				for j=1,GetContainerNumSlots(i) do
					itemID = ItemRack.GetID(i,j)
					itemName,itemTexture,equipSlot = ItemRack.GetInfoByID(itemID)
					if ItemRack.SlotInfo[id][equipSlot] and ItemRack.PlayerCanWear(id,i,j) and (ItemRack.IsSoulbound(i,j)) then
						if id~=0 or not ItemRack.AlreadyInMenu(itemID) then
							ItemRack.AddToMenu(itemID)
						end
					end
				end
			end
		elseif ItemRack.GetID(id)~=0 and ItemRackSettings.AllowEmpty=="ON" then
			table.insert(ItemRack.Menu,0)
		end
	else
		for i in pairs(ItemRackUser.Sets) do
			if not string.match(i,"^~") then
				ItemRack.AddToMenu(i)
			end
			table.sort(ItemRack.Menu)
		end
	end
	if showButtonMenu then
		table.insert(ItemRack.Menu,"MENU")
	end

	if #(ItemRack.Menu)<1 then
		ItemRackMenuFrame:Hide()
	else
		-- display outward from docking point
		local col,row,xpos,ypos = 0,0,ItemRack.DockInfo[ItemRack.currentDock].xstart,ItemRack.DockInfo[ItemRack.currentDock].ystart
		local max_cols = 1
		local button

		if ItemRackUser.SetMenuWrap=="ON" then
			max_cols = ItemRackUser.SetMenuWrapValue
		elseif #(ItemRack.Menu)>24 then
			max_cols = 5
		elseif #(ItemRack.Menu)>18 then
			max_cols = 4
		elseif #(ItemRack.Menu)>9 then
			max_cols = 3
		elseif #(ItemRack.Menu)>4 then
			max_cols = 2
		end

		for i=1,#(ItemRack.Menu) do
			button = ItemRack.CreateMenuButton(i,ItemRack.Menu[i]) or ItemRackButtonMenu
			button:SetPoint("TOPLEFT",ItemRackMenuFrame,ItemRack.menuDock,xpos,ypos)
			button:SetFrameLevel(ItemRackMenuFrame:GetFrameLevel()+1)
			if ItemRack.menuOrient=="VERTICAL" then
				xpos = xpos + ItemRack.DockInfo[ItemRack.currentDock].xdir*40
				col = col + 1
				if col==max_cols then
					xpos = ItemRack.DockInfo[ItemRack.currentDock].xstart
					col = 0
					ypos = ypos + ItemRack.DockInfo[ItemRack.currentDock].ydir*40
					row = row + 1
				end
				button:Show()
			else
				ypos = ypos + ItemRack.DockInfo[ItemRack.currentDock].ydir*40
				col = col + 1
				if col==max_cols then
					ypos = ItemRack.DockInfo[ItemRack.currentDock].ystart
					col = 0
					xpos = xpos + ItemRack.DockInfo[ItemRack.currentDock].xdir*40
					row = row + 1
				end
				button:Show()
			end
			icon = getglobal("ItemRackMenu"..i.."Icon")
			
			if icon then
				icon:SetDesaturated(0)
				if IsAltKeyDown() and ItemRackSettings.AllowHidden=="ON" and IsAltKeyDown() and ItemRack.IsHidden(ItemRack.Menu[i]) then
					icon:SetDesaturated(1)
				end
			end
		end
		if showButtonMenu then
			table.remove(ItemRack.Menu)
		else
			ItemRackButtonMenu:Hide()
		end
		local i = #(ItemRack.Menu)+1
		while getglobal("ItemRackMenu"..i) do
			getglobal("ItemRackMenu"..i):Hide()
			i=i+1
		end

		if col==0 then
			row = row-1
		end

		if ItemRack.menuOrient=="VERTICAL" then
			ItemRackMenuFrame:SetWidth(12+(max_cols*40))
			ItemRackMenuFrame:SetHeight(12+((row+1)*40))
		else
			ItemRackMenuFrame:SetWidth(12+((row+1)*40))
			ItemRackMenuFrame:SetHeight(12+(max_cols*40))
		end

		ItemRack.StartTimer("MenuMouseover")
		ItemRackMenuFrame:Show()
		ItemRack.UpdateMenuCooldowns()
		local count
		local border
		for i=1,#(ItemRack.Menu) do
			border = getglobal("ItemRackMenu"..i.."Border")
			border:Hide()
			if ItemRack.menuOpen==20 then
				getglobal("ItemRackMenu"..i.."Name"):SetText(ItemRack.Menu[i])
				local missing = ItemRack.MissingItems(ItemRack.Menu[i])
				if missing==0 then
					border:SetVertexColor(1,.1,.1)
					border:Show()
				elseif missing==1 then
					border:SetVertexColor(.3,.5,1)
					border:Show()
				end
			else
				getglobal("ItemRackMenu"..i.."Name"):SetText("")
				if ItemRack.Menu[i]~=0 and ItemRack.GetCountByID(ItemRack.Menu[i])==0 then
					border:SetVertexColor(.3,.5,1)
					border:Show()
				end
			end
			if ItemRack.menuOpen==0 then
				count = ItemRack.GetCountByID(ItemRack.Menu[i])
				getglobal("ItemRackMenu"..i.."Count"):SetText(count>0 and count or "")
			else
				getglobal("ItemRackMenu"..i.."Count"):SetText("")
			end
		end
	end
end

function ItemRack.UpdateMenuCooldowns()
	local id
	for i=1,#(ItemRack.Menu) do
		id = tonumber(string.match(ItemRack.Menu[i],"^(%-?%d+)"))
		if id and id>0 and ItemRack.menuOpen<20 then
			CooldownFrame_SetTimer(getglobal("ItemRackMenu"..i.."Cooldown"),GetItemCooldown(id))
		else
			getglobal("ItemRackMenu"..i.."Cooldown"):Hide()
		end
	end
	
end



function ItemRack.MenuMouseover()
	local frame = GetMouseFocus()
	if MouseIsOver(ItemRackMenuFrame) or IsShiftKeyDown() or (frame and frame:GetName() and frame:IsVisible() and ItemRack.MenuMouseoverFrames[frame:GetName()]) then
		return -- keep menu open if mouse over menu, shift is down or mouse is immediately over a mouseover frame
	end
	for i in pairs(ItemRack.MenuMouseoverFrames) do
		frame = getglobal(i)
		if frame and frame:IsVisible() and MouseIsOver(frame) then
			return -- keep menu open if some frame beneath mouse is a mouseover frame
		end
	end
	ItemRack.StopTimer("MenuMouseover")
	ItemRackMenuFrame:Hide()
end

function ItemRack.MenuOnHide()
	ItemRack.menuDockedTo = nil
end

function ItemRack.CreateMenuButton(idx,itemID)
	if itemID=="MENU" then return end
	local button
	if not getglobal("ItemRackMenu"..idx) then
		button = CreateFrame("CheckButton","ItemRackMenu"..idx,ItemRackMenuFrame,"ActionButtonTemplate")
		button:SetID(idx)
		button:SetFrameStrata("HIGH")
--		button:SetFrameLevel(ItemRackMenuFrame:GetFrameLevel()+1)
		button:RegisterForClicks("LeftButtonUp","RightButtonUp")
		button:SetScript("OnClick",ItemRack.MenuOnClick)
		button:SetScript("OnEnter",ItemRack.MenuTooltip)
		button:SetScript("OnLeave",ItemRack.ClearTooltip)
		CreateFrame("Frame",nil,button,"ItemRackTimeTemplate")
		ItemRack.SetFont("ItemRackMenu"..idx)
--		local font = button:CreateFontString("ItemRackMenu"..idx.."Time","OVERLAY","NumberFontNormal")
--		font:SetJustifyH("CENTER")
--		font:SetWidth(36)
--		font:SetHeight(12)
--		font:SetPoint("BOTTOMRIGHT","ItemRackMenu"..idx,"BOTTOMRIGHT")
	end
	if itemID~=0 then
		if ItemRackUser.Sets[itemID] then
			getglobal("ItemRackMenu"..idx.."Icon"):SetTexture(ItemRackUser.Sets[itemID].icon)
		else
			local _,texture = ItemRack.GetInfoByID(itemID)
			getglobal("ItemRackMenu"..idx.."Icon"):SetTexture(texture)
		end
	else
		getglobal("ItemRackMenu"..idx.."Icon"):SetTexture(select(2,GetInventorySlotInfo(ItemRack.SlotInfo[ItemRack.menuOpen].name)))
	end
	return getglobal("ItemRackMenu"..idx)
end

function ItemRack.ChatLinkID(itemID)
	local inv,bag,slot = ItemRack.FindItem(itemID)
	if bag then
		ChatFrameEditBox:Insert(GetContainerItemLink(bag,slot))
	elseif inv then
		ChatFrameEditBox:Insert(GetInventoryItemLink("player",inv))
	else
		local _,itemLink = GetItemInfo(string.match(itemID,"^(%-?%d+)") or 0)
		if itemLink then
			ChatFrameEditBox:Insert(itemLink)
		end
	end
end

function ItemRack.MenuOnClick()
	this:SetChecked(0)
	local item = ItemRack.Menu[this:GetID()]
	ItemRack.ClearLockList()
	if IsAltKeyDown() and ItemRackSettings.AllowHidden=="ON" then
		ItemRack.ToggleHidden(item)
		ItemRack.BuildMenu()
	elseif IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
		ItemRack.ChatLinkID(item)
	elseif ItemRack.menuInclude then
		if ItemRackOptFrame and ItemRackOptFrame:IsVisible() then
			ItemRackOpt.Inv[ItemRack.menuOpen].id = item
			ItemRackOpt.Inv[ItemRack.menuOpen].selected = 1
			ItemRackOpt.UpdateInv()
			ItemRackMenuFrame:Hide()
		end
	elseif ItemRack.menuOpen<20 then
		if ItemRack.BankOpen then
			if ItemRack.GetCountByID(item)==0 then
				local bankBag,bankSlot = ItemRack.FindInBank(item)
				if bankBag then
					local freeBag,freeSlot = ItemRack.FindSpace()
					if freeBag and not SpellIsTargeting() and not GetCursorInfo() then
						PickupContainerItem(bankBag,bankSlot)
						PickupContainerItem(freeBag,freeSlot)
					else
						ItemRack.Print("Not enough room in bags to pull this item from bank.")
					end
				end
			else
				local bankBag,bankSlot = ItemRack.FindBankSpace()
				if bankBag then
					local _,bag,slot = ItemRack.FindItem(item)
					if bag and not SpellIsTargeting() and not GetCursorInfo() then
						PickupContainerItem(bag,slot)
						PickupContainerItem(bankBag,bankSlot)
					end
				else
					ItemRack.Print("Not enough room in bank to put this item.")
				end
			end
		else
			if ItemRackSettings.EquipOnSetPick=="ON" and ItemRackOptFrame and ItemRackOptFrame:IsVisible() then
				ItemRackOpt.Inv[ItemRack.menuOpen].id = item
				ItemRackOpt.Inv[ItemRack.menuOpen].selected = 1
				ItemRackOpt.UpdateInv()
			end
			
			ItemRack.EquipItemByID(item,ItemRack.menuOpen)
			ItemRackMenuFrame:Hide()
		end
	elseif ItemRack.menuOpen==20 then
		if ItemRack.BankOpen then
			if ItemRack.MissingItems(item)==1 then
				ItemRack.GetBankedSet(item)
			else
				ItemRack.PutBankedSet(item)
			end
		elseif ItemRackSettings.EquipToggle=="ON" or IsShiftKeyDown() then
			ItemRack.ToggleSet(item)
		else
			ItemRack.EquipSet(item)
			ItemRack.EquipSet(item)

		end
		if not ItemRack.BankOpen then
			ItemRack.StopTimer("MenuMouseover")
			ItemRackMenuFrame:Hide()
		end
	end
end

function ItemRack.EquipItemByID(id,slot)
	if not id then return end
	if not ItemRack.SlotInfo[slot].swappable and (UnitAffectingCombat("player") or ItemRack.IsPlayerReallyDead()) then
		ItemRack.AddToCombatQueue(slot,id)
	elseif not GetCursorInfo() and not SpellIsTargeting() then
		if id~=0 then -- not an empty slot
			local _,b,s = ItemRack.FindItem(id)
			if b then
				local _,_,isLocked = GetContainerItemInfo(b,s)
				if not isLocked and not IsInventoryItemLocked(slot) then
					-- neither container item nor inventory item locked, perform swap
					local _,_,equipSlot = ItemRack.GetInfoByID(id)
					if equipSlot~="INVTYPE_2HWEAPON" or (ItemRack.HasTitansGrip and not ItemRack.NoTitansGrip[select(7,GetItemInfo(GetContainerItemLink(b,s))) or ""]) or not GetInventoryItemLink("player",17) then
						PickupContainerItem(b,s)
						PickupInventoryItem(slot)
					else
						local bfree,sfree = ItemRack.FindSpace()
						if bfree then
							PickupInventoryItem(17)
							PickupContainerItem(bfree,sfree)
							PickupInventoryItem(slot)
							PickupContainerItem(b,s)
						else
							ItemRack.Print("Not enough room to perform swap.")
						end
					end
				end
			end
		else
			local b,s = ItemRack.FindSpace()
			if b and not IsInventoryItemLocked(slot) then
				PickupInventoryItem(slot)
				PickupContainerItem(b,s)
			else
				ItemRack.Print("Not enough room to perform swap.")
			end
		end
	end
end	

--[[ Hooks to capture item use outside the mod ]]

function ItemRack.ReflectItemUse(id)
	if ItemRackUser.Buttons[id] then
		getglobal("ItemRackButton"..id):SetChecked(1)
		ItemRack.ReflectClicked[id] = 1
		ItemRack.StartTimer("ReflectClickedUpdate")
	end
	local baseID = string.match(GetInventoryItemLink("player",id) or "","item:(%-?%d+)")
	if baseID then
		ItemRackUser.ItemsUsed[baseID] = 1
	end
end

function ItemRack.newPaperDollFrame_OnShow()
	ItemRack.UpdateCombatQueue()
end

function ItemRack.newUseInventoryItem(slot)
	ItemRack.ReflectItemUse(slot)
end

function ItemRack.newUseAction(slot,cursor,self)
	if IsEquippedAction(slot) then
		local actionType,actionId = GetActionInfo(slot)
		if actionType=="item" then
			for i=0,19 do
				if tonumber(string.match(GetInventoryItemLink("player",i) or "","item:(%-?%d+)"))==actionId then
					ItemRack.ReflectItemUse(i)
					break
				end
			end
		end
	end
end

function ItemRack.newUseItemByName(name)
	for i=0,19 do
		if name==GetItemInfo(GetInventoryItemLink("player",i) or 0) then
			ItemRack.ReflectItemUse(i)
			break
		end
	end
end

--[[ Combat queue ]]

function ItemRack.IsPlayerReallyDead()
	local dead = UnitIsDeadOrGhost("player")
	if select(2,UnitClass("player"))=="HUNTER" then
		if GetLocale()=="enUS" and UnitAura("player","Feign Death") then
			return nil
		else
			for i=1,24 do
				if select(3,UnitBuff("player",i))=="Interface\\Icons\\Ability_Rogue_FeignDeath" then
					return nil
				end
			end
		end
	end
	return dead
end

function ItemRack.AddToCombatQueue(slot,id)
	if ItemRack.CombatQueue[slot]==id then
		ItemRack.CombatQueue[slot] = nil
	else
		ItemRack.CombatQueue[slot] = id
	end
	ItemRack.UpdateCombatQueue()
end

function ItemRack.UpdateCombatQueue()
	local queue,id
	for i in pairs(ItemRackUser.Buttons) do
		queue = getglobal("ItemRackButton"..i.."Queue")
		if ItemRack.CombatQueue[i] then
			queue:SetTexture(select(2,ItemRack.GetInfoByID(ItemRack.CombatQueue[i])))
			queue:SetAlpha(1)
			queue:Show()
		elseif ItemRackUser.QueuesEnabled[i] then
			queue:SetTexture("Interface\\AddOns\\ItemRack\\ItemRackGear")
			
			queue:Show()
		elseif i~=20 then
			queue:Hide()
		end
	end
	if PaperDollFrame:IsVisible() then
		for i=1,19 do
			queue = getglobal("Character"..ItemRack.SlotInfo[i].name.."Queue")
			if ItemRack.CombatQueue[i] then
				queue:SetTexture(select(2,ItemRack.GetInfoByID(ItemRack.CombatQueue[i])))
				queue:Show()
			else
				queue:Hide()
			end
		end
	end
end

--[[ Tooltip ]]

-- request a tooltip of an inventory slot
function ItemRack.InventoryTooltip()
	local id = this:GetID()
	if id==20 then
		ItemRack.SetTooltip(ItemRackUser.CurrentSet)
	else
		ItemRack.TooltipOwner = this
		ItemRack.TooltipType = "INVENTORY"
		ItemRack.TooltipSlot = id
		ItemRack.TooltipBag = ItemRack.CombatQueue[id] and ItemRack.GetInfoByID(ItemRack.CombatQueue[id])
		ItemRack.StartTimer("TooltipUpdate",0)
	end
end

-- request a tooltip of a menu item
function ItemRack.MenuTooltip()
	local id = this:GetID()
	if ItemRack.menuOpen==20 then
		ItemRack.SetTooltip(ItemRack.Menu[id])
	else
		ItemRack.TooltipOwner = this
		ItemRack.TooltipType = "BAG"
		local invMaybe
		invMaybe,ItemRack.TooltipBag,ItemRack.TooltipSlot = ItemRack.FindItem(ItemRack.Menu[this:GetID()])
		if ItemRack.TooltipBag and ItemRack.TooltipSlot then
			ItemRack.StartTimer("TooltipUpdate",0)
		else -- if invMaybe then
			ItemRack.IDTooltip(ItemRack.Menu[id])
		end
	end
end

-- request a tooltip of a straight item id
function ItemRack.IDTooltip(itemID)
	ItemRack.AnchorTooltip()
	local inv,bag,slot = ItemRack.FindItem(itemID)
	if inv then
		GameTooltip:SetInventoryItem("player",inv)
	elseif bag then
		GameTooltip:SetBagItem(bag,slot)
	else
		-- suffix fix by Nayala
		bag,slot = ItemRack.FindInBank(itemID)
		if bag then
			itemID = GetContainerItemLink(bag,slot)
		else
			itemID = "item:"..itemID..":0"
		end
		GameTooltip:SetHyperlink(itemID)
	end
	ItemRack.ShrinkTooltip()
	GameTooltip:Show()
end

function ItemRack.ClearTooltip()
	GameTooltip:Hide()
	ItemRack.StopTimer("TooltipUpdate")
	ItemRack.TooltipType = nil
end

function ItemRack.AnchorTooltip(owner)
	owner = owner or this
	if string.match(ItemRack.menuDockedTo or "","^Character") then
		GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
	elseif ItemRackSettings.TooltipFollow=="ON" then
		if owner.GetLeft and owner:GetLeft() and owner:GetLeft()<400 then
			GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
		else
			GameTooltip:SetOwner(owner,"ANCHOR_LEFT")
		end
	else
		GameTooltip_SetDefaultAnchor(GameTooltip,owner)
	end
end

-- display the tooltip created in the functions above, once a second if item has a cooldown
function ItemRack.TooltipUpdate()
	if ItemRack.TooltipType then
		local cooldown
		ItemRack.AnchorTooltip(ItemRack.TooltipOwner)
		if ItemRack.TooltipType=="BAG" then
			GameTooltip:SetBagItem(ItemRack.TooltipBag,ItemRack.TooltipSlot)
			cooldown = GetContainerItemCooldown(ItemRack.TooltipBag,ItemRack.TooltipSlot)
		else
			GameTooltip:SetInventoryItem("player",ItemRack.TooltipSlot)
			cooldown = GetInventoryItemCooldown("player",ItemRack.TooltipSlot)
		end
		ItemRack.ShrinkTooltip(ItemRack.TooltipOwner) -- if TinyTooltips on, shrink it
		if ItemRack.TooltipType=="INVENTORY" and ItemRack.TooltipBag then
			GameTooltip:AddLine("Queued: "..ItemRack.TooltipBag)
		end
		GameTooltip:Show()
		if cooldown==0 then
			-- stop updates if this trinket has no cooldown
			ItemRack.StopTimer("TooltipUpdate")
			ItemRack.TooltipType = nil
		end
	end

end

-- normal tooltip for options
function ItemRack.OnTooltip(line1,line2)
	if ItemRackSettings.ShowTooltips=="ON" then
		ItemRack.AnchorTooltip()
		if line1 then
			GameTooltip:AddLine(line1)
			GameTooltip:AddLine(line2,.8,.8,.8,1)
			GameTooltip:Show()
			return
		else
			local name = this:GetName() or ""
			for i=1,#(ItemRack.TooltipInfo) do
				if ItemRack.TooltipInfo[i][1]==name and ItemRack.TooltipInfo[i][2] then
					GameTooltip:AddLine(ItemRack.TooltipInfo[i][2])
					GameTooltip:AddLine(ItemRack.TooltipInfo[i][3],.8,.8,.8,1)
					GameTooltip:Show()
					return
				end
			end
		end
	end
end

function ItemRack.ShrinkTooltip(owner)
	if ItemRackSettings.TinyTooltips=="ON" then
		local r,g,b = GameTooltipTextLeft1:GetTextColor()
		local name = GameTooltipTextLeft1:GetText()
		local line,charge,durability,cooldown
		for i=2,GameTooltip:NumLines() do
			line = getglobal("GameTooltipTextLeft"..i)
			if line:IsVisible() then
				line = line:GetText() or ""
				if string.match(line,ItemRack.DURABILITY_PATTERN) then
					durability = line
				end
				if string.match(line,COOLDOWN_REMAINING) then
					cooldown = line
				end
				for j in pairs(ItemRack.CHARGES_PATTERNS) do
					if string.find(line,ItemRack.CHARGES_PATTERNS[j]) then
						charge = line
					end
				end
			end
		end
		ItemRack.AnchorTooltip(owner)
		GameTooltip:AddLine(name,r,g,b)
		GameTooltip:AddLine(charge,1,1,1)
		GameTooltip:AddLine(durability,1,1,1)
		GameTooltip:AddLine(cooldown,1,1,1)
	end
end

function ItemRack.SetTooltip(setname)
	local set = setname and ItemRackUser.Sets[setname] and ItemRackUser.Sets[setname].equip
	if set then
		local itemName,itemColor
		ItemRack.AnchorTooltip(owner)
		GameTooltip:AddLine(setname)
		if ItemRackSettings.TinyTooltips~="ON" then
			for i=0,19 do
				if set[i] then
					itemName = ItemRack.GetInfoByID(set[i])
					if itemName then
						if itemName~="(пусто)" and ItemRack.GetCountByID(set[i])==0 then
							if not ItemRack.FindInBank(set[i]) then
								itemColor = "FFFF1111"
							else
								itemColor = "FF4C80FF"
							end
						else
							itemColor = "FFAAAAAA"
						end
						GameTooltip:AddLine("|cFFFFFFFF"..ItemRack.SlotInfo[i].real..": |c"..itemColor..itemName)
					end
				end
			end
		end
		GameTooltip:Show()
	end
end




--[[ Character sheet menus ]]

ItemRack.oldPaperDollItemSlotButton_OnEnter = PaperDollItemSlotButton_OnEnter

function PaperDollItemSlotButton_OnEnter(self)
	ItemRack.oldPaperDollItemSlotButton_OnEnter(self)
	
end

function ItemRack.DockMenuToCharacterSheet()
	local name = this:GetName()
	for i=0,19 do
		if name=="Character"..ItemRack.SlotInfo[i].name then
			slot = i
		end
	end
	if slot then
		if slot==0 or (slot>=16 and slot<=18) then
			ItemRack.DockWindows("TOPLEFT",this,"BOTTOMLEFT","VERTICAL")
		else
			
			ItemRack.DockWindows("TOPLEFT",this,"TOPRIGHT","HORIZONTAL")
		end
		ItemRack.BuildMenu(slot)
	end
end

--[[ Minimap button ]]

function ItemRack.MinimapDragging()
	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/Minimap:GetEffectiveScale()+70
	ypos = ypos/Minimap:GetEffectiveScale()-ymin-70

	ItemRackSettings.IconPos = math.deg(math.atan2(ypos,xpos))
	ItemRack.MoveMinimap()
end

function ItemRack.MoveMinimap()
	if ItemRackSettings.ShowMinimap=="ON" then
		local xpos,ypos
		local angle = ItemRackSettings.IconPos or -100
		if ItemRackSettings.SquareMinimap=="ON" then
			-- brute force method until trig solution figured out - min/max a point on a circle beyond square
			xpos = 110 * cos(angle)
			ypos = 110 * sin(angle)
			xpos = math.max(-82,math.min(xpos,84))
			ypos = math.max(-86,math.min(ypos,82))
		else
			xpos = 80*cos(angle)
			ypos = 80*sin(angle)
		end
		ItemRackMinimapFrame:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-xpos,ypos-52)
		ItemRackMinimapFrame:Show()
	else
		ItemRackMinimapFrame:Hide()
	end
end

function ItemRack.MinimapOnClick()
	if IsShiftKeyDown() then
		if ItemRackUser.CurrentSet and ItemRackUser.Sets[ItemRackUser.CurrentSet] then
			ItemRack.UnequipSet(ItemRackUser.CurrentSet)
		end
	
	elseif arg1=="LeftButton" then
		if ItemRackMenuFrame:IsVisible() then
			ItemRackMenuFrame:Hide()
		else
			local xpos,ypos = GetCursorPosition()
			if ypos>400 then
				ItemRack.DockWindows("TOPRIGHT",ItemRackMinimapFrame,"BOTTOMRIGHT","VERTICAL")
			else
				ItemRack.DockWindows("BOTTOMRIGHT",ItemRackMinimapFrame,"TOPRIGHT","VERTICAL")
			end
			ItemRack.BuildMenu(20)
		end
	else
		ItemRack.ToggleOptions()
	end
end

function ItemRack.MinimapOnEnter()
	if ItemRackSettings.MinimapTooltip=="ON" then
		ItemRack.OnTooltip("ItemRack","ЛКМ: Выберите комплект\nПКМ: Открыть настройки\nAlt+ ЛКМ: Показать скрытые комплекты\nAlt+ ЛКМ по слоту в 'Информации о персонаже': Чтобы показать кнопку этого слота на экране")
	end
end


function ItemRack.MinimapShineUpdate()
	ItemRack.MinimapShineAlpha = ItemRack.MinimapShineAlpha + (arg1*2*ItemRack.MinimapShineDirection)
	if ItemRack.MinimapShineAlpha < .1 then
		ItemRack.StopTimer("MinimapShine")
		ItemRackMinimapShine:Hide()
	elseif ItemRack.MinimapShineAlpha > .9 then
		ItemRack.MinimapShineDirection = -1
	else
		ItemRackMinimapShine:SetAlpha(ItemRack.MinimapShineAlpha)
	end
end

function ItemRack.MinimapShineFadeIn()
	ItemRack.MinimapShineAlpha = .1
	ItemRack.MinimapShineDirection = 1
	ItemRackMinimapShine:Show()
	ItemRack.StartTimer("MinimapShine")
end

--[[ Non-LoD options support ]]

function ItemRack.ToggleOptions(tab)
	if not ItemRackOptFrame then
		EnableAddOn("ItemRackOptions") -- it's LoD, and required. Enable if disabled
		LoadAddOn("ItemRackOptions")
	end
	if ItemRackOptFrame:IsVisible() then
		ItemRackOptFrame:Hide()
	else
		ItemRackOptFrame:Show()
		if tab then
			ItemRackOpt.TabOnClick(tab)
		end
	end
end

function ItemRack.ReflectLock(override)
	if ItemRackUser.Locked=="ON" or override then
		ItemRackMenuFrame:EnableMouse(0)
		ItemRackMenuFrame:SetBackdropBorderColor(0,0,0,0)
		ItemRackMenuFrame:SetBackdropColor(0,0,0,0)
	else
		ItemRackMenuFrame:EnableMouse(1)
		ItemRackMenuFrame:SetBackdropBorderColor(.3,.3,.3,1)
		ItemRackMenuFrame:SetBackdropColor(1,1,1,1)
	end
	if ItemRackOptFrame then
		ItemRackOpt.ListScrollFrameUpdate()
	end
end

function ItemRack.ReflectAlpha()
	if ItemRackButton0 then
		for i=0,20 do
			getglobal("ItemRackButton"..i):SetAlpha(ItemRackUser.Alpha)
		end
	end
	ItemRackMenuFrame:SetAlpha(ItemRackUser.Alpha)
end

function ItemRack.ReflectMenuScale(scale)
	scale = scale or ItemRackUser.MenuScale
	ItemRackMenuFrame:SetScale(scale)
end

function ItemRack.SetFont(button)
	local item = getglobal(button.."Time")
	
		item:SetFont("Fonts\\ARIALN.TTF",14,"OUTLINE")
		item:SetTextColor(1,1,1,1)
		item:ClearAllPoints()
		item:SetPoint("BOTTOM",button,"BOTTOM")
	
end

function ItemRack.ReflectCooldownFont()
	local item
	for i=0,20 do
		ItemRack.SetFont("ItemRackButton"..i)
	end
	local i=1
	while getglobal("ItemRackMenu"..i) do
		ItemRack.SetFont("ItemRackMenu"..i)
		i=i+1
	end
end

--[[ Hidden menu items ]]

function ItemRack.AddHidden(id)
	if id then
		for i=1,#(ItemRackUser.Hidden) do
			if ItemRackUser.Hidden[i]==id then
				return
			end
		end
		table.insert(ItemRackUser.Hidden,id)
	end
end

function ItemRack.RemoveHidden(id)
	for i=1,#(ItemRackUser.Hidden) do
		if ItemRackUser.Hidden[i]==id then
			table.remove(ItemRackUser.Hidden,i)
			break
		end
	end
end

function ItemRack.IsHidden(id)
	for i=1,#(ItemRackUser.Hidden) do
		if ItemRackUser.Hidden[i]==id then
			return 1
		end
	end
	return nil
end

function ItemRack.ToggleHidden(id)
	if ItemRack.IsHidden(id) then
		ItemRack.RemoveHidden(id)
	else
		ItemRack.AddHidden(id)
	end
end

--[[ Key bindings ]]

function ItemRack.SetSetBindings()
	local buttonName,button
	for i in pairs(ItemRackUser.Sets) do
		if ItemRackUser.Sets[i].key then
			buttonName = "ItemRack"..UnitName("player")..GetRealmName()..i
			button = getglobal(buttonName) or CreateFrame("Button",buttonName,nil,"SecureActionButtonTemplate")
			button:SetAttribute("type","macro")
			button:SetAttribute("macrotext","/script ItemRack.RunSetBinding(\""..i.."\")")
			SetBindingClick(ItemRackUser.Sets[i].key,buttonName)
		end
	end
	SaveBindings(GetCurrentBindingSet())
end

function ItemRack.RunSetBinding(setname)
	if ItemRackSettings.EquipToggle=="ON" then
		ItemRack.ToggleSet(setname)
	else
		ItemRack.EquipSet(setname)
		ItemRack.EquipSet(setname)

	end
end

function ItemRack.AddBD(id)
	if not ItemRackUser.BD then -- to support the first download with the settings of the version without black diamonds
		ItemRackUser.BD = {}
	end
	if id then			
		for i=1,#(ItemRackUser.BD) do
			if ItemRackUser.BD[i]==id then
				return
			end
		end		
		table.insert(ItemRackUser.BD,id)
	end
end

function ItemRack.RemoveBD(id)
	if ItemRackUser.BD then
		for i=1,#(ItemRackUser.BD) do
			if ItemRackUser.BD[i]==id then
				table.remove(ItemRackUser.BD,i)
				break
			end
		end
	end
end

function ItemRack.IsBD(id)
	if ItemRackUser.BD then
		for i=1,#(ItemRackUser.BD) do
			if ItemRackUser.BD[i]==id then
				return 1
			end
		end
		return nil
	end
end

--[[ Slash Handler ]]

function ItemRack.SlashHandler(arg1)

	if arg1 and string.match(arg1,"equip") then
		local set = string.match(arg1,"equip (.+)")
		if not set then
			ItemRack.Print("Usage: /itemrack equip set name")
			ItemRack.Print("ie: /itemrack equip pvp gear")
		else
			ItemRack.EquipSet(set)
			ItemRack.EquipSet(set)
		end
		return
	elseif arg1 and string.match(arg1,"toggle") then
		local sets = string.match(arg1,"toggle (.+)")
		if not sets then
			ItemRack.Print("Usage: /itemrack toggle set name[, second set name]")
			ItemRack.Print("ie: /itemrack toggle pvp gear, tanking set")
		else
			local set1,set2 = string.match(sets,"(.+), ?(.+)")
			if not set1 then
				ItemRack.ToggleSet(sets)
			else
				if ItemRack.IsSetEquipped(set1) then
					ItemRack.EquipSet(set2)
					ItemRack.EquipSet(set2)
				else
					ItemRack.EquipSet(set1)
					ItemRack.EquipSet(set1)
				end
			end
		end
		return
	end

	arg1 = string.lower(arg1)

	if arg1=="reset" then
		ItemRack.ResetButtons()
	elseif arg1=="reset everything" then
		ItemRack.ResetEverything()
	elseif arg1=="lock" then
		ItemRackUser.Locked="ON"
		ItemRack.ReflectLock()
	elseif arg1=="unlock" then
		ItemRackUser.Locked="OFF"
		ItemRack.ReflectLock()
	elseif arg1=="opt" or arg1=="options" or arg1=="config" then
		ItemRack.ToggleOptions()
	else
		ItemRack.Print("/itemrack opt : открытие окна.")
		ItemRack.Print("/itemrack equip set name : Комплект снаряжения set name - имя комплекта.")
		ItemRack.Print("/itemrack toggle set name[, second set] : переключить set name - название комплекта.")
		ItemRack.Print("/itemrack reset : сбрасывает кнопки и их настройки.")
		ItemRack.Print("/itemrack reset everything : стирает ItemRack до по умолчанию.")
		ItemRack.Print("/itemrack lock/unlock : блокирует/разблокирует кнопки.")
	end

end

--[[ Bank Support ]]

-- returns 1 if the set has a banked item, 0 if there is an item missing entirely, nil if item is on person
function ItemRack.MissingItems(setname)
	local missing
	if not setname or not ItemRackUser.Sets[setname] then return end
	for _,i in pairs(ItemRackUser.Sets[setname].equip) do
		if i~=0 and ItemRack.GetCountByID(i)==0 then
			missing = 0
			if ItemRack.FindInBank(i) then
				return 1
			end
		end
	end
	return missing
end

-- pulls setname from bank to bags
function ItemRack.GetBankedSet(setname)
	if ItemRack.MissingItems(setname)~=1 or SpellIsTargeting() or GetCursorInfo() then return end
	local bag,slot,freeBag,freeSlot
	ItemRack.ClearLockList()
	for _,i in pairs(ItemRackUser.Sets[setname].equip) do
		bag,slot = ItemRack.FindInBank(i)
		if bag then
			freeBag,freeSlot = ItemRack.FindSpace()
			if freeBag then
				PickupContainerItem(bag,slot)
				PickupContainerItem(freeBag,freeSlot)
			else
				ItemRack.Print("Not enough room in bags to pull all items from '"..setname.."'.")
				return
			end
		end
	end
end

-- pushes setname from bags/worn to bank
function ItemRack.PutBankedSet(setname)
	if SpellIsTargeting() or GetCursorInfo() then return end
	local bag,slot,freeBag,freeSlot
	ItemRack.ClearLockList()
	for _,i in pairs(ItemRackUser.Sets[setname].equip) do
		if i~=0 then
			freeBag,freeSlot = ItemRack.FindBankSpace()
			if freeBag then
				inv,bag,slot = ItemRack.FindItem(i)
				if inv then
					PickupInventoryItem(inv)
				elseif bag then
					PickupContainerItem(bag,slot)
				end
				if CursorHasItem() then
					PickupContainerItem(freeBag,freeSlot)
				end
			else
				ItemRack.Print("Not enough room in bank to store all items from '"..setname.."'.")
				return
			end
		end
	end
end

function ItemRack.ResetEverything()
	StaticPopupDialogs["ItemRackCONFIRMRESET"] = {
		text = "Это восстановит ItemRack в его состояние по умолчанию, стирая все наборы, кнопки и настройки.\n Интерфейс будет перезагружен. Продолжить?",
		button1 = "Yes", button2 = "No", timeout = 0, hideOnEscape = 1, showAlert = 1,
		OnAccept = function() ItemRackUser=nil ItemRackSettings=nil ItemRackItems=nil ItemRackEvents=nil ReloadUI() end
	}
	StaticPopup_Show("ItemRackCONFIRMRESET")
end

-- if cpu profiling on, this will add a page to TinyPad with each ItemRack.func()'s time
function ItemRack.ProfileFuncs()
	if TinyPadPages then
		UpdateAddOnCPUUsage()
		local total = 0
		local t = {}
		local whole,decimal
		for i in pairs(ItemRack) do
			if type(ItemRack[i])=="function" then
				whole = GetFunctionCPUUsage(ItemRack[i])
				decimal = whole - math.floor(whole)
				whole = math.floor(whole)
				table.insert(t,string.format("%04d.%02d %s",whole,decimal,i))
			end
		end
		table.sort(t)
		local info = "ItemRack profile "..date().." "..UnitName("player").."\n"
		for i=1,#(t) do
			info = info..t[i].."\n"
		end
		table.insert(TinyPadPages,info)
	end
end

local function ItemRack_addLine(self,id)
		self:AddLine("|cff6E86D6ItemRack Комплекты экипировки:".."|cffffffff"..id)	
		self:Show()
end

GameTooltip:HookScript("OnTooltipSetItem", function(self)end)

local function ItemRack_attachItemTooltip(self)	
	local set =""
	local find_item =0
	local link = select(2,self:GetItem())
	if not link then return end
	local id = select(3,strfind(link, "^|%x+|Hitem:(%-?%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%-?%d+):(%-?%d+)"))
	local count =0
	for key,value in pairs(ItemRackUser.Sets) do 
	
		if key ~= "~Unequip" and key ~= "~CombatQueue" then
			for _,s in pairs(ItemRackUser.Sets[key].equip) do
			i, j = string.find(s, ":")
				if i then
					find_item =string.sub(s, 1, j-1)		
					if find_item == id then
					
					if count == 0 then
						set= set.." "..key
					else
						set= set..", "..key
					end
						count=count+1
					end		
				end
			end	
			find_item =0;
		end	
	end
	if id and set~=""  then ItemRack_addLine(self,set) end
end


GameTooltip:HookScript("OnTooltipSetItem", ItemRack_attachItemTooltip)
