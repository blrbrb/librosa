# librosa
/// Mission Statement

The purpose of this library is to make it as easy as possible for new modders, or people who don't understand programming to be creative with luanti.
It should be as simple as gardening.

Which is why the plantdef uses parameter names like `shade_tolerance` instead of `maxlightl`.
It's also why instead of asking for a list of biomes, the library will be used to keep track of all registered biomes; and  sort them catagoregically into groups based off of real life biome analogues. This way instead of having to remember all of the many mod and biome names, a user needs only to specify one of the default biome types e.g (`costal` `savannah` `mangroove` `glen` `temperate_forest` `jungle` `marsh`).

I thought of this because sometimes mods will register biomes without actually registering their associated nodes and attributes into groups which can easily be used to sort them
by climate. The biomelib library isn't very well maintained, and harder for beginner modders to understand. And the biome_info api doesn't really give you the ability to do anything beyond basic data retrevial. Librosa acts as a global "plant-placement manager". For moddders interested in realism and natural landscapes.

With this library, it's possible to create global definitions for unique plant decorations that need to be spawned in specific and realistic locations -- without having to be a lua expert. Furthermore, modders can easily and freely add their custom biome definitions


librosa is a minetest/luanti library for modders to quickly and easily add new plants to the game.





## Registering a biome to librosa
the register_biome() function takes two parameters. Your biome, and a biome typ(choose from defaults, or create your own)
```librosa.register_biome(biomedef, "costal")```
That's it. The biome will be registered as normal, it's surface nodes will be sorted into climate groups. And plant decorations registered with register_plant()
will automatically be placed in the correct spots.

You can also supply the names of already existing biomes if your mod already has methods to register biomes on it's own
All you need to do is is supply the name of the biome, and it's biome type:
```librosa.register_biome("grassland", "temperate_grassland")```

Furthermore, when registering a biome you have the option to either assign your biome to one of the default biome types. Or to create your own.
When registering, if the biome type isn't one of the already defined biometypes. The library will create a new key. Out of courtesy to other modders, if you choose to do this
please include documentation.



## Biome Types
Librosa uses a table of indexed biomes and aliases to sort biomes extensivley based on climate attributes in a easily understandable way.
The default biome types are
```
  aquatic
  alpine
  coastal
  wetland
  grassland
  forest
  equitorial
  desert


```
