;
; Reciter
; Text to phoneme for the Apple II
; Requires SAM to be loaded
;
; Disassembly by Robert Justice 01-Jun-2016
;
;
; macro to set the most significant bit on for ascii strings and off for the last char
            .macro     asciiset s
            .repeat    .strlen(s)-1, i
            .byte      .strat(s,i) | $80
            .endrepeat
			.byte      .strat(s,.strlen(s)-1)
            .endmacro
;
; Code equates
;
L00F5       = $00F5
L00F6       = $00F6
L00F7       = $00F7
L00F8       = $00F8
L00F9       = $00F9
L00FA       = $00FA
L00FB       = $00FB
L00FC       = $00FC
L00FD       = $00FD
L00FE       = $00FE
L00FF       = $00FF
SAVEZERO    = $8649     ; in SAM
FINDVAR     = $93B9     ; in SAM
SAMML       = $940E     ; in SAM
INPUTSTR    = $9500     ; input buffer
LFF3A       = $FF3A     ; Bell routine in Apple monitor
;
; Start of code
;
            .org $58A1
;
;Character flags
;bit7 = Character from A-Z
;bit6 =
;bit5
;bit4
;bit3
;bit2
;bit1
;bit0 = number from 0 - 9
; all zero = invalid char

CHRFLAGS:   .byte %00000000    ;NUL
            .byte %00000000    ;SOH
            .byte %00000000    ;STX
            .byte %00000000    ;ETX
            .byte %00000000    ;EOT
            .byte %00000000    ;ENQ
            .byte %00000000    ;ACK
            .byte %00000000    ;BEL
            .byte %00000000    ;BS
            .byte %00000000    ;TAB
            .byte %00000000    ;LF
            .byte %00000000    ;VT
            .byte %00000000    ;FF
            .byte %00000000    ;CR
            .byte %00000000    ;SO
            .byte %00000000    ;SI
            .byte %00000000    ;DLE
            .byte %00000000    ;DC1
            .byte %00000000    ;DC2
            .byte %00000000    ;DC3
            .byte %00000000    ;DC4
            .byte %00000000    ;NAK
            .byte %00000000    ;SYN
            .byte %00000000    ;ETB
            .byte %00000000    ;CAN
            .byte %00000000    ;EM
            .byte %00000000    ;SUB
            .byte %00000000    ;ESC
            .byte %00000000    ;FS
            .byte %00000000    ;GS
            .byte %00000000    ;RS
            .byte %00000000    ;US
            .byte %00000000    ;(space)
            .byte %00000010    ;!
            .byte %00000010    ;"
            .byte %00000010    ;#
            .byte %00000010    ;$
            .byte %00000010    ;%
            .byte %00000010    ;&
            .byte %10000010    ;'
            .byte %00000000    ;(
            .byte %00000000    ;)
            .byte %00000010    ;*
            .byte %00000010    ;+
            .byte %00000010    ;,
            .byte %00000010    ;-
            .byte %00000010    ;.
            .byte %00000010    ;/
            .byte %00000011    ;0
            .byte %00000011    ;1
            .byte %00000011    ;2
            .byte %00000011    ;3
            .byte %00000011    ;4
            .byte %00000011    ;5
            .byte %00000011    ;6
            .byte %00000011    ;7
            .byte %00000011    ;8
            .byte %00000011    ;9
            .byte %00000010    ;:
            .byte %00000010    ;;
            .byte %00000010    ;<
            .byte %00000010    ;=
            .byte %00000010    ;>
            .byte %00000010    ;?
            .byte %00000010    ;@
            .byte %11000000    ;A
            .byte %10101000    ;B
            .byte %10110000    ;C
            .byte %10101100    ;D
            .byte %11000000    ;E
            .byte %10100000    ;F
            .byte %10111000    ;G
            .byte %10100000    ;H
            .byte %11000000    ;I
            .byte %10111100    ;J
            .byte %10100000    ;K
            .byte %10101100    ;L
            .byte %10101000    ;M
            .byte %10101100    ;N
            .byte %11000000    ;O
            .byte %10100000    ;P
            .byte %10100000    ;Q
            .byte %10101100    ;R
            .byte %10110100    ;S
            .byte %10100100    ;T
            .byte %11000000    ;U
            .byte %10101000    ;V
            .byte %10101000    ;W
            .byte %10110000    ;X
            .byte %11000000    ;Y
            .byte %10111100    ;Z
            .byte %00000000    ;[
            .byte %00000000    ;\
            .byte %00000000    ;]
            .byte %00000010    ;^
            .byte %00000000    ;_

RECTBUFF:   .res $100
;
;Reciter Applesoft entry
;
RECTAPPS:   jsr SAVEZERO     ;save zero page locations, in SAM
            jsr FINDVAR      ;find $SA variable and copy to input buffer, in SAM
RECTML2:    lda #$A0         ;' ' space char
            sta RECTBUFF     ;store in first char of reciter buffer
            ldx #$01
            ldy #$00
L5A10:      lda INPUTSTR,Y   ;copy input buffer to reciter buffer
            sta RECTBUFF,X
            inx
            iny
            cpy #$FF
            bne L5A10
            jsr L5A23        ;process input string
