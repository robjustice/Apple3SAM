;
; SAM
; Software speech synthesizer for the Apple II
;
; Disassembly by Robert Justice 01-Jun-2016
;
;
;
; Code equates
;
;Zeropage variables
L0069       = $0069        ; Applesoft variable pointer - low byte
L006A       = $006A        ; Applesoft variable pointer - high byte
L00E0       = $00E0
L00E1       = $00E1
L00E2       = $00E2
L00E3       = $00E3
L00E4       = $00E4
L00E5       = $00E5
L00E6       = $00E6
L00E7       = $00E7
L00E8       = $00E8
L00E9       = $00E9
L00EA       = $00EA
L00EB       = $00EB
L00EC       = $00EC
L00ED       = $00ED
L00EE       = $00EE
L00EF       = $00EF
L00F0       = $00F0
L00F1       = $00F1
L00F2       = $00F2
L00F3       = $00F3
L00F4       = $00F4
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

RECTAPPS    = $5A01     ;Reciter Applesoft entry
RECTML      = $5E29     ;Reciter machine language entry
ERROR       = $94FF     ;output error code
INPUTSTR    = $9500     ;start address of input string
LC0A0       = $C0A0     ;slot IO address
LFF3A       = $FF3A     ;Bell routine in Apple monitor

;
; Start of code
;
            .org $7161
;
;sinus table
;
SINET:      .byte $00,$00,$00,$10,$10,$10,$10,$10
            .byte $10,$20,$20,$20,$20,$20,$20,$30
            .byte $30,$30,$30,$30,$30,$30,$40,$40
            .byte $40,$40,$40,$40,$40,$50,$50,$50
            .byte $50,$50,$50,$50,$50,$60,$60,$60
            .byte $60,$60,$60,$60,$60,$60,$60,$60
            .byte $60,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $60,$60,$60,$60,$60,$60,$60,$60
            .byte $60,$60,$60,$60,$50,$50,$50,$50
            .byte $50,$50,$50,$50,$40,$40,$40,$40
            .byte $40,$40,$40,$30,$30,$30,$30,$30
            .byte $30,$30,$20,$20,$20,$20,$20,$20
            .byte $10,$10,$10,$10,$10,$10,$00,$00
            .byte $00,$00,$00,$F0,$F0,$F0,$F0,$F0
            .byte $F0,$E0,$E0,$E0,$E0,$E0,$E0,$D0
            .byte $D0,$D0,$D0,$D0,$D0,$D0,$C0,$C0
            .byte $C0,$C0,$C0,$C0,$C0,$B0,$B0,$B0
            .byte $B0,$B0,$B0,$B0,$B0,$A0,$A0,$A0
            .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
            .byte $A0,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
            .byte $A0,$A0,$A0,$A0,$B0,$B0,$B0,$B0
            .byte $B0,$B0,$B0,$B0,$C0,$C0,$C0,$C0
            .byte $C0,$C0,$C0,$D0,$D0,$D0,$D0,$D0
            .byte $D0,$D0,$E0,$E0,$E0,$E0,$E0,$E0
            .byte $F0,$F0,$F0,$F0,$F0,$F0,$00,$00
;
; rectangle table
;
RECTT:      .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $90,$90,$90,$90,$90,$90,$90,$90
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
            .byte $70,$70,$70,$70,$70,$70,$70,$70
;
; mult table
;
MULTT:      .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$00,$01,$01,$02,$02,$03,$03
            .byte $04,$04,$05,$05,$06,$06,$07,$07
            .byte $00,$01,$02,$03,$04,$05,$06,$07
            .byte $08,$09,$0A,$0B,$0C,$0D,$0E,$0F
            .byte $00,$01,$03,$04,$06,$07,$09,$0A
            .byte $0C,$0D,$0F,$10,$12,$13,$15,$16
            .byte $00,$02,$04,$06,$08,$0A,$0C,$0E
            .byte $10,$12,$14,$16,$18,$1A,$1C,$1E
            .byte $00,$02,$05,$07,$0A,$0C,$0F,$11
            .byte $14,$16,$19,$1B,$1E,$20,$23,$25
            .byte $00,$03,$06,$09,$0C,$0F,$12,$15
            .byte $18,$1B,$1E,$21,$24,$27,$2A,$2D
            .byte $00,$03,$07,$0A,$0E,$11,$15,$18
            .byte $1C,$1F,$23,$26,$2A,$2D,$31,$34
            .byte $00,$FC,$F8,$F4,$F0,$EC,$E8,$E4
            .byte $E0,$DC,$D8,$D4,$D0,$CC,$C8,$C4
            .byte $00,$FC,$F9,$F5,$F2,$EE,$EB,$E7
            .byte $E4,$E0,$DD,$D9,$D6,$D2,$CF,$CB
            .byte $00,$FD,$FA,$F7,$F4,$F1,$EE,$EB
            .byte $E8,$E5,$E2,$DF,$DC,$D9,$D6,$D3
            .byte $00,$FD,$FB,$F8,$F6,$F3,$F1,$EE
            .byte $EC,$E9,$E7,$E4,$E2,$DF,$DD,$DA
            .byte $00,$FE,$FC,$FA,$F8,$F6,$F4,$F2
            .byte $F0,$EE,$EC,$EA,$E8,$E6,$E4,$E2
            .byte $00,$FE,$FD,$FB,$FA,$F8,$F7,$F5
            .byte $F4,$F2,$F1,$EF,$EE,$EC,$EB,$E9
            .byte $00,$FF,$FE,$FD,$FC,$FB,$FA,$F9
            .byte $F8,$F7,$F6,$F5,$F4,$F3,$F2,$F1
            .byte $00,$FF,$FF,$FE,$FE,$FD,$FD,$FC
            .byte $FC,$FB,$FB,$FA,$FA,$F9,$F9,$F8
;
; Buffers
; - this was random data in the original SAM binary
;			
BUFFER1:      .res $100
BUFFER2:      .res $100
BUFFER3:      .res $100
BUFFER4:      .res $100
BUFFER5:      .res $100
BUFFER6:      .res $100
BUFFER7:      .res $100     
BUFFER8:      .res $100
			
;Frequency 1 table		
FREQ1T:     .byte $00,$13,$13,$13,$13,$0A,$0E,$13
            .byte $18,$1B,$17,$15,$10,$14,$0E,$12
            .byte $0E,$12,$12,$10,$0D,$0F,$0B,$12
            .byte $0E,$0B,$09,$06,$06,$06,$06,$11
            .byte $06,$06,$06,$06,$0E,$10,$09,$0A
            .byte $08,$0A,$06,$06,$06,$05,$06,$00
            .byte $13,$1B,$15,$1B,$12,$0D,$06,$06
            .byte $06,$06,$06,$06,$06,$06,$06,$06
            .byte $06,$06,$06,$06,$06,$06,$06,$06
            .byte $06,$0A,$0A,$06,$06,$06,$2C,$13
			
;Frequency 2 table			
FREQ2T:     .byte $00,$43,$43,$43,$43,$54,$49,$43
            .byte $3F,$28,$2C,$1F,$25,$2C,$49,$31
            .byte $24,$1E,$33,$25,$1D,$45,$18,$32
            .byte $1E,$18,$53,$2E,$36,$56,$36,$43
            .byte $49,$4F,$1A,$42,$49,$25,$33,$42
            .byte $28,$2F,$4F,$4F,$42,$4F,$6E,$00
            .byte $48,$27,$1F,$2B,$1E,$22,$1A,$1A
            .byte $1A,$42,$42,$42,$6E,$6E,$6E,$54
            .byte $54,$54,$1A,$1A,$1A,$42,$42,$42
            .byte $6D,$56,$6D,$54,$54,$54,$7F,$7F

;Frequency 3 table
FREQ3T:     .byte $00,$5B,$5B,$5B,$5B,$6E,$5D,$5B
            .byte $58,$59,$57,$58,$52,$57,$5D,$3E
            .byte $52,$58,$3E,$6E,$50,$5D,$5A,$3C
            .byte $6E,$5A,$6E,$51,$79,$65,$79,$5B
            .byte $63,$6A,$51,$79,$5D,$52,$5D,$67
            .byte $4C,$5D,$65,$65,$79,$65,$79,$00
            .byte $5A,$58,$58,$58,$58,$52,$51,$51
            .byte $51,$79,$79,$79,$70,$6E,$6E,$5E
            .byte $5E,$5E,$51,$51,$51,$79,$79,$79
            .byte $65,$65,$70,$5E,$5E,$5E,$08,$01
			
