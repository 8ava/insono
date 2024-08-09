# Insono
A modular resource for adding immersion to your Roblox sound enviroment. Using math to muffle, and reverberate audio around you.
Sounds cast rays that determine how the room around you echos. When you turn your camera, sounds become muffled. The world around you comes to life.

[logo]: https://raw.githubusercontent.com/8ava/insono/main/git_readmegrapics/graphic_rayfurthest.png "Choosing the ray with the greatest distance"

This was constructed with a hands-off approach. This means we do not automate the stepping process. You can implement this wherever you see fit in your code.



## From script
```-- about Sounds
-- Insono uses Sound's "Volume" property to determine the intensity of the sound. Below is a chart detailing references to real world sounds for you to use.

--# [0 - 1]: Phone speaker, Radio, Small speaker, Keyboard, ect.
--# [1 - 3]: Guitar, Piano, Street firework, Industrial Fan, Screaming Pedestrian ect.
--# [3 - 4]: Concerts, Suppressed firearm, Electronic explosion, Glass breaking, ect.
--# [4 - 6]: Firearm discharge from middling ammunition, Small grenades, ect.
--# [6 - 10]: Planes, Server farms, Explosions with catastrophic damage, ect.


-- DATA WITHIN sound_physical_properties

--# effect_injection_priority: Marks the space in the priority list where the effects generated here are injected. (counting back from value)
--# peripheral_rolloff: The maximum rolloff when the sound source is 180 degrees from where the camera is facing.
--# reverb_wet_post_sub: Subtraction to apply after calculating the final reverb. Many games do not want prevalent reverb.
--# rolloff: a table listing the values for each band of the equalizer. (the higher the number the less rolloff)



-- DATA WITHIN class

--# listener_matrix: A CFrame, designed to be updated externally, which is used to calculate the resulting values in the updater sequence.
--# _raycast_length: Not intended to be changed, marked by the underscore in the index. It is the maximum value for raycasting, irrelevant to tweaking.
--# _collision_directories: A table that is free to be changed. Used as a whitelist for said raycasting.

-- METHODS WITHIN class

--# new(): Creates a wrapped object that is inserted into the registry for updating.										Requires (Sound object & Parent == BasePart)
--# set_sound_physical_properties(): Replaces the default environment properties with your custom ones.						Requires (intelisense autofill)
--# init(): self-explanatory																								(no requirement)
--# update_reverb(): An expensive method to update reverb for each sound. Should not be updated every frame, but frequently.(no requirement)
--# step(): The main process that updates rolloff, and peripheral muffling. Inexpensive. 									(no requirement)```