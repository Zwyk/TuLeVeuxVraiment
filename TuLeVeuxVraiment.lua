local addonName = "TuLeVeuxVraiment"
local addonStr = "|cff00bbaa"..addonName.."|cffffffff"
local tlvv = CreateFrame("FRAME", addonName);
tlvv:RegisterEvent("ADDON_LOADED");
tlvv:RegisterEvent("CHAT_MSG_LOOT");

tlvv:SetScript("OnEvent", function(self, event, arg1) self[event](self, arg1) end);

function SlashHandler(arg)
	if(arg == "export") then
		exportLoots()
	elseif(arg == "clean") then
		DataChar = {}
		print(addonStr.." data cleaned")
	else
		print(addonStr.." commands :")
		print("/tlvv export|cffaaaaaa to export current data|cffffffff")
		print("/tlvv clean|cffaaaaaa to delete current data|cffffffff")
	end
end

function tlvv:ADDON_LOADED(addon)
    if(addon == "TuLeVeuxVraiment") then

		SlashCmdList["TLVV"] = SlashHandler;
		SLASH_TLVV1 = "/tlvv";

		if not DataChar then
			DataChar = {}
		end
		if not DataGlobal then
			DataGlobal = {}
		end
    end
end

function tlvv:CHAT_MSG_LOOT(msg, ...)
	instanceName, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
	if instanceType == "raid" then
	    -- self loot
	    -- ...single item - "You receive loot: %s." -> item
	    local PATTERN_LOOT_ITEM_SELF = LOOT_ITEM_SELF:gsub("%%s", "(.+)")
	    -- ...multiple item - "You receive loot: %sx%d." -> item + quantity
	    local PATTERN_LOOT_ITEM_SELF_MULTIPLE = LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
	    -- other loot
	    -- ...single item - "%s receives loot: %s." -> item
	    local PATTERN_LOOT_ITEM = LOOT_ITEM:gsub("%%s", "(.+)")
	    -- ...multiple item - "%s receives loot: %sx%d." -> item + quantity
	    local PATTERN_LOOT_ITEM_MULTIPLE = LOOT_ITEM_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
	    
	    -- self
	    local loottype, itemLink, quantity, source, pname
	    if msg:match(PATTERN_LOOT_ITEM_SELF_MULTIPLE) then
	        loottype = "self multi"
	        itemLink, quantity = strmatch(msg, PATTERN_LOOT_ITEM_SELF_MULTIPLE)
	        pname = GetUnitName("player", false)
	    elseif msg:match(PATTERN_LOOT_ITEM_SELF) then
	        loottype = "self single"
	        itemLink = strmatch(msg, PATTERN_LOOT_ITEM_SELF)
	        pname = GetUnitName("player", false)
	        quantity = 1
	    elseif msg:match(PATTERN_LOOT_ITEM_MULTIPLE) then
	        loottype = "other multi"
	        pname, itemLink, quantity = strmatch(msg, PATTERN_LOOT_ITEM_MULTIPLE)
	    elseif msg:match(PATTERN_LOOT_ITEM) then
	        loottype = "other single"
	        pname, itemLink = strmatch(msg, PATTERN_LOOT_ITEM)
	        quantity = 1
	    end

	    if loottype and itemLink and quantity then
	        local itemID = ToItemID(itemLink)
	        local itemName, _, itemRarity = GetItemInfo(itemID)
	        
	        if itemRarity > 1 then
	        	local t = time()--date("%m/%d/%y %H:%M:%S")
	        	saveLoot(t, instanceID, pname, itemID, quantity)
	        end
	    end
	end
end

function saveLoot(time, instanceID, player, itemID, quantity)
	DataChar[#DataChar+1] =
		{
			["Timestamp"] = time,
			["InstanceID"] = instanceID,
		 	["Player"] = player,
		 	["ItemID"] = itemID,
		 	["Quantity"] = quantity,
		}
end

function exportLoots()
	local json = "{"
	json = jsonLn(json, 1).."\"Timestamp\": "..time()..","
	json = jsonLn(json, 1).."\"Loots\":"
	json = jsonLn(json, 1).."["
	for _,v in pairs(DataChar) do
		json = jsonLn(json, 2).."{"
		json = jsonLn(json, 3).."\"Timestamp\": "..v["Timestamp"]..","
		json = jsonLn(json, 3).."\"InstanceID\": "..v["InstanceID"]..","
		json = jsonLn(json, 3).."\"Player\": \""..v["Player"].."\","
		json = jsonLn(json, 3).."\"ItemID\": "..v["ItemID"]..","
		json = jsonLn(json, 3).."\"Quantity\": "..v["Quantity"]..","
		json = jsonLn(json, 2).."},"
	end
	json = jsonLn(json, 1).."]"
	json = jsonLn(json, 0).."}"
	KethoEditBox_Show(json)
end

function jsonLn(str, tabs)
	str = str.."\n"
	for i=1,tabs do
		str = str.."   "
	end
	return str
end

function ToItemID(itemString)
    if not itemString then
        return
    end

    local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = string.find(itemString, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

    return tonumber(Id)
end

function KethoEditBox_Show(text)
    if not KethoEditBox then
        local f = CreateFrame("Frame", "KethoEditBox", UIParent, "DialogBoxFrame")
        f:SetPoint("CENTER")
        f:SetSize(600, 500)
        
        f:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
                edgeSize = 16,
                insets = { left = 8, right = 6, top = 8, bottom = 8 },
        })
        f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue
        
        -- Movable
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetScript("OnMouseDown", function(self, button)
                if button == "LeftButton" then
                    self:StartMoving()
                end
        end)
        f:SetScript("OnMouseUp", f.StopMovingOrSizing)
        
        -- ScrollFrame
        local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame", KethoEditBox, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -16)
        sf:SetPoint("BOTTOM", KethoEditBoxButton, "TOP", 0, 0)
        
        -- EditBox
        local eb = CreateFrame("EditBox", "KethoEditBoxEditBox", KethoEditBoxScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false) -- dont automatically focus
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)
        
        -- Resizable
        f:SetResizable(true)
        f:SetMinResize(150, 100)
        
        local rb = CreateFrame("Button", "KethoEditBoxResizeButton", KethoEditBox)
        rb:SetPoint("BOTTOMRIGHT", -6, 7)
        rb:SetSize(16, 16)
        
        rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        
        rb:SetScript("OnMouseDown", function(self, button)
                if button == "LeftButton" then
                    f:StartSizing("BOTTOMRIGHT")
                    self:GetHighlightTexture():Hide() -- more noticeable
                end
        end)
        rb:SetScript("OnMouseUp", function(self, button)
                f:StopMovingOrSizing()
                self:GetHighlightTexture():Show()
                eb:SetWidth(sf:GetWidth())
        end)
        f:Show()
    end
    
    if text then
        KethoEditBoxEditBox:SetText(text)
        KethoEditBoxEditBox:HighlightText()
    end
    KethoEditBox:Show()
end