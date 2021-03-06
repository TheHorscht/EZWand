-- #########################################
-- #######   EZWand version v1.2.1   #######
-- #########################################

dofile_once("data/scripts/gun/procedural/gun_action_utils.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/gun/procedural/wands.lua")

-- ##########################
-- ####       UTILS      ####
-- ##########################

-- Removes spells from a table whose ID is not found in the gun_actions table
local function filter_spells(spells)
  dofile_once("data/scripts/gun/gun_actions.lua")
  if not spell_lookup then
    spell_lookup = {}
    for i, v in ipairs(actions) do
      spell_lookup[v.id] = true
    end
  end
  local out = {}
  for i, spell in ipairs(spells) do
    if spell_lookup[spell] then
      table.insert(out, spell)
    end
  end
  return out
end

local function string_split(inputstr, sep)
  sep = sep or "%s"
  local t= {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

local function test_conditionals(conditions)
  for i, conditon in ipairs(conditions) do
    if not conditon[1] then
      return false, conditon[2]
    end
  end
  return true
end

wand_props = {
  shuffle = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "boolean", "shuffle must be true or false" }
      }
    end,
    default = false,
  },
  spellsPerCast = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "number", "spellsPerCast must be a number" },
        { val > 0, "spellsPerCast must be a number > 0" },
      }
    end,
    default = 1,
  },
  castDelay = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "number", "castDelay must be a number" },
      }
    end,
    default = 20,
  },
  rechargeTime = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "number", "rechargeTime must be a number" },
      }
    end,
    default = 40,
  },
  manaMax = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "number", "manaMax must be a number" },
        { val > 0, "manaMax must be a number > 0" },
      }
    end,
    default = 500,
  },
  mana = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "number", "mana must be a number" },
        { val > 0, "mana must be a number > 0" },
      }
    end,
    default = 500,
  },
  manaChargeSpeed = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "number", "manaChargeSpeed must be a number" },
        { val > 0, "manaChargeSpeed must be a number > 0" },
      }
    end,
    default = 200,
  },
  capacity = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "number", "capacity must be a number" },
        { val > 0, "capacity must be a number > 0" },
      }
    end,
    default = 10,
  },
  spread = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "number", "spread must be a number" },
      }
    end,
    default = 10,
  },
  speedMultiplier = {
    validate = function(val)
      return test_conditionals{
        { type(val) == "number", "speedMultiplier must be a number" },
      }
    end,
    default = 1,
  },
}
-- Throws an error if the value doesn't have the correct format or the property doesn't exist
local function validate_property(name, value)
  if wand_props[name] == nil then
    error(name .. " is not a valid wand property.", 4)
  end
  local success, err = wand_props[name].validate(value)
  if not success then
    error(err, 4)
  end
end

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
    error("Arg 'values': table expected.", 2)
  end
  -- Check if all passed in values are valid wand properties and have the required type
  for k, v in pairs(values) do
    validate_property(k, v)
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
	local ability_component = EntityGetFirstComponentIncludingDisabled(entity_id, "AbilityComponent")
	return ComponentGetValue2(ability_component, "use_gun_script") == true
end

local function starts_with(str, start)
  return str:match("^" .. start) ~= nil
end

