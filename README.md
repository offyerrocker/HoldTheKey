# About HoldTheKey
Dependency mod for other PAYDAY 2 Lua mods, to make held keybind detection easier.
Compatible with both [BLT](https://github.com/JamesWilko/Payday-2-BLT-Lua) and [SuperBLT.](https://superblt.znix.xyz)

---

# Documentation and Usage:


**HoldTheKey:Add_Keybind(keybind_id)**

  Use this function to store keybinds, so that you may add them later. I would advise putting this inside a hook to `MenuManagerInitialize.`

  *Arguments:* `keybind_id` as defined in your mod's menu.

  *Returns:* Nothing. :(

  *Example:* 

  `Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_TacticalLean", function(menu_manager)`

  `HoldTheKey:Add_Keybind("keybindid_taclean_left")`

  `HoldTheKey:Add_Keybind("keybindid_taclean_right")`

  `[...]`

  `end)`

**HoldTheKey:Remove_Keybind(keybind_id)**

  Use this function to remove stored keybinds. I don't know when you'd ever need it but it's there if you do.

  *Arguments:* `keybind_id` as defined in your mod's menu.

  *Returns:* Nothing. :(

  *Example:*

  `HoldTheKey:Remove_Keybind("keybindid_pirateperfection_addthirtygazilliondollarstomyspendingcash")`

**HoldTheKey:Get_Mod_Keybind(keybind_id)**

  *Arguments:* `keybind_id` as defined in your mod's menu.

  *Returns:* The name of the bound keyboard button or mouse button.

  *Example:*

  `> HoldTheKey:Get_Mod_Keybind("keybindid_taclean_left")
  => "q"`

**HoldTheKey:Keybind_Held(keybind_id)**

  *Arguments:* `keybind_id` as defined in your mod's menu.

  *Returns:* Boolean- whether or not the key bound to that keybind is being held.

  *Example:* 

  `>HoldTheKey:Keybind_Held("keybindid_taclean_left")
  =>true`

**HoldTheKey:Key_Held(key)**

  *Arguments:* Keyboard button name or mouse button name.

  *Returns:* Boolean- whether or not that key is being held.

  *Example:*

  `>HoldTheKey:Key_Held("num 0")
  =>true`

**HoldTheKey:Get_BLT_Keybind(keybind_id)**

  Do not use this function in per-frame checks, because it'll severely hinder performance. Use **HoldTheKey:Add_Keybind()** and **HoldTheKey:Get_Mod_Keybind()** if you want to get the name of a key by its keybind_id.

  This is fine to use if you're a lazy dev and you want to test something without doing setup- it's functionally otherwise the same as **HoldTheKey:Get_Mod_Keybind()**, just without the required setup or optimization.

  *Arguments:* `keybind_id` as defined in your mod's menu.

  *Returns:* The name of the bound keyboard button or mouse button.

**HoldTheKey:Save_All_Keybinds()**

  Unimplemented

