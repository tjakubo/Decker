# Decker for Tabletop Simulator
Tool for defining and spawning custom cards and decks purely from scripting.
Create decks or single cards for your mod from code, maintain or update them by simply changing a few lines instead of manually creating/moving/splitting decks.
Change any card/deck images in the script instead of re-importing all of it again.

### Features:
* Easy organizing of card images/sheets (called "assets" here), just replace image links to update your cards/decks
* Define single images or image sheets of any supported size (1x1 to 10x7)
* Easy spawning of single cards (asset for face/back, row/column if asset is a sheet)
* Easy spawning of decks - just provide a list of cards defined as above
* Deck management - rearrange, insert or remove cards from decks defined through Decker (before spawning)

### Example code
```lua
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
```

### Full reference

Note: if an arg name has (something) next to it, it is the default value if not provided.
Decker does not do extensive assertions on passed arguments and will probably cause weird runtime errors when misused.

#### Library functions

* ``Decker.Asset(string faceLink, string backLink, table params)``
  * Creates a new asset to be used with other Decker functions
  * Args ``faceLink``, ``backLink``: strings with links to images like you would use for a custom deck
  * Arg ``param`` (optional) table of:
    * ``width (1)``: integer, how many columns of cards on image(s)
    * ``height (1)``: integer, how many rows of cards on image(s)
    * ``uniqueBack (false)``: bool, if ``backLink`` is also a sheet and not a single image
    * ``hiddenBack (false)``: bool, should backs be hidden in hands
  * Returns created ``asset``