;amplitude1 table
AMPL1T:     .byte $00,$00,$00,$00,$00,$0D,$0D,$0E
            .byte $0F,$0F,$0F,$0F,$0F,$0E,$0D,$0C
            .byte $0F,$0F,$0D,$0D,$0D,$0E,$0D,$0C
            .byte $0D,$0D,$0D,$0C,$09,$09,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$0B,$0B
            .byte $0B,$0B,$00,$00,$01,$0B,$00,$02
            .byte $0E,$0F,$0F,$0F,$0F,$0D,$02,$04
            .byte $00,$02,$04,$00,$01,$04,$00,$01
            .byte $04,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$0C,$00,$00,$00,$00,$0F,$0F

;amplitude2 table
AMPL2T:     .byte $00,$00,$00,$00,$00,$0A,$0B,$0D
            .byte $0E,$0D,$0C,$0C,$0B,$0B,$0B,$0B
            .byte $0C,$0C,$0C,$08,$08,$0C,$08,$0A
            .byte $08,$08,$0A,$03,$09,$06,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$03,$05
            .byte $03,$04,$00,$00,$00,$05,$0A,$02
            .byte $0E,$0D,$0C,$0D,$0C,$08,$00,$01
            .byte $00,$00,$01,$00,$00,$01,$00,$00
            .byte $01,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$0A,$00,$00,$0A,$00,$00,$00

;amplitude3 table
AMPL3T:     .byte $00,$00,$00,$00,$00,$08,$07,$08
            .byte $08,$01,$01,$00,$01,$00,$07,$05
            .byte $01,$00,$06,$01,$00,$07,$00,$05
            .byte $01,$00,$08,$00,$00,$03,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$01
            .byte $00,$00,$00,$00,$00,$01,$0E,$01
            .byte $09,$01,$00,$01,$00,$00,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$07,$00,$00,$05,$00,$13,$10

;Phoneme Stressed Length Table
PHOSTRLT:   .byte $00,$12,$12,$12,$08,$0B,$09,$0B
            .byte $0E,$0F,$0B,$10,$0C,$06,$06,$0E
            .byte $0C,$0E,$0C,$0B,$08,$08,$0B,$0A
            .byte $09,$08,$08,$08,$08,$08,$03,$05
            .byte $02,$02,$02,$02,$02,$02,$06,$06
            .byte $08,$06,$06,$02,$09,$04,$02,$01
            .byte $0E,$0F,$0F,$0F,$0E,$0E,$08,$02
            .byte $02,$07,$02,$01,$07,$02,$02,$07
            .byte $02,$02,$08,$02,$02,$06,$02,$02
            .byte $07,$02,$04,$07,$01,$04,$05,$05

;Phoneme Length Table			
PHONLENT:   .byte $00,$12,$12,$12,$08,$08,$08,$08
            .byte $08,$0B,$06,$0C,$0A,$05,$05,$0B
            .byte $0A,$0A,$0A,$09,$08,$07,$09,$07
            .byte $06,$08,$06,$07,$07,$07,$02,$05
            .byte $02,$02,$02,$02,$02,$02,$06,$06
            .byte $07,$06,$06,$02,$08,$03,$01,$1E
            .byte $0D,$0C,$0C,$0C,$0E,$09,$06,$01
            .byte $02,$05,$01,$01,$06,$01,$02,$06
            .byte $01,$02,$08,$02,$02,$04,$02,$02
            .byte $06,$01,$04,$06,$01,$04,$C7,$FF

; Number of frames at the end of a phoneme devoted to
; interpolating to next phoneme's final value			
OUTBLENT:   .byte $00,$02,$02,$02,$02,$04,$04,$04
            .byte $04,$04,$04,$04,$04,$04,$04,$04
            .byte $04,$04,$03,$02,$04,$04,$02,$02
            .byte $02,$02,$02,$01,$01,$01,$01,$01
            .byte $01,$01,$01,$01,$01,$01,$02,$02
            .byte $02,$01,$00,$01,$00,$01,$00,$05
            .byte $05,$05,$05,$05,$04,$04,$02,$00
            .byte $01,$02,$00,$01,$02,$00,$01,$02
            .byte $00,$01,$02,$00,$02,$02,$00,$01
            .byte $03,$00,$02,$03,$00,$02,$A0,$A0

; Number of frames at beginning of a phoneme devoted
; to interpolating to phoneme's final value			
INBLENDT:   .byte $00,$02,$02,$02,$02,$04,$04,$04
            .byte $04,$04,$04,$04,$04,$04,$04,$04
            .byte $04,$04,$03,$03,$04,$04,$03,$03
            .byte $03,$03,$03,$01,$02,$03,$02,$01
            .byte $03,$03,$03,$03,$01,$01,$03,$03
            .byte $03,$02,$02,$03,$02,$03,$00,$00
            .byte $05,$05,$05,$05,$04,$04,$02,$00
            .byte $02,$02,$00,$03,$02,$00,$04,$02
            .byte $00,$03,$02,$00,$02,$02,$00,$02
            .byte $03,$00,$03,$03,$00,$03,$B0,$A0

; Used to decide which phoneme's blend lengths. 
; The candidate with the lower score is selected.
BLENRNKT:   .byte $00,$1F,$1F,$1F,$1F,$02,$02,$02
            .byte $02,$02,$02,$02,$02,$02,$05,$05
            .byte $02,$0A,$02,$08,$05,$05,$0B,$0A
            .byte $09,$08,$08,$A0,$08,$08,$17,$1F
            .byte $12,$12,$12,$12,$1E,$1E,$14,$14
            .byte $14,$14,$17,$17,$1A,$1A,$1D,$1D
            .byte $02,$02,$02,$02,$02,$02,$1A,$1D
            .byte $1B,$1A,$1D,$1B,$1A,$1D,$1B,$1A
            .byte $1D,$1B,$17,$1D,$17,$17,$1D,$17
            .byte $17,$1D,$17,$17,$1D,$17,$17,$17

;sampledConsonantFlags table
SAMCONST:   .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $F1,$E2,$D3,$BB,$7C,$95,$01,$02
            .byte $03,$03,$00,$72,$00,$02,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00
            .byte $00,$00,$00,$1B,$00,$00,$19,$00
            .byte $00,$00,$00,$00,$00,$00,$00,$00

