local Decker = {}

-- provide unique ID starting from 20 for present decks
local nextID
do
    local _nextID = 20
    nextID = function()
        _nextID = _nextID + 1
        return tostring(_nextID)
    end
end

-- Asset signature (equality comparison)
local function assetSignature(assetData)
    return table.concat({
        assetData.FaceURL,
        assetData.BackURL,
        assetData.NumWidth,
        assetData.NumHeight,
        assetData.BackIsHidden and 'hb' or '',
        assetData.UniqueBack and 'ub' or ''
    })
end
-- Asset ID storage to avoid new ones for identical assets
local idLookup = {}
local function assetID(assetData)
    local sig = assetSignature(assetData)
    local key = idLookup[sig]
    if not key then
        key = nextID()
        idLookup[sig] = key
    end
    return key
end

local assetMeta = {
    deck = function(self, cardNum, options)
        return Decker.AssetDeck(self, cardNum, options)
    end
}
assetMeta = {__index = assetMeta}

-- Create a new CustomDeck asset
function Decker.Asset(face, back, options)
    local asset = {}
    options = options or {}
    asset.data = {
        FaceURL = face or error('Decker.Asset: faceImg link required'),
        BackURL = back or error('Decker.Asset: backImg link required'),
        NumWidth = options.width or 1,
        NumHeight = options.height or 1,
        BackIsHidden = options.hiddenBack or false,
        UniqueBack = options.uniqueBack or false
    }
    -- Reuse ID if asset existing
    asset.id = assetID(asset.data)
    return setmetatable(asset, assetMeta)
end
-- Pull a Decker.Asset from card JSONs CustomDeck entry
local function assetFromData(assetData)
    return setmetatable({data = assetData, id = assetID(assetData)}, assetMeta)
end

-- Create a base for JSON objects
function Decker.BaseObject()
    return {
        Name = 'Base',
        Transform = {
            posX = 0, posY = 5, posZ = 0,
            rotX = 0, rotY = 0, rotZ = 0,
            scaleX = 1, scaleY = 1, scaleZ = 1
        },
        Nickname = '',
        Description = '',
        ColorDiffuse = { r = 1, g = 1, b = 1 },
        Locked = false,
        Grid = true,
        Snap = true,
        Autoraise = true,
        Sticky = true,
        Tooltip = true,
        GridProjection = false,
        Hands = true,
        XmlUI = '',
        LuaScript = '',
        LuaScriptState = '',
        GUID = 'deadbf'
    }
end
-- Typical paramters map with defaults
local commonMap = {
    name   = {field = 'Nickname',    default = ''},
    desc   = {field = 'Description', default = ''},
    script = {field = 'LuaScript',   default = ''},
    xmlui  = {field = 'XmlUI',       default = ''},
    scriptState = {field = 'LuaScriptState', default = ''},
    locked  = {field = 'Locked',  default = false},
    tooltip = {field = 'Tooltip', default = true},
    guid    = {field = 'GUID',    default = 'deadbf'},
    hands   = {field = 'Hands',   default = true},
}
-- Apply some basic parameters on base JSON object
function Decker.SetCommonOptions(obj, options)
    options = options or {}
    for k,v in pairs(commonMap) do
        -- can't use and/or logic cause of boolean fields
        if options[k] ~= nil then
            obj[v.field] = options[k]
        else
            obj[v.field] = v.default
        end
    end
    -- passthrough unrecognized keys
    for k,v in pairs(options) do
        if not commonMap[k] then
            obj[k] = v
        end
    end
end
-- default spawnObjectJSON/spawnObjectData params since it doesn't like blank fields
local function defaultParams(params)
    params = params or {}
    params.position = params.position or {0, 5, 0}
    params.rotation = params.rotation or {0, 0, 0}
    params.scale = params.scale or {1, 1, 1}
    if params.sound == nil then
        params.sound = true
    end
    return params
end

-- For copy method
local deepcopy
deepcopy = function(t)
    local copy = {}
    for k,v in pairs(t) do
       if type(v) == 'table' then
           copy[k] = deepcopy(v)
       else
           copy[k] = v
       end
    end
    return copy