L5A1F:      jsr SAMML        ;Go say it, SAM machine language entry
            rts
;
; Translate the text to phonemes
;			
L5A23:      lda #$FF
            sta L00FA        ;input string index
L5A27:      lda #$FF
            sta L00F5        ;output string index
L5A2B:      inc L00FA
            ldx L00FA
            lda RECTBUFF,X   ;get char
            sta L00FD
            cmp #$8D         ;cmp to CR
            bne L5A40        ;no continue
            inc L00F5        ;yes
            ldx L00F5
            sta INPUTSTR,X   ;store CR in output string
            rts              ;all done

L5A40:      cmp #$AE         ;is it '.'
            bne L5A5E
            inx              ;yes
            lda RECTBUFF,X   ;get next char
            and #$7F         ;mask of high bit
            tay
            lda CHRFLAGS,Y   ;get flags for this char?
            and #$01         ;check flag bit 0
            bne L5A5E        ;not set continue processing
            inc L00F5        ;yes
            ldx L00F5
            lda #$AE         ;'.' 
            sta INPUTSTR,X   ;store in output string
            jmp L5A2B        ;continue with next char

L5A5E:      lda L00FD        ;load current char
            and #$7F         ;mask of high bit
            tay
            lda CHRFLAGS,Y   ;get flags for this char?
            sta L00F6
            and #$02         ;check flag bit 1
            beq L5A77        ;
            lda #<RULES      ;setup pointer to rules  #$6A
            sta L00FB        ;16bit pointer is in FB FC
            lda #>RULES      ;                        #$5E
            sta L00FC
            jmp L5ABB        ;parse rule

L5A77:      lda L00F6        ;load from temp charflag
            bne L5AA4        ;if flag 0, invalid char
            lda #$A0         ;replace with ascii ' '
            sta RECTBUFF,X
            inc L00F5
            ldx L00F5
            cpx #$78          ;max string length?
            bcs L5A8F
            sta INPUTSTR,X
            jmp L5A2B
			
L5A8E:      .res 1,$B1

L5A8F:      lda #$8D         ;CR
            sta INPUTSTR,X
			lda L00FA
            sta L5A8E
            jsr L5A1F
            lda L5A8E
            sta L00FA
            jmp L5A27
L5AA4:      lda L00F6        ;load from temp charflag
            and #$80         ;check bit 7
            bne L5AAB        ;yes set, so is char from A-Z
            .byte $00        ;BRK - error, to do

L5AAB:      lda L00FD        ;load current char
            sec
            sbc #$C1         ;subtract char 'A', this gives us an index from 0
            tax              ;for each letter of the alphabet
            lda L5DF5,X      ;get the rules table low byte address for that letter
            sta L00FB        ;store in the lookup pointer - low byte
            lda L5E0F,X      ;get the rules table high byte address for that letter
            sta L00FC        ;store in the lookup pointer - high byte
;
; parse rule
;			
L5ABB:      ldy #$00
L5ABD:      clc              ;inc 16bit rules pointer
            lda L00FB        ;in FB/FC
            adc #$01
            sta L00FB
            lda L00FC
            adc #$00
            sta L00FC
            lda (L00FB),Y    ;load char from rules
            bmi L5ABD        ;check if last char of rule (msb)
            iny              ;MSB not set, inc and we are at the start of a rule
L5ACF:      lda (L00FB),Y
            cmp #$A8         ;check if '('
            beq L5AD9        ;yes
            iny
            jmp L5ACF
L5AD9:      sty L00FF        ;index to ( in FF
L5ADB:      iny
            lda (L00FB),Y
            cmp #$A9         ;check if ')'
            bne L5ADB
            sty L00FE        ;index to ) in FE
L5AE4:      iny
            lda (L00FB),Y
            ora #$80         ;set MSB
            cmp #$BD         ;'='
            bne L5AE4
            sty L00FD        ;index to '=' in FD
            ldx L00FA        ;current index to input char in FA?
            stx L00F9
            ldy L00FF
            iny
L5AF6:      lda RECTBUFF,X   ;current char in input
            sta L00F6
            lda (L00FB),Y    ;get char of current rule
            cmp L00F6        ;is it match
            beq L5B04        ;yes
            jmp L5ABB        ;no, next rule
;
L5B04:      iny
            cpy L00FE        ;check against ) position
            bne L5B0C        ;no
            jmp L5B12        ;yes, all matched up to )
L5B0C:      inx
            stx L00F9
            jmp L5AF6        ;check next
L5B12:      lda L00FA
            sta L00F8
L5B16:      ldy L00FF
            dey
            sty L00FF
            lda (L00FB),Y
            sta L00F6
            bmi L5B24        ;is it last char of rule
            jmp L5CB9        ;yes

L5B24:      and #$7F         ;no
            tax
            lda CHRFLAGS,X   ; check bit 7
            and #$80
            beq L5B40
            ldx L00F8
            dex
            lda RECTBUFF,X
            cmp L00F6
            beq L5B3B
            jmp L5ABB
L5B3B:      stx L00F8
            jmp L5B16
            
L5B40:      lda L00F6
            cmp #$A0       ;' '
            bne L5B49
            jmp L5B84
L5B49:      cmp #$A3       ;'#'
            bne L5B50
            jmp L5B93
