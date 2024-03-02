-- This is a very shitty hacked together unit testing suite
-- I think it relies on the order of tests being correct...
-- Whatever, too lazy to improve it, at least it works :)
-- I execute it in the web console with mod-ws-api
-- https://github.com/probable-basilisk/noita-ws-api

Wand = EZWand

function table.ipairsmap(t, func)
  local out = {}
  for i, v in ipairs(t) do
    out[i] = func(v)
  end
  return out
end

local function table_count_occurences(table)
  local out = {}
  for i,v in ipairs(table) do
    out[v.action_id] = (out[v.action_id] or 0) + 1
  end
  return out
end

-- Compares two tables
function equals(o1, o2, ignore_mt)
  if o1 == o2 then return true end
  local o1Type = type(o1)
  local o2Type = type(o2)
  if o1Type ~= o2Type then return false end
  if o1Type ~= 'table' then return false end

  if not ignore_mt then
      local mt1 = getmetatable(o1)
      if mt1 and mt1.__eq then
          --compare using built in method
          return o1 == o2
      end
  end

  local keySet = {}

  for key1, value1 in pairs(o1) do
      local value2 = o2[key1]
      if value2 == nil or equals(value1, value2, ignore_mt) == false then
          return false
      end
      keySet[key1] = true
  end

  for key2, _ in pairs(o2) do
      if not keySet[key2] then return false end
  end
  return true
end

-- Test if a function throws an error
function throws(func, ...)
  local success, err = pcall(func, ...)
  return not success
end

local function GetHotspotComponent(entity_id)
  local comps = EntityGetAllComponents(entity_id)
  for i,v in ipairs(comps) do
    if ComponentGetValue(v, "transform_with_scale") ~= "" then
      return v
    end
  end
end

function GetWandSprite(entity_id)
  local item_file, offset_x, offset_y, tip_x, tip_y
  local ability_component = EntityGetFirstComponentIncludingDisabled(entity_id, "AbilityComponent")
  if ability_component ~= nil then
		item_file = ComponentGetValue2(ability_component, "sprite_file")
	end
	local sprite_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "SpriteComponent", "item")
	if sprite_comp ~= nil then
		offset_x = ComponentGetValue2(sprite_comp, "offset_x")
    offset_y = ComponentGetValue2(sprite_comp, "offset_y")
	end
	local hotspot_comp = GetHotspotComponent(entity_id) -- EntityGetFirstComponent(entity_id, "HotspotComponent", "shoot_pos")
  if hotspot_comp ~= nil then
    tip_x, tip_y = ComponentGetValue2(hotspot_comp, "offset")
  end
  return item_file, offset_x, offset_y, tip_x, tip_y
end

function test_constructors()
  local spells_count, attached_spells_count
  local wand = Wand()
  assert(wand.entity_id ~= nil)
  assert(wand.ability_component ~= nil)
  -- Check if defaults were set
  for k,v in pairs(wand_props) do
    if v.default then
      assert(wand[k] == v.default, string.format("Constructor didn't set default values for %s. Given: %s, Expected: %s", k, wand[k], v.default))
    end
  end
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 0, "Spells count expected to be 0, got: " .. spells_count)
  assert(attached_spells_count == 0, "Attached spells count expected to be 0, got: " .. attached_spells_count)
  test_Everything(wand)
  EntityKill(wand.entity_id)

  wand = Wand{}
  assert(wand.entity_id ~= nil)
  assert(wand.ability_component ~= nil)
  for k,v in pairs(wand_props) do
    if v.default then
      assert(wand[k] == v.default, string.format("Constructor didn't set default values for %s. Given: %s, Expected: %s", k, wand[k], v.default))
    end
  end
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 0)
  assert(attached_spells_count == 0)
  test_Everything(wand)
  EntityKill(wand.entity_id)

  wand = Wand{
    manaMax = 123,
    capacity = 7,
  }
  assert(wand.entity_id ~= nil)
  assert(wand.ability_component ~= nil)
  assert(wand.manaMax == 123)
  assert(wand.capacity == 7)
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 0)
  assert(attached_spells_count == 0)
  test_Everything(wand)
  EntityKill(wand.entity_id)

  wand = Wand("data/hax/EZWand/wandy.xml")
  assert(wand.entity_id ~= nil)
  assert(wand.ability_component ~= nil)
  test_Everything(wand)
  EntityKill(wand.entity_id)
end

