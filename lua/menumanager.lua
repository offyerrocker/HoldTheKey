_G.HoldTheKey = _G.HoldTheKey or {}
HoldTheKey.mod_path = ModPath
HoldTheKey.settings_savepath = SavePath .. "holdthekey_settings.txt"
HoldTheKey.mods_savepath = SavePath .. "holdthekey.txt"

HoldTheKey.settings = {
	allow_double_binding = true
}
HoldTheKey.saved_keybinds = {}
HoldTheKey.logged_errors = {} --lazy implementation but it'll work
HoldTheKey._input_cache = {} --used to store and track pressed/released states

--this is just a setting i added to the mod to allow double-binding since it's the same function, you can ignore this
function HoldTheKey:AllowDoublebinding()
	return self.settings.allow_double_binding
end

function HoldTheKey:Get_Mod_Keybind(keybind_id)
	if not keybind_id then 
		return
	end
	if not (self.saved_keybinds[keybind_id]) then
		if not self.logged_errors[keybind_id] then
			
			local key = self:Get_BLT_Keybind(keybind_id)
			if key then
				self.saved_keybinds[keybind_id] = key
				return key
			end
		
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
function HoldTheKey:Keybind_Held(keybind_id,ignore_chat_focus)
	if not ignore_chat_focus then 
		if not (managers and managers.hud) or managers.hud._chat_focus then --yeah, leaning back and forth with Tactical Lean mod while typing was weird
			return
		end
	end
	local key = self:Get_Mod_Keybind(keybind_id)

	if not key then