end
-- meta for all Decker derived objects
local commonMeta = {
    -- return object JSON string, used cached if present
    _cache = function(self)
        if not self.json then
            self.json = JSON.encode(self.data)
        end
        return self.json
    end,
    -- invalidate JSON string cache
    _recache = function(self)
        self.json = nil
        return self
    end,
    spawn = function(self, params)
        params = defaultParams(params)
        params.data = self.data
        return spawnObjectData(params)
    end,
    spawnJSON = function(self, params)
        params = defaultParams(params)
        params.json = self:_cache()
        return spawnObjectJSON(params)
    end,
    copy = function(self)
        return setmetatable(deepcopy(self), getmetatable(self))
    end,
    setCommon = function(self, options)
        Decker.SetCommonOptions(self.data, options)
        return self
    end,
}
-- apply common part on a specific metatable
local function customMeta(mt)
    for k,v in pairs(commonMeta) do
        mt[k] = v
    end
    mt.__index = mt
    return mt
end

-- DeckerCard metatable
local cardMeta = {
    setAsset = function(self, asset)
        local cardIndex = self.data.CardID:sub(-2, -1)
        self.data.CardID = asset.id .. cardIndex
        self.data.CustomDeck = {[asset.id] = asset.data}
        return self:_recache()
    end,
    getAsset = function(self)
        local deckID = next(self.data.CustomDeck)
        return assetFromData(self.data.CustomDeck[deckID])
    end,
    -- reset deck ID to a consistent value script-wise
    _recheckDeckID = function(self)
        local oldID = next(self.data.CustomDeck)
        local correctID = assetID(self.data.CustomDeck[oldID])
        if oldID ~= correctID then
            local cardIndex = self.data.CardID:sub(-2, -1)
            self.data.CardID = correctID .. cardIndex
            self.data.CustomDeck[correctID] = self.data.CustomDeck[oldID]
            self.data.CustomDeck[oldID] = nil
        end
        return self
    end
}
cardMeta = customMeta(cardMeta)
-- Create a DeckerCard from an asset
function Decker.Card(asset, row, col, options)
    row, col = row or 1, col or 1
    options = options or {}
    local card = Decker.BaseObject()
    card.Name = 'Card'
    -- optional custom fields
    Decker.SetCommonOptions(card, options)
    if options.sideways ~= nil then
        card.SidewaysCard = options.sideways
        -- FIXME passthrough set that field, find some more elegant solution
        card.sideways = nil
    end
    -- CardID string is parent deck ID concat with its 0-based index (always two digits)
    local num = (row-1)*asset.data.NumWidth + col - 1
    num = string.format('%02d', num)
    card.CardID = asset.id .. num
    -- just the parent asset reference needed
    card.CustomDeck = {[asset.id] = asset.data}

    local obj = setmetatable({data = card}, cardMeta)
    obj:_recache()
    return obj
end