;sample data? maybe this is phoneme description            
SAMPLDAT:   .byte $38,$84,$6B,$19,$C6,$63,$18,$86
            .byte $73,$98,$C6,$B1,$1C,$CA,$31,$8C
            .byte $C7,$31,$88,$C2,$30,$98,$46,$31
            .byte $18,$C6,$35,$0C,$CA,$31,$0C,$C6
            .byte $21,$10,$24,$69,$12,$C2,$31,$14
            .byte $C4,$71,$08,$4A,$22,$49,$AB,$6A
            .byte $A8,$AC,$49,$51,$32,$D5,$52,$88
            .byte $93,$6C,$94,$22,$15,$54,$D2,$25

            .byte $96,$D4,$50,$A5,$46,$21,$08,$85
            .byte $6B,$18,$C4,$63,$10,$CE,$6B,$18
            .byte $8C,$71,$19,$8C,$63,$35,$0C,$C6
            .byte $33,$99,$CC,$6C,$B5,$4E,$A2,$99
            .byte $46,$21,$28,$82,$95,$2E,$E3,$30
            .byte $9C,$C5,$30,$9C,$A2,$B1,$9C,$67
            .byte $31,$88,$66,$59,$2C,$53,$18,$84
            .byte $67,$50,$CA,$E3,$0A,$AC,$AB,$30

            .byte $AC,$62,$30,$8C,$63,$10,$94,$62
            .byte $B1,$8C,$82,$28,$96,$33,$98,$D6
            .byte $B5,$4C,$62,$29,$A5,$4A,$B5,$9C
            .byte $C6,$31,$14,$D6,$38,$9C,$4B,$B4
            .byte $86,$65,$18,$AE,$67,$1C,$A6,$63
            .byte $19,$96,$23,$19,$84,$13,$08,$A6
            .byte $52,$AC,$CA,$22,$89,$6E,$AB,$19
            .byte $8C,$62,$34,$C4,$62,$19,$86,$63

            .byte $18,$C4,$23,$58,$D6,$A3,$50,$42
            .byte $54,$4A,$AD,$4A,$25,$11,$6B,$64
            .byte $89,$4A,$63,$39,$8A,$23,$31,$2A
            .byte $EA,$A2,$A9,$44,$C5,$12,$CD,$42
            .byte $34,$8C,$62,$18,$8C,$63,$11,$48
            .byte $66,$31,$9D,$44,$33,$1D,$46,$31
            .byte $9C,$C6,$B1,$0C,$CD,$32,$88,$C4
            .byte $73,$18,$86,$73,$08,$D6,$63,$58

            .byte $07,$81,$E0,$F0,$3C,$07,$87,$90
            .byte $3C,$7C,$0F,$C7,$C0,$C0,$F0,$7C
            .byte $1E,$07,$80,$80,$00,$1C,$78,$70
            .byte $F1,$C7,$1F,$C0,$0C,$FE,$1C,$1F
            .byte $1F,$0E,$0A,$7A,$C0,$71,$F2,$83
            .byte $8F,$03,$0F,$0F,$0C,$00,$79,$F8
            .byte $61,$E0,$43,$0F,$83,$E7,$18,$F9
            .byte $C1,$13,$DA,$E9,$63,$8F,$0F,$83

            .byte $83,$87,$C3,$1F,$3C,$70,$F0,$E1
            .byte $E1,$E3,$87,$B8,$71,$0E,$20,$E3
            .byte $8D,$48,$78,$1C,$93,$87,$30,$E1
            .byte $C1,$C1,$E4,$78,$21,$83,$83,$C3
            .byte $87,$06,$39,$E5,$C3,$87,$07,$0E
            .byte $1C,$1C,$70,$F4,$71,$9C,$60,$36
            .byte $32,$C3,$1E,$3C,$F3,$8F,$0E,$3C
            .byte $70,$E3,$C7,$8F,$0F,$0F,$0E,$3C

            .byte $78,$F0,$E3,$87,$06,$F0,$E3,$07
            .byte $C1,$99,$87,$0F,$18,$78,$70,$70
            .byte $FC,$F3,$10,$B1,$8C,$8C,$31,$7C
            .byte $70,$E1,$86,$3C,$64,$6C,$B0,$E1
            .byte $E3,$0F,$23,$8F,$0F,$1E,$3E,$38
            .byte $3C,$38,$7B,$8F,$07,$0E,$3C,$F4
            .byte $17,$1E,$3C,$78,$F2,$9E,$72,$49
            .byte $E3,$25,$36,$38,$58,$39,$E2,$DE

            .byte $3C,$78,$78,$E1,$C7,$61,$E1,$E1
            .byte $B0,$F0,$F0,$C3,$C7,$0E,$38,$C0
            .byte $F0,$CE,$73,$73,$18,$34,$B0,$E1
            .byte $C7,$8E,$1C,$3C,$F8,$38,$F0,$E1
            .byte $C1,$8B,$86,$8F,$1C,$78,$70,$F0
            .byte $78,$AC,$B1,$8F,$39,$31,$DB,$38
            .byte $61,$C3,$0E,$0E,$38,$78,$73,$17
            .byte $1E,$39,$1E,$38,$64,$E1,$F1,$C1

            .byte $4E,$0F,$40,$A2,$02,$C5,$8F,$81
            .byte $A1,$FC,$12,$08,$64,$E0,$3C,$22
            .byte $E0,$45,$07,$8E,$0C,$32,$90,$F0
            .byte $1F,$20,$49,$E0,$F8,$0C,$60,$F0
            .byte $17,$1A,$41,$AA,$A4,$D0,$8D,$12
            .byte $82,$1E,$1E,$03,$F8,$3E,$03,$0C
            .byte $73,$80,$70,$44,$26,$03,$24,$E1
            .byte $3E,$04,$4E,$04,$1C,$C1,$09,$CC

            .byte $9E,$90,$21,$07,$90,$43,$64,$C0
            .byte $0F,$C6,$90,$9C,$C1,$5B,$03,$E2
            .byte $1D,$81,$E0,$5E,$1D,$03,$84,$B8
            .byte $2C,$0F,$80,$B1,$83,$E0,$30,$41
            .byte $1E,$43,$89,$83,$50,$FC,$24,$2E
            .byte $13,$83,$F1,$7C,$4C,$2C,$C9,$0D
            .byte $83,$B0,$B5,$82,$E4,$E8,$06,$9C
            .byte $07,$A0,$99,$1D,$07,$3E,$82,$8F

            .byte $70,$30,$74,$40,$CA,$10,$E4,$E8
            .byte $0F,$92,$14,$3F,$06,$F8,$84,$88
            .byte $43,$81,$0A,$34,$39,$41,$C6,$E3
            .byte $1C,$47,$03,$B0,$B8,$13,$0A,$C2
            .byte $64,$F8,$18,$F9,$60,$B3,$C0,$65
            .byte $20,$60,$A6,$8C,$C3,$81,$20,$30
            .byte $26,$1E,$1C,$38,$D3,$01,$B0,$26
            .byte $40,$F4,$0B,$C3,$42,$1F,$85,$32

            .byte $26,$60,$40,$C9,$CB,$01,$EC,$11
            .byte $28,$40,$FA,$04,$34,$E0,$70,$4C
            .byte $8C,$1D,$07,$69,$03,$16,$C8,$04
            .byte $23,$E8,$C6,$9A,$0B,$1A,$03,$E0
            .byte $76,$06,$05,$CF,$1E,$BC,$58,$31
            .byte $71,$66,$00,$F8,$3F,$04,$FC,$0C
            .byte $74,$27,$8A,$80,$71,$C2,$3A,$26
            .byte $06,$C0,$1F,$05,$0F,$98,$40,$AE

            .byte $01,$7F,$C0,$07,$FF,$00,$0E,$FE
            .byte $00,$03,$DF,$80,$03,$EF,$80,$1B
            .byte $F1,$C2,$00,$E7,$E0,$18,$FC,$E0
            .byte $21,$FC,$80,$3C,$FC,$40,$0E,$7E
            .byte $00,$3F,$3E,$00,$0F,$FE,$00,$1F
            .byte $FF,$00,$3E,$F0,$07,$FC,$00,$7E
            .byte $10,$3F,$FF,$00,$3F,$38,$0E,$7C
            .byte $01,$87,$0C,$FC,$C7,$00,$3E,$04

            .byte $0F,$3E,$1F,$0F,$0F,$1F,$0F,$02
            .byte $83,$87,$CF,$03,$87,$0F,$3F,$C0
            .byte $07,$9E,$60,$3F,$C0,$03,$FE,$00
            .byte $3F,$E0,$77,$E1,$C0,$FE,$E0,$C3
            .byte $E0,$01,$DF,$F8,$03,$07,$00,$7E
            .byte $70,$00,$7C,$38,$18,$FE,$0C,$1E
            .byte $78,$1C,$7C,$3E,$0E,$1F,$1E,$1E
            .byte $3E,$00,$7F,$83,$07,$DB,$87,$83

            .byte $07,$C7,$07,$10,$71,$FF,$00,$3F
            .byte $E2,$01,$E0,$C1,$C3,$E1,$00,$7F
            .byte $C0,$05,$F0,$20,$F8,$F0,$70,$FE
            .byte $78,$79,$F8,$02,$3F,$0C,$8F,$03
            .byte $0F,$9F,$E0,$C1,$C7,$87,$03,$C3
            .byte $C3,$B0,$E1,$E1,$C1,$E3,$E0,$71
            .byte $F0,$00,$FC,$70,$7C,$0C,$3E,$38
            .byte $0E,$1C,$70,$C3,$C7,$03,$81,$C1

            .byte $C7,$E7,$00,$0F,$C7,$87,$19,$09
            .byte $EF,$C4,$33,$E0,$C1,$FC,$F8,$70
            .byte $F0,$78,$F8,$F0,$61,$C7,$00,$1F
            .byte $F8,$01,$7C,$F8,$F0,$78,$70,$3C
            .byte $7C,$CE,$0E,$21,$83,$CF,$08,$07
            .byte $8F,$08,$C1,$87,$8F,$80,$C7,$E3
            .byte $00,$07,$F8,$E0,$EF,$00,$39,$F7
            .byte $80,$0E,$F8,$E1,$E3,$F8,$21,$9F

            .byte $C0,$FF,$03,$F8,$07,$C0,$1F,$F8
            .byte $C4,$04,$FC,$C4,$C1,$BC,$87,$F0
            .byte $0F,$C0,$7F,$05,$E0,$25,$EC,$C0
            .byte $3E,$84,$47,$F0,$8E,$03,$F8,$03
            .byte $FB,$C0,$19,$F8,$07,$9C,$0C,$17
            .byte $F8,$07,$E0,$1F,$A1,$FC,$0F,$FC
            .byte $01,$F0,$3F,$00,$FE,$03,$F0,$1F
            .byte $00,$FD,$00,$FF,$88,$0D,$F9,$01

            .byte $FF,$00,$70,$07,$C0,$3E,$42,$F3
            .byte $0D,$C4,$7F,$80,$FC,$07,$F0,$5E
            .byte $C0,$3F,$00,$78,$3F,$81,$FF,$01
            .byte $F8,$01,$C3,$E8,$0C,$E4,$64,$8F
            .byte $E4,$0F,$F0,$07,$F0,$C2,$1F,$00
            .byte $7F,$C0,$6F,$80,$7E,$03,$F8,$07
            .byte $F0,$3F,$C0,$78,$0F,$82,$07,$FE
            .byte $22,$77,$70,$02,$76,$03,$FE,$00

            .byte $FE,$67,$00,$7C,$C7,$F1,$8E,$C6
            .byte $3B,$E0,$3F,$84,$F3,$19,$D8,$03
            .byte $99,$FC,$09,$B8,$0F,$F8,$00,$9D
            .byte $24,$61,$F9,$0D,$00,$FD,$03,$F0
            .byte $1F,$90,$3F,$01,$F8,$1F,$D0,$0F
            .byte $F8,$37,$01,$F8,$07,$F0,$0F,$C0
            .byte $3F,$00,$FE,$03,$F8,$0F,$C0,$3F
            .byte $00,$FA,$03,$F0,$0F,$80,$FF,$01

            .byte $B8,$07,$F0,$01,$FC,$01,$BC,$80
            .byte $13,$1E,$00,$7F,$E1,$40,$7F,$A0
            .byte $7F,$B0,$00,$3F,$C0,$1F,$C0,$38
            .byte $0F,$F0,$1F,$80,$FF,$01,$FC,$03
            .byte $F1,$7E,$01,$FE,$01,$F0,$FF,$00 
            .byte $7F,$C0,$1D,$07,$F0,$0F,$C0,$7E 
            .byte $06,$E0,$07,$E0,$0F,$F8,$06,$C1 
            .byte $FE,$01,$FC,$03,$E0,$0F,$00,$FC