L5B50:      cmp #$AE       ;'.'
            bne L5B57
            jmp L5B9D
L5B57:      cmp #$A6       ;'&'
            bne L5B5E
            jmp L5BAC
L5B5E:      cmp #$C0       ;'@'
            bne L5B65
            jmp L5BCC
L5B65:      cmp #$DE       ;'^'
            bne L5B6C
            jmp L5BF1
L5B6C:      cmp #$AB       ;'+'
            bne L5B73
            jmp L5C00
L5B73:      cmp #$BA       ;':'
            bne L5B7A
            jmp L5C15
L5B7A:      jsr LFF3A         ;bell
            jsr LFF3A
            jsr LFF3A
            .byte $00         ;BRK
L5B84:      jsr L5C24
            and #$80
            beq L5B8E
            jmp L5ABB
L5B8E:      stx L00F8
            jmp L5B16
L5B93:      jsr L5C24
            and #$40
            bne L5B8E
            jmp L5ABB
L5B9D:      jsr L5C24
            and #$08
            bne L5BA7
            jmp L5ABB
L5BA7:      stx L00F8
            jmp L5B16
L5BAC:      jsr L5C24
            and #$10
            bne L5BA7
            lda RECTBUFF,X
            cmp #$C8            ;'H'
            beq L5BBD     
            jmp L5ABB     
L5BBD:      dex           
            lda RECTBUFF,X
            cmp #$C3            ;'C'
            beq L5BA7     
            cmp #$D3            ;'S'
            beq L5BA7     
            jmp L5ABB     
L5BCC:      jsr L5C24     
            and #$04      
            bne L5BA7     
            lda RECTBUFF,X
            cmp #$C8            ;'H'
            beq L5BDD     
            jmp L5ABB     
L5BDD:      cmp #$D4            ;'T'
            beq L5BEC     
            cmp #$C3            ;'C'
            beq L5BEC     
            cmp #$D3            ;'S'
            beq L5BEC
            jmp L5ABB
L5BEC:      stx L00F8
            jmp L5B16
L5BF1:      jsr L5C24
            and #$20
            bne L5BFB
            jmp L5ABB
L5BFB:      stx L00F8
            jmp L5B16
L5C00:      ldx L00F8
            dex
            lda RECTBUFF,X
            cmp #$C5             ;'E'
            beq L5BFB     
            cmp #$C9             ;'I'
            beq L5BFB     
L5C0E:      cmp #$D9             ;'Y'
            beq L5BFB
            jmp L5ABB
L5C15:      jsr L5C24
            and #$20
            bne L5C1F
            jmp L5B16
L5C1F:      stx L00F8
            jmp L5C15
L5C24:      ldx L00F8
            dex
            lda RECTBUFF,X
            and #$7F
            tay
            lda CHRFLAGS,Y
            rts
			
;"COPYRIGHT 1982 DON" (high bit set)
            .byte $C3,$CF,$D0,$D9,$D2,$C9,$C7,$C8
            .byte $D4,$A0,$B1,$B9,$B8,$B2,$A0,$C4
            .byte $CF,$CE
;
; get flags
;			
L5C43:      ldx L00F7
            inx
            lda RECTBUFF,X
            and #$7F
            tay
            lda CHRFLAGS,Y
            rts

L5C50:      ldx L00F7         ;is a '%'
            inx
            lda RECTBUFF,X
            cmp #$C5          ;'E'
            bne L5CA2
            inx
            lda RECTBUFF,X
            and #$7F
            tay
            dex
            lda CHRFLAGS,Y
            and #$80
            beq L5C71
            inx
            lda RECTBUFF,X
            cmp #$D2          ;'R'
            bne L5C76
L5C71:      stx L00F7
            jmp L5CBD
L5C76:      cmp #$D3          ;'S'
            beq L5C71      
            cmp #$C4          ;'D'
            beq L5C71      
            cmp #$CC          ;'L'
            bne L5C8C      
            inx            
            lda RECTBUFF,X 
            cmp #$D9          ;'Y'
            bne L5CB6      
            beq L5C71      
L5C8C:      cmp #$C6          ;'F'
            bne L5CB6      
            inx            
            lda RECTBUFF,X 
            cmp #$D5          ;'U'
            bne L5CB6      
            inx            
            lda RECTBUFF,X 
            cmp #$CC          ;'L'
            beq L5C71      
            bne L5CB6      
L5CA2:      cmp #$C9          ;'I'
            bne L5CB6      
            inx            
            lda RECTBUFF,X 
            cmp #$CE          ;'N'
            bne L5CB6      
            inx            
            lda RECTBUFF,X 
            cmp #$C7          ;'G'
            beq L5C71
L5CB6:      jmp L5ABB
;
;matching rule?
;
L5CB9:      lda L00F9
            sta L00F7
L5CBD:      ldy L00FE
            iny
            cpy L00FD
            bne L5CC7
            jmp L5DD4
L5CC7:      sty L00FE
            lda (L00FB),Y
            sta L00F6
            and #$7F
            tax
            lda CHRFLAGS,X
            and #$80            ;check flag bit7
            beq L5CE9
            ldx L00F7
            inx
            lda RECTBUFF,X
            cmp L00F6
            beq L5CE4
            jmp L5ABB
