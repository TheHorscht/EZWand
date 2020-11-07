-- ########################################
-- #######   EZWand version UNRELEASED   #######
-- ########################################

dofile_once("data/scripts/gun/procedural/gun_action_utils.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/gun/procedural/wands.lua")
dofile_once("data/scripts/gun/procedural/gun_procedural.lua")

-- ##########################
-- ####       UTILS      ####
-- ##########################

wand_props = {
  shuffle = {
    validate = function(val)
      local v = tonumber(val)
      local err = "shuffle needs to be 1 or 0"
      assert(type(v) == "number", err)
      assert(v == 0 or v == 1, err)
    end,
    default = 0,
  },
  spellsPerCast = {
    validate = function(val)
      local v = tonumber(val)
      local err = "spellsPerCast needs to be a number > 0"
      assert(type(v) == "number", err)
      assert(v > 0, err)
    end,
    default = 1,
  },
  castDelay = {
    validate = function(val)
      local v = tonumber(val)
      local err = "castDelay needs to be a number"
      assert(type(v) == "number", err)
    end,
    default = 20,
  },
  rechargeTime = {
    validate = function(val)
      local v = tonumber(val)
      local err = "rechargeTime needs to be a number"
      assert(type(v) == "number", err)
    end,
    default = 40,
  },
  manaMax = {
    validate = function(val)
      local v = tonumber(val)
      local err = "manaMax needs to be a number > 0"
      assert(type(val) == "number", err)
      assert(v > 0, err)
    end,
    default = 500,
  },
  mana = {
    validate = function(val)
      local v = tonumber(val)
      local err = "mana needs to be a number > 0"
      assert(type(val) == "number", err)
      assert(v > 0, err)
    end,
    default = 500,
  },
  manaChargeSpeed = {
    validate = function(val)
      local v = tonumber(val)
      local err = "manaChargeSpeed needs to be a number > 0"
      assert(type(val) == "number", err)
      assert(val > 0, err)
    end,
    default = 200,
  },
  capacity = {
    validate = function(val)
      local v = tonumber(val)
      local err = "capacity needs to be a number > 0"
      assert(type(val) == "number", err)
      assert(val > 0, err)
    end,
    default = 10,
  },
  spread = {
    validate = function(val)
      local v = tonumber(val)
      local err = "spread needs to be a number"
      assert(type(val) == "number", err)
    end,
    default = 10,
  },
  speedMultiplier = {
    validate = function(val)
      local v = tonumber(val)
      local err = "spread needs to be a number"
      assert(type(val) == "number", err)
    end,
    default = 1,
  },
}

--[[
  values is a table that contains info on what values to set
  example:
  values = {
    manaMax = 50,
    rechargeSpeed = 20
  }
  etc
  calls error() if values contains invalid properties
  fills in missing properties with default values
]]
function validate_wand_properties(values)
  if type(values) ~= "table" then
    error("Arg 'values': table expected.")
  end
  -- Check if all passed in values are valid wand properties and have the required type
  for k,v in pairs(values) do
    if wand_props[k] == nil then
      error("Key '" .. tostring(k) .. "' is not a valid wand property.")
    else
      -- The validate function calls error() if the validation fails
      wand_props[k].validate(v)
    end
  end
  -- Fill in missing properties with default values
  for k,v in pairs(wand_props) do
    values[k] = values[k] or v.default
  end
  return values
end

 function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

-- Returns true if entity is a wand
local function entity_is_wand(entity_id)
	local comp = EntityGetComponent(entity_id, "ManaReloaderComponent")
	return comp ~= nil
end

