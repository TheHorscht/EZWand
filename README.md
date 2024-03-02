# EZWand v2.0.0

A utility library for mod developers of Noita which simplifies the workflow of creating and manipulating wands. Use at your own risk I don't want to be responsible for your mod breaking :)

## Installation
Just move `EZWand.lua` somewhere and then:
```lua
local EZWand = dofile_once("EZWand.lua")
```
## Usage
### Creation / constructors:
```lua
-- New wand with default values
local wand = EZWand()
-- Wrap an existing wand
local wand = EZWand(wand_entity_id)
-- Load a wand from XML
local wand = EZWand("data/entities/items/wand_level_04.xml")
-- New wand and set values (notice the {} syntax)
local wand = EZWand(table_of_property_values)
-- e.g. (with lua table call shortcut):
local wand = EZWand{
  manaMax = 200,
  rechargeTime = 5,
  spread = -10
  -- What is not set is initialized with defaults
}
-- Default values are:
wand.shuffle = false
wand.spellsPerCast = 1
wand.castDelay = 20
wand.rechargeTime = 40
wand.manaMax = 500
wand.mana = 500
wand.manaChargeSpeed = 200
wand.capacity = 10
wand.spread = 10
wand.speedMultiplier = 1
```
### Manipulation of properties:
```lua
-- Single properties
wand.manaMax = 123
wand.shuffle = false
wand.capacity = wand.capacity + 5
-- Set multiple at once
wand:SetProperties({
  manaMax = 200,
  shuffle = true
})
-- Get multiple at once
local props = wand:GetProperties() -- Gets all
props = wand:GetProperties({"manaMax", "capacity"}) -- Gets some
```
### Adding spells:
```lua
-- Single
wand:AddSpells("BULLET")
-- Multiple
wand:AddSpells("BULLET", "BULLET", "BLACK_HOLE")
-- From table
local spells_to_add = { "BULLET", "BULLET", "BLACK_HOLE" }
wand:AddSpells(spells_to_add)
-- Or add multiple like this, which will result in 1 bomb followed by 3 bullets and then 1 black hole:
wand:AddSpells("BOMB", { "BULLET", 3 }, "BLACK_HOLE")
-- the same but different syntax like this
wand:AddSpells("BOMB", "BULLET", 3, "BLACK_HOLE")
-- This also works with when passing in a table

-- To add always cast spells, simply use the same syntax
-- but with wand:AttachSpells instead
wand:AttachSpells("BLACK_HOLE")
```
### Removing Spells:
```lua
-- Remove all spells
wand:RemoveSpells()
-- Remove one BLACK_HOLE spell
wand:RemoveSpells("BLACK_HOLE")
-- Remove two BLACK_HOLE spells
wand:RemoveSpells("BLACK_HOLE", 2) or wand:RemoveSpells("BLACK_HOLE", "BLACK_HOLE")
-- Remove all slotted BLACK_HOLE spells
wand:RemoveSpells("BLACK_HOLE", -1)
-- or with table version
wand:RemoveSpells({ "BULLET", "BLACK_HOLE" })
-- Always cast spell version:
wand:DetachSpells()
-- Remove a spell at a certain position:
local success, error_msg = wand:RemoveSpellAtIndex(index)
```
### Getting spells and spell count
```lua
-- Returns two values, first is regular spells, second always cast spells
local spells_count, attached_spells_count = wand:GetSpellsCount()
-- Returns the amount of slots on a wand that are not occupied by a spell
local free_slots_count = wand:GetFreeSlotsCount()
-- Now let's get the spells
local spells, attached_spells = wand:GetSpells()
-- spells and attached_spells is a table with the following properties:
spells = {
  {
    action_id = "BLACK_HOLE",
    inventory_x = 1, inventory_y = 0,
    entity_id = <entity_id>
  }, {
    action_id = "GRENADE",
    inventory_x = 2, inventory_y = 0,
    entity_id = <entity_id>
  }
}
-- Print all spells action_ids:
for i,spell in ipairs(spells) do
  print(spell.action_id)
end
```
### Misc
```lua
-- Returns a boolean whether an entity is a wand or not
EZWand.IsWand(entity_id)
local wand = EZWand.GetHeldWand() -- either nil if not holding a wand or an EZWand object
local cloned_wand = wand:Clone()
-- Applies an appropriate Sprite using the games own algorithm
-- based on capacity etc, use this after changing properties,
-- if you want the sprite to match the stats
wand:UpdateSprite()
-- Sets the name and whether it will actually use it for displaying it in the UI
-- show_name_in_ui will default to true
wand:SetName("name", show_name_in_ui)
local name, show_name_in_ui = wand:GetName()
-- Places the wand in the world in an unpicked state,
-- re-enables ray particles etc
wand:PlaceAt(x, y)
wand:PutInPlayersInventory()
wand:SetSprite(image_file, offset_x, offset_y, tip_x, tip_y)
local image_file, offset_x, offset_y, tip_x, tip_y = wand:GetSprite()
-- Make it impossible to edit the wand
-- freeze_wand {boolean} prevents spells from being added to the wand or moved
-- freeze_spells {boolean} prevents the spells from being removed
wand:SetFrozen(freeze_wand, freeze_spells)
```
***
Naming convention for the functions is Add/Remove for regular spells and Attach/Detach for always cast spells.
The names for the properties resemble the one found ingame, not the ones on the components.
### Here are all available properties:
```lua
  wand.shuffle -- true or false
  wand.spellsPerCast
  -- In frames, ingame values are based on 60 FPS, so 60 would be 1.0s
  wand.castDelay
   -- Returns the current cast delay in frames, can also be set to change the current cast delay
  wand.currentCastDelay
  -- Same as castDelay
  wand.rechargeTime
  wand.currentRechargeTime
  wand.manaMax
  wand.mana
  wand.manaChargeSpeed
  wand.capacity
  -- Number like -13.2 without "DEG"
  wand.spread
  wand.speedMultiplier
  -- Properties to access underlying entity/component ids:
  wand.entity_id
  wand.ability_component
```
You can always use your regular functions like EntityGetComponent etc using
```lua
EntityHasTag(wand.entity_id, "wand")
```
## Rendering a wand tooltip
To render a wand tooltip you can use EZWand.RenderTooltip() to render a tooltip based on some predefined properties (no need for the wand to exist), or you can use
wand:RenderTooltip() to render the tooltip of an existing wand.
It creates its own gui object, so no need to provide one. Just call it every frame.
Spell tooltips don't work because they're hardcoded and we can't access info about them.
If you're rendering your own GUI alongside this, it's recommended to pass in your gui to prevent mouse events from not working correctly.
```lua
EZWand.RenderTooltip(x, y, props[, gui])
wand:RenderTooltip(x, y[, gui])
```
Where props is a table just like the one you get when using EZWand.Deserialize(), so to create that table you could do this (and better cache the result):
```lua
local props = EZWand.Deserialize(EZWand(wand):Serialize())
EZWand.RenderTooltip(x, y, props, gui)
```
or you can also fill in the props manually:
```lua
EZWand.RenderTooltip(x, y, {
  props = {
    shuffle = true,
    spellsPerCast = 1,
    castDelay = 30,
    rechargeTime = 30,
    manaMax = 200,
    manaChargeSpeed = 20,
    capacity = 10,
    spread = 0,
  },
  spells = { "BOMB", "BOMB" },
  always_cast_spells = { "BOMB", "BOMB" },
  sprite_image_file = "data/items_gfx/handgun.png",
}, gui)
```