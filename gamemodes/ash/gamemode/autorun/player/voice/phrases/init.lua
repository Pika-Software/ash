local Entity_EmitSound = Entity.EmitSound

local math_random = math.random
local isstring = isstring
local istable = istable
local pairs = pairs

local CurTime = CurTime

MODULE.ClientFiles = {
    "cl_init.lua"
}

MODULE.Networks = {
    "sync"
}

---@type ash.sound
local ash_sound = require( "ash.sound" )
local sound_get = ash_sound.get

---@type ash.player
local ash_player = require( "ash.player" )
local player_isSpeaking = ash_player.isSpeaking

---@class ash.player.voice.phrases
local ash_phrases = {}

---@type table<Player, string>
local player_voices = {}

setmetatable( player_voices, {
    __index = function( self, pl )
        local voice_name = "default"
        self[ pl ] = voice_name
        return voice_name
    end,
    __mode = "k"
} )

--- [SERVER]
---
--- Gets the voice for a player.
---
---@param pl Player
---@return string voice_name
function ash_phrases.getVoice( pl )
    return player_voices[ pl ]
end

--- [SERVER]
---
--- Sets the voice for a player.
---
---@param pl Player
---@param voice_name string
function ash_phrases.setVoice( pl, voice_name )
    player_voices[ pl ] = voice_name
end

do

    local Entity_StopSound = Entity.StopSound

    ---@type table<Player, { name: string, volume: number, pitch: number, level: number, time: number }>
    local sounds = {}

    --- [SERVER]
    ---
    --- Plays a voice phrase.
    ---
    ---@param pl Player
    ---@param phrase_name string
    ---@param sound_volume? number
    ---@param sound_pitch? number
    ---@param sound_level? number
    ---@param sound_dsp? number
    ---@param rf? CRecipientFilter
    ---@return string | nil
    function ash_phrases.play( pl, phrase_name, sound_volume, sound_pitch, sound_level, sound_dsp, rf )
        if player_isSpeaking( pl ) then
            return
        end

        local previous_sound = sounds[ pl ]
        if previous_sound ~= nil then
            if ( CurTime() - previous_sound.time ) < 0.5 then
                return
            end

            ash_phrases.stop( pl )
        end

        local data = sound_get( "ash.player.phrase." .. player_voices[ pl ] .. "." .. phrase_name )
        if data == nil then
            return
        end

        local sound_path

        local sound = data.sound
        if isstring( sound ) then
            ---@cast sound string
            sound_path = sound
        elseif istable( sound ) then
            ---@cast sound string[]
            local sound_count = #sound
            if sound_count ~= 0 then
                sound_path = sound[ math_random( 1, sound_count ) ]
            end
        end

        if sound_path == nil then
            return
        end

        if sound_level == nil then
            sound_level = data.level
        end

        ---@cast sound_level integer

        if sound_pitch == nil then
            local data_pitch = data.pitch
            if istable( data_pitch ) then
                ---@cast data_pitch integer[]
                sound_pitch = math_random( data_pitch[ 1 ], data_pitch[ 2 ] )
            else
                ---@cast data_pitch integer
                sound_pitch = data_pitch
            end
        end

        ---@cast sound_pitch integer

        if sound_volume == nil then
            sound_volume = data.volume
        end

        ---@cast sound_volume number

        if rf == nil then
            rf = RecipientFilter()
            rf:AddPAS( pl:EyePos() )
        end

        rf:AddPlayer( pl )

        local sound_time = CurTime()

        net.Start( "sync" )

        net.WritePlayer( pl )
        net.WriteBool( true )

        net.WriteDouble( sound_time )
        net.WriteString( sound_path )

        net.WriteUInt( sound_level, 9 )
        net.WriteUInt( sound_pitch, 8 )
        net.WriteFloat( sound_volume )

        net.Send( rf )

        if ash_player.isAlive( pl ) then
            sounds[ pl ] = {
                name = sound_path,
                volume = sound_volume,
                pitch = sound_pitch,
                level = sound_level,
                time = sound_time
            }

            Entity_EmitSound( pl, sound_path, sound_level, sound_pitch, sound_volume, 2, 0, sound_dsp or 1, rf )
        else

            local entity = ash_player.getRagdoll( pl )
            if entity ~= nil and entity:IsValid() then
                Entity_EmitSound( entity, sound_path, sound_level, sound_pitch, sound_volume, 2, 0, sound_dsp or 1, rf )
            end

        end

        return sound_path
    end

    --- [SERVER]
    ---
    --- Stops a voice phrase.
    ---
    ---@param pl Player
    function ash_phrases.stop( pl )
        local sound = sounds[ pl ]
        if sound ~= nil then
            sounds[ pl ] = nil
            Entity_StopSound( pl, sound.name )

            net.Start( "sync" )
            net.WritePlayer( pl )
            net.WriteBool( false )
            net.Broadcast()
        end
    end

    -- hook.Add( "PostPlayerDeath", "Cleanup", ash_phrases.stop )