-- DeckerDeck meta
local deckMeta = {
    count = function(self)
        return #self.data.DeckIDs
    end,
    -- Transform index into positive
    index = function(self, ind)
        if ind < 0 then
            return self:count() + ind + 1
        else
            return ind
        end
    end,
    swap = function(self, i1, i2)
        local ri1, ri2 = self:index(i1), self:index(i2)
        assert(ri1 > 0 and ri1 <= self:count(), 'DeckObj.rearrange: index ' .. i1 .. ' out of bounds')
        assert(ri2 > 0 and ri2 <= self:count(), 'DeckObj.rearrange: index ' .. i2 .. ' out of bounds')
        self.data.DeckIDs[ri1], self.data.DeckIDs[ri2] = self.data.DeckIDs[ri2], self.data.DeckIDs[ri1]
        local co = self.data.ContainedObjects
        co[ri1], co[ri2] = co[ri2], co[ri1]
        return self:_recache()
    end,
    -- rebuild self.data.CustomDeck based on contained cards
    _rescanDeckIDs = function(self, id)
        local cardIDs = {}
        for k,card in ipairs(self.data.ContainedObjects) do
            local cardID = next(card.CustomDeck)
            if not cardIDs[cardID] then
                cardIDs[cardID] = card.CustomDeck[cardID]
            end
        end
        -- eeh, GC gotta earn its keep as well
        -- FIXME if someone does shitton of removals, may cause performance issues?
        self.data.CustomDeck = cardIDs
    end,
    remove = function(self, ind, skipRescan)
        local rind = self:index(ind)
        assert(rind > 0 and rind <= self:count(), 'DeckObj.remove: index ' .. ind .. ' out of bounds')
        local card = self.data.ContainedObjects[rind]
        table.remove(self.data.DeckIDs, rind)
        table.remove(self.data.ContainedObjects, rind)
        if not skipRescan then
            self:_rescanDeckIDs(next(card.CustomDeck))
        end
        return self:_recache()
    end,
    removeMany = function(self, ...)
        local indices = {...}
        table.sort(indices, function(e1,e2) return self:index(e1) > self:index(e2) end)
        for _,ind in ipairs(indices) do
            self:remove(ind, true)
        end
        self:_rescanDeckIDs()
        return self:_recache()
    end,
    insert = function(self, card, ind)
        ind = ind or (self:count() + 1)
        local rind = self:index(ind)
        assert(rind > 0 and rind <= (self:count()+1), 'DeckObj.insert: index ' .. ind .. ' out of bounds')
        table.insert(self.data.DeckIDs, rind, card.data.CardID)
        table.insert(self.data.ContainedObjects, rind, card.data)
        local id = next(card.data.CustomDeck)
        if not self.data.CustomDeck[id] then
            self.data.CustomDeck[id] = card.data.CustomDeck[id]
        end
        return self:_recache()
    end,
    reverse = function(self)
        local s,e = 1, self:count()
        while s < e do
            self:swap(s, e)
            s = s+1
            e = e-1
        end
        return self:_recache()
    end,
    cardAt = function(self, ind)
        local rind = self:index(ind)
        assert(rind > 0 and rind <= (self:count()+1), 'DeckObj.insert: index ' .. ind .. ' out of bounds')
        local card = setmetatable({data = deepcopy(self.data.ContainedObjects[rind])}, cardMeta)
        card:_recache()
        return card
    end,
    switchAssets = function(self, replaceTable)
        -- destructure replace table into
        -- [ID_to_replace] -> [ID_to_replace_with]
        -- [new_asset_ID] -> [new_asset_data]
        local idReplace = {}
        local assets = {}
        for oldAsset, newAsset in pairs(replaceTable) do
            assets[newAsset.id] = newAsset.data
            idReplace[oldAsset.id] = newAsset.id
        end
        -- update deckIDs
        for k,cardID in ipairs(self.data.DeckIDs) do
            local deckID, cardInd = cardID:sub(1, -3), cardID:sub(-2, -1)
            if idReplace[deckID] then
                self.data.DeckIDs[k] = idReplace[deckID] .. cardInd
            end
        end
        -- update CustomDeck data - nil replaced
        for replacedID in pairs(idReplace) do
            if self.data.CustomDeck[replacedID] then
                self.data.CustomDeck[replacedID] = nil
            end
        end
        -- update CustomDeck data - add replacing
        for _,replacingID in pairs(idReplace) do
            self.data.CustomDeck[replacingID] = assets[replacingID]
        end
        -- update card data
        for k,cardData in ipairs(self.data.ContainedObjects) do
            local deckID = next(cardData.CustomDeck)
            if idReplace[deckID] then
                cardData.CustomDeck[deckID] = nil
                cardData.CustomDeck[idReplace[deckID]] = assets[idReplace[deckID]]
            end
        end
        return self:_recache()
    end,
    getAssets = function(self)
        local assets = {}
        for id,assetData in pairs(self.data.CustomDeck) do
            assets[#assets+1] = assetFromData(assetData)
        end
        return assets
    end
}
deckMeta = customMeta(deckMeta)
-- Create DeckerDeck object from DeckerCards
function Decker.Deck(cards, options)
    assert(#cards > 1, 'Trying to create a Decker.deck with less than 2 cards')
    local deck = Decker.BaseObject()
    deck.Hands = false
    deck.Name = 'Deck'
    Decker.SetCommonOptions(deck, options)
    deck.DeckIDs = {}
    deck.CustomDeck = {}
    deck.ContainedObjects = {}
    for _,card in ipairs(cards) do
        deck.DeckIDs[#deck.DeckIDs+1] = card.data.CardID
        local id = next(card.data.CustomDeck)
        if not deck.CustomDeck[id] then
            deck.CustomDeck[id] = card.data.CustomDeck[id]
        end
        deck.ContainedObjects[#deck.ContainedObjects+1] = card.data
    end

    local obj = setmetatable({data = deck}, deckMeta)
    obj:_recache()
    return obj
end
-- Create DeckerDeck from an asset using X cards on its sheet
function Decker.AssetDeck(asset, cardNum, options)
    cardNum = cardNum or asset.data.NumWidth * asset.data.NumHeight
    local row, col, width = 1, 1, asset.data.NumWidth
    local cards = {}
    for k=1,cardNum do
        cards[#cards+1] = Decker.Card(asset, row, col)
        col = col+1
        if col > width then
            row, col = row+1, 1
        end
    end
    return Decker.Deck(cards, options)
end

return Decker