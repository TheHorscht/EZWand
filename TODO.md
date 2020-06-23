- Add overload to AddSpells function to allow adding multiple spells in one go like:
  AddSpells({ "BLACK_HOLE", 10 }, { "LIGHT_BULLET", 10 })
  or AddSpells{{"BLACK_HOLE", 10 }, { "LIGHT_BULLET", 10 }}