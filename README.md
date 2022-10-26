# A comfy terminal :)
A little terminal emulator written with xlib in nim.
Don't expect it to replace your st or urxvt anytime soon, I just started writing it and I usually don't finish my projects.

##Dependancies:
### To run
In the comfy.ini I set the font to IBM Plex Mono, if you want to use that one you need it installed
### To build
Nim, any version should do, I used 1.6.6

```
nim c -r -d:relase comfy.nim
```
or
```
nim c -r -d:danger comfy.nim
```
if you are feeling brave.

you can then copy the bin to */usr/bin*, or whereever you put your bins 

## Why?
For fun, mainly.
Also, I like the Terry Davis' make-everything-yourself idea.
I'm using a patched up st build right now and going through that barely commented, hardly readable C code isn't really fun.
I don't think open software makes much sense if you can't actually understand the code  ¯\-(ツ)-/¯

## The goal
To have a very minimal, simlpe X terminal emulator that looks good and can do the things I personally want from it, all in an easily readable and modifyable langugage, Nim.

## What works or is planned
- [ ] Text-input (Special charakters, as in anything that needs a modifier like / on german keyboards, aren't working yet)
- [X] foreground and background colors
- [X] execute commands (ls, cat, echo usw. are working
- [X] arrow up/ down to go through command history (only current session)
- [ ] Show adjustable symbols on the left (the >> part) (may leave that to shell)
- [ ] Show working directory on the side
- [ ] Zsh integration
- [ ] Terminal programs like Vim and Ranger should work
