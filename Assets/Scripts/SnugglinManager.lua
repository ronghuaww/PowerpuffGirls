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

--------------------------------
------  PUBLIC FUNCTIONS  ------
--------------------------------


-- Spawns a Snugglin NPC at the specified position
-- Returns the spawned GameObject
function SpawnAtPosition(position: Vector3): GameObject
    if not position then
        print("ERROR: No position provided to SpawnAtPosition")
        return nil
    end
    if not snugglinPrefab then
        print("ERROR: No snugglinPrefab assigned in SnugglinManager")
        return nil
    end

    local _spawnedNpc = Object.Instantiate(snugglinPrefab, position, Quaternion.identity)

    if _spawnedNpc then
        table.insert(_spawnedSnugglins, _spawnedNpc)
    end

    return _spawnedNpc
end

-- Makes the Snugglin NPC walk to the specified position
-- Returns true if movement was initiated successfully
function WalkToPosition(snugglinObject: GameObject, position: Vector3, callback: ((...any) -> (...any))?): boolean
    if not snugglinObject then
        print("ERROR: No snugglinObject provided to WalkToPosition")
        return false
    end
    if not position then
        print("ERROR: No position provided to WalkToPosition")
        return false
    end

    local _character = getCharacterFromGameObject(snugglinObject)
    if not _character then
        print("ERROR: Snugglin does not have a Character component")
        return false
    end

    return _character:MoveTo(position, -1, callback)
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