L5CE4:      stx L00F7
            jmp L5CBD
L5CE9:      lda L00F6
            cmp #$A0      ;' '
            bne L5CF2
            jmp L5D34
L5CF2:      cmp #$A3      ;'#'
            bne L5CF9
            jmp L5D43
L5CF9:      cmp #$AE      ;'.'
            bne L5D00
            jmp L5D4D
L5D00:      cmp #$A6      ;'&'
            bne L5D07
            jmp L5D5C
L5D07:      cmp #$C0      ;'@'
            bne L5D0E
            jmp L5D7C
L5D0E:      cmp #$DE      ;'^'
            bne L5D15
            jmp L5DA1
L5D15:      cmp #$AB      ;'+'
            bne L5D1C
            jmp L5DB0
L5D1C:      cmp #$BA      ;':'
            bne L5D23
            jmp L5DC5
L5D23:      cmp #$A5      ;'%'
            bne L5D2A
            jmp L5C50
L5D2A:      jsr LFF3A     ;monitor bell routine
            jsr LFF3A
            jsr LFF3A
            .byte $00     ;BRK
;
;char is a ' '            
L5D34:      jsr L5C43     ;get char flags
            and #$80      ;check flag bit7
            beq L5D3E
            jmp L5ABB     ;check next rule
L5D3E:      stx L00F7
            jmp L5CBD
;char is a '#'
L5D43:      jsr L5C43     ;get char flags
            and #$40
            bne L5D3E
            jmp L5ABB     ;check next rule
;char is a '.'
L5D4D:      jsr L5C43     ;get char flags
            and #$08
            bne L5D57
            jmp L5ABB     ;check next rule
L5D57:      stx L00F7
            jmp L5CBD
;char is a '&'            
L5D5C:      jsr L5C43     ;get char flags
            and #$10
            bne L5D57
            lda RECTBUFF,X
            cmp #$C8      ;'H'
            beq L5D6D
            jmp L5ABB     ;check next rule
L5D6D:      inx
            lda RECTBUFF,X
            cmp #$C3
            beq L5D57
            cmp #$D3
            beq L5D57
            jmp L5ABB

L5D7C:      jsr L5C43     ;is a '@'
            and #$04
            bne L5D57
            lda RECTBUFF,X
            cmp #$C8      ;'H'
            beq L5D8D
            jmp L5ABB     ;check next rule
L5D8D:      cmp #$D4      ;'T'
            beq L5D9C
            cmp #$C3      ;'C'
            beq L5D9C
            cmp #$D3      ;'S'
            beq L5D9C
            jmp L5ABB     ;check next rule
L5D9C:      stx L00F7
            jmp L5CBD
;
;char is a '^'
L5DA1:      jsr L5C43     ;get char flags
            and #$20
            bne L5DAB
            jmp L5ABB     ;check next rule
L5DAB:      stx L00F7
            jmp L5CBD
;
;char is a '+'
L5DB0:      ldx L00F7  
            inx
            lda RECTBUFF,X
            cmp #$C5
            beq L5DAB
            cmp #$C9
            beq L5DAB
            cmp #$D9
            beq L5DAB
            jmp L5ABB     ;check next rule
;
;char is a ';'           
L5DC5:      jsr L5C43      ;get char flags
            and #$20
            bne L5DCF
            jmp L5CBD
L5DCF:      stx L00F7
            jmp L5DC5

L5DD4:      ldy L00FD
            lda L00F9
            sta L00FA
L5DDA:      lda (L00FB),Y
            sta L00F6
            ora #$80
            cmp #$BD       ;'="
            beq L5DEB
            inc L00F5
            ldx L00F5
            sta INPUTSTR,X
L5DEB:      bit L00F6
            bmi L5DF2
            jmp L5A2B
L5DF2:      iny
            bne L5DDA    ; assume y is never zero?

;lookup table to optimse rule table start point
;address of position in table for rule start 
;characters A to Z
;low byte
L5DF5:      .byte <RULESA
            .byte <RULESB
            .byte <RULESC
            .byte <RULESD
            .byte <RULESE
            .byte <RULESF
            .byte <RULESG
            .byte <RULESH
            .byte <RULESI
            .byte <RULESJ
            .byte <RULESK
            .byte <RULESL
            .byte <RULESM
            .byte <RULESN
            .byte <RULESO
            .byte <RULESP
            .byte <RULESQ
            .byte <RULESR
            .byte <RULESS
            .byte <RULEST
            .byte <RULESU
            .byte <RULESV
            .byte <RULESW
            .byte <RULESX
            .byte <RULESY
            .byte <RULESZ
;high byte			
L5E0F:      .byte >RULESA
            .byte >RULESB
            .byte >RULESC
            .byte >RULESD
            .byte >RULESE
            .byte >RULESF
            .byte >RULESG
            .byte >RULESH
            .byte >RULESI
            .byte >RULESJ
            .byte >RULESK
            .byte >RULESL
            .byte >RULESM
            .byte >RULESN
            .byte >RULESO
            .byte >RULESP
            .byte >RULESQ
            .byte >RULESR
            .byte >RULESS
            .byte >RULEST
            .byte >RULESU
            .byte >RULESV
            .byte >RULESW
            .byte >RULESX
            .byte >RULESY
            .byte >RULESZ
