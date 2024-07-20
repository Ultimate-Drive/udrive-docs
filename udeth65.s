;
; Copyright (c) 2024, Phillip Allison
; All rights reserved. 
;
; Redistribution and use in source and binary forms, with or without 
; modification, are permitted provided that the following conditions 
; are met: 
; 1. Redistributions of source code must retain the above copyright 
;    notice, this list of conditions and the following disclaimer. 
; 2. Redistributions in binary form must reproduce the above copyright 
;    notice, this list of conditions and the following disclaimer in the 
;    documentation and/or other materials provided with the distribution. 
; 3. Neither the name of the Institute nor the names of its contributors 
;    may be used to endorse or promote products derived from this software 
;    without specific prior written permission. 
;
; THIS SOFTWARE IS PROVIDED BY THE INSTITUTE AND CONTRIBUTORS ``AS IS'' AND 
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
; ARE DISCLAIMED.  IN NO EVENT SHALL THE INSTITUTE OR CONTRIBUTORS BE LIABLE 
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS 
; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
; SUCH DAMAGE. 
;
; This file is part of the Contiki operating system.
; 
; Author: Phillip Allison  <ultimatedrive@apple2email.com>
;
UDROMSignOfs		:= $EC	;				"UltimateDrive"
UDROMVerOfs		:= $F9	;				MAX/MIN

UDIOExec		:= $C080 ;				Write
UDIOStatus		:= $C081 ;				Read
UDIOCmd			:= $C082 ;				Write
UDIOCmdNetOpen	    	:= $70 ;
UDIOCmdNetClose	    	:= $71 ;
UDIOCmdNetSend	    	:= $72 ;
UDIOCmdNetRcvd	    	:= $73 ;
UDIOCmdNetPeek	    	:= $74 ;
UDIOCmdNetStatus    	:= $75 ;
UDIOCmdNetSDMA      	:= $76 ;	 			Send Frame Via DMA
UDIOCmdNetRDMA      	:= $77 ;				Read Frame via DMA
UDIOUnitNum		:= $C083 ;				Write
UDIOMemPtrL		:= $C084 ;
UDIOMemPtrH		:= $C085 ;
UDIOBlockNum		:= $C086 ;				Write 4 bytes, BE
UDIORData		:= $C087 ;				Read
UDIOWData		:= $C088 ;				Write
UDIODoDMA		:= $C089 ;				Write
UDIOMode		:= $C08D ;				Read NZ = DMA, Write b7





;---------------------------------------------------------------------

	.macpack	module
	module_header	_udeth

	; Driver signature
	.byte	$65, $74, $68	; "eth"
	.byte	$01		; Ethernet driver API version number

	; Ethernet address
mac:	.byte	$00, $00, $00, $00, $00, $00,	; received from Udrive
	
	; Buffer attributes
bufaddr:.res	2		; Address
bufsize:.res	2		; Size

	; Jump table.
		jmp init
		jmp poll
		jmp send
		jmp exit

;---------------------------------------------------------------------

	.if DYN_DRV

	.zeropage
sp:		.res	2		; Stack pointer (Do not trash !)
reg:	.res	2		; Pointer Register content
csx:    .res    1       ; Device Slot Storage
ptr:	.res	2		; Indirect addressing pointer
len:	.res	2		; Data length
tpa:    .res    2       ; Temp A
tpb:    .res    2       ; Tempb
	.else

	.include "zeropage.inc"
reg	:=	ptr1		; Pointer Register content
csx :=  ptr2        ; Device Slot Storage
ptr	:=	ptr3		; Indirect addressing pointer
len	:=	ptr4		; Data length
tpa :=  tmp1        ; Temp A
tpb :=  tmp2        ; Temp B

	.endif
.define ROMSIG:	 "UltimateDrive"
ROMSIGL:		:= *-ROMSIG
;=====================================================================

	.ifdef __APPLE2__

	.rodata
;---------------------------------------------------------------------

;---------------------------------------------------------------------

	.data

init:
	; Convert slot number to slot I/O offset
Detect:		
			lda #UDROMSignOfs
			sta tpa
            lda #$C7
.1:			sta tpa+1
			ldy #ROMSIGL-1
.10:		lda (tpa),y
			cmp ROMSIG,y
			beq	.2
			lda tpa+1
			dec
			cmp #$C0
			bne .1
			lda #$21 ; bad file
			sec
