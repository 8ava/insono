



--[[
[2024-08-08]- java
               +_&+-¦¦¦                                                         
          ,__¯¯    +¦¦¦                                                         
       ,_¦¯'      _¦¦¦                                                          
     _¦¯         ¦¦¦¯             ,_¦¦                                          
  ,_¦¯          _¦¦¯   ¦¦_  _¦¦Ç -¦¦¦'       _¦¦¦¯_   ¦¦_  _¦¦_     _¦¦¯¯W      
 ¦¦¦           _¦¦¯   _¦¦¯_¯¦¦¦" _¦¦¦     ¦¦¦¦¦¯ J¦  +¦¦¦+¯_¦¦¯  ¦¦¦¦¦+ ¦¦  +¦  
 ¦¦¦          +¦¦¦   _¦¦¦¯`_¦¦' ¦¯ ¦¦¦   ¦¦¦¦¦¯  ¦' _¦¦¦¯+¦¦¦¯  ¦¦¦¦¦T ,¦  _¯   
   '         ¬¦¦¦   _¦¦¦T ¦¦¦  _¯  j¦¦¦_¯¦¦¯¯¦_+¦_Æ¯¦¦¦¯ +¦¦- +¦¦¦¯¯¦__¦_R¯     
             ¦¦¦"   ¦¦¯   ¦¦M+¯¦  _¦¦¦¯  ¦¦  ,_¯   ¯¦¯   ¦¦¦,_( ¦¦  ,_¯         
             ¦¦¦     ¯`    ¯¯'  +¯¯+      +¯¯(      +T    +¯(    +¯¯(           
             ¦¦¦                                                                
              ¯¦¦                                                               
]]


--[[
Insono is a resource that creates and manages and automates the physical effects that the real world changes about sound. 
Each sound shoots rays off walls to determine echoing, and looking away from sounds now muffles them to your ears. I took a
hands-off approach to this resource, so it does not automate the process of updating the effects, allowing you to implement it wherever you want.
]]



-- about Sounds
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
--# step(): The main process that updates rolloff, and peripheral muffling. Inexpensive. 									(no requirement)




local abs = math.abs
local acos = math.acos
local sqrt = math.sqrt
local pi = math.pi


local sound_physical_properties = {
	effect_injection_priority = 1,
	
	peripheral_rolloff = 9,
	reverb_wet_post_sub = -5,

	rolloff = {
		low = 3,
		mid = 10,
		high = 5,
	}
}

-- create dynamic registries
local regist_sounds = {}



local class = {
	listener_matrix = game.Workspace.CurrentCamera.CFrame,
	
	_raycast_length = 9e9,
	_collision_directories = {game.Workspace}
}




local uninitialized_equalizer = Instance.new('EqualizerSoundEffect')
local uninitialized_reverb = Instance.new('ReverbSoundEffect')

function class.new(sound: Sound & {Parent: BasePart})
	sound.RollOffMaxDistance = 9e9
	sound.RollOffMinDistance = 9e9
	
	local object = {
		node = sound.Parent,
		source = sound,
		equalizer = Instance.fromExisting(uninitialized_equalizer),
		reverb = Instance.fromExisting(uninitialized_reverb)
	}
	
	object.equalizer.Parent = object.source
	object.reverb.Parent = object.source
	
	table.insert(regist_sounds, object)
end

function class.set_sound_physical_properties(a: {effect_injection_priority: number, peripheral_rolloff: number, reverb_wet_post_sub: number, rolloff: {low: number, mid: number, high: number}})
	sound_physical_properties = a
end


function class.init()
	uninitialized_reverb.DryLevel = 0
	uninitialized_reverb.WetLevel = -9e9
	
	uninitialized_reverb.Priority = sound_physical_properties.effect_injection_priority
	uninitialized_equalizer.Priority = sound_physical_properties.effect_injection_priority - 1
	
	class.set_sound_physical_properties({
		effect_injection_priority = 1,

		peripheral_rolloff = 9,
		reverb_wet_post_sub = -5,

		rolloff = {
			low = 3,
			mid = 10,
			high = 5,
		}
	})
end



local function autoFree(a)
	if not a.source then -- lazy clear operation for if instance reference is destroyed
		table.clear(a)
		
		return true
	end
end


function class.update_reverb()
	local ray_parameters = RaycastParams.new()
	
	for a, b in { -- this is just messy, courtesy of roblox, all it does is create a raycast parameters without making unnecessary lines.
		FilterDescendantsInstances = class._collision_directories,
		FilterType = Enum.RaycastFilterType.Include,
		RespectCanCollide = false
		} do
		ray_parameters[a] = b
	end
	
	for _, a in regist_sounds do
		if autoFree(a) then
			continue
		end
		
		local node_matrix = a.node.CFrame
		
		local casts = { -- sorting like this so i can easier catch missing rays
			game.Workspace:Raycast(node_matrix.Position, node_matrix.Position + Vector3.new(0, class._raycast_length, 0), ray_parameters),
			game.Workspace:Raycast(node_matrix.Position, node_matrix.LookVector * class._raycast_length, ray_parameters)
		}
		
		if #casts > 0 then -- thanks for being a great language :)
			local product = 1
			
			-- get the furthest distance
			for _, a in casts do
				if a and abs(a.Distance) > product then
					product += abs(a.Distance) -- why i calculate it twice! multithread this please!
				end
			end
			
			
			local sound_filter = a.reverb
			local audio_intensity = a.source.Volume
			
			local distance = sqrt(product) -- sorry, just wanna keep things organized
			
			
			local decay_length = distance / 2
			local reflections = distance / 100
			local output_volume = -distance
			local brightness = 1 - (audio_intensity / 10 / 2)
			
			
			-- set values
			
			sound_filter.DecayTime = decay_length
			sound_filter.Density = brightness
			sound_filter.WetLevel = output_volume + sound_physical_properties.reverb_wet_post_sub
			sound_filter.Diffusion = reflections
		else
			-- we are in a room so big that reverb is not necessary

			local sound_filter = a.reverb
			
			sound_filter.DecayTime = 0
			sound_filter.Density = 0
			sound_filter.WetLevel = -9e9
		end
	end
end


function class.step()
	local camera_position = class.listener_matrix.Position
	local camera_look = class.listener_matrix.LookVector

	for _, a in regist_sounds do
		if autoFree(a) then
			continue
		end
		
		local sound_position = a.node.Position
		local sound_filter = a.equalizer
		local audio_intensity = a.source.Volume -- we determine how powerful the sound is based off its volume


		-- distance attenuation
		-- technically higher frequencies travel the longest, however in listening practice, i find that mid frequencies sound more realistic

		local distance = abs((sound_position - camera_position).Magnitude)


		local distance_factor_sub = -distance / audio_intensity

		local gain_low = distance_factor_sub / sound_physical_properties.rolloff.low
		local gain_mid = distance_factor_sub / sound_physical_properties.rolloff.mid
		local gain_high = distance_factor_sub / sound_physical_properties.rolloff.high


		-- peripheral attenuation
		-- lower frequencies have less resistance traveling through material

		local direction_to = (sound_position - camera_position).Unit
		local theta = acos(camera_look:Dot(direction_to)) / 2 / audio_intensity

		gain_high -= theta * sound_physical_properties.peripheral_rolloff
		--gain_mid -= theta * sound_physical_properties.direction_rolloff / 2

		-- set values 

		sound_filter.LowGain = gain_low
		sound_filter.MidGain = gain_mid
		sound_filter.HighGain = gain_high
	end
end


return class