local function ends_with(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

-- Parses a serialized wand string into a table with it's properties
local function deserialize(str)
  if not starts_with(str, "EZW") then
    return "Wrong wand import string format"
  end
  local values = string_split(str, ";")
  if #values ~= 18 then
    return "Wrong wand import string format"
  end

  return {
    props = {
      shuffle = values[2] == "1",
      spellsPerCast = tonumber(values[3]),
      castDelay = tonumber(values[4]),
      rechargeTime = tonumber(values[5]),
      manaMax = tonumber(values[6]),
      mana = tonumber(values[7]),
      manaChargeSpeed = tonumber(values[8]),
      capacity = tonumber(values[9]),
      spread = tonumber(values[10]),
      speedMultiplier = tonumber(values[11])
    },
    spells = string_split(values[12] == "-" and "" or values[12], ","),
    always_cast_spells = string_split(values[13] == "-" and "" or values[13], ","),
    sprite_image_file = values[14],
    offset_x = tonumber(values[15]),
    offset_y = tonumber(values[16]),
    tip_x = tonumber(values[17]),
    tip_y = tonumber(values[18])
  }
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
    protected.entity_id = EntityLoad("data/entities/items/wand_level_04.xml", rng_seed_x or 0, rng_seed_y or 0)
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
    if starts_with(from, "EZW") then
      local values = deserialize(from)
      protected.entity_id = EntityLoad("data/entities/items/wand_level_04.xml", rng_seed_x or 0, rng_seed_y or 0)
      protected.ability_component = EntityGetFirstComponentIncludingDisabled(protected.entity_id, "AbilityComponent")
      validate_wand_properties(values.props)
      o:SetProperties(values.props)
      o:RemoveSpells()
      o:DetachSpells()
      -- Filter spells whose ID no longer exist (for instance when a modded spellpack was disabled)
      values.spells = filter_spells(values.spells)
      values.always_cast_spells = filter_spells(values.always_cast_spells)
      o:AddSpells(values.spells)
      o:AttachSpells(values.always_cast_spells)
      o:SetSprite(values.sprite_image_file, values.offset_x, values.offset_y, values.tip_x, values.tip_y)
    -- Load a wand by xml
    elseif ends_with(from, ".xml") then
      local x, y = GameGetCameraPos()
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
      ComponentSetValue2(self.ability_component, key, value)
    end,
    gunaction_config = function(key, value)
      ComponentObjectSetValue2(self.ability_component, "gunaction_config", key, value)
    end,
    gun_config = function(key, value)
      ComponentObjectSetValue2(self.ability_component, "gun_config", key, value)
    end,
  }
  -- We need a special rule for capacity, since always cast spells count towards capacity, but not in the UI...
  if key == "capacity" then
    local spells, attached_spells = self:GetSpells()
    -- If capacity is getting reduced, remove any spells that don't fit anymore
    local spells_to_remove = {}
    for i=#spells, value+1, -1 do
      table.insert(spells_to_remove, { spells[i].action_id, 1 })
    end
    if #spells_to_remove > 0 then
      self:RemoveSpells(spells_to_remove)
    end
    value = value + #attached_spells
  end
  target_setters[variable_mappings[key].target](mapped_key, value)
end
-- Retrieves the actual property from the component or object
function wand:_GetProperty(key)
  local mapped_key = variable_mappings[key].name
  local target_getters = {
    ability_component = function(key)
      return ComponentGetValue2(self.ability_component, key, value)
    end,
    gunaction_config = function(key)
      return ComponentObjectGetValue2(self.ability_component, "gunaction_config", key)
    end,
    gun_config = function(key)
      return ComponentObjectGetValue2(self.ability_component, "gun_config", key)
    end,
  }
  local result = target_getters[variable_mappings[key].target](mapped_key)
  -- We need a special rule for capacity, since always cast spells count towards capacity, but not in the UI...
  if key == "capacity" then
    result = result - select(2, self:GetSpellsCount())
  end
  return result
end

function wand:SetProperties(key_values)
  for k,v in pairs(key_values) do
    validate_property(k, v)
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
    result[key] = self:_GetProperty(key)
  end
  return result
