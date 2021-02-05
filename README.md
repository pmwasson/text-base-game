# Where's Askey?

Your dog Askey is missing! Explore the kingdom looking for him.

## Introduction

This is a tile-based game (Ultima-like) using the Apple 2 text mode for a contest being run on Facebook. 

## Download

You can grab the latest disk image for PRODOS: https://github.com/pmwasson/text-base-game/raw/main/disk/askey_prodos.dsk

Or DOS 3.3: PRODOS: https://github.com/pmwasson/text-base-game/raw/main/disk/askey_dos33.do

Requires an Apple IIe or better.

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

Official contest announcement from Roby Sherman's Apple II Software Enthusiasts

THE FIRST A2SE PROGRAMMING EXHIBITION OF 2021 is here and it's all about doing more with less! 

As a kid I played a lot of text based games, notably Texttrain (by Beagle Bros), various Star Trek games, Nethack (on an old MicroVAX II running Ultrix), various BBS games, etc. These games pushed the limits of how plain old ASCII characters (normal, flashing, and inverse) combined with animation could be used to create some amazingly creative, fun, and memorable experiences that rivaled even some of the more graphical games at the time.

For this programming exhibition it isn't about program size or even the language you code in, it's all about creating a text based game that is both CREATIVE (in terms of the use of text based characters but also the game itself) and, of course, FUN to play.

The rules are as follows:
* Your creation must be 100% text based and make some use of not only NORMAL text characters in the gameplay but also some sort of INVERSE or FLASHing characters in the gameplay as well (not just in the instructions, intro screen, messages, etc.)
* 40 or 80 columns are acceptable
* You can use MouseText but I would advise caution here as not all Apple II models have them and may not have the version of MouseText you want
* Programs can be written in Applesoft or Assembler (or compiled) and be any size you'd like, but they must run under DOS 3.3
* Third party music or sound libraries may be used so long as the content playing is of your own creation
* No use of hi-res character generators are permitted
* Post your original submissions to this group (not this posting) no later than March 30th, 2021

The first prize for this exhibition is going to be $150 USD (to be received in the form of either a gift card, electronic payment, or a donation made in your name. Sorry, I'm not sending any more $100 bills in the mail. LOL)
Please post any questions you have to this post.
Good luck and have fun, everyone!