end

--- [SERVER]
---
--- Gets a voice phrase.
---
---@param voice_name string
---@param phrase_name string
---@return ash.sound.Data | nil
function ash_phrases.get( voice_name, phrase_name )
    return sound_get( "ash.player.phrase." .. voice_name .. "." .. phrase_name )
end

--- [SERVER]
---
--- Registers a voice.
---
---@param voice_name string
---@param phrases_map table<string, ash.sound.Data>
---@param override? boolean
function ash_phrases.register( voice_name, phrases_map, override )
    for phrase_name, sound_data in pairs( phrases_map ) do
        local sound_name = "ash.player.phrase." .. voice_name .. "." .. phrase_name
        sound_data.name = sound_name

        if override == true then
            ash_sound.register( sound_data )
        else
            ash_sound.merge( sound_data.name, sound_data )
        end
    end
end

---@type table<string, ash.sound.Data>
local female01 = {
    behind_you = {
        sound = {
            "behindyou01.wav",
            "behindyou02.wav"
        }
    },
    busy = {
        sound = "busy02.wav",
    },
    ammo_here = {
        sound = "ammo03.wav" -- Here, ammo!
    },
    take_ammo = {
        sound = {
            "ammo04.wav", -- Take some ammo!
            "ammo05.wav" -- Take some ammo!
        }
    },
    pain = {
        sound = {
            "pain01.wav",
            "pain02.wav",
            "pain03.wav",
            "pain04.wav",
            "pain05.wav",
            "pain06.wav",
            "pain07.wav",
            "pain08.wav",
            "pain09.wav",
            "ow01.wav",
            "ow02.wav",
            "uhoh.wav"
        }
    },
    moan = {
        sound = {
            "moan01.wav",
            "moan02.wav",
            "moan03.wav",
            "moan04.wav",
            "moan05.wav"
        }
    },
    doing_something = {
        sound = "doingsomething.wav"
    },
    stop_looking = {
        sound = "vquestion01.wav"
    },
    excuseme = {
        sound = {
            "excuseme01.wav",
            "excuseme02.wav"
        }
    },
    fantastic = {
        sound = {
            "fantastic01.wav",
            "fantastic02.wav"
        }
    },
    finally = {
        sound = "finally.wav"
    },
    help = {
        sound = "help01.wav"
    },
    hi = {
        sound = {
            "hi01.wav",
            "hi02.wav"
        }
    },
    get_down = {
        sound = "getdown02.wav"
    },
    lets_go = {
        sound = {
            "letsgo01.wav",
            "letsgo02.wav"
        }
    },
    like_that = {
        sound = "likethat.wav"
    },
    my_arm = {
        sound = {
            "myarm01.wav",
            "myarm02.wav"
        }
    },
    my_gut = {
        sound = "mygut02.wav"
    },
    my_leg = {
        sound = {
            "myleg01.wav",
            "myleg02.wav"
        }
    },
    nice = {
        sound = {
            "nice01.wav",
            "nice02.wav"
        }
    },
    hungry = {
        sound = {
            "question06.wav", -- Sometimes I dream about cheese.
            "question09.wav", -- I could eat a horse, hooves and all.
            -- "question27.wav", -- I think I ate something bad.
            "question28.wav" -- God I'm hungry.
        }
    },
    hopeful = {
        sound = {
            "question04.wav", -- When this is all over I'm...aw, who am I kidding?
            "question07.wav", -- You smell that? It's freedom.
            "question10.wav", -- I can't believe this day has finally come.
            -- "question13.wav", -- If I could live my life over again...
            "question16.wav", -- Finally, change is in the air!
            "question17.wav", -- Do you feel it? I feel it!
            "question20.wav", -- Some day this will all be a bad memory.
            "question23.wav", -- I can't get this tune out of my head. [whistles]
            "question25.wav", -- I just knew it was gonna be one of those days.
            "question29.wav", -- When this is all over, I'm gonna mate.
            "vquestion04.wav", -- Sometimes I wonder how I ended up with you.
            "answer40.wav", -- There's a first time for everything.
            "answer28.wav" -- I wish I had a dime for every time somebody said that.
        }
    },
    rejection = {
        sound = {
            "no01.wav",
            "no02.wav",
            "ohno.wav", -- Oh no!
            "gordead_ans04.wav", -- Oh, God!
            "gordead_ans05.wav", -- Oh no!
            "gordead_ans06.wav", -- Please no!
            "gordead_ques06.wav", -- This can't be!
            "question18.wav", -- I don't feel anything anymore.
            "question26.wav", -- This is bullshit!
            "gordead_ques14.wav" -- It's not supposed to end like this.
        }
    },
    confused = {
        sound = {
            "gordead_ans01.wav", -- Now what?
            "gordead_ans02.wav", -- And things were going so well.
            "gordead_ans03.wav", -- Don't tell me.
            "gordead_ans11.wav", -- What's the use?
            "gordead_ans12.wav", -- What's the point?
            "gordead_ans13.wav", -- Why go on?
            "gordead_ans14.wav", -- We're done for.
            "gordead_ans15.wav", -- Well, now what?
            "gordead_ques10.wav", -- This is bad.
            "gordead_ques16.wav", -- What now?
            "question11.wav", -- I'm pretty sure this isn't part of the plan.
            -- "squad_affirm06.wav" -- Here goes nothing.
        }
    },
    freeman_death = {
        sound = {
            "gordead_ans09.wav", -- I had a feeling even he couldn't help us.
            "gordead_ans18.wav", -- He's done this before. He'll be okay.
            "gordead_ans20.wav", -- Somebody take his crowbar.
            "gordead_ques11.wav", -- I thought he was invincible!
            "gordead_ques15.wav", -- Dr. Freeman? Can you hear me? Do not go into the light!
            "gordead_ques13.wav", -- So much for our last hope.
            "gordead_ques17.wav", -- Any last words, Doc?
            "sorrydoc02.wav", -- Sorry, Doc.
            "sorrydoc04.wav", -- Sorry, Doc.
            "sorryfm01.wav", -- Sorry, Freeman.
        }
    },
    corpse = {
        sound = {
            "gordead_ques01.wav", -- He's dead.
            "gordead_ques02.wav", -- What a way to go.
            "gordead_ques07.wav", -- Look, he's dead!
            "gordead_ans08.wav", -- Should we bury him here?
            "gordead_ans10.wav", -- Spread the word.
            "gordead_ans19.wav", -- I'm gonna be sick.
            "question11.wav", -- I'm pretty sure this isn't part of the plan.
            "question12.wav", -- Looks to me like things are getting worse, not better.
            -- "vquestion02.wav", -- I don't know how you things have survived as long as you have.
            -- "question14.wav", -- I'm not even gonna tell you what that reminds me of.
            -- "question21.wav", -- I'm not a betting man, but the odds are not good.
            "question30.wav", -- I'm glad there's no kids around to see this.
            "answer11.wav", -- I'll put it on your tombstone.
            "answer07.wav" -- Same here.
        }
    },
    agree = {
        sound = {
            "yeah02.wav", -- Yeah!
            "answer32.wav", -- Right on.
            "ok01.wav", -- Okay.
            "ok02.wav", -- Okay!
            "squad_affirm03.wav", -- Whatever you say.
            "squad_affirm04.wav", -- Okay I'm going.
            "squad_affirm05.wav" -- Here goes.
        }
    },
    apologize = {
        sound = {
            "sorry01.wav",
            "sorry02.wav",
            "sorry03.wav",
            "pardonme01.wav",
            "pardonme02.wav"
        }
    },
    im_ready = {
        sound = {
            "okimready01.wav",
            "okimready02.wav",
            "okimready03.wav"
        }
    },
    combine = {
        sound = {
            "combine01.wav",
            "combine02.wav",
        }
    },
    civil_protection = {
        sound = {
            "civilprotection01.wav",
            "civilprotection02.wav",
            "combine01.wav",
            "combine02.wav",
            "cps01.wav",
            "cps02.wav"
        }
    },
    medkit = {
        sound = {
            "health01.wav",
            "health02.wav",
            "health03.wav",
            "health04.wav",
            "health05.wav"
        }
    },
    waiting_somebody = {
        sound = "waitingsomebody.wav"
    },
    wait_for_me = {
        sound = "squad_reinforce_single04.wav"
    },
    watchout = {
        sound = "watchout.wav",
    },
    watch_what_you_doing = {
        sound = "watchwhat.wav",
    },
    whoops = {
        sound = "whoops01.wav"
    },
    you_got_it = {
        sound = "yougotit02.wav",
    },
    follow = {
        sound = "answer13.wav" -- I'm with you.
    },
    strider = {
        sound = "strider.wav"
    },
    run = {
        sound = {
            "strider_run.wav",
            "runforyourlife01.wav",
            "runforyourlife02.wav"
        }
    },
    zombies = {
        sound = {
            "zombies01.wav",
            "zombies02.wav"
        }
    },
    up_there = {
        sound = {
            "upthere01.wav",
            "upthere02.wav"
        }
    },
    here = {
        sound = {
            "overhere01.wav",
            "overthere01.wav",
            "overthere02.wav"
        }
    },
    startle = {
        sound = {
            "startle01.wav",
            "startle02.wav"
        }
    },
    hacks = {
        sound = {
            "hacks01.wav",
            "hacks02.wav",
            "thehacks01.wav",
            "thehacks02.wav",
            "itsamanhack01.wav",
            "itsamanhack02.wav",
            "herecomehacks01.wav",
            "herecomehacks02.wav"
        }
    },
    headcrabs = {
        sound = {
            "headcrabs01.wav",
            "headcrabs02.wav"
        }
    },
    scanners = {
        sound = {
            "scanners01.wav",
            "scanners02.wav"
        }
    },
    got_one = {
        sound = {
            "gotone01.wav",
            "gotone02.wav"
        }
    },
    take_cover = {
        sound = {
            "takecover02.wav"
        }
    },
    this_will_do_nicely = {
        sound = {
            "thislldonicely01.wav"
        }
    },
    are_we_gonna_get_going_soon = {
        sound = {
            "getgoingsoon.wav"
        }
    },
    get_hell_out_of_here = {
        sound = {
            "gethellout.wav"
        }
    },
    good_god = {
        sound = {
            "goodgod.wav"
        }
    },
    gotta_reload = {
        sound = {
            "gottareload01.wav"
        }
    },
    heads_up = {
        sound = {
            "headsup01.wav",
            "headsup02.wav"
        }
    },
    here_they_come = {
        sound = "heretheycome01.wav"
    },
    we_here_to_help = {
        sound = {
            "heretohelp01.wav",
            "heretohelp02.wav"
        }
    },
    hit_in_gut = {
        sound = {
            "hitingut01.wav",
            "hitingut02.wav"
        }
    },
    hold_down_spot = {
        sound = {
            "holddownspot01.wav",
            "holddownspot02.wav"
        }
    },
    i_will_stay_here = {
        sound = "illstayhere01.wav"
    },
    im_hurt = {
        sound = {
            "imhurt01.wav",
            "imhurt02.wav"
        }
    },
    im_sticking_here = {
        sound = {
            "imstickinghere01.wav",
            "littlecorner01.wav"
        }
    },
    incoming = {
        sound = "incoming02.wav"
    },
    gunship = {
        sound = "gunship02.wav"
    },
    we_trusted_you = {
        sound = {
            "wetrustedyou01.wav",
            "wetrustedyou02.wav"
        }
    },
    lead_the_way = {
        sound = {
            "leadtheway01.wav",
            "leadtheway02.wav"
        }
    },
    out_of_your_way = {
        sound = "outofyourway02.wav"
    },
    not_the_man_i_thought = {
        sound = {
            "notthemanithought01.wav",
            "notthemanithought02.wav"
        }
    },
    squad_approach = {
        sound = {
            "squad_approach02.wav",
            "squad_approach03.wav",
            "squad_approach04.wav"
        }
    },
    squad_follow = {
        sound = {
            "squad_follow02.wav",
            "squad_follow03.wav"
        }
    },
    squad_reinforce = {
        sound = "squad_reinforce_group04.wav"
    }
}

---@type table<string, ash.sound.Data>
local male01 = table.Copy( female01 )

for _, data in pairs( female01 ) do
    local sound = data.sound
    if isstring( sound ) then
        ---@cast sound string
        data.sound = "vo/npc/female01/" .. sound
    else
        ---@cast sound string[]
        for i = 1, #sound, 1 do
            sound[ i ] = "vo/npc/female01/" .. sound[ i ]
        end
    end
end

for _, data in pairs( male01 ) do
    local sound = data.sound
    if isstring( sound ) then
        ---@cast sound string
        data.sound = "vo/npc/male01/" .. sound
    else
        ---@cast sound string[]
        for i = 1, #sound, 1 do
            sound[ i ] = "vo/npc/male01/" .. sound[ i ]
        end
    end
end

ash_phrases.register( "female01", female01, true )
ash_phrases.register( "male01", male01, true )

return ash_phrases
