_G.HoldTheKey = _G.HoldTheKey or {}
local HTK = _G.HoldTheKey
HTK.mod_path = ModPath
HTK.settings_savepath = SavePath .. "holdthekey_settings.txt"
HTK.mods_savepath = SavePath .. "holdthekey.txt"

HTK.settings = {
	allow_double_binding = true
}
HTK.saved_keybinds = {}
HTK.logged_errors = {} --lazy implementation but it'll work

--this is just a setting i added to the mod to allow double-binding since it's the same function, you can ignore this
function HTK:AllowDoublebinding()
	return self.settings.allow_double_binding
end

--i dunno when you'd need this since you have Key_Held() but i'm adding it anyway
function HTK:Get_Mod_Keybind(keybind_id)
	if not keybind_id then 
		return
	end
	if not (self.saved_keybinds[keybind_id]) then
		if not self.logged_errors[keybind_id] then
			self.logged_errors[keybind_id] = true
			log("HoldTheKey:Get_Mod_Keybind(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		end
		return
	elseif self.logged_errors[keybind_id] then 
		self.logged_errors[keybind_id] = nil
	end
	
	
	return self.saved_keybinds[keybind_id]
end

--this is designed to be run every frame. more efficient than searching the entire blt keybind table every frame
--returns bool
function HTK:Keybind_Held(keybind_id)
	if not (managers and managers.hud) or managers.hud._chat_focus then --yeah, leaning back and forth with Tactical Lean mod while typing was weird
		return false
	end
	local key = self:Get_Mod_Keybind(keybind_id)

	if not key then
--		log("HoldTheKey:Keybind_Held(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		return false	
	end
	
	return self:Key_Held(key)
end

function HTK:Key_Held(key) --not sure if i can find a use-case for wanting to check held-keys while chat is open
	if not (managers and managers.hud) or managers.hud._chat_focus then
		return false
	end
	
	key = tostring(key)
	if key:find("mouse ") then 
		if not key:find("wheel") then 
			key = key:sub(7)
		end
		return Input:mouse():down(Idstring(key))
	else
		return Input:keyboard():down(Idstring(key))
	end
end

--sometimes BLT doesn't cooperate. this function is for directly adding keybinds by both connection name and key name.
function HTK:Add_Keybind_Hard(keybind_id,key)
	self.saved_keybinds[keybind_id] = key
	log("HoldTheKey: Forced add keybind (" .. tostring(keybind_id) .. "," .. tostring(key)..")")
end

--pretty self explanatory. keybinds are added to this mod's save.txt (questionable decision, i'll think about if this is a good idea lol)
function HTK:Add_Keybind(keybind_id)
	if not (keybind_id) then
--		log("HoldTheKey:Add_Keybind(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		return
	end
	
	local key = self:Get_BLT_Keybind(keybind_id)
--	log("HoldTheKey:Add_Keybind() Saved keybind with id [" .. tostring(key) .. "]")
	self.saved_keybinds[keybind_id] = key

	self:SaveKeybinds()
end

function HTK:Remove_Keybind(keybind_id) --not sure when anyone would ever use this but just in case okay
	if not (keybind_id) then
		log("HoldTheKey:Remove_Keybind(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		return
	end
	HTK.saved_keybinds[keybind_id] = nil
--	HTK:SaveKeybinds()
end

function HTK:Refresh_Keybinds() --refresh and save all keybinds
	self.logged_errors = {}
	log("Refreshed HoldTheKey keybinds")
	for id,key in pairs(self.saved_keybinds) do
		 self:Add_Keybind(id)
	end
	self:SaveKeybinds()
end

--NOT designed to be run every frame. please for the love of god, use Add_Keybind() and Get_Mod_Keybind() instead
--should only be run on rebind event or in cases where performance doesn't matter as much, like menus or whatever
function HTK:Get_BLT_Keybind(id)
	for k,v in pairs(BLT.Keybinds._keybinds) do
		if type(v) == "table" then
			if v["_id"] == id then
				if v["_key"] and v["_key"]["pc"] then --todo add support for controller binds via not-pc
					return tostring(v["_key"]["pc"])
				else
					return --"unbound_keybind_1"
				end
			end
		else
			log("HTK: Found a non-table keybind " .. tostring(v))	--this should never happen		
		end
	end
	
	if BLT.Keybinds._potential_keybinds then
		--has to iterate through two sets of tables because caches
		for k,v in pairs(BLT.Keybinds._potential_keybinds) do
			if type(v) == "table" then
				if v["id"] == id then
					if v["pc"] then --todo add support for controller binds via not-pc, dunno how superblt does it and i'm too lazy right now
						return tostring(v["pc"])
					else
						return --"unbound_keybind_2"
					end
				end
			else
				log("HTK: Cached: Found a non-table keybind " .. tostring(v))	--yeah still shouldn't happen		
			end
		end
	end
end

function HTK:ClearSavedKeybinds()
	self.saved_keybinds = {}
	self:SaveKeybinds()
end

function HTK:LoadKeybinds()
	local file = io.open(self.mods_savepath, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.saved_keybinds[k] = v
		end
	else
		self:SaveKeybinds()
	end
end
function HTK:SaveKeybinds()
	local file = io.open(self.mods_savepath,"w+")
	if file then
		file:write(json.encode(self.saved_keybinds))
		file:close()
	end
end
function HTK:LoadSettings()
	local file = io.open(self.settings_savepath, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
		end
	else
		self:SaveSettings()
	end
end
function HTK:SaveSettings()
	local file = io.open(self.settings_savepath,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_HTK", function( loc )
	loc:load_localization_file( HTK.mod_path .. "loc/en.txt")
end)

Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_HTK", function(menu_manager)
	MenuCallbackHandler.callback_htk_toggle_doublebinding = function(self,item) --turn on doublebinding
		local value = item:value() == 'on'
		HTK.settings.allow_double_binding = value
		HTK:SaveSettings()
	end
	MenuCallbackHandler.callback_htk_button_reset = function(self) --delete
		HTK:ClearSavedKeybinds()
	end
	MenuCallbackHandler.callback_htk_button_reload = function(self) --refresh- from htk save file, then get by blt saved keybinds, then save to htk savefile
		HTK:LoadKeybinds()
		HTK:Refresh_Keybinds()
	end	
	MenuCallbackHandler.callback_htk_close = function(this)
		HTK:SaveSettings()--this is redundant for now, but whatever
	end
	HTK:LoadKeybinds() --todo make this NOT initialise every time the menu is started? nah it's prob fine
	HTK:LoadSettings()
	MenuHelper:LoadFromJsonFile(HTK.mod_path .. "menu/options.txt", HTK, HTK.settings)
	
end)
	