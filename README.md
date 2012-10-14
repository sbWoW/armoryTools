sample rep query (diff today <> yesterday)

select character.name,faction.name,a.value,b.value,a.standing,b.standing from reputation a, reputation b, character, faction where a.factionid = b.factionid and a.characterid = b.characterid and (a.value < b.value) and date(a.date) != date(b.date) and date(a.date) = date('now') and a.factionid=faction.id and a.characterid=character.id order by character.name, faction.name


