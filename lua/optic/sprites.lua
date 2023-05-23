local function sprites(size)
    return {
        -- Kill medals
        kill = {name = "normal_kill", width = size, height = size},
        rocketKill = {name = "rocket_kill", width = size, height = size},
        supercombine = {name = "needler_kill", width = size, height = size},

        -- Multikills
        doubleKill = {name = "double_kill", width = size, height = size},
        tripleKill = {name = "triple_kill", width = size, height = size},
        overkill = {name = "overkill", width = size, height = size},
        killtacular = {name = "killtacular", width = size, height = size},
        killtrocity = {name = "killtrocity", width = size, height = size},
        killimanjaro = {name = "killimanjaro", width = size, height = size},
        killtastrophe = {name = "killtastrophe", width = size, height = size},
        killpocalypse = {name = "killpocalypse", width = size, height = size},
        killionaire = {name = "killionaire", width = size, height = size},

        -- Killing sprees
        killingSpree = {name = "killing_spree", width = size, height = size},
        killingFrenzy = {name = "killing_frenzy", width = size, height = size},
        runningRiot = {name = "running_riot", width = size, height = size},
        rampage = {name = "rampage", width = size, height = size},
        untouchable = {name = "untouchable", width = size, height = size, alias = "nightmare"},
        invincible = {name = "invincible", width = size, height = size, alias = "boogeyman"},
        inconceivable = {name = "inconceivable", width = size, height = size, alias = "grim_reaper"},
        unfriggenbelievable = {
            name = "unfriggenbelievable",
            width = size,
            height = size,
            alias = "demon"
        },
        comebackKill = {name = "comeback_kill", width = size, height = size},

        -- Bonus
        firstStrike = {name = "first_strike", width = size, height = size},
        fromTheGrave = {name = "from_the_grave", width = size, height = size},
        closeCall = {name = "close_call", width = size, height = size},
        snapshot = {name = "snapshot", width = size, height = size},
        snipe = {name = "snipe", width = size, height = size},
        splatter = {name = "splatter", width = size, height = size},
        stick = {name = "stick", width = size, height = size},
        autopilot = {name = "autopilot", width = size, height = size},
        perfect = {name = "perfect", width = size, height = size},
        cluster_luck = {name = "cluster_luck", width = size, height = size},
        ninja = {name = "ninja", width = size, height = size},
        sneak_king = {name = "sneak_king", width = size, height = size},
        nade_shot = {name = "nade_shot", width = size, height = size},
        mind_the_gap = {name = "mind_the_gap", width = size, height = size},
        hail_mary = {name = "hail_mary", width = size, height = size},
        fire_and_forget = {name = "fire_and_forget", width = size, height = size},
        quigley = {name = "quigley", width = size, height = size},
        melee = {name = "melee", width = size, height = size},
        back_smack = {name = "back_smack", width = size, height = size},
        combat_evolved = {name = "combat_evolved", width = size, height = size},
        quick_draw = {name = "quick_draw", width = size, height = size},
        three_sixty = {name = "360", width = size, height = size},
        last_shot = {name = "last_shot", width = size, height = size},

        -- CTF
        flagCaptured = {name = "flag_captured", width = size, height = size},
        flagRunner = {name = "flag_runner", width = size, height = size},
        flagChampion = {name = "flag_champion", width = size, height = size},

        hitmarkerHit = {
            name = "hitmarker",
            width = size,
            height = size,
            renderGroup = "crosshair",
            noHudMessage = true
        },
        hitmarkerKill = {
            name = "hitmarker_kill",
            width = size * 1.25,
            height = size * 1.25,
            renderGroup = "crosshair",
            noHudMessage = true
        }
    }
end

return sprites
