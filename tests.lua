-- This is a very shitty hacked together unit testing suite
-- I think it relies on the order of tests being correct...
-- Whatever, too lazy to improve it, at least it works :)
-- I execute it in the web console with mod-ws-api
-- https://github.com/probable-basilisk/noita-ws-api

Wand = EZWand

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
    assert(tonumber(wand[k]) == v.default, string.format("Constructor didn't set default values for %s. Given: %s, Expected: %s", k, wand[k], v.default))
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
    assert(tonumber(wand[k]) == v.default)
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

  wand = Wand("data/ws/EZWand/wandy.xml")
  assert(wand.entity_id ~= nil)
  assert(wand.ability_component ~= nil)
  test_Everything(wand)
  EntityKill(wand.entity_id)
end

function test_getters_and_setters(wand)
  wand.shuffle = 0
  assert(wand.shuffle == 0)
  wand.shuffle = 1
  assert(wand.shuffle == 1)
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
  assert(wand.spread == -42.47)
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
--wand:AddSpells("BOMB")
--wand:AddSpells({"BOMB", 5})
--wand:AddSpells("BULLET", {"BOMB", 5})
--wand:AddSpells({"BOMB", 5}, "BULLET")
--wand:AddSpells({"BOMB", 2}, {"BULLET", 5})

-- These should error out
--wand:AddSpells{2, {}, {"BULLET", 5}}
--wand:AddSpells{{"BOMB", 2}, {}, {"BULLET", 5}}

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
  wand:AddSpells(to_add)
  spells, attached_spells = wand:GetSpells()
  for i,v in ipairs(to_add) do
    assert(v == spells[i].action_id, string.format("Expected %s, got %s", v, spells[i].action_id))
  end

  wand:DetachSpells()
  wand:AttachSpells(to_attach)
  spells, attached_spells = wand:GetSpells()
  for i,v in ipairs(to_attach) do
    assert(v == attached_spells[i].action_id)
  end
end

local function table_count_occurences(table)
  local out = {}
  for i,v in ipairs(table) do
    out[v.action_id] = (out[v.action_id] or 0) + 1
  end
  return out
end
-- Oh boy this is one CHUNKY test function that could use some refactoring but whatever
function test_RemoveSpecificSpells(wand)
  local test_spells = { "BURST_2", "BURST_3", "Y_SHAPE", "CIRCLE_SHAPE", "FLY_DOWNWARDS" }
  local spells_count, attached_spells_count
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AddSpells{ test_spells[1], test_spells[1], test_spells[3], test_spells[3], test_spells[4], test_spells[4], test_spells[5], }
  -- Test single spell removal, both syntaxes
  wand:RemoveSpells{ test_spells[3] }
  wand:RemoveSpells( test_spells[4] )
  -- Double checking can't hurt!
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 3)
  local spells, attached_spells = wand:GetSpells()
  assert(#spells == 3)
  -- Order is not guaranteed and hard to test without inventory_pos.x working so we just test like so
  local occurences = table_count_occurences(spells)
  assert(occurences[test_spells[1]] == 2)
  assert(occurences[test_spells[5]] == 1)
  -- Next test, this time DetachSpells
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AttachSpells{ test_spells[1], test_spells[1], test_spells[3], test_spells[3], test_spells[4], test_spells[4], test_spells[5], }
  wand:DetachSpells{ test_spells[3] }
  wand:DetachSpells( test_spells[4] )
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(attached_spells_count == 3)
  spells, attached_spells = wand:GetSpells()
  assert(#attached_spells == 3)
  occurences = table_count_occurences(attached_spells)
  assert(occurences[test_spells[1]] == 2)
  assert(occurences[test_spells[5]] == 1)
  -- All of the above again, this time test if multile spells can be removed with 1 call
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AddSpells{ test_spells[1], test_spells[1], test_spells[3], test_spells[2], test_spells[4], test_spells[2], test_spells[5], }
  -- Test multi spell removal, both syntaxes
  wand:RemoveSpells{ test_spells[2], test_spells[3] }
  wand:RemoveSpells( test_spells[4], test_spells[5] )
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(spells_count == 2)
  spells, attached_spells = wand:GetSpells()
  assert(#spells == 2)
  occurences = table_count_occurences(spells)
  assert(occurences[test_spells[1]] == 2)
  -- Next test, this time DetachSpells
  wand:RemoveSpells()
  wand:DetachSpells()
  wand:AttachSpells{ test_spells[1], test_spells[1], test_spells[3], test_spells[2], test_spells[4], test_spells[2], test_spells[5], }
  wand:DetachSpells{ test_spells[2], test_spells[3] }
  wand:DetachSpells( test_spells[4], test_spells[5] )
  spells_count, attached_spells_count = wand:GetSpellsCount()
  assert(attached_spells_count == 2)
  spells, attached_spells = wand:GetSpells()
  assert(#attached_spells == 2)
  occurences = table_count_occurences(attached_spells)
  assert(occurences[test_spells[1]] == 2)
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
end

function run_wand_tests()
  test_constructors()
  print("All tests passed!")
end
