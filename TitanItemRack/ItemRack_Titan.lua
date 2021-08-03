TITAN_ITEMRACK_ID="ItemRack"


local thb_ver=nil
local thb_tt=nil
local L = LibStub("AceLocale-3.0"):GetLocale("Titan", true)

function TitanPanelItemRackButton_OnLoad(self)
	--thb_ver = 
	thb_tt = "ItemRack Options"
    self.registry = {
      id = TITAN_ITEMRACK_ID,
      menuText = TITAN_ITEMRACK_ID,
      --version = thb_ver,
      buttonTextFunction = "ItemRack_Titan_GetButtonText",
      category = "Interface",
      tooltipTitle = thb_tt,
      tooltipTextFunction = "ItemRack_Titan_GetTooltipText",
  	  icon = ItemRack.GetTextureBySlot(20),
      iconWidth = 16,
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowColoredText = 1,
	  	}
    };
    
		
end

function ItemRack_Titan_GetTooltipText()
    return ITEMRACK_TITAN_TOOLTIP;
end


function ItemRack_Titan_GetButtonText()

	if (TitanGetVar(TITAN_ITEMRACK_ID, "ShowLabelText")) then 
      return "ItemRack";
    else
      return nil
    end
  end


function TitalPanelItemRackButton_OnClick(self, button)
  if button~="RightButton"  then
		local xpos,ypos = GetCursorPosition()
			if ypos>400 then
				ItemRack.DockWindows("TOPRIGHT",TitanPanelItemRackButton,"BOTTOMRIGHT","VERTICAL")
			else
				ItemRack.DockWindows("BOTTOMRIGHT",TitanPanelItemRackButton,"TOPRIGHT","VERTICAL")
			end
			ItemRack.BuildMenu(20)
			
			
	else 
	ItemRack.ToggleOptions()
  end
end

function ItemRackt_Titan_Update()
	local button = TitanUtils_GetButton(TITAN_ITEMRACK_ID);
			local icon = _G[button:GetName().."Icon"];
			icon:SetTexture(ItemRack.GetTextureBySlot(20));
end
