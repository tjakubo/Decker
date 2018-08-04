# Decker for Tabletop Simulator
Tool for defining and spawning custom cards and decks purely from scripting. 
Create decks or single cards for your mod from code, maintain or update them by simply changing a few lines instead of manually creating/moving/splitting decks.
Change any card/deck images in the script instead of re-importing all of it again.

### Features:
* Easy organizing of card images/sheets (called "assets" here), just replace one link to update your cards/decks
* Assets can hold single images or image sheets of any supported size (up to 10x7)
* Easy spawning of single cards (asset for face/back, row/column if asset is a sheet)
* Easy spawning of decks - just provide a list of cards defines as above
* Deck management - rearrange, insert or remove cards from decks defined through Decker (before spawning)

### Example code
```lua
-- Use Atom plugin command below or paste decker.ttslua code there
#include Decker

-- open links in browser to see what these links depict
local cardFaces = 'https://i.imgur.com/wiyVst7.png'
local cardBack = 'https://i.imgur.com/KQtQGE7.png'

-- define a new asset from face/back links, add width/height (since these default to 1)
local cardAsset = Decker.Asset(cardFaces, cardBack, {width = 2, height = 2})

-- define cards on the asset, skipping three because we can
local cardOne = Decker.Card(cardAsset, 1, 1) -- (asset, row, column)
local cardTwo = Decker.Card(cardAsset, 1, 2) 
local cardFour = Decker.Card(cardAsset, 2, 2) 

-- define a deck of cardFour, two cardOne's and two cardTwo's
local myDeck = Decker.Deck({cardFour, cardOne, cardOne, cardTwo, cardTwo})

-- so far, all of the above are just scripting definitions, nothing is spawned
-- e.g. if I decided game is balanced better with just one cardTwo in the deck, I can just remove it
--  from above code and leave rest of the code unchanged (still using myDeck below)
-- same goes for changing art on cards (just replace link in Decker.Asset definitions)

-- let's do some testing when any chat message is sent
function onChat()
    -- spawn two of our decks (e.g. for each player)
    myDeck:spawn({position = {-4, 3, 0}})
    myDeck:spawn({position = {4, 3, 0}})
    
    -- spawn a single card
    cardFour:spawn({positions = {0, 3, 6}})
    
    -- -- -- --
    -- ADVANCED SECTION (for those comfortable wih Lua)

    -- we can use DeckerDeck methods to modify it
    -- let's remove cardOne's from it (index 2 and 3)
    myDeck:remove(2, 3)
    -- now let's swap first and last card so it's {cardTwo, cardTwo, cardFour} and spawn it
    -- negative index (anywhere in methods) means counting from the end down
    myDeck:swap(1, -1):spawn({0, 3, 0})
    
    -- all :spawn methods return a regular object - proceed like with anything
    local someDeck = myDeck:spawn({position = {0, 3, -6}})
    someDeck.highlightOn({0, 0, 1}, 10)
    someDeck.setName('this is some deck')
    -- for convenience, stuff like name/description/xmlui can be assigned to stuff before spawning
    --  to avoid calls like setName above - see spawnParams in full reference section
end
```

### Full reference

#### Library functions

* ``Decker.Asset(string faceLink, string backLink, table params)``
  * Creates a new asset to be used with other Decker functions
  * Args ``faceLink``, ``backLink``: strings with links to images like you would use for a custom deck
  * Arg ``param`` (optional) table of: 
    * ``width``: integer, how many columns of cards on image(s), default 1
    * ``height``: integer, how many rows of cards on image(s), default 1
    * ``uniqueBack``: bool, if ``backLink`` is also a sheet and not a single image, default false
    * ``hiddenBack``: bool, should backs be hidden in hands, default false
  * Returns created ``asset``
  