local function ends_with(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

local function validate_property(name, value)
  if wand_props[name] == nil then
    error(name .. " is not a valid wand property.")
  end
  if value ~= nil then
    -- check if value has the correct format etc for key
  end
end

local function SetWandSprite(entity_id, item_file, offset_x, offset_y, tip_x, tip_y)
  local ability_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "AbilityComponent")
	if ability_comp then
    ComponentSetValue2(ability_comp, "sprite_file", item_file)
	end
  local function GetComponentValues(comp, value_names)
    local values_out = {}
    for i, value_name in ipairs(value_names) do
      values_out[value_name] = ComponentGetValue(comp, value_name)
    end
    return values_out
  end
  local sprite_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "SpriteComponent", "item")
  if sprite_comp then
    ComponentSetValue2(sprite_comp, "image_file", item_file)
    ComponentSetValue2(sprite_comp, "offset_x", offset_x)
    ComponentSetValue2(sprite_comp, "offset_y", offset_y)
    EntityRefreshSprite(entity_id, sprite_comp)
	end
	local hotspot_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "HotspotComponent", "shoot_pos")
  if hotspot_comp then
    ComponentSetValue2(hotspot_comp, "offset", tip_x, tip_y)
	end	
end

local function GetWandSprite(entity_id, ability_comp)
  local item_file, offset_x, offset_y, tip_x, tip_y
	if ability_comp ~= nil then
		item_file = ComponentGetValue2(ability_comp, "sprite_file")
	end
	local sprite_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "SpriteComponent", "item")
	if sprite_comp ~= nil then
		offset_x = ComponentGetValue2(sprite_comp, "offset_x")
    offset_y = ComponentGetValue2(sprite_comp, "offset_y")
	end
	local hotspot_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "HotspotComponent", "shoot_pos")
  if hotspot_comp ~= nil then
    tip_x, tip_y = ComponentGetValue2(hotspot_comp, "offset")
  end
  return item_file, offset_x, offset_y, tip_x, tip_y
end

-- ##########################
-- ####    UTILS END     ####
-- ##########################

local wand = {}
-- Setter
wand.__newindex = function(table, key, value)
  if rawget(table, "_protected")[key] ~= nil then
    error("Cannot set protected property '" .. key .. "'")
  end
  table:SetProperties({ [key] = value })
end
-- Getter
wand.__index = function(table, key)
  if type(rawget(wand, key)) == "function" then
    return rawget(wand, key)
  end
  if rawget(table, "_protected")[key] ~= nil then
    return rawget(table, "_protected")[key]
  end
  return table:GetProperties({ key })[key]
end

function wand:new(from, rng_seed_x, rng_seed_y)
  -- 'protected' should not be accessed by end users!
  local protected = {}
  local o = {
    _protected = protected
  }
  setmetatable(o, self)
  if type(from) == "table" or from == nil then
    -- Just load some existing wand that we alter later instead of creating one from scratch
    protected.entity_id = EntityLoad("data/entities/items/wand_level_04.xml")
    protected.ability_component = EntityGetFirstComponentIncludingDisabled(protected.entity_id, "AbilityComponent")
    -- Copy all validated props over or initialize with defaults
    local props = from or {}
    validate_wand_properties(props)
    o:SetProperties(props)
    o:RemoveSpells()
    o:DetachSpells()
  elseif tonumber(from) or type(from) == "number" then
    -- Wrap an existing wand
    protected.entity_id = from
    protected.ability_component = EntityGetFirstComponentIncludingDisabled(protected.entity_id, "AbilityComponent")
  else
    -- Load a wand by xml
    if ends_with(from, ".xml") then
      local player_unit = EntityGetWithTag("player_unit")[1]
      local x, y = EntityGetTransform(player_unit)
      protected.entity_id = EntityLoad(from, rng_seed_x or x, rng_seed_y or y)
      protected.ability_component = EntityGetFirstComponentIncludingDisabled(protected.entity_id, "AbilityComponent")
    else
      error("Wrong format for wand creation.", 2)
    end
  end

  if not entity_is_wand(protected.entity_id) then
    error("Loaded entity is not a wand.", 2)
  end

  return o
end

local variable_mappings = {
  shuffle = { target = "gun_config", name = "shuffle_deck_when_empty" },
  spellsPerCast = { target = "gun_config", name="actions_per_round"},
  castDelay = { target = "gunaction_config", name="fire_rate_wait"},
  rechargeTime = { target = "gun_config", name="reload_time"},
  manaMax = { target = "ability_component", name="mana_max"},
  mana = { target = "ability_component", name="mana"},
  manaChargeSpeed = { target = "ability_component", name="mana_charge_speed"},
  capacity = { target = "gun_config", name="deck_capacity"},
  spread = { target = "gunaction_config", name="spread_degrees"},
  speedMultiplier = { target = "gunaction_config", name="speed_multiplier"},
}

