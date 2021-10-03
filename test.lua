-- Decker test scenario

local Decker = require('Decker')

local function dummy(...) return ... end
if not spawnObjectJSON then
    spawnObjectJSON = function() return {highlightOn = dummy} end
end
if not JSON then
    JSON = {encode_pretty = dummy, decode = dummy}
end
local _JSON = JSON
JSON = {encode = _JSON.encode_pretty, encode_pretty = _JSON.encode_pretty, decode = _JSON.decode}

local cardFaces = 'https://i.imgur.com/wiyVst7.png'
local cardBack = 'https://i.imgur.com/KQtQGE7.png'

local cardAsset1 = Decker.Asset(cardFaces, cardBack, {width = 2, height = 2})
local cardAsset2 = Decker.Asset(cardBack, cardFaces, {width = 1, height = 2})

local duplicateAsset = Decker.Asset(cardFaces, cardBack, {width = 2, height = 2})
local anotherDuplicate = Decker.Card(duplicateAsset):getAsset()
assert(cardAsset1.id == duplicateAsset.id and duplicateAsset.id == anotherDuplicate.id,
       'identical assets with different IDs')

local cards1 = {
    Decker.Card(cardAsset1, 1, 1),
    Decker.Card(cardAsset1, 1, 2),
    Decker.Card(cardAsset1, 2, 1, {name = 'card three', Autoraise = false}),
    Decker.Card(cardAsset1, 2, 2),
}
assert(cards1[3]:getAsset().id == cardAsset1.id, 'card:getAsset returns a new ID')
local cards2 = {
    Decker.Card(cardAsset2, 1, 1),
    Decker.Card(cardAsset2, 2, 1),
}
local deck1 = Decker.Deck(cards1):reverse()
local deck2 = cardAsset1:deck(3)
local deck4 = Decker.Deck({cards1[1], cards2[1], cards2[2]})
assert(deck1:getAssets()[1].id == cardAsset1.id, 'deck:getAssets generated a new ID')
assert(#deck4:getAssets() == 2, 'deck:getAssets returned wrong number of assets')

local _x = -15
local function nextPos()
    local next = {_x, 3, 0}
    _x = _x + 5
    return {position = next}
end

local function expectOrder(order, obj)
    local desc = table.concat(order, '\n')
    local tPos = obj.getPosition()
    tPos.z = tPos.z + 3 + #order*0.75
    tPos.y = 1
    local text = spawnObject({
        type = '3DText',
        position = tPos,
        rotation = {90, 0, 0},
    })
    text.setValue(desc)
    text.TextTool.setFontSize(50)
    return obj
end

function onLoad()
    expectOrder( {'HIGHLIGHTED', 1, 2, 3, 4},
    deck2:copy():insert(deck1:cardAt(1), deck2:count()+1):spawn(nextPos()) ).highlightOn({0, 1, 0}, 10)

    expectOrder( {3, 2, 1},
    deck2:swap(1, 3):spawn(nextPos()) )

    expectOrder( {2, 1, 2},
    deck1:removeMany(1, -3):remove(2):insert(deck1:cardAt(1), 2):insert(cards1[1], 2):spawn(nextPos()) )

    expectOrder( {1, 'card', 'back'},
    deck4:spawn(nextPos()) )

    expectOrder( {'back'},
    cards1[3]:copy():setAsset(cardAsset2):setCommon({ name = 'back', desc = 'back desc' }):spawn(nextPos()) )

    expectOrder( {3},
    cards1[3]:spawn(nextPos()) )

    expectOrder( {'card', 1, 2},
    deck4:copy():switchAssets({[cardAsset1] = cardAsset2, [cardAsset2] = cardAsset1}):spawn(nextPos()) )

    expectOrder( {'sideways\nthree' },
    Decker.Card(cardAsset1, 2, 1, {name = 'card three', sideways = true}):spawn(nextPos()) )

    Wait.time(rotateAll, 1)
end
function rotateAll()
    for _,obj in ipairs(getAllObjects()) do
        if obj.tag == 'Deck' or obj.tag == 'Card' then
            local rot = obj.getRotation()
            obj.setRotation({rot[1], rot[2]+180, rot[3]})
        end
    end
end
if spawnObjectJSON == dummy then
    onLoad()
end