;
; more buffers..
L8521:      .res $3C
L855D:      .res $3C
L8599:      .res $3C
;
;zero page temp storage
L85D5:      .res $28 

;amplitudeRescale
L85FD:      .byte $00,$01,$02,$02,$02,$03,$03,$04
            .byte $04,$05,$06,$08,$09,$0B,$0D,$0F

L860D:      .byte $00,$00,$E0,$E6,$EC,$F3,$F9,$00
            .byte $06,$0C,$06

L8618:      ldy #$00
            bit L00F2
            bpl L8627
            sec
            lda #$00
            sbc L00F2
            sta L00F2
            ldy #$80
L8627:      sty L00EF
            lda #$00
            ldx #$08
L862D:      asl L00F2
            rol A
            cmp L00F1
            bcc L8638
            sbc L00F1
            inc L00F2
L8638:      dex
            bne L862D
            sta L00F0
            bit L00EF
            bpl L8648
            sec
            lda #$00
            sbc L00F2
            sta L00F2
L8648:      rts
;
; Save zero page locations E0-FF
;
SAVEZERO:   ldx #$1F
L864B:      lda L00E0,X
            sta L85D5,X
            dex
            bne L864B
            rts
;
; Restore zero page locations E0-FF
;
RESTZERO:   ldx #$1F
L8656:      lda L85D5,X
            sta L00E0,X
            dex
            bne L8656
            rts
			
;"COPYRIGHT 1982 DON" (high bit set)
            .byte $C3,$CF,$D0,$D9,$D2,$C9,$C7,$C8
            .byte $D4,$A0,$B1,$B9,$B8,$B2,$A0,$C4
            .byte $CF,$CE
            
L8671:      lda L8521
            cmp #$FF
            bne L8679
            rts
			
L8679:      lda #$00
            tax
            sta L00E9
L867E:      ldy L00E9
            lda L8521,Y
            sta L00F5
            cmp #$FF
            bne L868C
            jmp L86E9
L868C:      cmp #$01
            bne L8693
            jmp L8985
L8693:      cmp #$02
            bne L869A
            jmp L898B
L869A:      lda L855D,Y
            sta L00E8
            lda L8599,Y
            sta L00E7
            ldy L00E8
            iny
            lda L860D,Y
            sta L00E8
            ldy L00F5
L86AE:      lda FREQ1T,Y
            sta BUFFER2,X
            lda FREQ2T,Y
            sta BUFFER3,X
            lda FREQ3T,Y
            sta BUFFER4,X
            lda AMPL1T,Y
            sta BUFFER5,X
            lda AMPL2T,Y
            sta BUFFER6,X
            lda AMPL3T,Y
            sta BUFFER7,X
            lda SAMCONST,Y
            sta BUFFER8,X
            clc

L86DA       = *+1           ; pitch modifier
            lda #$40        ; pitch
            adc L00E8
            sta BUFFER1,X
            inx
            dec L00E7
            bne L86AE
            inc L00E9
            bne L867E
L86E9:      lda #$00
            sta L00E9
            sta L00EE
            tax
L86F0:      ldy L8521,X
            inx
            lda L8521,X
            cmp #$FF
            bne L86FE
            jmp L87FD
L86FE:      tax
            lda BLENRNKT,X
            sta L00F5
            lda BLENRNKT,Y
            cmp L00F5
            beq L8727
            bcc L871A
            lda OUTBLENT,Y
            sta L00E8
            lda INBLENDT,Y
            sta L00E7
            jmp L8731
L871A:      lda INBLENDT,X
            sta L00E8
            lda OUTBLENT,X
            sta L00E7
            jmp L8731
L8727:      lda OUTBLENT,Y
            sta L00E8
            lda OUTBLENT,X
            sta L00E7
L8731:      clc
            lda L00EE
            ldy L00E9
            adc L8599,Y
            sta L00EE
            adc L00E7
            sta L00EA
            lda #<BUFFER1       ;#$61 BUFFER1 pointer low byte
            sta L00EB
            lda #>BUFFER1       ;#$74 BUFFER1 pointer high byte
            sta L00EC
            sec
            lda L00EE
            sbc L00E8
            sta L00E6
            clc
            lda L00E8
            adc L00E7
            sta L00E3
            tax
            dex
            dex
            bpl L875D
            jmp L87F6
L875D:      lda L00E3
            sta L00E5
            lda L00EC
            cmp #>BUFFER1       ;#$74
            bne L87A4
            ldy L00E9
            lda L8599,Y
            lsr A
            sta L00E1
            iny
            lda L8599,Y
            lsr A
            sta L00E2
            clc
            lda L00E1
            adc L00E2
            sta L00E5
            clc
            lda L00EE
            adc L00E2
            sta L00E2
            sec
            lda L00EE
            sbc L00E1
            sta L00E1
            ldy L00E2
            lda (L00EB),Y
            sec
            ldy L00E1
            sbc (L00EB),Y
            sta L00F2
            lda L00E5
            sta L00F1
            jsr L8618
            ldx L00E5
            ldy L00E1
            jmp L87BA
L87A4:      ldy L00EA
            sec
            lda (L00EB),Y
            ldy L00E6
            sbc (L00EB),Y
            sta L00F2
            lda L00E5
            sta L00F1
            jsr L8618
            ldx L00E5
            ldy L00E6
L87BA:      lda #$00
            sta L00F5
            clc
L87BF:      lda (L00EB),Y
            adc L00F2
            sta L00ED
            iny
            dex
            beq L87EB
            clc
            lda L00F5
            adc L00F0
            sta L00F5
            cmp L00E5
            bcc L87E4
            lda L00F5
            sbc L00E5
            sta L00F5
            bit L00EF
            bmi L87E2
            inc L00ED
            bne L87E4