;
;
; Reciter Machine Language entry
;
RECTML:		jsr SAVEZERO
            jmp RECTML2

			.res 59     ;padding?
			
RULES:
            asciiset "(A)="                   ;this is a dummy rule that is not used
            asciiset "(!)=."
;            asciiset "(") =-AH5NKWOWT- "
;            asciiset "(")=KWOW4T-"
;hack as i can't see to work out how to escape "
            .byte $A8,$A2
            asciiset ") =-AH5NKWOWT- "
            .byte $A8,$A2
            asciiset ")=KWOW4T-"
            asciiset "(#)= NAH4MBER"
            asciiset "($)= DAA4LER"
            asciiset "(%)= PERSEH4NT"
            asciiset "(&)= AEND"
            asciiset "(')="
            asciiset "(*)= AE4STERIHSK"
            asciiset "(+)= PLAH4S"
            asciiset "(,)=,"
            asciiset " (-) =-"
            asciiset "(-)="
            asciiset "(.)= POYNT"
            asciiset "(/)= SLAE4SH"
            asciiset "(0)= ZIY4ROW"
            asciiset " (1ST)=FER4ST"
            asciiset " (10TH)=TEH4NTH"
            asciiset "(1)= WAH4N"
            asciiset " (2ND)=SEH4KUND"
            asciiset "(2)= TUW4"
            asciiset " (3RD)=THER4D"
            asciiset "(3)= THRIY4"
            asciiset "(4)= FOH4R"
            asciiset " (5TH)=FIH4FTH"
            asciiset "(5)= FAY4V"
            asciiset "(6)= SIH4KS"
            asciiset "(7)= SEH4VUN"
            asciiset " (8TH)=EY4TH"
            asciiset "(8)= EY4T"
            asciiset "(9)= NAY4N"
            asciiset "(:)=. "
            asciiset "(;)=."
            asciiset "(<)= LEH4S DHAEN"
            asciiset "(=)= IY4KWULZ"
            asciiset "(>)= GREY4TER DHAEN"
            asciiset "(?)=."
            asciiset "(@)= AE6T"
            asciiset "(^)= KAE4RIXT"
RULESA:     asciiset "]A"               ;the start rule for each letter is not used
            asciiset " (A.)=EH4Y. "
            asciiset "(A) =AH "
            asciiset " (ARE) =AAR"
            asciiset " (AR)O=AXR"
            asciiset "(AR)#=EH4R "
            asciiset " ^(AS)#=EY4S"
            asciiset "(A)WA=AX"
            asciiset "(AW)=AO5 "
            asciiset " :(ANY)=EH4NIY"
            asciiset "(A)^+#=EY5 "
            asciiset "#:(ALLY)=ULIY"
            asciiset " (AL)#=UL"
            asciiset "(AGAIN)=AXGEH4N"
            asciiset "#:(AG)E=IHJ"
            asciiset "(A)^%=EY"
            asciiset "(A)^+:#=AE"
            asciiset " :(A)^+ =EY4 "
            asciiset " (ARR)=AXR"
            asciiset "(ARR)=AE4R"
            asciiset " ^(AR) =AA5R"
            asciiset "(AR)=AA5R"
            asciiset "(AIR)=EH4R"
            asciiset "(AI)=EY4 "
            asciiset "(AY)=EY5 "
            asciiset "(AU)=AO4 "
            asciiset "#:(AL) =UL"
            asciiset "#:(ALS) =ULZ"
            asciiset "(ALK)=AO4K"
            asciiset "(AL)^=AOL"
            asciiset " :(ABLE)=EY4BUL"
            asciiset "(ABLE)=AXBUL"
            asciiset "(A)VO=EY4"
            asciiset "(ANG)+=EY4NJ"
            asciiset "(ATARI)=AHTAA4RIY"
            asciiset "(A)TOM=AE"
            asciiset "(A)TTI=AE"
            asciiset " (AT) =AET"
            asciiset " (A)T=AH"
            asciiset "(A)=AE"
RULESB:     asciiset "]B"
            asciiset " (B) =BIY4"
            asciiset " (BE)^#=BIH"
            asciiset "(BEING)=BIY4IHNX"
            asciiset " (BOTH) =BOW4TH"
            asciiset " (BUS)#=BIH4Z "
            asciiset "(BREAK)=BREY5K"
            asciiset "(BUIL)=BIH4L"
            asciiset "(B)=B"
RULESC:     asciiset "]C"
            asciiset " (C) =SIY4"
            asciiset " (CH)^=K"
            asciiset "^E(CH)=K"
            asciiset "(CHA)R#=KEH5"
            asciiset "(CH)=CH"
            asciiset " S(CI)#=SAY4 "
            asciiset "(CI)A=SH"
            asciiset "(CI)O=SH"
            asciiset "(CI)EN=SH"
            asciiset "(CITY)=SIHTIY"
            asciiset "(C)+=S"
            asciiset "(CK)=K"
            asciiset "(COM)=KAHM"
            asciiset "(CUIT)=KIHT"
            asciiset "(CREA)=KRIYEY"
            asciiset "(C)=K"