--		log("HoldTheKey:Keybind_Held(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		return false	
	end
	
	return self:Key_Held(key)
end

function HoldTheKey:Key_Held(key,ignore_chat_focus) --most HtK functions call this one at some point
	if not ignore_chat_focus and not (managers and managers.hud) or managers.hud._chat_focus then
		--couldn't find any use-case for wanting to check held-keys while chat is open
		return --"nil" indicates that the chat is open or managers.hud is not loaded, as opposed to "false" which means that the key isn't pressed
	end
	
	key = tostring(key)
	local result
	if key:find("mouse ") then 
		if not key:find("wheel") then 
			key = key:sub(7)
		end
		result = Input:mouse():down(Idstring(key))
	else
		result = Input:keyboard():down(Idstring(key))
	end
	self._input_cache[key] = result --save last state to cache
	return result	
end

--[[ 
I wrote these before realising that it's actually pointless to save a cache when it's only refreshed on call anyway
Released() is inherently nonfunctional If multiple calls to either permutation of Released() are made in one frame, only the first one will register a "released" result

Pressed() will work, but if you want to track released then you should write your own cache such that it does not interfere with (and is not interfered with by) other mods
You can use these functions as a base for that if you need


function HoldTheKey:Key_Released(key)
	if key and self._input_cache[key] then
		return self:Key_Held(key) == false --check specifically for false
	else
		return false
	end
end

function HoldTheKey:Keybind_Released(keybind_id)
	local key = self:Get_Mod_Keybind(keybind_id)

	if key and self._input_cache[key] then
		return self:Key_Held(key) == false
	else
		return false
	end
--	return 
end
--]]

function HoldTheKey:Key_Pressed(key)
	if key and not self._input_cache[key] then
		return self:Key_Held(key)
	else
		return false
	end
end

function HoldTheKey:Keybind_Pressed(keybind_id)
	local key = self:Get_Mod_Keybind(keybind_id)
	
	if key and not self._input_cache[key] then
		return self:Key_Held(key)
	else
		return false
	end
end

--sometimes BLT doesn't cooperate. this function is for directly adding keybinds by both connection name and key name.
function HoldTheKey:Add_Keybind_Hard(keybind_id,key)
	self.saved_keybinds[keybind_id] = key
	log("HoldTheKey: Forced add keybind (" .. tostring(keybind_id) .. "," .. tostring(key)..")")
end

--pretty self explanatory. keybinds are added to this mod's save.txt
function HoldTheKey:Add_Keybind(keybind_id)
	if not (keybind_id) then
--		log("HoldTheKey:Add_Keybind(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		return
	end
	
	local key = self:Get_BLT_Keybind(keybind_id)
--	log("HoldTheKey:Add_Keybind() Saved keybind with id [" .. tostring(key) .. "]")
	self.saved_keybinds[keybind_id] = key

	self:SaveKeybinds()
end

function HoldTheKey:Remove_Keybind(keybind_id) --not sure when anyone would ever use this but just in case okay
	if not (keybind_id) then
		log("HoldTheKey:Remove_Keybind(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		return
	end
	HoldTheKey.saved_keybinds[keybind_id] = nil
--	HoldTheKey:SaveKeybinds()
end

function HoldTheKey:Refresh_Keybinds() --refresh and save all keybinds
	self.logged_errors = {}
	log("Refreshed HoldTheKey keybinds")
	for id,key in pairs(self.saved_keybinds) do
		 self:Add_Keybind(id)
	end
	self:SaveKeybinds()
end

--NOT designed to be run every frame. please for the love of god, use Add_Keybind() and Get_Mod_Keybind() instead
--should only be run on rebind event or in cases where performance doesn't matter as much, like menus or whatever
function HoldTheKey:Get_BLT_Keybind(id)
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
			log("HoldTheKey: Found a non-table keybind " .. tostring(v))	--this should never happen		
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
				log("HoldTheKey: Cached: Found a non-table keybind " .. tostring(v))	--yeah still shouldn't happen		
			end
		end
	end
end

function HoldTheKey:ClearSavedKeybinds()
	self.saved_keybinds = {}
	self:SaveKeybinds()
end

function HoldTheKey:LoadKeybinds()
	local file = io.open(self.mods_savepath, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.saved_keybinds[k] = v
		end
	else
		self:SaveKeybinds()
	end
--Console:logall(json.decode(io.open(HoldTheKey.mods_savepath, "r"):read("*all")))
end
function HoldTheKey:SaveKeybinds()
	local file = io.open(self.mods_savepath,"w+")
	if file then
		file:write(json.encode(self.saved_keybinds))
		file:close()
	end
end
function HoldTheKey:LoadSettings()
	local file = io.open(self.settings_savepath, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
		end
	else
		self:SaveSettings()
	end
end
function HoldTheKey:SaveSettings()
	local file = io.open(self.settings_savepath,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

Hooks:Add("CustomizeControllerOnKeySet","CallMenuBoundKey_HTK",function(connection_name,key_button)
	if connection_name then--HoldTheKey:Get_Mod_Keybind(item:parameters().connection_name) then
		HoldTheKey:Add_Keybind_Hard(connection_name, key_button)
	end
	HoldTheKey:Refresh_Keybinds()--update and save new keybinds when rebinding mod controls
end)

if not BeardLib then 
	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_HTK", function( loc )
		loc:load_localization_file( HoldTheKey.mod_path .. "loc/en.txt")
	end)
end

Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_HTK", function(menu_manager)
	MenuCallbackHandler.callback_htk_toggle_doublebinding = function(self,item) --turn on doublebinding
		local value = item:value() == 'on'
		HoldTheKey.settings.allow_double_binding = value
		HoldTheKey:SaveSettings()
	end
	MenuCallbackHandler.callback_htk_button_reset = function(self) --delete
		HoldTheKey:ClearSavedKeybinds()
	end
	MenuCallbackHandler.callback_htk_button_reload = function(self) --refresh- from htk save file, then get by blt saved keybinds, then save to htk savefile
		HoldTheKey:LoadKeybinds()
		HoldTheKey:Refresh_Keybinds()
	end	
	MenuCallbackHandler.callback_htk_close = function(this)
		HoldTheKey:SaveSettings()--this is redundant for now, but whatever
	end
	HoldTheKey:LoadKeybinds() --todo make this NOT initialise every time the menu is started? nah it's prob fine
	HoldTheKey:LoadSettings()
	MenuHelper:LoadFromJsonFile(HoldTheKey.mod_path .. "menu/options.txt", HoldTheKey, HoldTheKey.settings)
	
end)
	