* ``Decker.Card(asset cardAsset, int rowNum, int colNum, table commonParams)``
  * Creates (but not spawns yet!) a new ``DeckerCard`` object that defines a single card
  * Arg ``cardAsset``: asset created using ``Decker.Asset`` to be used fo this card
  * Args ``rowNum``, ``colNum``: integers which row/column from the asset this card is
  * Arg ``commonParams`` (optional) table of object properties, see "Common Params Table" section
  * Returns created ``DeckerCard`` object 
  
* ``Decker.Deck(table cards, table commonParams)``
  * Creates (but not spawns yet!) a new ``DeckerDeck`` object that defines a deck
  * Arg ``cards``: table of ``DeckerCard`` this deck consists of (order is preserved)
  * Arg ``commonParams`` (optional) table of object properties, see "Common Params Table" section
  * Returns created ``DeckerDeck`` object
  
#### Object methods

* ``DeckerCard:spawn(table spawnParams) and DeckerDeck:spawn(table spawnParams)``
  * Spawns the object on the table, you can still modify/spawn it more afterwards
  * Arg ``spawnParams``: table of ``parameters`` for [spawnObjectJSON](https://api.tabletopsimulator.com/base/#spawnobjectjson)
  * Returns a TTS [object](https://api.tabletopsimulator.com/object/) of the spawned card
  * Keep in mind objects may not be immediately ready, see [object.spawning](https://api.tabletopsimulator.com/object/#member-variables)
  
* ``DeckerDeck:insert(DeckerCard card, int index)``
  * Inserts a ``DeckerCard`` into a ``DeckerDeck``
  * Arg ``card``: DeckerCard to be inserted in the deck
  * Arg ``index``: index at which the card is inserted (shifting others up)
    * Negative index means couning from last down
  * Returns ``self`` for chaining methods
  
* ``DeckerDeck:remove(int index)``
  * Removes a card from ``DeckerDeck``
  * Arg ``index``: index at which a card is removed (shifting others down)
    * Negative index means couning from last down
  * Returns ``self`` for chaining methods
  
* ``DeckerDeck:removeMany(int index1, int index2, ...)``
  * Removes many cards from ``DeckerDeck`` so you don't have to keep shifting down indices in mind
  * Args ``indexN``: indices at which cards are removed (shifting others down)
    * No shifting between indices in the call (use deck:removeMany(1, 2, 3) to remove first 3 cards)
    * Negative index means couning from last down
  * Returns ``self`` for chaining methods
  
* ``DeckerDeck:swap(int indexOne, int indexTwo)``
  * Swaps card positions in ``DeckerDeck``
  * Arg ``indexOne``, ``indexTwo``: indices at which cards positions are swapped with each other
    * Negative indices means couning from last down
  * Returns ``self`` for chaining methods
  
* ``DeckerDeck:reverse()``
  * Reverses a ``DeckerDeck`` card order (basically swapping cards end-to-end)
  * Returns ``self`` for chaining methods
  
* ``DeckerDeck:copy()``
  * Copies a deck object (e.g. to modify it and keep original one too)
  * Returns a copy of ``safe`` (same contents but can be modified separately)
  
  
### Common Params Table

Both ``Decker.Deck`` and ``Decker.Card`` take a ``commonParams`` table as last parameter. It can be used to set some
common object properties like name, description, lock status etc so you don't have to do it every time you spawn the thing.

``commonParams`` table can consists of keys:
* ``name``: string, name of the object, default empty
* ``desc``: string, description of the object, default empty
* ``locked``: bool, if the object is locked when spawned, default false
* ``script``: string, lua script on the object, default empty
* ``xmlui``: string, XML UI code of the object, default empty
* ``tooltip``: bool, if the tooltip on object is shown, default true
* ``scriptState``: string, saved state of the script, default empty
* ``guid``: string, GUID this object will *try* to have, default 'deadbf'
Keep in ming ``guid`` field will be ignored (TTS does this, not me) if it's invalid or if an object of this GUID already exists.
  
  
  
  
