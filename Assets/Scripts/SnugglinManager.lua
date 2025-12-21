--!Type(Module)

--------------------------------
------  SERIALIZED FIELDS ------
--------------------------------

--!SerializeField
local snugglinPrefab: GameObject = nil

--!SerializeField
local spawnPointOBJ: GameObject = nil

--!SerializeField
local sittingPointsOBJ: {GameObject} = nil

--!SerializeField
local snugglinData: {SnugglinBase} = nil


--------------------------------
------     LOCAL STATE    ------
--------------------------------

local _spawnedSnugglins: {GameObject} = {}

--------------------------------
------  LOCAL FUNCTIONS   ------
--------------------------------

local function getCharacterFromGameObject(gameObject: GameObject): Character
    if not gameObject then
        return nil
    end
    return gameObject:GetComponent(Character)
end

local function getRandomSnugglinData(): SnugglinBase
    local _randomIndex = math.random(1, #snugglinData)
    return snugglinData[_randomIndex]
end

local function getRandomSittingPoint(): Vector3 | nil
    if not sittingPointsOBJ or #sittingPointsOBJ == 0 then
        return nil
    end
    local _randomIndex = math.random(1, #sittingPointsOBJ)
    return sittingPointsOBJ[_randomIndex].transform.position
end

local function applyOutfitToCharacter(character: Character, outfit: CharacterOutfit)
    if not character or not outfit then
        return
    end
    character:SetOutfit(outfit)
end

--------------------------------
------  PUBLIC FUNCTIONS  ------
--------------------------------


-- Spawns a Snugglin NPC at the specified position
-- Returns the spawned GameObject
function SpawnAtPosition(): GameObject | nil
    local spawnPos = spawnPointOBJ.transform.position
    if not snugglinPrefab then
        print("ERROR: No snugglinPrefab assigned in SnugglinManager")
        return nil
    end

    local _spawnedNpc = Object.Instantiate(snugglinPrefab, spawnPos, Quaternion.identity)
    local _character = getCharacterFromGameObject(_spawnedNpc)
    if not _character then return nil end
    local _snugglinData = getRandomSnugglinData()
    if _snugglinData then
        applyOutfitToCharacter(_character, _snugglinData.GetOutfit())
    end

    if _spawnedNpc then
        table.insert(_spawnedSnugglins, _spawnedNpc)
    end

    return _spawnedNpc
end

-- Makes the Snugglin NPC walk to the specified position
-- Returns true if movement was initiated successfully
function WalkToPosition(snugglinObject: GameObject, callback: ((...any) -> (...any))?): boolean
    if not snugglinObject then
        print("ERROR: No snugglinObject provided to WalkToPosition")
        return false
    end
    local randomSittingPos = getRandomSittingPoint()

    local _character = getCharacterFromGameObject(snugglinObject)
    if not _character then
        print("ERROR: Snugglin does not have a Character component")
        return false
    end

    return _character:MoveTo(randomSittingPos, -1, callback)
end



-- Destroys a spawned Snugglin NPC
function DespawnSnugglin(snugglinObject: GameObject): boolean
    if not snugglinObject then
        print("ERROR: No snugglinObject provided to DespawnSnugglin")
        return false
    end

    for i, snugglin in ipairs(_spawnedSnugglins) do
        if snugglin == snugglinObject then
            table.remove(_spawnedSnugglins, i)
            break
        end
    end

    Object.Destroy(snugglinObject)
    return true
end

-- Returns all currently spawned Snugglins
function GetAllSpawnedSnugglins(): {GameObject}
    return _spawnedSnugglins
end


function self:ClientStart()
    local snugglinObject = SpawnAtPosition()
    Timer.After(2, function() WalkToPosition(snugglinObject) end)
end