RULESD:     asciiset "]D"
            asciiset " (D) =DIY4"
            asciiset " (DR.) =DAA4KTER"
            asciiset "#:(DED) =DIHD"
            asciiset ".E(D) =D"
            asciiset "#:^E(D) =T"
            asciiset " (DE)^#=DIH"
            asciiset " (DO) =DUW"
            asciiset " (DOES)=DAHZ"
            asciiset "(DONE) =DAH5N"
            asciiset "(DOING)=DUW4IHNX"
            asciiset " (DOW)=DAW"
            asciiset "#(DU)A=JUW"
            asciiset "#(DU)^#=JAX "
            asciiset "(D)=D"
RULESE:     asciiset "]E"
            asciiset " (E) =IYIY4"
            asciiset "#:(E) ="
            asciiset "':^(E) ="
            asciiset " :(E) =IY"
            asciiset "#(ED) =D"
            asciiset "#:(E)D ="
            asciiset "(EV)ER=EH4V"
            asciiset "(E)^%=IY4 "
            asciiset "(ERI)#=IY4RIY"
            asciiset "(ERI)=EH4RIH"
            asciiset "#:(ER)#=ER"
            asciiset "(ERROR)=EH4ROHR"
            asciiset "(ERASE)=IHREY5S "
            asciiset "(ER)#=EHR"
            asciiset "(ER)=ER"
            asciiset " (EVEN)=IYVEHN"
            asciiset "#:(E)W="
            asciiset "@(EW)=UW"
            asciiset "(EW)=YUW"
            asciiset "(E)O=IY"
            asciiset "#:&(ES) =IHZ"
            asciiset "#:(E)S ="
            asciiset "#:(ELY) =LIY"
            asciiset "#:(EMENT)=MEHNT"
            asciiset "(EFUL)=FUHL"
            asciiset "(EE)=IY4 "
            asciiset "(EARN)=ER5N"
            asciiset " (EAR)^=ER5 "
            asciiset "(EAD)=EHD"
            asciiset "#:(EA) =IYAX"
            asciiset "(EA)SU=EH5 "
            asciiset "(EA)=IY5 "
            asciiset "(EIGH)=EY4 "
            asciiset "(EI)=IY4 "
            asciiset " (EYE)=AY4 "
            asciiset "(EY)=IY"
            asciiset "(EU)=YUW5 "
            asciiset "(EQUAL)=IY4KWUL"
            asciiset "(E)=EH"
RULESF:     asciiset "]F"
            asciiset " (F) =EH4F"
            asciiset "(FUL)=FUHL"
            asciiset "(FRIEND)=FREH5ND"
            asciiset "(FATHER)=FAA4DHER"
            asciiset "(F)F="
            asciiset "(F)=F"
RULESG:     asciiset "]G"
            asciiset " (G) =JIY4"
            asciiset "(GIV)=GIH5V"
            asciiset " (G)I^=G"
            asciiset "(GE)T=GEH5 "
            asciiset "SU(GGES)=GJEH4S "
            asciiset "(GG)=G"
            asciiset " B#(G)=G"
            asciiset "(G)+=J"
            asciiset "(GREAT)=GREY4T "
            asciiset "(GON)E=GAO5N"
            asciiset "#(GH)="
            asciiset " (GN)=N"
            asciiset "(G)=G"
RULESH:     asciiset "]H"
            asciiset " (H) =EY4CH"
            asciiset " (HAV)=/HAE6V"
            asciiset " (HERE)=/HIYR"
            asciiset " (HOUR)=AW5ER"
            asciiset "(HOW)=/HAW"
            asciiset "(H)#=/H"
            asciiset "(H)="
RULESI:     asciiset "]I"
            asciiset " (IN)=IHN"
            asciiset " (I) =AY4 "
            asciiset "(I) =AY"
            asciiset "(IN)D=AY5N"
            asciiset "SEM(I)=IY "
            asciiset " ANT(I)=AY"
            asciiset "(IER)=IYER"
            asciiset "#:R(IED) =IYD"
            asciiset "(IED) =AY5D"
            asciiset "(IEN)=IYEHN"
            asciiset "(IE)T=AY4EH"
            asciiset "(I')=AY5"
            asciiset " :(I)^%=AY5 "
            asciiset " :(IE) =AY4"
            asciiset "(I)%=IY"
            asciiset "(IE)=IY4 "
            asciiset " (IDEA)=AYDIY5AH"
            asciiset "(I)^+:#=IH"
            asciiset "(IR)#=AYR"
            asciiset "(IZ)%=AYZ"
            asciiset "(IS)%=AYZ"
            asciiset "I^(I)^#=IH"
            asciiset "+^(I)^+=AY "
            asciiset "#:^(I)^+=IH"
            asciiset "(I)^+=AY"
            asciiset "(IR)=ER"
            asciiset "(IGH)=AY4 "
            asciiset "(ILD)=AY5LD "
            asciiset " (IGN)=IHGN"
            asciiset "(IGN) =AY4N"
            asciiset "(IGN)^=AY4N "
            asciiset "(IGN)%=AY4N"
            asciiset "(ICRO)=AY4KROH"
            asciiset "(IQUE)=IY4K"
            asciiset "(I)=IH"
