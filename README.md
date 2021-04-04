# Where's Askey?

Your dog Askey is missing! Explore the kingdom looking for him.

## Introduction

This is a tile-based game (Ultima-like) using the Apple 2 text mode for a contest being run on Facebook. 

## Download

You can grab the latest disk image for PRODOS: https://github.com/pmwasson/text-base-game/raw/main/disk/askey_prodos.dsk

Or DOS 3.3: https://github.com/pmwasson/text-base-game/raw/main/disk/askey_dos33.do

Requires an Apple IIe or better.

## Play in a browser

I've upload a version to the Internet Archive, allowing it to be played online using their online emulator:
https://archive.org/details/askey_prodos

## Instructions

Instructions including in the basic HELLO program:

```
 10  REM ***********************                                                
 20  REM * "Where's Askey?"    *                                                
 30  REM * By Paul Wasson      *                                                
 40  REM * February 2021       *                                                
 50  REM ***********************                                                
 90  HOME                                                                       
 100  PRINT "Where's Askey?"                                                    
 110  PRINT                                                                     
 120  PRINT "  <W>    - Move up"                                                
 130  PRINT "<A> <D>  - Move left/right"                                        
 140  PRINT "  <S>    - Move down"                                              
 150  PRINT                                                                     
 160  PRINT "<SPACE>  - Interact with people"                                   
 170  PRINT "           and objects"                                            
 180  PRINT                                                                     
 190  PRINT " <ESC>   - Quit game"                                              
 200  PRINT                                                                     
 210  PRINT "]BRUN ASKEY"                                                       
 220  PRINT  CHR$ (4),"BRUN ASKEY"                                              
```

## Toolchain

Using ca65 (part of the cc65 compiler) for assembling. https://cc65.github.io/

AppleCommander to build disk images. https://applecommander.github.io/

AppleWin for emulation. https://github.com/AppleWin/AppleWin

## Contest?

Where's Askey was entered in Roby Sherman's Apple II Software Enthusiast text based game contest for 2021 and came in first place!

Thanks Roby for organizing the contest and to all the other participants for making it so enjoyable.

You can find all the entries here: https://www.crowcousins.com/programming-exhibitions.html