-- Sets the actual property on the corresponding component/object
function wand:_SetProperty(key, value)
  local mapped_key = variable_mappings[key].name
  local target_setters = {
    ability_component = function(key, value)
      ComponentSetValue(self.ability_component, key, value)
    end,
    gunaction_config = function(key, value)
      ComponentObjectSetValue(self.ability_component, "gunaction_config", key, value)
    end,
    gun_config = function(key, value)
      ComponentObjectSetValue(self.ability_component, "gun_config", key, value)
    end,
  }
  -- We need a special rule for capacity, since always cast spells count towards capacity, but not in the UI...
  if key == "capacity" then
    -- TODO: set capacity to value + numalwayscastspells
    value = value + select(2, self:GetSpellsCount())
  end
  target_setters[variable_mappings[key].target](mapped_key, tostring(value))
end
-- Retrieves the actual property from the component or object
function wand:_GetProperty(key)
  local mapped_key = variable_mappings[key].name
  local target_getters = {
    ability_component = function(key)
      return ComponentGetValue(self.ability_component, key, value)
    end,
    gunaction_config = function(key)
      return ComponentObjectGetValue(self.ability_component, "gunaction_config", key)
    end,
    gun_config = function(key)
      return ComponentObjectGetValue(self.ability_component, "gun_config", key)
    end,
  }
  local result = target_getters[variable_mappings[key].target](mapped_key)
  -- We need a special rule for capacity, since always cast spells count towards capacity, but not in the UI...
  if key == "capacity" then
    result = result - select(2, self:GetSpellsCount())
  end
  return tonumber(result)
end

function wand:SetProperties(key_values)
  for k,v in pairs(key_values) do
    validate_property(k)
    self:_SetProperty(k, v)
  end
end

function wand:GetProperties(keys)
  -- Return all properties when empty
  if keys == nil then
    keys = {}
    for k,v in pairs(wand_props) do
      table.insert(keys, k)
    end
  end
  local result = {}
  for i,key in ipairs(keys) do
    validate_property(key)
    result[key] = self:_GetProperty(key)
  end
  return result
end
-- For making the interface nicer, this allows us to use this one function here for
function wand:_AddSpells(spells, attach)
  -- Check if capacity is sufficient
  if not attach and self:GetSpellsCount() + #spells > tonumber(self.capacity) then
    error("Wand capacity too low to add that many spells.", 3)
  end
  for i,action_id in ipairs(spells) do
    if not attach then
      AddGunAction(self.entity_id, action_id)
    else
      -- Extend slots to not consume one slot
      -- self.capacity = self.capacity + 1
      AddGunActionPermanent(self.entity_id, action_id)
    end
  end