.99			rts
.2:			dey
			bpl .10 ; Still matching RomSig
*--------------------------------------
.3			asl ; We found a Udrive Lets store the card slot
            asl
            asl
            asl
            sta csx ; ($C7 becomes $C|7 << 4 == $70)
			jsr sendinit
            beq .9
            jmp GETMAC ; Store Mac Address in 'mac'
.9			rts ; Wee... Init / Open is done! We are in MACRAW mode
	.endif

;=====================================================================


sendinit:
    		lda #UDIOCmdNetOpen ; Open Command
    		jmp IOExecA ; rts performed by the called routine

;---------------------------------------------------------------------

poll:
			lda #$UDIOCmdNetPeek
    		jsr IOExecA
    		lda UDIORData,x 
			sta	len
			lda UDIORData,x 
    		sta len+1
			ora len
			bne ispacket
nopacket:
			lda #$00	; register no packet
			tax
			sec
			rts

ispacket:
; Is bufsize < length ?
			lda bufsize
			cmp len
			lda bufsize+1
			sbc len+1
			bcc nopacket   ; this should not happen....

recvpacket:
			lda bufaddr
			sta ptr
    		sta UDIOMemPtrL,x
			lda bufaddr+1
			sta ptr+1
    		sta UDIOMemPtrH,x
			jsr rdlng

quitpkt:
			lda len
			ldx len+1
			clc
			rts


;---------------------------------------------------------------------

send:
	        ; Save data length
	        sta len
	        stx len+1
			ldx csx
	        cmp UDIOStatus,x ; Reset Write Buffer
	        sta UDIOWData,x	; write length to UD Buffer
	        lda len+1
	        sta UDIOWData,x    ; MSB of len 
	        lda bufaddr
	        sta ptr
	        lda bufaddr+1
	        sta ptr+1
	        jsr wrlng	; send the packet
.w:	        lda UDIOStatus,x
			bmi .w
			lsr	; CS if error, A = ERROR CODE ?
exit:		rts
GETMAC:
            ldy #0
.1:
            lda UDIORData,X
            sta mac,y
            iny
            cpy #$6
            bne .1
            rts 

IOExecA:		
            ldx csx
            sta UDIOCmd,x
IOExec:			
                
			lda UDIOExec,x

.1			lda UDIOStatus,x
			bmi .1
			lsr	; CS if error, A = ERROR CODE ?
			rts
;---------------------------------------------------------------------
; Write data to the Udrive (256 bytes or less)

wrtpg:      sta tmp
            ldy #0
wrtpg2:     lda (ptr),y    ; get a byte
            sta UDIOWData,x     ; send it to the Udrive
	        iny	               ; increment to next byte              
                dec     tmp
	        bne	wrtpg2         ; keep copying while tmp > 0
	        rts
;--------------------------------------------------------------------
; Write data to the Udrive in Polling Mode (len number of bytes)
wrlng:
		ldx csx
	        lda ptr+1          ; save ptr+1
	        pha
	        lda len+1
	        pha
	        beq wrlng3
wrlng2:lda #0
	        jsr wrtpg
	        inc ptr+1          ; increment to next page
	        dec len+1          ; decrease count by 256 bytes
	        bne wrlng2
wrlng3:     lda len
	        beq wrlng4
	        jsr wrtpg
wrlng4:
            lda #UDIOCmdNetSend
            jsr IOExecA
            pla
	        sta len+1
	        pla
	        sta ptr+1
	        rts
;---------------------------------------------------------------------
; Read data from the Udrive (256 bytes or less)
rdpg:   

            sta tmp
            ldy #0
.1:
            lda UDIORData,x         ; get the byte
	        sta (ptr),y
	        iny
	        dec tmp
	        bne .1
	        rts

;--------------------------------------------------------------------
; Read data from the Udrive in Polling mode (len number of bytes)
rdlng:
            lda #UDIOCmdNetRcvd
		jsr IOExecA
	        lda ptr+1          ; save ptr+1
	        pha
	        lda len+1
	        pha
	        beq rdlng3
rdlng2:	
            lda #0
	        jsr rdpg
	        inc ptr+1          ; increment to next page
	        dec len+1          ; decrease count by 256 bytes
	        bne rdlng2
rdlng3: 
            lda len
	        beq rdlng4
	        jsr rdpg
rdlng4: 
            pla
	        sta len+1
	        pla
	        sta ptr+1
	        rts

;---------------------------------------------------------------------