L87E2:      dec L00ED
L87E4:      lda L00ED
            sta (L00EB),Y
            clc
            bcc L87BF
L87EB:      inc L00EC
            lda L00EC
            cmp #>BUFFER1+7       ;#$7B
            beq L87F6
            jmp L875D
L87F6:      inc L00E9
            ldx L00E9
            jmp L86F0
L87FD:      lda L00EE
            clc
            ldy L00E9
            adc L8599,Y
            sta L00ED
            ldx #$00
L8809:      lda BUFFER2,X
            lsr A
            sta L00F5
            sec
            lda BUFFER1,X
            sbc L00F5
            sta BUFFER1,X
            dex
            bne L8809
            lda #$00
            sta L00E8
            sta L00E7
            sta L00E6
            sta L00EE
            lda #$48
            sta L00EA
            lda #$03
            sta L00F5
            lda #<BUFFER5      ;#$61 another pointer low byte
            sta L00EB
            lda #>BUFFER5      ;#$78 another pointer high byte
            sta L00EC
L8835:      ldy #$00
L8837:      lda (L00EB),Y
            tax
            lda L85FD,X
            sta (L00EB),Y
            dey
            bne L8837
            inc L00EC
            dec L00F5
            bne L8835
            ldy #$00
            lda BUFFER1,Y
            sta L00E9
            tax
            lsr A
            lsr A
            sta L00F5
            sec
            txa
            sbc L00F5
            sta L00E3
            jmp L8869
L885D:      jsr L88FA
            iny
            iny
            dec L00ED
            dec L00ED
            jmp L88AB
L8869:      lda BUFFER8,Y
            sta L00E4
            and #$F8
            bne L885D
            ldx L00E8       ; get phase
            clc
            lda SINET,X     ; load sine value (high 4 bits)
            ora BUFFER5,Y   ; get amplitude (in low 4 bits)
            tax
            lda MULTT,X     ; multiplication table
            sta L00F5       ; store
            ldx L00E7       ; get phase
            lda SINET,X     ; load sine value (high 4 bits)
            ora BUFFER6,Y   ; get amplitude (in low 4 bits)
            tax
            lda MULTT,X     ; multiplication table
            adc L00F5       ; add with previous values
            sta L00F5       ; store
            ldx L00E6       ; get phase
            lda RECTT,X     ; load rect value (high 4 bits)
            ora BUFFER7,Y   ; get amplitude (in low 4 bits)
            tax
            lda MULTT,X     ; multiplication table
            adc L00F5       ; add with previous values
            adc #$80

L88A2       = *+1           ; slot modifier	
            sta LC0A0       ; output to DAC
            dec L00EA
            bne L88B2
            iny
            dec L00ED
L88AB:      bne L88AE
            rts

L88AF       =*+1            ; speed modifier			
L88AE:      lda #$48        ; speed
            sta L00EA
L88B2:      dec L00E9
            bne L88D1
L88B6:      lda BUFFER1,Y
            sta L00E9
            tax
            lsr A
            lsr A
            sta L00F5
            sec
            txa
            sbc L00F5
            sta L00E3
            lda #$00
            sta L00E8
            sta L00E7
            sta L00E6
            jmp L8869
L88D1:      dec L00E3
            bne L88DF
            lda L00E4
            beq L88DF
            jsr L88FA
            jmp L88B6
L88DF:      clc
            lda L00E8
            adc BUFFER2,Y
            sta L00E8
            clc
            lda L00E7
            adc BUFFER3,Y
            sta L00E7
            clc
            lda L00E6
            adc BUFFER4,Y
            sta L00E6
            jmp L8869
L88FA:      sty L00EE
            lda L00E4
            tay
            and #$07
            tax
            dex
            stx L00F5
            lda L89C1,X
            sta L00F2
            clc
            lda #>SAMPLDAT       ;sample data pointer high byte?
            adc L00F5
            sta L00EC
            lda #<SAMPLDAT       ;sample data pointer low byte?
            sta L00EB
            tya
            and #$F8
            bne L8926
            ldy L00EE
            lda BUFFER1,Y
            lsr A
            lsr A
            lsr A
            lsr A
            jmp L8952
L8926:      eor #$FF
            tay
L8929:      lda #$08
            sta L00F5
            lda (L00EB),Y
L892F:      asl A
            bcc L8939
            ldx L00F2
L8935       =*+1           ; slot modifier
            stx LC0A0      ; output to DAC
            bne L893F
L8939:      ldx #$9A       ; modified 54
L893C       =*+1           ; slot modifier
            stx LC0A0      ; output to DAC
            nop
L893F:      ldx #$07
L8941:      dex
            bne L8941
            dec L00F5
            bne L892F
            iny
            bne L8929
            lda #$01
            sta L00E9
            ldy L00EE
            rts
L8952:      eor #$FF
            sta L00E8
            ldy L00FF
L8958:      lda #$08
            sta L00F5
            lda (L00EB),Y
L895E:      asl A
            bcc L8968
            ldx #$9A
L8964       =*+1            ; slot modifier
            stx LC0A0       ; output to DAC
            bmi L896E
L8968:      ldx #$64
L896B       =*+1            ; slot modifier
            stx LC0A0       ; output to DAC
            nop
L896E:      ldx #$06
L8970:      dex
            bne L8970
            dec L00F5
            bne L895E
            iny
            inc L00E8
            bne L8958
            lda #$01
            sta L00E9
            sty L00FF
            ldy L00EE
            rts
L8985:      lda #$01
            sta L00ED
            bne L898F
L898B:      lda #$FF
            sta L00ED
L898F:      stx L00EE
            txa
            sec
            sbc #$1E
            bcs L8999
            lda #$00
L8999:      tax
L899A:      lda BUFFER1,X
            cmp #$7F
            bne L89A5
            inx
            jmp L899A
L89A5:      clc
            adc L00ED
            sta L00E8
            sta BUFFER1,X
L89AD:      inx
            cpx L00EE
            beq L89BE
            lda BUFFER1,X
            cmp #$FF
            beq L89AD
            lda L00E8
            jmp L89A5
L89BE:      jmp L869A

L89C1:      .byte $80,$A4,$70,$70,$6C
;
; buffers that hold the result of the parsed input string
; PHOINDEX - contains the phoneme number
; PHOLENGT - contains the phoneme length
; PHOSTRES - contains the phoneme stress
;			
PHOINDEX:    .res $100
L8AC4       =   PHOINDEX+254
PHOLENGT:    .res $100
PHOSTRES:    .res $100

;stressInputTable
;           '*', '1', '2', '3', '4', '5', '6', '7', '8'
STRESINT:   .byte $AA,$B1,$B2,$B3,$B4,$B5,$B6,$B7
            .byte $B8,$B9

;signInputTable1
FICHRTAB:
            .byte $A0 ; ' '
            .byte $AE ; '.'
            .byte $BF ; '?'
            .byte $AC ; ','
            .byte $AD ; '-'
            .byte $C9 ; 'I'
            .byte $C9 ; 'I'
            .byte $C5 ; 'E'
            .byte $C1 ; 'A'
            .byte $C1 ; 'A'
            .byte $C1 ; 'A'
            .byte $C1 ; 'A'
            .byte $D5 ; 'U'
            .byte $C1 ; 'A'
            .byte $C9 ; 'I'
            .byte $C5 ; 'E'
            .byte $D5 ; 'U'
            .byte $CF ; 'O'
            .byte $D2 ; 'R'
            .byte $CC ; 'L'
            .byte $D7 ; 'W'
            .byte $D9 ; 'Y'
            .byte $D7 ; 'W'
            .byte $D2 ; 'R'
            .byte $CC ; 'L'
            .byte $D7 ; 'W'
            .byte $D9 ; 'Y'
            .byte $CD ; 'M'
            .byte $CE ; 'N'
            .byte $CE ; 'N'
            .byte $C4 ; 'D'
            .byte $D1 ; 'Q'
            .byte $D3 ; 'S'
            .byte $D3 ; 'S'
            .byte $C6 ; 'F'
            .byte $D4 ; 'T'
            .byte $AF ; '/'
            .byte $AF ; '/'
            .byte $DA ; 'Z'
            .byte $DA ; 'Z'
            .byte $D6 ; 'V'
            .byte $C4 ; 'D'
            .byte $C3 ; 'C'
            .byte $AA ; '*'
            .byte $CA ; 'J'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $C5 ; 'E'
            .byte $C1 ; 'A'
            .byte $CF ; 'O'
            .byte $C1 ; 'A'
            .byte $CF ; 'O'
            .byte $D5 ; 'U'
            .byte $C2 ; 'B'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $C4 ; 'D'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $C7 ; 'G'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $C7 ; 'G'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $D0 ; 'P'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $D4 ; 'T'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $CB ; 'K'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $CB ; 'K'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $D5 ; 'U'
            .byte $D5 ; 'U'
            .byte $D5 ; 'U'

