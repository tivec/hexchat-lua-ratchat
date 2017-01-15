# FuelRats plugin for HexChat
Add improved highlights for HexChat, tailored for the FuelRats.

## Requirements
* [HexChat](https://hexchat.github.io/) version 2.12.x
* Lua interface should have been selected on installation of HexChat. 

## Installation Instructions
* Copy RatChatPlugin.lua to the HexChat addons folder. On windows, you find this at %appdata%\Hexchat\addons, on Linux you will find this in ~/config/hexchat/addons
* In HexChat, open the plugins window (Window->Plugins and Scripts), click Load and choose the RatChatPlugin.lua file. If you restart HexChat, the file will automatically be loaded.
* If you installed the plugin correctly, you should be able to type /ratchat and get some instructions

## Disclaimer
* I release this code as is as per the LICENSE file.
* This script uses io.open and io.write and creates a .txt file in your config/addons directory. If you do not trust this, check the source.

## Usage and other information
* Entering /ratchat will list the commands you have access to.
* The plugin has three modes. "Off" will not highlight or play sounds. "Silent" will highlight, but no sounds. "Loud" will play the sounds you define.
* Default mode of the plugin is "loud", but it will not have any defined highlights and sounds.
* Highlight colors are specified with a number, as listed in the Settings->Preferences->Interface->Colors dialog.
* Example:
  * /ratchat add squeak 22 bold squeak.wav
    * this will highlight the word squeak in bold purple, and play the sound squeak.wav.

## Known bugs and issues
* This script is only tested on Windows. Other systems may have problems
* Sound files MUST be .wav and placed in the sounds directory (%appdata%\Hexchat\sounds on Windows).

## What to do if you find a bug or have a feature request
* File an issue on GitHub and I will get to it.

## Changes
### 0.2
* First public release.
* Beware messy code, future cleanup planned.