function test_getters_and_setters(wand)
  wand.shuffle = false
  assert(wand.shuffle == false)
  wand.shuffle = true
  assert(wand.shuffle == true)
  wand.spellsPerCast = 17
  assert(wand.spellsPerCast == 17)
  wand.castDelay = 17
  assert(wand.castDelay == 17)
  wand.rechargeTime = 17
  assert(wand.rechargeTime == 17)
  wand.manaMax = 17
  assert(wand.manaMax == 17)
  wand.mana = 17
  assert(wand.mana == 17)
  wand.manaChargeSpeed = 17
  assert(wand.manaChargeSpeed == 17)
  wand.capacity = 17
  assert(wand.capacity == 17)
  wand.spread = 17
  assert(wand.spread == 17)
  wand.speedMultiplier = 17
  assert(wand.speedMultiplier == 17)
end

function test_GetProperties(wand)
  local all_props = wand:GetProperties()
  
  for k,v in pairs(wand_props) do
    assert(all_props[k] ~= nil)
  end

  local some_props = wand:GetProperties{
    "manaMax", "manaChargeSpeed"
  }
  assert(some_props.manaMax ~= nil)
  assert(some_props.manaChargeSpeed ~= nil)
end

function test_SetProperties(wand)
  wand:SetProperties{ manaMax = 6969, spread = -42.47 }
  assert(wand.manaMax == 6969)
  assert(wand.spread - -42.47 < 0.01)
end

function test_RemoveSpells(wand)
  wand:RemoveSpells()
  wand:DetachSpells()
  local spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 0)
  assert(attached_spells_count == 0)
end

function test_AddSpells(wand)
  local spells_count, attached_spells_count
  -- Test table version
  wand:AddSpells{"BULLET"}
  wand:AttachSpells{"BULLET"}
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 1)
  assert(attached_spells_count == 1)
  wand:AddSpells{"BULLET", "BULLET"}
  wand:AttachSpells{"BULLET", "BULLET", "BULLET"}
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 3)
  assert(attached_spells_count == 4)
  -- Test vararg version
  wand:AddSpells("BULLET")
  wand:AttachSpells("BULLET")
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 4)
  assert(attached_spells_count == 5)
  wand:AddSpells("BULLET", "BULLET")
  wand:AttachSpells("BULLET", "BULLET", "BULLET")
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 6)
  assert(attached_spells_count == 8)
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AddSpells("BULLET", 3, "BLACK_HOLE", 2)
  wand:AttachSpells("BULLET", 3, "BLACK_HOLE", 2)
  local spells, attached_spells = wand:GetSpells()
  local occurences = table_count_occurences(spells)
  assert(occurences["BULLET"] == 3)
  assert(occurences["BLACK_HOLE"] == 2)
  occurences = table_count_occurences(attached_spells)
  assert(occurences["BULLET"] == 3)
  assert(occurences["BLACK_HOLE"] == 2)
  -- These should throw an error
  assert(throws(wand.AddSpells, wand, 2, {}, {"BULLET", 5}))
  assert(throws(wand.AddSpells, wand, {"BOMB", 2}, {}, {"BULLET", 5}))
  -- Test that we can't surpass capacity
  wand:RemoveSpells()
  wand.capacity = 3
  assert(throws(wand.AddSpells, wand, "BOMB", 4))
end

function test_GetSpellsCount(wand)
  wand:RemoveSpells()
  wand:DetachSpells()
  local spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 0)
  assert(attached_spells_count == 0)
  wand:AddSpells{"BULLET", "BULLET"}
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 2)
  assert(attached_spells_count == 0)
  wand:RemoveSpells()
  wand:AttachSpells{"BULLET", "BULLET"}
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 0)
  assert(attached_spells_count == 2)
  wand:DetachSpells()
  wand:AddSpells{"BULLET", "BULLET"}
  wand:AttachSpells{"BULLET", "BULLET"}
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 2)
  assert(attached_spells_count == 2)
end

