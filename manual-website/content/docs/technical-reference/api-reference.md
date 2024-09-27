---
title: "API Reference"
weight: 2
---
## API Reference

The interface for calling the API from the Apple II side is quite simple. 

There are calls without data and calls with data.

### Calling the API

To execute a call without data you simply:
- store the command number in the `IO_Cmd` offset location for your card's slot
- trigger it by reading the `IO_Exec` offset location for your card's slot
- wait for completion by checking bit 7 of the `IO_Status` offset location for your card's slot

Those three locations are:
```
IO_Exec         =     $C080
IO_Status       =     $C081
IO_Cmd          =     $C082
```
And the slot offset is the _slot number*16_.

So if you have a card in slot 5, the offset is 5*16, which is 80 in decimal or $50 in hexidecimal. 

That means you would call IO_Exec by doing a load like ` lda $C0D0`.

However, most programmers will store the _slot number*16_ in a variable and use `lda {cmd},x`.

Example:
```
IO_CMD_MoAll    =  $2B              ; Mount All Images
Slot_n0         db $50              ; Hardcoding slot 5 for demonstration purposes

                ...

                lda   #IO_Cmd_MoAll ; ($2B)
                ldx   Slot_n0
                stal  IO_Cmd,x      ; set our command
                ldal  IO_Exec,x     ; start!
:wait           ldal  IO_Status,x   ; waitloop
                bmi   :wait
                lsr                 ; CS if error, A = ERROR CODE 
                rts
```

@todo add data example


### API Command Reference

| Command Name     | Number | Description |
| ---------------- | ------ | ---------------------------------------------------------------------------------------------------------- |
|`IO_CMD_GetCD`    | `$22`  | DiskBuffer holds the PWD, UnitNum is for which drive, 00 terminated, Floppy 1 and 2 are image #$21 and $22 |
|`IO_CMD_SetCD`    | `$23`  | DiskBuffer sets the PWD, UnitNum is for which drive, 00 terminated, Floppy 1 and 2 are image #$21 and $22  |
|`IO_CMD_GetFile`  | `$26`  | returns the filename of UnitNum in DiskBuffer, Floppies are $21 and $22                                    |
|`IO_CMD_SetFile`  | `$27`  | sets the filename of UnitNum in DiskBuffer, Floppies are $21 and $22                                       |
|`IO_CMD_UMount`   | `$28`  | Unmounts Image at UnitNum                                                                                  |
|`IO_CMD_Mount`    | `$29`  | Mounts Image at UnitNum                                                                                    |
|`IO_CMD_UMoAll`   | `$2A`  | Unmount All Images                                                                                         |
|`IO_CMD_MoAll`    | `$2B`  | Mount All Images                                                                                           |
|`IO_CMD_GetMounts`| `$2C`  | Get Mount Configuration last saved to SDCard                                                               |
|`IO_CMD_SetMounts`| `$2D`  | Saves Mount Configuration to SDCard for Next Reboot                                                        |
|`IO_CMD_Reboot`   | `$2F`  | Reboots card, This will force reset low on Apple II Bus No StatCode                                        |
|`IO_Cmd_Menu`     | `$60`  |  Download BIN at $2000                                                                                     |
|`IO_Cmd_SvBnk20`  | `$61`  |  Saves Bank $00/20 to temp file on SDCard                                                                  |
|`IO_Cmd_RsBnk20`  | `$62`  |  Restore Bank $00/20 from temp file on SDCard                                                              |
|`IO_Cmd_SaveBuff` | `$63`  |  Saves Buffer for $00/20 bank if DMA is impossible                                                         |