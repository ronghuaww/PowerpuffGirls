--!Type(ScriptableObject)

--!SerializeField
local name: string = ""
--!SerializeField
local outfit: CharacterOutfit = nil

--!SerializeField
local rarity: string = ""

function GetName(): string
    return name
end

function GetOutfit(): CharacterOutfit
    return outfit
end

function GetRarity(): string
    return rarity
end