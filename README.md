
<html>
    <p align="center">
        <img width="200px" src="img/optic-logo.png"/>
    </p>
    <h1 align="center">Optic</h1>
    <p align="center">
        Optic medals for Halo Custom Edition using Harmony
    </p>
</html>

# Description
This project is an effort to bring medals to Halo Custom Edition that are compatible with Chimera
1.0, but at the same time looking for a better and more flexible way to customize your own medals,
this repository aims to be the standard for medals released under the Mercury repository, but feel
free to contribute by pull requests or discussing on our 
[Discord Server](https://discord.shadowmods.net).

This project is possible thanks to [Harmony](https://github.com/JerryBrick/harmony),
[Chimera](https://github.com/SnowyMouse/chimera),
[Mercury](https://github.com/Sledmine/Mercury) and [lua-blam](https://github.com/Sledmine/lua-blam).

# Downloading and Installation

Get it on [Mercury](https://github.com/Sledmine/Mercury) by using the following command:
```
mercury install optic
```

# Supported Medals
Right now the project is aiming to provide an acceptable quantity of medals from Halo 4 as an
standard for medals available to recreate on Halo Custom Edition.

## General
- Kill
- Double Kill
- Triple Kill
- Overkill
- Killtacular
- Killtrocity
- Killamanjaro
- Killtastrophe
- Killpocalypse
- Killionaire

## Multilayer
- Rocket Kill
- Needler Kill
- Killing Spree
- Killing Frenzy
- Running Riot
- Rampage
- Untouchable (Nightmare)
- Invincible (Boogeyman)
- Inconceivable (Grim Reaper)
- Unfriggenbelievable (Demon)
- Comback Kill
- First Strike
- From The Grave
- Close Call
- Snapshot
- Flag Captured
- Flag Runner
- Flag Champion

## Singleplayer
- Melee Kill
- Headshot
- Back Smack
- Splatter
- Cluster Luck
- Hail Mary
- Mind the Gap
- Stick

Also this project provides simple hitmaker support.

New medals will be added later on further development, be sure to follow us on our
[Discord Server](https://discord.shadowmods.net) for upcoming releases with new features, fixes and
new medals.

# FAQ
## Why I can't use medal packs as how HAC2 once had?
This is an entire new project that uses Harmony as the core tool to render medals animations on the 
game, meaning that the engine or system to handle game actions to eventually convert them into 
medals, needed to be built from zero in order to create a better and flexible system than the
presented by HAC2, more and better medals will come later after different releases.

## Why are some medals not working on protected maps?
This optic project uses lua-blam as a tool to determine different events happening on the game,
if the map you are playing is "protected" lua-blam will have some problems at getting the required
information from the game memory resulting in some medals not being able to be triggered.

## Why some medals does not have an announcer sound?
As we are attempting to provide a set of standard medals for Halo Custom Edition independent of the
style you want to see in game, some of the medals were renamed or redesigned to appear in other
medals style or ported to work in a style were those medals originally were not there, so the mod
attempts to remove some aspects from specific medals to make them work across styles when possible.

# Medals Adjustments

- Halo 4 -> Super Combine -> Needler Kill
- Halo Infinite -> Breacher -> Needler Kill
- Halo Infinite -> First Strike (redesigned cause it does not exist originally)
