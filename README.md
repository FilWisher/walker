# Walker

The virus escaped. The zombies are everywhere. Against all the odds, a small,
scattered community of survivors remain. Find them and eat them.

Walker is a game written in Lua for [LÖVE](https://love2d.org/). I don't intend
to finish this.

## Gameplay

The game takes place in a birdseye-view world. The levels are populated by
CPU-operated zombies and survivors. The player plays a single zombie whose
objective it is to find and eat the survivors.

The controls of the player is limited to directional controls and two attacks:

  1. Eat brain: eat the brain of a survivor or another zombie. Eating a brain
     restores a variable amount of health. Eating a survivor brain restores a
     large amount of health; eating a zombie brain restores a small amount of
     health.
  2. Infect: bite a survivor to infect them and turn them into a zombie. Once a
     survivor has turned into a zombie, they follow the player around. Bite a
     zombie for them to follow the player around. Biting a zombie sacrifices
     some health.

Lone CPU zombies wonder aimlessly while there are no survivors in sight. If
there is a survivor in sight, they walk towards them attempting to eat them.
Once a CPU zombie has been bitten, they will follow the player to within a set
radius. When the player is not moving and the CPU zombie is within the set
radius, the zombie will wander aimlessly within the player's zombie radius.

Survivors are armed and will either patrol along set lines or camp. Once a
zombie is in sight, the survivors will leave their patrol lines and start
attacking the zombie(s) they can see. Once out of sight line, the survivors will
return to their camp or patrol lines. 

Survivors will attack from a distance defined by the weapon they are using:

  1. Assault rifle - long radius
  2. Pistol - short radius
  3. Baseball bat - close quarters
  4. Fists - close quarters

Gun-wielding survivors will attempt to keep a longer distance away from the
zombies.

The difficulty of the game can be tuned by:

  1. Number of other zombies spawned
  2. Amount of player health
  3. Amount of zombie health
  4. Amount of survivor health
  5. Strength of survivor attacks
  6. Number of survivors

## Map parsing

Levels should be parsable from maps to help with quick level design. Example:

```
  o = player start
  # = wall
  z = zombie start
  s = survivor start

  ########################################
  #              z  #        z           #
  #  z              #                    #
  #       z                     z    z   #
  #            z    #     z              #
  #                 #              z     #
  #########   ################ ###########
  #           #              #           #
  #    z   z  #        s     #           #
  #           #  s           #           #
  #           # s  s         #     s     #
  #    o      # s s                      #
  ########################################
```