end
local function extract_spells_from_vararg(...)
  local spells = {}
  local spell_args = ...
  if select("#", ...) > 1 or type(spell_args) ~= "table" or (type(spell_args) == "table" and #spell_args == 2 and type(spell_args[1]) == "string" and type(spell_args[2]) == "number") then
    spell_args = {...}
  end
  local function add_spell(i, spell_id)
    if type(spell_id) == "string" then
      table.insert(spells, spell_id)
    else
      error("Spell ID at index " .. i .. " has the wrong format, string or table with amount { \"BOMB\", 3 } expeced.", 4)
    end
  end
  for i, spell in ipairs(spell_args) do
    if type(spell) == "table" then
      if #spell ~= 2 then
        error("Wrong argument format at index " .. i .. ". Expected format for multiple spells shortcut: { \"BOMB\", 3 }", 3)
      end
      for i2=1, spell[2] do
        add_spell(i, spell[1])
      end
    else
      add_spell(i, spell)
    end
  end
  return spells
end
-- Input can be a table of action_ids, or multiple arguments
-- e.g.:
-- AddSpells("BLACK_HOLE")
-- AddSpells("BLACK_HOLE", "BLACK_HOLE", "BLACK_HOLE")
-- AddSpells({"BLACK_HOLE", "BLACK_HOLE"})
-- To add multiple spells you can also use this shortcut:
-- AddSpells("BLACK_HOLE", {"BOMB", 5}) this will add 1 blackhole followed by 5 bombs
function wand:AddSpells(...)
  local spells = extract_spells_from_vararg(...)
  self:_AddSpells(spells, false)
end
-- Same as AddSpells but permanently attach the spells
function wand:AttachSpells(...)
  local spells = extract_spells_from_vararg(...)
  self:_AddSpells(spells, true)
end
-- Returns: spells_count, always_cast_spells_count
function wand:GetSpellsCount()
	local children = EntityGetAllChildren(self.entity_id)
  if children == nil then
    return 0, 0
  end
  -- Count the number of always cast spells
  local always_cast_spells_count = 0
  for i,spell in ipairs(children) do
    local item_component = EntityGetFirstComponentIncludingDisabled(spell, "ItemComponent")
    if item_component ~= nil and ComponentGetValue2(item_component, "permanently_attached") == true then
      always_cast_spells_count = always_cast_spells_count + 1
    end
  end

	return #children - always_cast_spells_count, always_cast_spells_count
end
-- Returns two values:
-- 1: table of spells with each entry having the format { action_id = "BLACK_HOLE", inventory_x = 1, entity_id = <action_entity_id> }
-- 2: table of attached spells with the same format
-- inventory_x should give the position in the wand slots, 1 = first up to num_slots
-- inventory_x is not working yet
function wand:GetSpells()
	local spells = {}
	local always_cast_spells = {}
	local children = EntityGetAllChildren(self.entity_id)
  if children == nil then
    return spells, always_cast_spells
  end
	for _, spell in ipairs(children) do
		local action_id = nil
		local permanent = false
		local inventory_x = -1
    local item_action_component = EntityGetFirstComponentIncludingDisabled(spell, "ItemActionComponent")
    if item_action_component then
      local val = ComponentGetValue2(item_action_component, "action_id")
      action_id = val
    end
    local item_component = EntityGetFirstComponentIncludingDisabled(spell, "ItemComponent")
    if item_component then
      permanent = ComponentGetValue2(item_component, "permanently_attached")      
      local inventory_y
      inventory_x, inventory_y = ComponentGetValue2(item_component, "inventory_slot")
    end
    if action_id ~= nil then
			if permanent == true then
				table.insert(always_cast_spells, { action_id = action_id, entity_id = spell, inventory_x = inventory_x })
			else
				table.insert(spells, { action_id = action_id, entity_id = spell, inventory_x = inventory_x })
			end
		end
  end
	return spells, always_cast_spells
end

function wand:_RemoveSpells(action_ids, detach)
	local spells, attached_spells = self:GetSpells()
  local which = detach and attached_spells or spells
  for i,v in ipairs(which) do
    if action_ids == nil or table.contains(action_ids, v.action_id) then
      EntityRemoveFromParent(v.entity_id)
      if detach then
        self.capacity = self.capacity - 1
      end
    end
  end
end
-- action_ids = {"BLACK_HOLE", "GRENADE"} remove all spells of those types
-- If action_ids is empty, remove all spells
function wand:RemoveSpells(...)
  local args = {...}
  local spells
  if #args == 0 then
    spells = nil
  elseif type(args[1]) == "table" then
    spells = ...
  else
    spells = { ... }
  end
  self:_RemoveSpells(spells, false)
end
function wand:DetachSpells(...)
  local args = {...}
  local spells
  if #args == 0 then
    spells = nil
  elseif type(args[1]) == "table" then
    spells = ...
  else
    spells = { ... }
  end
  self:_RemoveSpells(spells, true)
end

function wand:Clone()
  local new_wand = wand:new(self:GetProperties())
  local spells, attached_spells = self:GetSpells()
  for k, v in pairs(spells) do
    new_wand:AddSpells{v.action_id}
  end
  for k, v in pairs(attached_spells) do
    new_wand:AttachSpells{v.action_id}
  end
  -- TODO: Make this work if sprite_file is an xml
  SetWandSprite(new_wand.entity_id, GetWandSprite(self.entity_id, self.ability_component))
  return new_wand
end

-- Applies an appropriate Sprite using the games own algorithm
function wand:UpdateSprite()
  local gun = {
    fire_rate_wait = self.castDelay,
    actions_per_round = self.spellsPerCast,
    shuffle_deck_when_empty = self.shuffle,
    deck_capacity = self.capacity,
    spread_degrees = self.spread,
    reload_time = self.rechargeTime,
  }
  local sprite_data = GetWand(gun)
  SetWandSprite(self.entity_id, 
    sprite_data.file, sprite_data.grip_x, sprite_data.grip_y,
    (sprite_data.tip_x - sprite_data.grip_x),
    (sprite_data.tip_y - sprite_data.grip_y))
end

function wand:PlaceAt(x, y)
	EntitySetComponentIsEnabled(self.entity_id, self.ability_component, true)
	local hotspot_comp = EntityGetFirstComponentIncludingDisabled(self.entity_id, "HotspotComponent")
	EntitySetComponentIsEnabled(self.entity_id, hotspot_comp, true)
  local item_component = EntityGetFirstComponentIncludingDisabled(self.entity_id, "ItemComponent")
	EntitySetComponentIsEnabled(self.entity_id, item_component, true)
	local sprite_component = EntityGetFirstComponentIncludingDisabled(self.entity_id, "SpriteComponent")
	EntitySetComponentIsEnabled(self.entity_id, sprite_component, true)
  local light_component = EntityGetFirstComponentIncludingDisabled(self.entity_id, "LightComponent")
  EntitySetComponentIsEnabled(self.entity_id, light_component, true)
  
  ComponentSetValue(item_component, "has_been_picked_by_player", "0")
  ComponentSetValue(item_component, "play_hover_animation", "1")
  ComponentSetValueVector2(item_component, "spawn_pos", x, y)

	local lua_comp = EntityGetFirstComponentIncludingDisabled(self.entity_id, "LuaComponent")
	EntitySetComponentIsEnabled(self.entity_id, lua_comp, true)
	local simple_physics_component = EntityGetFirstComponentIncludingDisabled(self.entity_id, "SimplePhysicsComponent")
  EntitySetComponentIsEnabled(self.entity_id, simple_physics_component, false)
	-- Does this wand have a ray particle effect? Most do, except the starter wands
	local sprite_particle_emitter_comp = EntityGetFirstComponentIncludingDisabled(self.entity_id, "SpriteParticleEmitterComponent")
	if sprite_particle_emitter_comp ~= nil then
		EntitySetComponentIsEnabled(self.entity_id, sprite_particle_emitter_comp, true)
	else
		-- TODO: As soon as there's some way to clone Components or Transplant/Remove+Add to another Entity, copy
		-- the SpriteParticleEmitterComponent of entities/base_wand.xml
  end
end

function wand:PutInPlayersInventory()
  local inventory_id = EntityGetWithName("inventory_quick")
  -- Get number of wands currently already in inventory
  local count = 0
  local inventory_items = EntityGetAllChildren(inventory_id)
  if inventory_items ~= nil then
    for i,v in ipairs(inventory_items) do
      if entity_is_wand(v) then
        count = count + 1
      end
    end
  end
  if count < 4 then
    -- local item_components = EntityGetComponent(rawget(self, "_protected").entity_id, "ItemComponent")
    local item_components = EntityGetComponent(self.entity_id, "ItemComponent")
    if item_components ~= nil and item_components[1] ~= nil then
      ComponentSetValue(item_components[1], "play_hover_animation", "0")
      ComponentSetValue(item_components[1], "has_been_picked_by_player", "1")
    end
    EntityAddChild(inventory_id, self.entity_id)
  else
    error("Cannot add wand to players inventory, it's already full.", 2)
  end
end

return function(from, rng_seed_x, rng_seed_y)
  return wand:new(from, rng_seed_x, rng_seed_y)
end
