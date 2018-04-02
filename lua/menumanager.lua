_G.HoldTheKey = _G.HoldTheKey or {}
local HTK = _G.HoldTheKey
HTK.mod_path = ModPath
HTK.settings_savepath = SavePath .. "holdthekey_settings.txt"
HTK.mods_savepath = SavePath .. "holdthekey.txt"

HTK.settings = {
	allow_double_binding = true
}
HTK.saved_keybinds = {}

--this is just a setting i added to the mod to allow double-binding since it's the same function, you can ignore this
function HTK:AllowDoublebinding()
	return HTK.settings.allow_double_binding
end

--i dunno when you'd need this since you have Key_Held() but i'm adding it anyway
function HTK:Get_Mod_Keybind(keybind_id)
	if not (keybind_id) then
		log("HoldTheKey: ERROR! Invalid mod_id or keybind_id")
		return
	end
	
	return HTK.saved_keybinds[keybind_id]
end

--this is designed to be run every frame. more efficient than searching the entire blt keybind table every frame
--returns bool
function HTK:Keybind_Held(keybind_id)
	local key = HTK:Get_Mod_Keybind(keybind_id)

	if not key then
		log("HoldTheKey:Keybind_Held(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		return false	
	end
	
	return (key:find("mouse ") and Input:mouse():down(Idstring(key:sub(7))) or Input:keyboard():down(Idstring(key)))
end

function HoldTheKey:Key_Held(key)
	key = tostring(key)
	return (key:find("mouse ") and Input:mouse():down(Idstring(key:sub(7))) or Input:keyboard():down(Idstring(key)))	
end

--pretty self explanatory. keybinds are added to this mod's save.txt (questionable decision, i'll think about if this is a good idea lol)
function HTK:Add_Keybind(keybind_id)
	if not (keybind_id) then
		log("HoldTheKey:Add_Keybind(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		return
	end
	
	local key = HTK:Get_BLT_Keybind(keybind_id)
	log("HoldTheKey:Add_Keybind() Saved keybind with id [" .. tostring(key) .. "]")
	HTK.saved_keybinds[keybind_id] = key

	HTK:SaveKeybinds()
end

function HTK:Remove_Keybind(keybind_id) --not sure when anyone would ever use this but just in case okay
	if not (keybind_id) then
		log("HoldTheKey:Remove_Keybind(" .. tostring(keybind_id) .. ") ERROR! Invalid keybind_id")
		return
	end
	HTK.saved_keybinds[keybind_id] = nil	
end

function HTK:Save_All_Keybinds()
	for id,key in pairs(HTK.saved_keybinds) do
		HTK:Get_BLT_Keybind(id)
	end
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
					return "nil keybind"
				end
			end
		else
			log("HTK: Found a non-table keybind " .. tostring(v))	--this should never happen		
		end
	end
	
	if _G.BLTSuperMod then
		--has to iterate through two sets of tables because caches
		for k,v in pairs(BLT.Keybinds._potential_keybinds) do
			if type(v) == "table" then
				if v["id"] == id then
					if v["pc"] then --todo add support for controller binds via not-pc, dunno how superblt does it and i'm too lazy right now
						return tostring(v["pc"])
					else
						return "unbound_keybind"
					end
				end
			else
				log("HTK: SuperBLT Found a non-table keybind " .. tostring(v))	--yeah still shouldn't happen		
			end
		end
	end
end

function HTK:ClearSavedKeybinds()
	HTK.saved_keybinds = {}
	HTK:SaveKeybinds()
end

function HTK:LoadKeybinds()
	local file = io.open(self.mods_savepath, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.saved_keybinds[k] = v
		end
	else
		HTK:SaveKeybinds()
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
		HTK:SaveSettings()
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
	MenuCallbackHandler.callback_htk_button_reset = function(self) --refresh
		HTK:ClearSavedKeybinds()
	end
	MenuCallbackHandler.callback_htk_button_reload = function(self) --refresh
		HTK:LoadKeybinds()
	end	
	MenuCallbackHandler.callback_htk_close = function(this)
		HTK:SaveSettings()
	end
	HTK:LoadKeybinds() --todo make this NOT initialise every time the menu is started
	HTK:LoadSettings()
	MenuHelper:LoadFromJsonFile(HTK.mod_path .. "menu/options.txt", HTK, HTK.settings)
	
end)
	