end
-- For making the interface nicer, this allows us to use this one function here for
function wand:_AddSpells(spells, attach)
  -- Check if capacity is sufficient
  local count = 0
  for i, v in ipairs(spells) do
    count = count + v[2]
  end
  local spells_on_wand = self:GetSpells()
  local positions = {}
  for i, v in ipairs(spells_on_wand) do
    positions[v.inventory_x] = true
  end

  if not attach and #spells_on_wand + count > self.capacity then
    error(string.format("Wand capacity (%d/%d) cannot fit %d more spells. ", #spells_on_wand, self.capacity, count), 3)
  end
  local current_position = 0
  for i,spell in ipairs(spells) do
    for i2=1, spell[2] do
      if not attach then
        local action_entity_id = CreateItemActionEntity(spell[1])
        EntityAddChild(self.entity_id, action_entity_id)
        EntitySetComponentsWithTagEnabled(action_entity_id, "enabled_in_world", false)
        local item_component = EntityGetFirstComponentIncludingDisabled(action_entity_id, "ItemComponent")
        while positions[current_position] do
          current_position = current_position + 1
        end
        positions[current_position] = true
        ComponentSetValue2(item_component, "inventory_slot", current_position, 0)
      else
        AddGunActionPermanent(self.entity_id, spell[1])
      end
    end
  end
end

function extract_spells_from_vararg(...)
  local spells = {}
  local spell_args = select("#", ...) == 1 and type(...) == "table" and ... or {...}
  local i = 1
  while i <= #spell_args do
    if type(spell_args[i]) == "table" then
      -- Check for this syntax: { "BOMB", 1 }
      if type(spell_args[i][1]) ~= "string" or type(spell_args[i][2]) ~= "number" then
        error("Wrong argument format at index " .. i .. ". Expected format for multiple spells shortcut: { \"BOMB\", 3 }", 3)
      else
        table.insert(spells, spell_args[i])
      end
    elseif type(spell_args[i]) == "string" then
      local amount = spell_args[i+1]
      if type(amount) ~= "number" then
        amount = 1
        table.insert(spells, { spell_args[i], amount })
      else
        table.insert(spells, { spell_args[i], amount })
        i = i + 1
      end
    else
      error("Wrong argument format.", 3)
    end
    i = i + 1
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
    local item_action_component = EntityGetFirstComponentIncludingDisabled(spell, "ItemActionComponent")
    if item_action_component then
      local val = ComponentGetValue2(item_action_component, "action_id")
      action_id = val
    end
    local inventory_x, inventory_y = -1, -1
    local item_component = EntityGetFirstComponentIncludingDisabled(spell, "ItemComponent")
    if item_component then
      permanent = ComponentGetValue2(item_component, "permanently_attached")
      inventory_x, inventory_y = ComponentGetValue2(item_component, "inventory_slot")
    end
    if action_id then
			if permanent == true then
				table.insert(always_cast_spells, { action_id = action_id, entity_id = spell, inventory_x = inventory_x, inventory_y = inventory_y })
			else
				table.insert(spells, { action_id = action_id, entity_id = spell, inventory_x = inventory_x, inventory_y = inventory_y })
			end
		end
  end
  table.sort(always_cast_spells, function(a, b) return a.inventory_x < b.inventory_x end)
  table.sort(spells, function(a, b) return a.inventory_x < b.inventory_x end)
	return spells, always_cast_spells
end

function wand:_RemoveSpells(spells_to_remove, detach)
	local spells, attached_spells = self:GetSpells()
  local which = detach and attached_spells or spells
  local spells_to_remove_remaining = {}
  for _, spell in ipairs(spells_to_remove) do
    spells_to_remove_remaining[spell[1]] = (spells_to_remove_remaining[spell[1]] or 0) + spell[2]
  end
  for i, v in ipairs(which) do
    if #spells_to_remove == 0 or spells_to_remove_remaining[v.action_id] and spells_to_remove_remaining[v.action_id] ~= 0 then
      if #spells_to_remove > 0 then
        spells_to_remove_remaining[v.action_id] = spells_to_remove_remaining[v.action_id] - 1
      end
      -- This needs to happen because EntityKill takes one frame to take effect or something
      EntityRemoveFromParent(v.entity_id)
      EntityKill(v.entity_id)
      if detach then
        self.capacity = self.capacity - 1
      end
    end
  end
end
-- action_ids = {"BLACK_HOLE", "GRENADE"} remove all spells of those types
-- If action_ids is empty, remove all spells
-- If entry is in the form of {"BLACK_HOLE", 2}, only remove 2 instances of black hole
function wand:RemoveSpells(...)
  local spells = extract_spells_from_vararg(...)
  self:_RemoveSpells(spells, false)
end
function wand:DetachSpells(...)
  local spells = extract_spells_from_vararg(...)
  self:_RemoveSpells(spells, true)
end

function wand:RemoveSpellAtIndex(index)
  if index+1 > self.capacity then
    return false, "index is bigger than capacity"
  end
  local spells = self:GetSpells()
  for i, spell in ipairs(spells) do
    if spell.inventory_x == index then
      -- This needs to happen because EntityKill takes one frame to take effect or something
      EntityRemoveFromParent(spell.entity_id)
      EntityKill(spell.entity_id)
      return true
    end
  end
  return false, "index at " .. index .. " does not contain a spell"
end

-- Make it impossible to edit the wand
-- freeze_wand prevents spells from being added to the wand or moved
-- freeze_spells prevents the spells from being removed
function wand:SetFrozen(freeze_wand, freeze_spells)
  local item_component = EntityGetFirstComponentIncludingDisabled(self.entity_id, "ItemComponent")
  ComponentSetValue2(item_component, "is_frozen", freeze_wand)
  local spells = self:GetSpells()
  for i, spell in ipairs(spells) do
    local item_component = EntityGetFirstComponentIncludingDisabled(spell.entity_id, "ItemComponent")
    ComponentSetValue2(item_component, "is_frozen", freeze_spells)
  end
end

function wand:SetSprite(item_file, offset_x, offset_y, tip_x, tip_y)
	if self.ability_component then
    ComponentSetValue2(self.ability_component, "sprite_file", item_file)
	end
  local sprite_comp = EntityGetFirstComponentIncludingDisabled(self.entity_id, "SpriteComponent", "item")
  if sprite_comp then
    ComponentSetValue2(sprite_comp, "image_file", item_file)
    ComponentSetValue2(sprite_comp, "offset_x", offset_x)
    ComponentSetValue2(sprite_comp, "offset_y", offset_y)
    EntityRefreshSprite(self.entity_id, sprite_comp)
	end
	local hotspot_comp = EntityGetFirstComponentIncludingDisabled(self.entity_id, "HotspotComponent", "shoot_pos")
  if hotspot_comp then
    ComponentSetValue2(hotspot_comp, "offset", tip_x, tip_y)
	end
end

function wand:GetSprite()
  local item_file, offset_x, offset_y, tip_x, tip_y
	if self.ability_component then
		item_file = ComponentGetValue2(self.ability_component, "sprite_file")
	end
	local sprite_comp = EntityGetFirstComponentIncludingDisabled(self.entity_id, "SpriteComponent", "item")
	if sprite_comp then
		offset_x = ComponentGetValue2(sprite_comp, "offset_x")
    offset_y = ComponentGetValue2(sprite_comp, "offset_y")
	end
	local hotspot_comp = EntityGetFirstComponentIncludingDisabled(self.entity_id, "HotspotComponent", "shoot_pos")
  if hotspot_comp then
    tip_x, tip_y = ComponentGetValue2(hotspot_comp, "offset")
  end
  return item_file, offset_x, offset_y, tip_x, tip_y
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
  new_wand:SetSprite(self:GetSprite())
  return new_wand
end

--[[
  These are pulled from data/scripts/gun/procedural/gun_procedural.lua
  because dofiling that file overwrites the init_total_prob function,
  which ruins things in biome scripts
]]
function WandDiff( gun, wand )
	local score = 0
	score = score + ( math.abs( gun.fire_rate_wait - wand.fire_rate_wait ) * 2 )
	score = score + ( math.abs( gun.actions_per_round - wand.actions_per_round ) * 20 )
	score = score + ( math.abs( gun.shuffle_deck_when_empty - wand.shuffle_deck_when_empty ) * 30 )
	score = score + ( math.abs( gun.deck_capacity - wand.deck_capacity ) * 5 )
	score = score + math.abs( gun.spread_degrees - wand.spread_degrees )
	score = score + math.abs( gun.reload_time - wand.reload_time )
	return score
end

function GetWand( gun )
	local best_wand = nil
	local best_score = 1000
	local gun_in_wand_space = {}

	gun_in_wand_space.fire_rate_wait = clamp(((gun["fire_rate_wait"] + 5) / 7)-1, 0, 4)
	gun_in_wand_space.actions_per_round = clamp(gun["actions_per_round"]-1,0,2)
	gun_in_wand_space.shuffle_deck_when_empty = clamp(gun["shuffle_deck_when_empty"], 0, 1)
	gun_in_wand_space.deck_capacity = clamp( (gun["deck_capacity"]-3)/3, 0, 7 ) -- TODO
	gun_in_wand_space.spread_degrees = clamp( ((gun["spread_degrees"] + 5 ) / 5 ) - 1, 0, 2 )
	gun_in_wand_space.reload_time = clamp( ((gun["reload_time"]+5)/25)-1, 0, 2 )

	for k,wand in pairs(wands) do
		local score = WandDiff( gun_in_wand_space, wand )
		if( score <= best_score ) then
			best_wand = wand
			best_score = score
			-- just randomly return one of them...
			if( score == 0 and Random(0,100) < 33 ) then
				return best_wand
			end
		end
	end
	return best_wand
end
--[[ /data/scripts/gun/procedural/gun_procedural.lua ]]

-- Applies an appropriate Sprite using the games own algorithm
function wand:UpdateSprite()
  local gun = {
    fire_rate_wait = self.castDelay,
    actions_per_round = self.spellsPerCast,
    shuffle_deck_when_empty = self.shuffle and 1 or 0,
    deck_capacity = self.capacity,
    spread_degrees = self.spread,
    reload_time = self.rechargeTime,
  }
  local sprite_data = GetWand(gun)
  self:SetSprite(sprite_data.file, sprite_data.grip_x, sprite_data.grip_y,
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
  if inventory_items then
    for i,v in ipairs(inventory_items) do
      if entity_is_wand(v) then
        count = count + 1
      end
    end
  end
  local players = EntityGetWithTag("player_unit")
  if count < 4 and #players > 0 then
    local item_component = EntityGetFirstComponentIncludingDisabled(self.entity_id, "ItemComponent")
    if item_component then
      ComponentSetValue2(item_component, "has_been_picked_by_player", true)
    end
    GamePickUpInventoryItem(players[1], self.entity_id, false)
  else
    error("Cannot add wand to players inventory, it's already full.", 2)
  end
end

-- Turns the wand properties etc into a string
-- Output string looks like:
-- EZWv(version);shuffle[1|0];spellsPerCast;castDelay;rechargeTime;manaMax;mana;manaChargeSpeed;capacity;spread;speedMultiplier;
-- SPELL_ONE,SPELL_TWO;ALWAYS_CAST_ONE,ALWAYS_CAST_TWO;sprite.png;offset_x;offset_y;tip_x;tip_y
function wand:Serialize()
  local spells_string = ""
  local always_casts_string = ""
  local spells, always_casts = self:GetSpells()
  for i, spell in ipairs(spells) do
    spells_string = spells_string .. (i == 1 and "" or ",") .. spell.action_id
  end
  for i, spell in ipairs(always_casts) do
    always_casts_string = always_casts_string .. (i == 1 and "" or ",") .. spell.action_id
  end

  local sprite_image_file, offset_x, offset_y, tip_x, tip_y = self:GetSprite()

  -- Add a workaround for the starter wands which are the only ones with an xml sprite
  -- Modded wands which use xmls won't work sadly
  if sprite_image_file == "data/items_gfx/handgun.xml" then
    sprite_image_file = "data/items_gfx/handgun.png"
    offset_x = 4
    offset_y = 3.5
  end
  if sprite_image_file == "data/items_gfx/bomb_wand.xml" then
    sprite_image_file = "data/items_gfx/bomb_wand.png"
    offset_x = 4
    offset_y = 3.5
  end

  local serialize_version = "1"
  return ("EZWv%s;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%s;%s;%s;%d;%d;%d;%d"):format(
    serialize_version,
    self.shuffle and 1 or 0,
    self.spellsPerCast,
    self.castDelay,
    self.rechargeTime,
    self.manaMax,
    self.mana,
    self.manaChargeSpeed,
    self.capacity,
    self.spread,
    self.speedMultiplier,
    spells_string == "" and "-" or spells_string,
    always_casts_string == "" and "-" or always_casts_string,
    sprite_image_file, offset_x, offset_y, tip_x, tip_y
  )
end

return setmetatable({}, {
  __call = function(self, from, rng_seed_x, rng_seed_y)
    return wand:new(from, rng_seed_x, rng_seed_y)
  end,
  __newindex = function(self)
    error("Can't assign to this object.", 2)
  end,
  __index = function(self, key)
    return ({
      Deserialize = deserialize
    })[key]
  end
})
