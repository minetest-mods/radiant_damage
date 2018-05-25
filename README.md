# radiant_damage

This mod allows registered nodes to damage a player if the player is simply near them, rather than having to be immersed in them directly. For example, in real life simply being close to lava would burn you. Or perhaps being near a highly radioactive material would be damaging.

This mod comes with a set of predefined radiant damage types, all of which can be enabled and disabled independently, and allows other mods to make use of its system to register their own.

## Configurable Presets

**Important note:** none of these predefined radiant damage types are enabled by default. This is because one of this mod's intended uses is as a library for other mods to use to enable their own radiant damage types. There is no way to de-register a globalstep callback (the mechanism used by this mod to deliver damage) once it has been registered, so to keep the mod maximally flexible nothing is registered by default.

Set one or more of the following types to enabled if you want this mod to have an effect out-of-the-box.

The following settings exist for predefined radiant damage types:

    radiant_damage_enable_lava_damage (Enable radiant lava damage) bool false
    radiant_damage_lava_damage (Damage dealt per second when standing directly adjacent to one lava node) int 10
    radiant_damage_lava_range (Maximum range at which radiant lava damage is dealt) int 4

    radiant_damage_enable_fire_damage (Enable radiant fire damage) bool false
    radiant_damage_fire_damage (Damage dealt per second when standing directly adjacent to one fire node) int 2
    radiant_damage_fire_range (Maximum range at which radiant fire damage is dealt) int 2

    radiant_damage_enable_mese_damage (Enable mese ore radiation damage) bool false
    radiant_damage_mese_interval (Number of seconds between mese radiation damage checks) int 5
    radiant_damage_mese_damage (Damage dealt per second when standing directly adjacent to one mese node) int 5
    radiant_damage_mese_range (Maximum range at which mese radiation causes damage) int 3
	radiant_damage_mese_occlusion (Sets whether other nodes block mese radiation) bool false

## API

Call:

```
	radiant_damage.register_radiant_damage(damage_def)
```

where damage_def is a table such as:

```
damage_def:
{
	damage_name = "lava", -- a string used in logs to identify the type of damage dealt.
	interval = 1, -- number of seconds between each damage check. Defaults to 1.
	range = 3, -- maximum range of the damage. Can be omitted if inverse_square_falloff is true, in that case it defaults to the range at which 1 point of damage is done.
	inverse_square_falloff = true, -- if true, damage falls off with the inverse square of the distance. If false, damage is constant within the range.
	damage = 10, -- number of damage points dealt each interval (if inverse square falloff is true this is the damage done to players 1 node away)
	nodenames = {"group:lava"}, -- nodes that cause this damage. Same format as the nodenames parameter for minetest.find_nodes_in_area
	occlusion = true, -- if true, damaging effect only passes through air. Other nodes will cast protective "shadows".
	above_only = false, -- if true, damage only propagates directly upward. Useful for things that damage you if you stand on them.
	cumulative = true, -- if true, all nodes within range do damage. If false, only the nearest one does damage.
}
```