;signInputTable2
SECHRTAB:
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $D9 ; 'Y'
            .byte $C8 ; 'H'
            .byte $C8 ; 'H'
            .byte $C5 ; 'E'
            .byte $C1 ; 'A'
            .byte $C8 ; 'H'
            .byte $CF ; 'O'
            .byte $C8 ; 'H'
            .byte $D8 ; 'X'
            .byte $D8 ; 'X'
            .byte $D2 ; 'R'
            .byte $D8 ; 'X'
            .byte $C8 ; 'H'
            .byte $D8 ; 'X'
            .byte $D8 ; 'X'
            .byte $D8 ; 'X'
            .byte $D8 ; 'X'
            .byte $C8 ; 'H'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $D8 ; 'X'
            .byte $D8 ; 'X'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $C8 ; 'H'
            .byte $AA ; '*'
            .byte $C8 ; 'H'
            .byte $C8 ; 'H'
            .byte $D8 ; 'X'
            .byte $AA ; '*'
            .byte $C8 ; 'H'
            .byte $AA ; '*'
            .byte $C8 ; 'H'
            .byte $C8 ; 'H'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $D9 ; 'Y'
            .byte $D9 ; 'Y'
            .byte $D9 ; 'Y'
            .byte $D7 ; 'W'
            .byte $D7 ; 'W'
            .byte $D7 ; 'W'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $D8 ; 'X'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $D8 ; 'X'
            .byte $AA ; '*'
            .byte $AA ; '*'
            .byte $CC ; 'L'
            .byte $CD ; 'M'
            .byte $CE ; 'N'
;
;flags
;
L8D72:      
             .byte  $00
             .byte  $00
             .byte  $00
             .byte  $00
             .byte  $00
             .byte  $A4
             .byte  $A4
             .byte  $A4
             .byte  $A4
             .byte  $A4
             .byte  $A4
             .byte  $84
             .byte  $84
             .byte  $A4
             .byte  $A4
             .byte  $84
             .byte  $84
             .byte  $84
             .byte  $84
             .byte  $84
             .byte  $84
             .byte  $84
             .byte  $44
             .byte  $44
             .byte  $44
             .byte  $44
             .byte  $44
             .byte  $4C
             .byte  $4C
             .byte  $4C
             .byte  $48
             .byte  $4C
             .byte  $40
             .byte  $40
             .byte  $40
             .byte  $40
             .byte  $40
             .byte  $40
             .byte  $44
             .byte  $44
             .byte  $44
             .byte  $44
             .byte  $48
             .byte  $40
             .byte  $4C
             .byte  $44
             .byte  $00
             .byte  $00
             .byte  $B4
             .byte  $B4
             .byte  $B4
             .byte  $94
             .byte  $94
             .byte  $94
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4E
             .byte  $4B
             .byte  $4B
             .byte  $4B
             .byte  $4B
             .byte  $4B
             .byte  $4B
             .byte  $4B
             .byte  $4B
             .byte  $4B
             .byte  $4B
             .byte  $4B
             .byte  $4B
;             .byte  $80  table overlaps??
;             .byte  $C1
;             .byte  $C1
;
;flags2
;
L8DC0:       .byte  $80,$C1,$C1,$C1,$C1,$00,$00,$00
             .byte  $00,$00,$00,$00,$00,$00,$00,$00
             .byte  $00,$00,$00,$00,$00,$00,$00,$10
             .byte  $10,$10,$10,$08,$0C,$08,$04,$40
             .byte  $24,$20,$20,$24,$00,$00,$24,$20
             .byte  $20,$24,$20,$20,$00,$20,$00,$00
             .byte  $00,$00,$00,$00,$00,$00,$00,$00
             .byte  $00,$04,$04,$04,$00,$00,$00,$00
             .byte  $00,$00,$00,$00,$00,$04,$04,$04
             .byte  $00,$00,$00,$00,$00,$00
;
;save registers
;
SAVEREGS:   sta L00FC    
            stx L00FB
            sty L00FA
            rts
;
;restore registers
;
RESTREGS:   lda L00FC
            ldx L00FB
            ldy L00FA
            rts
;
;insert phoneme into list
;
; input - index position, X register
;       - F9 phoneme number
;       - F8 phoneme length
;       - F7 phonene stress
;
L8E1C:      jsr SAVEREGS
            ldx #$C7
            ldy #$C8
L8E23:      dex
            dey
            lda PHOINDEX,X
            sta PHOINDEX,Y
            lda PHOLENGT,X
            sta PHOLENGT,Y
            lda PHOSTRES,X
            sta PHOSTRES,Y
            cpx L00F6
            bne L8E23
            lda L00F9
            sta PHOINDEX,X
            lda L00F8
            sta PHOLENGT,X
            lda L00F7
            sta PHOSTRES,X
            jsr RESTREGS
            rts
;
;initialise phoneme buffers and parse input string
;
L8E4E:      ldx #$00           ;clear all regs
            txa
            tay
            sta L00FF          ;clear $00FF 
L8E54:      sta PHOSTRES,Y     ;clear (stress) buffer at $8BC6 to 0, $C7 bytes
            iny
            cpy #$C7
            bne L8E54
L8E5C:      cpx #$C8           ;have we checked all input chars?
            bcc L8E66          ;no, check next
            lda #$8D           ;yes
            sta INPUTSTR,X     ;store CR in current position
            rts                ;and return
;
;parse input string
;
L8E66:      lda INPUTSTR,X     ;load from input string
            cmp #$8D           ;is it a CR
            beq L8EE1          ;yes, then end of input string
            sta L00FE          ;first char stored in FE
            inx
            lda INPUTSTR,X     ;load next from input string
            sta L00FD          ;second char stored in FD
            ldy #$00
@3:         lda FICHRTAB,Y     ;lookup table for first char, $50 chars  8CD0-8D20
            cmp L00FE          ;compare to first char
            bne @1             ;no match, try next
            lda SECHRTAB,Y     ;match, then lookup table for second char, $50 chars  8D21-8D71
            cmp #$AA           ;'*' indicates single char phoneme
            beq @1             ;ignor and keep going?
            cmp L00FD          ;compare to second char
            beq @2             ;matched both
@1:         iny
            cpy #$51           ;$50 char's to check
            bne @3             ;check next table entry for first char
            beq @4             ;not found in first char, try to match with second
@2:         tya                ;transfer phoneme index to A
            ldy L00FF          ;load index into phoneme buffer 
            sta PHOINDEX,Y      ;phoneme index buffer
            inc L00FF          ;inc index
            inx                ;inc current input string index
            jmp L8E5C          ;lets go check the next input string
			
@4:         ldy #$00
@7:         lda SECHRTAB,Y     ;lookup table for second char
            cmp #$AA           ;check if '*'
            bne @5             ;no
            lda FICHRTAB,Y     ;yes
            cmp L00FE
            beq @6
@5:         iny                ;next
            cpy #$51           ;are we done all?
            bne @7             ;no, do next
            beq @8
@6:         tya
            ldy L00FF          ;load index into phoneme buffers 
            sta PHOINDEX,Y      ;phoneme index buffer
            inc L00FF          ;inc index
            jmp L8E5C          ;lets go check the next input string

@8:         lda L00FE          ;load current first char
            ldy #$08
@10:        cmp STRESINT,Y     ;compare to stress integer table
            beq @9             ;yes, it is a stress integer
            dey
            bne @10            ;no, try next
            jsr LFF3A          ;error, call monitor bell routine
            jsr LFF3A          ;and again
            stx ERROR          ;store error code
            jsr RESTZERO       ;restore zeropage
            rts                ;exit