RULESJ:     asciiset "]J"
            asciiset " (J) =JEY4"
            asciiset "(J)=J"
RULESK:     asciiset "]K"
            asciiset " (K) =KEY4"
            asciiset " (K)N="
            asciiset "(K)=K"
RULESL:     asciiset "]L"
            asciiset " (L) =EH4L"
            asciiset "(LO)C#=LOW"
            asciiset "L(L)="
            asciiset "#:^(L)%=UL"
            asciiset "(LEAD)=LIYD"
            asciiset " (LAUGH)=LAE4F"
            asciiset "(L)=L"
RULESM:     asciiset "]M"
            asciiset " (M) =EH4M"
            asciiset " (MR.) =MIH4STER"
            asciiset " (MS.)=MIH5Z"
            asciiset " (MRS.) =MIH4SIXZ"
            asciiset "(MOV)=MUW4V"
            asciiset "(MACHIN)=MAHSHIY5N"
            asciiset "M(M)="
            asciiset "(M)=M"
RULESN:     asciiset "]N"
            asciiset " (N) =EH4N"
            asciiset "E(NG)+=NJ"
            asciiset "(NG)R=NXG"
            asciiset "(NG)#=NXG"
            asciiset "(NGL)%=NXGUL"
            asciiset "(NG)=NX"
            asciiset "(NK)=NXK"
            asciiset " (NOW) =NAW4 "
            asciiset "N(N)="
            asciiset "(NON)E=NAH4N"
            asciiset "(N)=N"
RULESO:     asciiset "]O"
            asciiset " (O) =OH4W"
            asciiset "(OF) =AHV"
            asciiset " (OH) =OW5 "
            asciiset "(OROUGH)=ER4OW"
            asciiset "#:(OR) =ER"
            asciiset "#:(ORS) =ERZ"
            asciiset "(OR)=AOR"
            asciiset " (ONE)=WAHN"
            asciiset "#(ONE) =WAHN"
            asciiset "(OW)=OW"
            asciiset " (OVER)=OW5VER"
            asciiset "PR(O)V=UW4"
            asciiset "(OV)=AH4V"
            asciiset "(O)^%=OW5 "
            asciiset "(O)^EN=OW"
            asciiset "(O)^I#=OW5 "
            asciiset "(OL)D=OW4L"
            asciiset "(OUGHT)=AO5T "
            asciiset "(OUGH)=AH5F"
            asciiset " (OU)=AW"
            asciiset "H(OU)S#=AW4 "
            asciiset "(OUS)=AXS"
            asciiset "(OUR)=OHR"
            asciiset "(OULD)=UH5D "
            asciiset "(OU)^L=AH5 "
            asciiset "(OUP)=UW5P "
            asciiset "(OU)=AW"
            asciiset "(OY)=OY"
            asciiset "(OING)=OW4IHNX"
            asciiset "(OI)=OY5 "
            asciiset "(OOR)=OH5R"
            asciiset "(OOK)=UH5K"
            asciiset "F(OOD)=UW5D"
            asciiset "L(OOD)=AH5D "
            asciiset "M(OOD)=UW5D"
            asciiset "(OOD)=UH5D"
            asciiset "F(OOT)=UH5T"
            asciiset "(OO)=UW5 "
            asciiset "(O')=OH"
            asciiset "(O)E=OW"
            asciiset "(O) =OW"
            asciiset "(OA)=OW4 "
            asciiset " (ONLY)=OW4NLIY"
            asciiset " (ONCE)=WAH4NS"
            asciiset "(ON'T)=OW4NT"
            asciiset "C(O)N=AA"
            asciiset "(O)NG=AO"
            asciiset " :^(O)N=AH"
            asciiset "I(ON)=UN"
            asciiset "#:(ON) =UN"
            asciiset "#^(ON)=UN"
            asciiset "(O)ST =OW"
            asciiset "(OF)^=AO4F"
            asciiset "(OTHER)=AH5DHER"
            asciiset "R(O)B=RAA"
            asciiset "PR(O):#=ROW5"
            asciiset "(OSS) =AO5S"
            asciiset "#:^(OM)=AHM"
            asciiset "(O)=AA"
RULESP:     asciiset "]P"
            asciiset " (P) =PIY4"
            asciiset "(PH)=F"
            asciiset "(PEOPL)=PIY5PUL "
            asciiset "(POW)=PAW4 "
            asciiset "(PUT) =PUHT"
            asciiset "(P)P="
            asciiset " (P)N="
            asciiset " (P)S="
            asciiset " (PROF.)=PROHFEH4SER"
            asciiset "(P)=P"
RULESQ:     asciiset "]Q"
            asciiset " (Q) =KYUW4"
            asciiset "(QUAR)=KWOH5R "
            asciiset "(QU)=KW"
            asciiset "(Q)=K"
RULESR:     asciiset "]R"
            asciiset " (R) =AA4R"
            asciiset " (RE)^#=RIY"
            asciiset "(R)R="
            asciiset "(R)=R"
