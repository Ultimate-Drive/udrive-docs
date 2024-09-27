---
title: "Installation"
weight: 1
---
## Installation

Before you install the UltimateDrive, ensure that your Apple II system is powered off. 

Choose an available expansion slot and insert the card using even pressure on both ends to avoid inserting it at an angle. 

Make sure that the card is positioned so the MicroSD card slot is facing the front of the computer.
![Image showing the card with arrows indicating the longer side (with the sdcard slot) oriented to the front of the Apple 2 with the short / networking side oriented to the back of the case.](/udrive-docs//img/cardinstall00.png)

### Slots and Disk II support

We offer a _Disk II Virtual Card_ which can be put in any slot in Apple II, Apple II+, Apple IIe, and Apple IIgs machines, EXCEPT slot 3 if there is an 80 column card present. 

The actual slot MUST NOT be occupied by another card, but the device will failsafe to no virtual card if another card responds to the assigned virtual card's Slot IO / ROM.

### Slots and the Apple IIgs

The Apple IIgs has a number of built-in devices which use virtual slots.  These are configured in the Apple IIgs Control Panel.

To make sure your slot is configured correctly for UltimateDrive, enter the Control Panel with the keypress combination `OpenApple-Ctrl-Esc`.  

Then navigate to _Control Panel -> Slots_ and verify the slot you are using is set to "Your Card". 
![The Apple IIgs Control Panel showing the Slots configuration](/udrive-docs//img/iigs-control-panel-slots.png)

NOTE: This may need to be done for Virtual Disk II slot as well??? @todo

### MicroSD card setup
UltimateDrive is designed for UHS-1 or better SDHC/SDXC cards.

Format your card with a FAT filesystem like FAT32 or exFAT



{{< section  >}}