;stress integer
@9:         tya                 
            ldy L00FF          ;load index into phoneme buffers
            dey
            sta PHOSTRES,Y     ;store stress in stress buffer 
            jmp L8E5C          ;lets go check the next input string

L8EE1:      lda #$FF           ;FF denotes end of phoneme list
            ldy L00FF          ;load index into phoneme buffers
            sta PHOINDEX,Y     ;phoneme index buffer
            rts                ;exit
			
L8EE9:      ldy #$00
L8EEB:      lda PHOINDEX,Y
            cmp #$FF
            beq L8F0D
            tax
            lda PHOSTRES,Y
            beq L8F03
            bmi L8F03
            lda PHOSTRLT,X
            sta PHOLENGT,Y
            jmp L8F09
L8F03:      lda PHONLENT,X
            sta PHOLENGT,Y
L8F09:      iny
            jmp L8EEB
L8F0D:      rts

L8F0E:      lda #$00
            sta L00FF
L8F12:      ldx L00FF
            lda PHOINDEX,X
            cmp #$FF
            bne L8F1C
            rts
L8F1C:      sta L00F9
            tay
            lda L8D72,Y
            tay
            and #$02
            bne L8F2C
            inc L00FF
            jmp L8F12
L8F2C:      tya
            and #$01
            bne L8F5D
            inc L00F9
            ldy L00F9
            lda PHOSTRES,X
            sta L00F7
            lda PHONLENT,Y
            sta L00F8
            inx
            stx L00F6
            jsr L8E1C
            inc L00F9
            ldy L00F9
            lda PHONLENT,Y
            sta L00F8
            inx
            stx L00F6
            jsr L8E1C
            inc L00FF
            inc L00FF
            inc L00FF
            jmp L8F12
L8F5D:      inx
            lda PHOINDEX,X
            beq L8F5D
            sta L00F5
            cmp #$FF
            bne L8F6C
            jmp L8F7E
L8F6C:      tay
            lda L8D72,Y
            and #$08
            bne L8FA6
            lda L00F5
            cmp #$24
            beq L8FA6
            cmp #$25
            beq L8FA6
L8F7E:      ldx L00FF
            lda PHOSTRES,X
            sta L00F7
            inx
            stx L00F6
            ldx L00F9
            inx
            stx L00F9
            lda PHONLENT,X
            sta L00F8
            jsr L8E1C
            inc L00F6
            inx
            stx L00F9
            lda PHONLENT,X
            sta L00F8
            jsr L8E1C
            inc L00FF
            inc L00FF
L8FA6:      inc L00FF
            jmp L8F12
L8FAB:      lda #$00
            sta L00FF
L8FAF:      ldx L00FF
L8FB1:      lda PHOINDEX,X
            bne L8FBB
            inc L00FF
            jmp L8FAF
L8FBB:      cmp #$FF
            bne L8FC0
            rts
L8FC0:      tay
            lda L8D72,Y
            and #$10
            beq L8FE7
            lda PHOSTRES,X
            sta L00F7
            inx
            stx L00F6
            lda L8D72,Y
            and #$20
            beq L8FE3
            lda #$15
L8FD9:      sta L00F9
            jsr L8E1C
            ldx L00FF
            jmp L910B
L8FE3:      lda #$14
            bne L8FD9
L8FE7:      lda PHOINDEX,X
            cmp #$4E
            bne L9005
            lda #$18
L8FF0:      sta L00F9
            lda PHOSTRES,X
            sta L00F7
            lda #$0D
            sta PHOINDEX,X
            inx
            stx L00F6
            jsr L8E1C
            jmp L918C
L9005:      cmp #$4F
            bne L900D
            lda #$1B
            bne L8FF0
L900D:      cmp #$50
            bne L9015
            lda #$1C
            bne L8FF0
L9015:      tay
            lda L8D72,Y
            and #$80
            beq L9048
            lda PHOSTRES,X
            beq L9048
            inx
            lda PHOINDEX,X
            bne L9048
            inx
            ldy PHOINDEX,X
            lda L8D72,Y
            and #$80
            beq L9048
            lda PHOSTRES,X
            beq L9048
            stx L00F6
            lda #$00
            sta L00F7
            lda #$1F
            sta L00F9
            jsr L8E1C
            jmp L918C
L9048:      ldx L00FF
            lda PHOINDEX,X
            cmp #$17
            bne L9081
            dex
            lda PHOINDEX,X
            cmp #$45
            bne L9061
            lda #$2A
            sta PHOINDEX,X
            jmp L9129
L9061:      cmp #$39
            bne L906D
            lda #$2C
            sta PHOINDEX,X
            jmp L9132
L906D:      tay
            inx
            lda L8D72,Y
            and #$80
            bne L9079
            jmp L918C
L9079:      lda #$12
            sta PHOINDEX,X
            jmp L918C
L9081:      cmp #$18
            bne L909C
            dex
            ldy PHOINDEX,X
            inx
            lda L8D72,Y
            and #$80
            bne L9094
            jmp L918C
L9094:      lda #$13
            sta PHOINDEX,X
            jmp L918C
L909C:      cmp #$20
L909E:      bne L90B4
            dex
            lda PHOINDEX,X
            cmp #$3C
            beq L90AB
            jmp L918C
L90AB:      inx
            lda #$26
            sta PHOINDEX,X
            jmp L918C
L90B4:      cmp #$48
            bne L90CF
            inx
            ldy PHOINDEX,X
            dex
            lda L8D72,Y
            and #$20
            beq L90C7
            jmp L90EA
L90C7:      lda #$4B
            sta PHOINDEX,X
            jmp L90EA
L90CF:      cmp #$3C
            bne L90EA
            inx
            ldy PHOINDEX,X
            dex
            lda L8D72,Y
            and #$20
            beq L90E2
            jmp L918C
L90E2:      lda #$3F
            sta PHOINDEX,X
            jmp L918C
L90EA:      ldy PHOINDEX,X
            lda L8D72,Y
            and #$01
            beq L910B
            dex
            lda PHOINDEX,X
            inx
            cmp #$20
            beq L9101
            tya
            jmp L914A
L9101:      sec
            tya
            sbc #$0C
            sta PHOINDEX,X
            jmp L918C
L910B:      lda PHOINDEX,X
            cmp #$35
            bne L9129
            dex
            ldy PHOINDEX,X
            inx
            lda L8DC0,Y
            and #$04
            bne L9121
            jmp L918C
L9121:      lda #$10
            sta PHOINDEX,X
            jmp L918C
L9129:      cmp #$2A
            bne L9132
L912D:      tay
            iny
            jmp L9139
L9132:      cmp #$2C
            beq L912D
            jmp L914A
L9139:      sty L00F9
            inx
            stx L00F6
            dex
            lda PHOSTRES,X
            sta L00F7
            jsr L8E1C
            jmp L918C
L914A:      cmp #$45
            bne L9150
            beq L9157
L9150:      cmp #$39
            beq L9157
            jmp L918C
L9157:      dex
            ldy PHOINDEX,X
            inx
            lda L8D72,Y
            and #$80
            beq L918C
            inx
            lda PHOINDEX,X
            beq L9180
            tay
            lda L8D72,Y
            and #$80
            beq L918C
            lda PHOSTRES,X
            bne L918C
L9176:      ldx L00FF
            lda #$1E
            sta PHOINDEX,X
            jmp L918C
L9180:      inx
            lda PHOINDEX,X
            tay
            lda L8D72,Y
            and #$80
            bne L9176
L918C:      inc L00FF
            jmp L8FAF
L9191:      lda #$00
            sta L00FF
L9195:      ldx L00FF
            ldy PHOINDEX,X
            cpy #$FF
            bne L919F
            rts
L919F:      lda L8D72,Y
            and #$40
            beq L91BE
            inx
            ldy PHOINDEX,X
            lda L8D72,Y
            and #$80
            beq L91BE
            ldy PHOSTRES,X
            beq L91BE
            bmi L91BE
            iny
            dex
            tya
            sta PHOSTRES,X
L91BE:      inc L00FF
            jmp L9195
L91C3:      ldx #$FF
            stx L00F3
            inx
            stx L00F4
            stx L00FF
L91CC:      ldx L00FF
            ldy PHOINDEX,X
            cpy #$FF
            bne L91D6
            rts
