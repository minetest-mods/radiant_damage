# radiant_damage

This mod allows registered nodes to damage a player if the player is simply near them, rather than having to be immersed in them directly. For example, in real life simply being close to lava would burn you. Or perhaps being near a highly radioactive material would be damaging.

This mod comes with a set of predefined radiant damage types, all of which can be enabled and disabled independently, and allows other mods to make use of its system to register their own.

## Configurable Presets

**Important note:** none of these predefined radiant damage types are enabled by default. This is because one of this mod's intended uses is as a library for other mods to use to enable their own radiant damage types. There is no way to de-register a globalstep callback (the mechanism used by this mod to deliver damage) once it has been registered, so to keep the mod maximally flexible nothing is registered by default.

Set one or more of the following types to enabled if you want this mod to have an effect out-of-the-box.

The following settings exist for predefined radiant damage types:

    radiant_damage_enable_heat_damage (Enable radiant heat damage) bool false
    radiant_damage_lava_damage (Damage dealt per second when standing directly adjacent to one lava node) int 10
    radiant_damage_fire_damage (Damage dealt per second when standing directly adjacent to one fire node) int 2
    
    radiant_damage_enable_mese_damage (Enable mese ore radiation damage) bool false
    radiant_damage_mese_interval (Number of seconds between mese radiation damage checks) int 5
    radiant_damage_mese_damage (Damage dealt per second when standing directly adjacent to one mese ore node) int 2

## API

Call:

```
	radiant_damage.register_radiant_damage(damage_def)
```

where damage_def is a table such as:

```
{
	damage_name = "radiant damage", -- a string used to identify the type of damage dealt.
	interval = 1, -- number of seconds between each damage check
	range = 3, -- range of the damage. Can be omitted if inverse_square_falloff is true, in that case it defaults to the range at which 1 point of damage is done by the most damaging emitter node type.
	emitted_by = {}, -- nodes that emit this damage. At least one is required.
	attenuated_by = {} -- This allows certain intervening node types to modify the damage that radiates through it. Note: Only works in Minetest version 0.5 and above.
	default_attenuation = 1, -- the amount the damage is multiplied by when passing through any other non-air nodes. Note that in versions before Minetest 0.5 any value other than 1 will result in total occlusion (ie, any non-air node will block all damage)
	inverse_square_falloff = true, -- if true, damage falls off with the inverse square of the distance. If false, damage is constant within the range.
	above_only = false, -- if true, damage only propagates directly upward. Useful for when you want to damage players that stand on the node.
}
```

emitted_by has the following format:
```
	{["default:stone_with_mese"] = 2, ["default:mese"] = 9}
```
where the value associated with each entry is the amount of damage dealt. Groups are permitted. Note that negative damage represents "healing" radiation.

attenuated_by has the following similar format:

```
	{["group:stone"] = 0.25, ["default:steelblock"] = 0}
```

where the value is a multiplier that is applied to the damage passing through it. Groups are permitted. Note that you can use values greater than one to make a node type magnify damage instead of attenuating it.