RULESS:     asciiset "]S"
            asciiset " (S) =EH4S"
            asciiset "(SH)=SH"
            asciiset "#(SION)=ZHUN"
            asciiset "(SOME)=SAHM"
            asciiset "#(SUR)#=ZHER"
            asciiset "(SUR)#=SHER"
            asciiset "#(SU)#=ZHUW"
            asciiset "#(SSU)#=SHUW"
            asciiset "#(SED) =ZD"
            asciiset "#(S)#=Z"
            asciiset "(SAID)=SEHD"
            asciiset "^(SION)=SHUN"
            asciiset "(S)S="
            asciiset ".(S) =Z"
            asciiset "#:.E(S) =Z"
            asciiset "#:^#(S) =S"
            asciiset "U(S) =S"
            asciiset " :#(S) =Z"
            asciiset "##(S) =Z"
            asciiset " (SCH)=SK"
            asciiset "(S)C+="
            asciiset "#(SM)=ZUM"
            asciiset "#(SN)'=ZUN"
            asciiset "(STLE)=SUL"
            asciiset "(S)=S"
RULEST:     asciiset "]T"
            asciiset " (T) =TIY4"
            asciiset " (THE) #=DHIY"
            asciiset " (THE) =DHAX"
            asciiset "(TO) =TUX"
            asciiset " (THAT)=DHAET"
            asciiset " (THIS) =DHIHS"
            asciiset " (THEY)=DHEY"
            asciiset " (THERE)=DHEHR"
            asciiset "(THER)=DHER"
            asciiset "(THEIR)=DHEHR"
            asciiset " (THAN) =DHAEN"
            asciiset " (THEM) =DHEHM"
            asciiset "(THESE) =DHIYZ"
            asciiset " (THEN)=DHEHN"
            asciiset "(THROUGH)=THRUW4 "
            asciiset "(THOSE)=DHOHZ"
            asciiset "(THOUGH) =DHOW"
            asciiset "(TODAY)=TUXDEY"
            asciiset "(TOMO)RROW=TUMAA5"
            asciiset "(TO)TAL=TOW5"
            asciiset " (THUS)=DHAH4S "
            asciiset "(TH)=TH"
            asciiset "#:(TED) =TIXD"
            asciiset "S(TI)#N=CH"
            asciiset "(TI)O=SH"
            asciiset "(TI)A=SH"
            asciiset "(TIEN)=SHUN"
            asciiset "(TUR)#=CHER"
            asciiset "(TU)A=CHUW"
            asciiset " (TWO)=TUW"
            asciiset "&(T)EN="
            asciiset "F(T)EN="
            asciiset "(T)=T"
RULESU:     asciiset "]U"
            asciiset " (U) =YUW4"
            asciiset " (UN)I=YUWN"
            asciiset " (UN)=AHN"
            asciiset " (UPON)=AXPAON"
            asciiset "@(UR)#=UH4R"
            asciiset "(UR)#=YUH4R"
            asciiset "(UR)=ER"
            asciiset "(U)^ =AH"
            asciiset "(U)^^=AH5 "
            asciiset "(UY)=AY5 "
            asciiset " G(U)#="
            asciiset "G(U)%="
            asciiset "G(U)#=W"
            asciiset "#N(U)=YUW"
            asciiset "@(U)=UW"
            asciiset "(U)=YUW"
RULESV:     asciiset "]V"
            asciiset " (V) =VIY4"
            asciiset "(VIEW)=VYUW5 "
            asciiset "(V)=V"
RULESW:     asciiset "]W"
            asciiset " (W) =DAH4BULYUW"
            asciiset " (WERE)=WER"
            asciiset "(WA)SH=WAA"
            asciiset "(WA)ST=WEY"
            asciiset "(WA)S=WAH"
            asciiset "(WA)T=WAA"
            asciiset "(WHERE)=WHEHR"
            asciiset "(WHAT)=WHAHT"
            asciiset "(WHOL)=/HOWL"
            asciiset "(WHO)=/HUW"
            asciiset "(WH)=WH"
            asciiset "(WAR)#=WEHR"
            asciiset "(WAR)=WAOR"
            asciiset "(WOR)^=WER"
            asciiset "(WR)=R"
            asciiset "(WOM)A=WUHM"
            asciiset "(WOM)E=WIHM"
            asciiset "(WEA)R=WEH"
            asciiset "(WANT)=WAA5NT"
            asciiset "ANS(WER)=ER "
            asciiset "(W)=W"
RULESX:     asciiset "]X"
            asciiset " (X) =EH4KS"
            asciiset " (X)=Z"
            asciiset "(X)=KS"
RULESY:     asciiset "]Y"
            asciiset " (Y) =WAY4"
            asciiset "(YOUNG)=YAHNX"
            asciiset " (YOUR)=YOHR"
            asciiset " (YOU)=YUW"
            asciiset " (YES)=YEHS"
            asciiset " (Y)=Y"
            asciiset "F(Y)=AY"
            asciiset "PS(YCH)=AYK "
            asciiset "#:^(Y) =IY"
            asciiset "#:^(Y)I=IY"
            asciiset " :(Y) =AY"
            asciiset " :(Y)#=AY"
            asciiset " :(Y)^+:#=IH"
            asciiset " :(Y)^#=AY"
            asciiset "(Y)=IH"
RULESZ:     asciiset "]Z"
            asciiset " (Z) =ZIY4"
            asciiset "(Z)=Z"
			
            .res $131
			