L91D6:      clc
            lda L00F4
            adc PHOLENGT,X
            sta L00F4
            cmp #$E8
            bcc L91E5
            jmp L920E
L91E5:      lda L8DC0,Y
            and #$01
            beq L9203
            inx
            stx L00F6
            lda #$00
            sta L00F4
            sta L00F7
            lda #$FE
            sta L00F9
            jsr L8E1C
            inc L00FF
            inc L00FF
            jmp L91CC
L9203:      cpy #$00
            bne L9209
            stx L00F3
L9209:      inc L00FF
            jmp L91CC
L920E:      ldx L00F3
            lda #$1F
            sta PHOINDEX,X
            lda #$04
            sta PHOLENGT,X
            lda #$00
            sta PHOSTRES,X
            inx
            stx L00F6
            lda #$FE
            sta L00F9
            lda #$00
            sta L00F4
            sta L00F7
            jsr L8E1C
            inx
            stx L00FF
            jmp L91CC

L9235:      .byte $2C
;
; output
;
L9236:      lda #$00
            tax
            tay
L923A:      lda PHOINDEX,X
            cmp #$FF
            bne L924A
            lda #$FF
            sta L8521,Y
            jsr L8671
            rts
L924A:      cmp #$FE
            bne L9262
            inx
            stx L9235
            lda #$FF
            sta L8521,Y
            jsr L8671
            ldx L9235
            ldy #$00
            jmp L923A
L9262:      cmp #$00
            bne L926A
            inx
            jmp L923A
L926A:      sta L8521,Y
            lda PHOLENGT,X
            sta L8599,Y
            lda PHOSTRES,X
            sta L855D,Y
            inx
            iny
            jmp L923A
L927E:      ldx #$00
L9280:      ldy PHOINDEX,X
            cpy #$FF
            bne L928A
L9287:      jmp L92CC
L928A:      lda L8DC0,Y
            and #$01
            bne L9295
            inx
            jmp L9280
L9295:      stx L00FF
L9297:      dex
            beq L9287
            ldy PHOINDEX,X
            lda L8D72,Y
            and #$80
            beq L9297
L92A4:      ldy PHOINDEX,X
            lda L8DC0,Y
            and #$20
            beq L92B5
            lda L8D72,Y
            and #$04
            beq L92C3
L92B5:      lda PHOLENGT,X
            sta L00F5
            lsr A
            clc
            adc L00F5
            adc #$01
            sta PHOLENGT,X
L92C3:      inx
            cpx L00FF
            bne L92A4
            inx
            jmp L9280
L92CC:      ldx #$00
            stx L00FF
L92D0:      ldx L00FF
            ldy PHOINDEX,X
            cpy #$FF
            bne L92DA
            rts
L92DA:      lda L8D72,Y
            and #$80
            bne L92E4
            jmp L9348
L92E4:      inx
            ldy PHOINDEX,X
            lda L8D72,Y
            sta L00F5
            and #$40
            beq L9324
            lda L00F5
            and #$04
            beq L930A
            dex
            lda PHOLENGT,X
            sta L00F5
            lsr A
            lsr A
            clc
            adc L00F5
            adc #$01
            sta PHOLENGT,X
L9307:      jmp L93B4
L930A:      lda L00F5
            and #$01
            beq L9307
            dex
            lda PHOLENGT,X
            tay
            lsr A
            lsr A
            lsr A
            sta L00F5
            sec
            tya
            sbc L00F5
            sta PHOLENGT,X
            jmp L93B4
L9324:      cpy #$12
            beq L932F
            cpy #$13
            beq L932F
L932C:      jmp L93B4
L932F:      inx
            ldy PHOINDEX,X
            lda L8D72,Y
            and #$40
            beq L932C
            ldx L00FF
            lda PHOLENGT,X
            sec
            sbc #$01
            sta PHOLENGT,X
            jmp L93B4
L9348:      lda L8DC0,Y
            and #$08
            beq L936B
            inx
            ldy PHOINDEX,X
            lda L8D72,Y
            and #$02
            bne L935D
L935A:      jmp L93B4
L935D:      lda #$06
            sta PHOLENGT,X
            dex
            lda #$05
            sta PHOLENGT,X
            jmp L93B4
L936B:      lda L8D72,Y
            and #$02
            beq L9398
L9372:      inx
            ldy PHOINDEX,X
            beq L9372
            lda L8D72,Y
            and #$02
            beq L935A
            lda PHOLENGT,X
            lsr A
            clc
            adc #$01
            sta PHOLENGT,X
            ldx L00FF
            lda PHOLENGT,X
            lsr A
            clc
            adc #$01
            sta PHOLENGT,X
L9395:      jmp L93B4
L9398:      lda L8DC0,Y
            and #$10
            beq L9395
            dex
            ldy PHOINDEX,X
            lda L8D72,Y
            and #$02
            beq L9395
            inx
            lda PHOLENGT,X
            sec
            sbc #$02
            sta PHOLENGT,X
L93B4:      inc L00FF
            jmp L92D0
;
; find Applesoft $SA variable location and length
;
FINDVAR:    lda L0069      ; Applesoft variable pointer low byte
            sta L00FE
            lda L006A      ; Applesoft variable pointer high byte
            sta L00FF
L93C1:      ldy #$00
            lda (L00FE),Y
            cmp #$53       ; 'S'
            bne L93E2
            iny
            lda (L00FE),Y
            cmp #$C1       ; 'A' with high bit set
            bne L93E2      ; we have a match if equal
            iny            ; 
            lda (L00FE),Y  ; get length
            sta L00FD
            iny
            lda (L00FE),Y  ; get string address low byte
            sta L00FB
            iny
            lda (L00FE),Y  ; get string address high byte
            sta L00FC
            jmp L93F4      ; we have it, go copy to buffer
L93E2:      clc            ; not found
            lda L00FE
            adc #$07       ; add 7 to index to next entry
            sta L00FE
            lda L00FF
            adc #$00
            sta L00FF
            cmp #$C0
            bne L93C1      ; try next
            rts
;
; copy Applesoft variable to buffer
;
L93F4:      ldy #$00
L93F6:      lda (L00FB),Y      ; read from applesoft storage
            ora #$80           ; set high bit
            sta INPUTSTR,Y     ; store in buffer
            iny
            cpy L00FD          ; check length
            bne L93F6          ; next
            lda #$8D           ; done, add CR to end
            sta INPUTSTR,Y
            rts
;
;S.A.M. from Applesoft
;
SAMAPPS:    jsr SAVEZERO
            jsr FINDVAR        ; find $SA variable and copy to buffer at %9500
;
;S.A.M. from machine language
;
SAMML:      lda #$FF           ; set no error    
            sta ERROR
            jsr L8E4E          ; process string and create phoneme list and stress
            lda ERROR
            cmp #$FF
            bne L946F          ; error after parsing input string
            jsr L8FAB          ; add something to length?
            jsr L9191
            jsr L8EE9          ; add length
            jsr L927E
            jsr L8F0E
            clc                ; now we hanve phoneme, length, stress set?
            lda SLOT           ;load configured slot
            adc #$08           ;translate to IO address
            asl A
            asl A
            asl A
            asl A
            sta L88A2          ;update DAC write address
            sta L8935          ;update DAC write address
            sta L893C          ;update DAC write address
            sta L8964          ;update DAC write address
            sta L896B          ;update DAC write address
            lda PITCH          ;load configured pitch
            sta L86DA          ;update pitch value
            lda SPEED          ;load configured speed
            sta L88AF          ;update speed value
            ldx #$00           ;set index to start
L9453:      lda PHOINDEX,X      ;get first phoneme
            cmp #$50
            bcs L945F
            inx
            bne L9453
            beq L9464
L945F:      lda #$FF
            sta PHOINDEX,X
L9464:      jsr L91C3
            lda #$FF
            sta L8AC4         
            jsr L9236           ;do the output?
L946F:      jsr RESTZERO
            rts

;pad out
            .res $7D

            jmp SAMAPPS      ;S.A.M. from Applesoft
            jmp RECTAPPS     ;reciter from Applesoft
            jmp SAMML        ;S.A.M. from machine language
            jmp RECTML       ;reciter from machine language
SLOT:       .byte $02        ;slot
PITCH:      .byte $40        ;pitch
SPEED:      .byte $48        ;speed

