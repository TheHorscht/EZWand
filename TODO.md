- FIX: Detach spells adds a slot?
- Update functions for 1.0
- Add function to freeze wand and spells on it
- In the constructor, check if the entity id was passed in as a string
- Add property to change whether wand recharges (mana recharge and cast recharge) only in hand
- Add function to serialize and deserialize wand to string
- When reducing capacity, remove spells that don't fit onto it anymore
- Add functio/overload to remove spells at certain positions
- Add overload to AddSpells function to allow adding multiple spells in one go like:
  AddSpells({ "BLACK_HOLE", 10 }, { "LIGHT_BULLET", 10 })
  or AddSpells{{"BLACK_HOLE", 10 }, { "LIGHT_BULLET", 10 }}