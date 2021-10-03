-- Use and IDE plugin supporting require or paste decker.ttslua code there
local Decker = require('Decker.Decker')

-- open in browser to see what these links depict
local cardFaces = 'https://i.imgur.com/wiyVst7.png'
local cardBack = 'https://i.imgur.com/KQtQGE7.png'

-- define a new asset from face/back links, add width/height (since these default to 1x1)
local cardAsset = Decker.Asset(cardFaces, cardBack, {width = 2, height = 2})

-- define cards on the asset, skipping three because we can (would be row 2, column 1)
local cardOne = Decker.Card(cardAsset, 1, 1) -- (asset, row, column)
local cardTwo = Decker.Card(cardAsset, 1, 2)
local cardFour = Decker.Card(cardAsset, 2, 2)

-- define a deck of cardFour, two cardOne's and two cardTwo's
local myDeck = Decker.Deck({cardFour, cardOne, cardOne, cardTwo, cardTwo})

-- so far, all of the above are just scripting definitions, nothing is spawned
-- e.g. if I decided game is balanced better with just one cardTwo in the deck, I can just remove it
--  from above code and leave rest of the code unchanged (still using myDeck below)
-- same goes for changing art on cards (just replace links from Decker.Asset definitions)

-- let's do some testing when any chat message is sent
function onChat()
    -- spawn two of our decks (e.g. for each player), one flipped
    myDeck:spawn({position = {-4, 3, 0}})
    myDeck:spawn({position = {4, 3, 0}, rotation = {0, 0, 180}})

    -- spawn a single card
    cardFour:spawn({position = {0, 3, 6}})

    -- see below for a bit more functionality Decker offers
    advancedExample()
end

function advancedExample()
    -- all :spawn methods return a regular object - proceed like with anything
    local someDeck = myDeck:spawn({position = {0, 3, -6}})
    someDeck.highlightOn({0, 0, 1}, 10)
    someDeck.setName('this is some deck')
    -- for convenience, stuff like name/description/xmlui can be assigned to stuff before spawning
    --  to avoid calls like setName above - see spawnParams in full reference section of docs

    -- we can use DeckerDeck methods to modify it
    -- let's remove both cardOne's from it (index 2 and 3)
    myDeck:removeMany(2, 3)
    -- now let's swap first and last card so it's {cardTwo, cardTwo, cardFour} and spawn it
    -- negative index (anywhere in methods) means counting from the end down
    myDeck:swap(1, -1):spawn({position = {0, 3, 0}})

    -- we can swap assets on decks after creation
    -- this new asset switches card fromnts and backs
    local weirdAsset = Decker.Asset(cardBack, cardFaces, {width = 2, height = 2})
    -- to leave myDeck as-is, we'll be working on a copy
    -- you can have many replacements at once, [oldAsset] = newAsset
    myDeck:copy():switchAssets({ [cardAsset] = weirdAsset }):spawn({position = {12, 3, 0}})
end

function onLoad()
    broadcastToAll('Post any chat message to execute example code', {1, 1, 1})
end