function test_GetSpells(wand)
  local spells, attached_spells
  local to_add = { "BULLET", "BOUNCY_ORB", "BOUNCY_ORB", "BULLET", "BLACK_HOLE", "BULLET" }
  local to_attach = { "BLACK_HOLE", "BULLET", "BLACK_HOLE", "BULLET", "BLACK_HOLE", "BULLET" }
  wand:RemoveSpells()
  wand.capacity = 10
  wand:AddSpells(to_add)
  spells, attached_spells = wand:GetSpells()
  for i,v in ipairs(to_add) do
    assert(v == spells[i].action_id, string.format("Expected %s, got %s, i=%d", v, spells[i].action_id, i))
  end

  wand:DetachSpells()
  wand:AttachSpells(to_attach)
  spells, attached_spells = wand:GetSpells()
  assert(#to_attach == #attached_spells)
  local attached_spell_ids = {}
  for i,v in ipairs(attached_spells) do
    table.insert(attached_spell_ids, v.action_id)
  end
  table.sort(attached_spell_ids)
  table.sort(to_attach)
  assert(equals(attached_spell_ids, to_attach))
end

-- Oh boy this is one CHUNKY test function that could use some refactoring but whatever
function test_RemoveSpecificSpells(wand)
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AddSpells("BOMB", 5, "BULLET", 3)
  -- Test single spell removal, with vararg and table syntax
  wand:RemoveSpells{"BOMB", 2}
  wand:RemoveSpells("BULLET", 1)
  local spells, attached_spells = wand:GetSpells()
  assert(#spells == 5)
  -- Order is not guaranteed and hard to test without inventory_pos.x working so we just test like so
  local occurences = table_count_occurences(spells)
  assert(occurences["BOMB"] == 3)
  assert(occurences["BULLET"] == 2)
  -- Next test, this time DetachSpells
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AttachSpells("BOMB", 5, "BULLET", 3)
  wand:DetachSpells{"BOMB", 2}
  wand:DetachSpells("BULLET", 1)
  spells, attached_spells = wand:GetSpells()
  assert(#attached_spells == 5)
  occurences = table_count_occurences(attached_spells)
  assert(occurences["BOMB"] == 3)
  assert(occurences["BULLET"] == 2)
  -- All of the above again, this time test if multiple spells can be removed with 1 call
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AddSpells("BOMB", 5, "BULLET", 3)
  -- Test single spell removal, with vararg and table syntax
  wand:RemoveSpells{"BOMB", 1, "BULLET", 1}
  wand:RemoveSpells("BOMB", 1, "BULLET", 1)
  local spells, attached_spells = wand:GetSpells()
  assert(#spells == 4)
  -- Order is not guaranteed and hard to test without inventory_pos.x working so we just test like so
  local occurences = table_count_occurences(spells)
  assert(occurences["BOMB"] == 3)
  assert(occurences["BULLET"] == 1)
  -- Next test, this time DetachSpells
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AttachSpells("BOMB", 5, "BULLET", 3)
  wand:DetachSpells{"BOMB", 1, "BULLET", 1}
  wand:DetachSpells("BOMB", 1, "BULLET", 1)
  spells, attached_spells = wand:GetSpells()
  assert(#attached_spells == 4)
  occurences = table_count_occurences(attached_spells)
  assert(occurences["BOMB"] == 3)
  assert(occurences["BULLET"] == 1)
  -- Test if remove all syntax works
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AddSpells("BOMB", 5, "BULLET", 3)
  wand:RemoveSpells("BOMB", -1)
  spells, attached_spells = wand:GetSpells()
  assert(#spells == 3)
  occurences = table_count_occurences(spells)
  assert(occurences["BOMB"] == nil)
  assert(occurences["BULLET"] == 3)
  -- Test if using the same spell twice works
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AddSpells("BOMB", 3)
  wand:RemoveSpells("BOMB", "BOMB")
  spells, attached_spells = wand:GetSpells()
  assert(#spells == 1)
  occurences = table_count_occurences(spells)
  assert(occurences["BOMB"] == 1)
end

function test_RemoveSpellAtIndex(wand)
  wand.capacity = 5
  wand:RemoveSpells()
  wand:AddSpells("BOMB", "BULLET", "BLACK_HOLE")
  local success = wand:RemoveSpellAtIndex(0)
  local spells = table.ipairsmap(wand:GetSpells(), function(v) return v.action_id end)
  assert(success)
  assert(equals(spells, { "BULLET", "BLACK_HOLE" }))

  wand:RemoveSpells()
  wand:AddSpells("BOMB", "BULLET", "BLACK_HOLE")
  local success = wand:RemoveSpellAtIndex(1)
  local spells = table.ipairsmap(wand:GetSpells(), function(v) return v.action_id end)
  assert(success)
  assert(equals(spells, { "BOMB", "BLACK_HOLE" }))

  local success, err = wand:RemoveSpellAtIndex(6)
  assert(success == false)
  assert(type(err) == "string")
  
  -- Test if it returns an error correctly when trying to remove at index that doesn't have a spell
  local success, err = wand:RemoveSpellAtIndex(1)
  assert(success == false)
  assert(type(err) == "string")
end

function test_DetachSpells_does_not_reduce_capacity(wand)
  wand:DetachSpells()
  wand:AttachSpells("BULLET", 5)
  local old_capacity = wand.capacity
  wand:DetachSpells()
  assert(wand.capacity == old_capacity)
end

function test_reducing_capacity_removes_excess_spells(wand)
  wand:RemoveSpells()
  wand:DetachSpells()
  wand.capacity = 20
  wand:AddSpells("BOMB", 20)
  wand:AttachSpells("BOMB", 3)
  wand.capacity = 15
  local spells, attached_spells = wand:GetSpells()
  assert(#spells == 15, #spells)
  assert(#attached_spells == 3, #attached_spells)
  wand.capacity = 17
  spells = wand:GetSpells()
  assert(#spells == 15, #spells)
  assert(#attached_spells == 3, #attached_spells)
end

function test_Clone(wand)
  local cloned_wand = wand:Clone()
  for k,v in pairs(wand_props) do
    assert(cloned_wand[k] == wand[k], string.format("Clone failed, stats are not equal: %s, New wand: %s, Old wand: %s", k, tostring(cloned_wand[k]), tostring(wand[k])))
  end
  local spells, attached_spells = wand:GetSpells()
  local cloned_spells, cloned_attached_spells = wand:GetSpells()
  assert(#spells == #cloned_spells)
  assert(#attached_spells == #cloned_attached_spells)
  -- Double checking never hurts ;)
  local spells_count, attached_spells_count = wand:GetSpellsCount()
  local clone_spells_count, clone_attached_spells_count = cloned_wand:GetSpellsCount()
  assert(spells_count == clone_spells_count)
  assert(attached_spells_count == clone_attached_spells_count)
  for i, v in ipairs(spells) do
    assert(v.action_id == cloned_spells[i].action_id)
  end
  for i, v in ipairs(attached_spells) do
    assert(v.action_id == cloned_attached_spells[i].action_id)
  end
  -- Test if sprites are the same
  local a1, b1, c1, d1, e1 = GetWandSprite(wand.entity_id)
  local a2, b2, c2, d2, e2 = GetWandSprite(cloned_wand.entity_id) 
  assert(a1 == a2, string.format("Clone failed, %s ~= %s", a1, a2))
  assert(b1 == b2, string.format("Clone failed, %s ~= %s", b1, b2))
  assert(c1 == c2, string.format("Clone failed, %s ~= %s", c1, c2))
  assert(d1 == d2, string.format("Clone failed, %s ~= %s", d1, d2))
  assert(e1 == e2, string.format("Clone failed, %s ~= %s", e1, e2))
  EntityKill(cloned_wand.entity_id)
end

function test_UpdateSprite(wand)
  wand.shuffle = true
  wand.spellsPerCast = 17
  wand.castDelay = 17
  wand.rechargeTime = 17
  wand.manaMax = 17
  wand.mana = 17
  wand.manaChargeSpeed = 17
  wand.capacity = 17
  wand.spread = 17
  wand.speedMultiplier = 17
  wand:UpdateSprite()
  local a, b, c, d, e = wand:GetSprite()
  assert(a == "data/items_gfx/wands/wand_0706.png")
  assert(b == 2)
  assert(c == 4)
  assert(d == 16)
  assert(e == 0)
end

function test_wrong_accessor(wand)
  local success, err_msg = pcall(function()
    local a = wand.something
  end)
  assert(success == false)
  assert(err_msg and err_msg:find("EZWand has no property 'something'"))
end

-- No good way to test this except to make sure it doesn't throw errors
function test_RenderTooltip(wand)
  wand:RenderTooltip(5, 5)
end

function test_Everything(wand) -- Gets called multiple times from inside test_constructors, DON'T CALL THIS YOURSELF
  test_getters_and_setters(wand)
  test_GetProperties(wand)
  test_SetProperties(wand)
  test_RemoveSpells(wand)
  test_AddSpells(wand)
  test_GetSpells(wand)
  test_GetSpellsCount(wand)
  test_RemoveSpecificSpells(wand)
  test_Clone(wand)
  test_reducing_capacity_removes_excess_spells(wand)
  test_DetachSpells_does_not_reduce_capacity(wand)
  test_RemoveSpellAtIndex(wand)
  test_UpdateSprite(wand)
  test_wrong_accessor(wand)
  test_RenderTooltip(wand)
end

function test_extract_spells_from_vararg()
  assert(equals(extract_spells_from_vararg("BOMB"),                    { { "BOMB", 1 } }   ))
  assert(equals(extract_spells_from_vararg("BOMB", 1),                 { { "BOMB", 1 } }   ))
  assert(equals(extract_spells_from_vararg({ "BOMB", 1 }),             { { "BOMB", 1 } }   ))
  assert(equals(extract_spells_from_vararg("BOMB", "WHAT"),            { { "BOMB", 1 }, { "WHAT", 1 } }   ))
  assert(equals(extract_spells_from_vararg("BOMB", 5, "WHAT"),         { { "BOMB", 5 }, { "WHAT", 1 } }   ))
  assert(equals(extract_spells_from_vararg("BOMB", 5, "WHAT", 3),      { { "BOMB", 5 }, { "WHAT", 3 } }   ))
  assert(equals(extract_spells_from_vararg("BOMB", "WHAT", 3),         { { "BOMB", 1 }, { "WHAT", 3 } }   ))
  assert(equals(extract_spells_from_vararg("BOMB", { "WHAT", 3 } ),    { { "BOMB", 1 }, { "WHAT", 3 } }   ))
  assert(equals(extract_spells_from_vararg({}),               {}                  ))
  assert(equals(extract_spells_from_vararg(),                 {}                  ))
  assert(throws(extract_spells_from_vararg, {}, 5))
  assert(throws(extract_spells_from_vararg, 5))
  assert(throws(extract_spells_from_vararg, false))
  assert(throws(extract_spells_from_vararg, true))
  assert(throws(extract_spells_from_vararg, { true }))
end

function test_serialize_deserialize()
  local base_stats = {
    shuffle = false,
    spellsPerCast = 1,
    castDelay = 20,
    rechargeTime = 40,
    manaMax = 500,
    mana = 500,
    manaChargeSpeed = 200,
    capacity = 10,
    spread = 10,
    speedMultiplier = 1,
  }
  local wand = Wand(base_stats)
  wand:AddSpells("", 2, "BOMB", 2, "BLACK_HOLE")
  wand:AttachSpells("LIGHT_BULLET", "BULLET_TIMER", 2)
  wand:SetSprite("data/items_gfx/wands/wand_0666.png", 1, 2, 3, 4)
  local serialized = wand:Serialize()
  local expected = "EZWv2;0;1;20;40;500;500;200;10;10;1;,,BOMB,BOMB,BLACK_HOLE,,,,,;LIGHT_BULLET,BULLET_TIMER,BULLET_TIMER;data/items_gfx/wands/wand_0666.png;1;2;3;4;;0"
  -- First test if the serialized string matches what we expect
  assert(serialized == expected, string.format("\nExpected:\n%s\nGot:\n%s", expected, serialized))
  EntityKill(wand.entity_id)
  wand = Wand(serialized)
  -- Then try to construct the same wand again from the serialized version,
  -- check if it's the same by serializing it again and comparing the serialized string
  local serialized = wand:Serialize()
  assert(serialized == expected, string.format("\nExpected:\n%s\nGot:\n%s", expected, serialized))
  EntityKill(wand.entity_id)

  -- Test if deserializing an old version still works
  local wand = Wand("EZWv1;0;1;20;40;500;500;200;10;10;1;,,BOMB,BOMB,BLACK_HOLE,,,,,;LIGHT_BULLET,BULLET_TIMER,BULLET_TIMER;data/items_gfx/wands/wand_0666.png;1;2;3;4")
  EntityKill(wand.entity_id)

  -- Test if name setting works
  local wand = Wand("EZWv2;0;1;20;40;500;500;200;10;10;1;,,BOMB,BOMB,BLACK_HOLE,,,,,;LIGHT_BULLET,BULLET_TIMER,BULLET_TIMER;data/items_gfx/wands/wand_0666.png;1;2;3;4;HelloBlaster;0")
  local name, show_in_ui = wand:GetName()
  assert(name == "HelloBlaster")
  assert(show_in_ui == false)
  EntityKill(wand.entity_id)
  local wand = Wand("EZWv2;0;1;20;40;500;500;200;10;10;1;,,BOMB,BOMB,BLACK_HOLE,,,,,;LIGHT_BULLET,BULLET_TIMER,BULLET_TIMER;data/items_gfx/wands/wand_0666.png;1;2;3;4;HelloBlaster;1")
  local name, show_in_ui = wand:GetName()
  assert(name == "HelloBlaster")
  assert(show_in_ui == true)
  EntityKill(wand.entity_id)
end

function run_wand_tests()
  test_constructors()
  test_extract_spells_from_vararg()
  test_serialize_deserialize()
  print("All tests passed!")
end