* ``Decker.Card(asset cardAsset, int rowNum, int colNum, table commonParams)``
  * Creates (but not spawns yet!) a new ``DeckerCard`` object that defines a single card
  * Arg ``cardAsset``: asset created using ``Decker.Asset`` to be used fo this card
  * Args ``rowNum (1)``, ``colNum (1)``: integers which row/column from the asset this card is
  * Arg ``commonParams`` (optional) table of object properties, see [Common Params Table](#common-params-table)
    * Method-specific field ``sideways (false)``: bool, if the card be oriented sideways
  * Returns created ``DeckerCard`` object

* ``Decker.Deck(table cards, table commonParams)``
  * Creates (but not spawns yet!) a new ``DeckerDeck`` object that defines a deck
  * Arg ``cards``: table of ``DeckerCard`` this deck consists, also see [Indexing and order](#indexing-and-order)
  * Arg ``commonParams`` (optional) table of object properties, see [Common Params Table](#common-params-table)
  * Returns created ``DeckerDeck`` object

* ``Decker.AssetDeck(asset deckAsset, int cardsNum, table commonParams)``
  * Creates (but not spawns yet!) a new ``DeckerDeck`` object that defines a deck from single asset (skipping Decker.Card)
  * Arg ``deckAsset``: an asset used for cards in this deck
  * Arg ``cardsNum (assetSize)``: number of cards in this deck (goes sequentially over cards in asset, row by row)
  * Arg ``commonParams`` (optional) table of object properties, see [Common Params Table](#common-params-table) section
  * Returns created ``DeckerDeck`` object
  
* ``Decker.RescanExistingDeckIDs()``
  * Looks through existing objects on a table, adjusting internals to avoid clashing "DeckIDs" when creating assets
  * Sometimes might need to be called (once), after non-Decker decks are already spawned but before Decker.Asset-s are created
  * Returns ``true`` if a potentially clashing deck was found, ``false`` otherwise

#### Object methods

* ``DeckerCard:spawn(table spawnParams) and DeckerDeck:spawn(table spawnParams)``
  * Spawns the object on the table, you can still modify/spawn it more afterwards
  * Arg ``spawnParams``: table of ``parameters`` for [spawnObjectJSON](https://api.tabletopsimulator.com/base/#spawnobjectjson) or [spawnObjectData](https://api.tabletopsimulator.com/base/#spawnobjectdata)
  * Returns a TTS [object](https://api.tabletopsimulator.com/object/) of the spawned card
  * Keep in mind objects may not be immediately ready, see [object.spawning](https://api.tabletopsimulator.com/object/#member-variables)

* ``DeckerCard:setCommon(table commonParams) and DeckerDeck:setCommon(table commonParams)``
  * Sets common params for a deck/card (like name, description, script, etc) to be set upon spawning
  * Arg ``commonParams``: table of object properties, see [Common Params Table](#common-params-table) section
  * Returns ``self`` for chaining methods

* ``DeckerCard:setAsset(asset newAsset)``
  * Sets a new asset for a single card
  * Arg ``newAsset``: new asset to be set on the card
  * While the new asset doesn't have to be of same dimensions, setting so can move the card in terms of row/column!
  * (this is built in TTS behavior, internally a continuous index is kept, not row/column number)
  * Returns ``self`` for chaining methods

* ``DeckerCard:getAsset()``
  * Returns an ``asset`` associated with this card

* ``DeckerDeck:insert(DeckerCard card, int index)``
  * Inserts a ``DeckerCard`` into a ``DeckerDeck``
  * Arg ``card``: DeckerCard to be inserted in the deck
  * Arg ``index (lastInDeck)``: index at which the card is inserted (shifting others up), also see [Indexing and order](#indexing-and-order)
  * Returns ``self`` for chaining methods

* ``DeckerDeck:remove(int index)``
  * Removes a card from ``DeckerDeck``
  * Arg ``index (lastInDeck)``: index at which a card is removed (shifting others down), also see [Indexing and order](#indexing-and-order)
    * Negative index means couning from last down
  * Returns ``self`` for chaining methods

* ``DeckerDeck:removeMany(int index1, int index2, ...)``
  * Removes many cards from ``DeckerDeck`` so you don't have to keep shifting down indices in mind
  * Args ``indexN``: indices at which cards are removed (shifting others down), also see [Indexing and order](#indexing-and-order)
    * No shifting between indices in the call (use deck:removeMany(1, 2, 3) to remove first 3 cards)
  * Returns ``self`` for chaining methods

* ``DeckerDeck:swap(int indexOne, int indexTwo)``
  * Swaps card positions in ``DeckerDeck``
  * Arg ``indexOne``, ``indexTwo``: indices at which cards positions are swapped with each other, [Indexing and order](#indexing-and-order)
  * Returns ``self`` for chaining methods

* ``DeckerDeck:reverse()``
  * Reverses a ``DeckerDeck`` card order (basically swapping cards end-to-end)
  * Returns ``self`` for chaining methods
  
* ``DeckerDeck:sort(sortFunction)``
  * Sorts cards in a ``DeckerDeck`` based on a provided comparison function
  * Sort function receives raw data table of each compared card, see e.g. `log(soemCard.getData())`
  * Returns ``self`` for chaining methods 

* ``DeckerDeck:getAssets()``
  * Returns a table of all ``asset``s on cards in this deck

* ``DeckerDeck:switchAssets(table assetMap)``
  * Replaces each asset provided as a key with asset provided as value under this key
  * Arg ``assetMap``: table keyed with assets-to-be-replaced with values being assets-to-replace
  * Returns ``self`` for chaining methods

* ``DeckerDeck:copy()``
  * Copies a deck object (e.g. to modify it and keep original one too)
  * Returns a copy of ``self`` (same contents but can be modified separately)

* ``DeckerDeck:cardAt(int index)``
  * Gets a ``DeckerCard`` from a ``DeckerDeck`` at particular position
  * Arg ``index``: index of the card to get
  * Returns a ``DeckerCard`` object

### Indexing and order
When creating decks using ``Decker.Deck``, cards go in order of
**top-to-bottom when looking on a face-down deck (placed so a card back is visible on top of it)**.
In ``Decker.Deck({card1, card2, card3})``, ``card1`` will be one with exposed back and ``card3`` will be one with exposed face.


Stuff called "index" in Decker functions means a positive number counting from top of the deck (back-visible card is index 1), negative numbers means counting from the other end (front-visible card is index -1).

### Common Params Table

Both ``Decker.Deck`` and ``Decker.Card`` take a ``commonParams`` table as last parameter. It can be used to set some
common object properties like name, description, lock status etc so you don't have to do it every time you spawn the thing.

Setting any key outside of the range listed below (plus ``sideways`` for ``Decker.Card``) will set key/value directly on the resulting object JSON. You can use this to set JSON fields not handled by Decker directly per table below.

``commonParams`` table can consists of keys:
* ``name``: string, name of the object, default empty
* ``desc``: string, description of the object, default empty
* ``value``: string, value of the object, default 0
* ``tags``: table of strings, tags of the object, default empty table
* ``locked``: bool, if the object is locked when spawned, default false
* ``script``: string, lua script on the object, default empty
* ``xmlui``: string, XML UI code of the object, default empty
* ``tooltip``: bool, if the tooltip on object is shown, default true
* ``scriptState``: string, saved state of the script, default empty
* ``guid``: string, GUID this object will *try* to have, default 'deadbf'
* ``hands``: bool, if the object should go into player hands, default true for cards, default false for decks
Keep in mind ``guid`` field will be ignored (TTS does this, not me) if it's invalid or if an object of this GUID already exists.
