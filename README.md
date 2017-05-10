# aviator

Adds a craftable block to the game.
After placing you will be granted fly priv in an
area of 20 nodes radius from placed block.
fly priv will be taken after 30 minutes.

The block can be digged and remaining time is saved
Also the block will be saved to inventory if you
go too far from it, if you leave the game or the
server shuts down.

Added a chatcommand "/7" to call back your aviator
to your inventory. This allows climbing and other
more convinient use of it.

You can configue the mod by opening init.lua:

[]....
-- configure mod here
local flength = 1800     -- how many seconds you can fly
local maxdistance = 20  -- maxradius (values >20 will need extra cpu power using forceloaded blocks)
-- end configuration
....[]

maxdistance is the radius counted from position of the aviator node.
with 20 as radius you will be able to fly in a sphere of 40 nodes of diameter
with the aviator node as central point.

Setting maxdistance to bigger values as 20 will need forceloaded blocks. Those can be configured
in your minetest.config or from minetest application in: advanced Settings/server+singleplayer/Game/max_forceloaded_blocks = xxx









