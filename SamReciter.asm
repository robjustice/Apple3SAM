            .NOPATCHLIST
            .TITLE  "SOS SAM Driver -- 0.5  03-Oct-16"
;-----------------------------------------------------------------------
;
;
;               SOS Software Automated Mouth (SAM) Driver
;               
;               Based on a disassembly of the AppleII SAM and Reciter programs
;               Converted to work as a SOS Driver
;               Uses Apple /// 6 bit DA converter for output
;
;       Revisions:
;
;       0.1     22-May-16
;               Initial version
;
;       0.2     27-May-16
;               Add Pitch and Speed control
;               If user sends in a seperate string:
;                #P<decimal number> this will set the pitch. eg #P123
;                #S<decimal number> this will set the speed. eg #S123
;                 range 0-255
;
;       0.3     29-May-16
;               Add ability to read error code
;               Return from single CR or LF directly (then does not affect error code)
;
;       0.4     01-Jun-16
;               Add Reciter as a sub device
;       0.41    07-Jun-16
;               Fix up shift right to convert to 6 bit.
;       0.42    07-Jun-16
;               Set speed back to match original sam default. Now speech samples match
;               A2 sam exactly. (after triming to 6 bits)
;       0.43    17-Jul-16
;               Convert lowercase input to upper
;       0.5     02-Oct-16
;               Add function to read the converted 'text to phoneme' string from reciter
;               First read after a write will return the error code
;               Second read after a write will return the converted string (phonemes)
;
;
;
;-----------------------------------------------------------------------

DEVTYPE     .EQU    61                  ;Character device, read/write, SAM
SUBTYPE     .EQU    01
ROBJ        .EQU    524A
RELEASE     .EQU    0430
            .PAGE
;-----------------------------------------------------------------------
;
;  The macro SWITCH performs an N way branch based on a switch index.  The
;  maximum value of the switch index is 127 with bounds checking provided
;  as an option.  The macro uses the A and Y registers and alters the C,
;  Z, and N flags of the status register, but the X register is unchanged.
;
;               SWITCH  [index], [bounds], adrs_table, [*]
;
;       index   This is the variable that is to be used as the switch index.
;               If omitted, the value in the accumulator is used.
;
;      bounds   This is the maximum allowable value for index.  If index
;               exceeds this value, the carry bit will be set and execution
;               will continue following the macro.  If bounds is omitted,
;               no bounds checking will be performed.
;
;  adrs_table   This is a table of addresses (low byte first) used by the
;               switch.  The first entry corresponds to index zero.
;
;           *   If an asterisk is supplied as the fourth parameter, the
;               macro will push the switch address but will not exit to
;               it; execution will continue following the macro.  The
;               program may then load registers or set the status before
;               exiting to the switch address.
;
;-----------------------------------------------------------------------

            .MACRO  SWITCH
            .IF     "%1" <> ""                ;If PARM1 is present,
            LDA     %1                        ;  Load A with switch index
            .ENDC
            .IF     "%2" <> ""                ;If PARM2 is present,
            CMP     #%2+1                     ;  Perform bounds checking
            BCS     $3579                     ;  on switch index
            .ENDC
            ASL     A
            TAY
            LDA     %3+1,Y                    ;Get switch address from table
            PHA                               ;  and push onto stack
            LDA     %3,Y
            PHA
            .IF     "%4" <> "*"               ;If PARM4 is omitted,
            RTS                               ;  Exit to code
            .ENDC                             ;Otherwise, drop through
            .IF     "%2" <> ""
$3579
            .ENDC
            .ENDM
            .PROC   SAM
            .WORD   0FFFF
            .WORD   35.                       ;Length of comment field... entered manually.
            .ASCII  "SAM Speech Driver "
            .ASCII  "By Robert Justice"
;                             1         2         3         4
;                    1234567890123456789012345678901234567890
;
;-----------------------------------------------------------------------
;
;       Device Handler Identification Block 0
;
;-----------------------------------------------------------------------
DIB0        .WORD   DIB1                      ;Link to next device handler
            .WORD   SAM_MAIN                  ;Entry point address
            .BYTE   4                         ;Length of device name
            .ASCII  ".SAM           "
            .BYTE   80                        ;Device # (Mark active)
SLOT0       .BYTE   00                        ;Slot # (not used)
            .BYTE   00                        ;Unit #
            .BYTE   DEVTYPE
            .BYTE   SUBTYPE
            .BYTE   00
            .WORD   0000
            .WORD   ROBJ
            .WORD   RELEASE
;-----------------------------------------------------------------------
;
;       Device Handler Configuration Block 0
;
;-----------------------------------------------------------------------
            .WORD   2
PITCH       .BYTE   040                       ;Pitch
SPEED       .BYTE   048                       ;Speed
            .PAGE

;-----------------------------------------------------------------------
;
;       Device Handler Identification Block 1
;
;-----------------------------------------------------------------------
DIB1        .WORD   0000                      ;Link to next device handler
            .WORD   SAM_MAIN                  ;Entry point address
            .BYTE   8                         ;Length of device name
            .ASCII  ".RECITER       "         ;15 chars
            .BYTE   80                        ;Device # (Mark active)
SLOT1       .BYTE   00                        ;Slot # of SAM card
            .BYTE   01                        ;Unit #
            .BYTE   DEVTYPE
            .BYTE   SUBTYPE
            .BYTE   00
            .WORD   0000
            .WORD   ROBJ
            .WORD   RELEASE
;-----------------------------------------------------------------------
;
;       Device Handler Configuration Block 1
;
;-----------------------------------------------------------------------
            .WORD   0
            .PAGE

;-----------------------------------------------------------------------
;
;       SOS Device Handler Interface
;
;-----------------------------------------------------------------------

SOSINT      .EQU    0C0
REQCODE     .EQU    SOSINT+0                  ;SOS request code
SOSUNIT     .EQU    SOSINT+1                  ;Unit number
BUFFER      .EQU    SOSINT+2                  ;Buffer pointer
REQCNT      .EQU    SOSINT+4                  ;Requested count
CTLSTAT     .EQU    SOSINT+2                  ;Control/status code
CSLIST      .EQU    SOSINT+3                  ;Control/status list pointer
RTNCNT      .EQU    SOSINT+8                  ;Actual Read count


;-----------------------------------------------------------------------
;
;       SOS Global Subroutines
;
;-----------------------------------------------------------------------

ALLOCSIR    .EQU    1913                      ;SOS resource allocation
DEALCSIR    .EQU    1916                      ;SOS resource deallocation
SYSERR      .EQU    1928                      ;SOS error return


;-----------------------------------------------------------------------
;
;       SOS Error Codes
;
;-----------------------------------------------------------------------

XREQCODE    .EQU    20                        ;Invalid request code
XCTLCODE    .EQU    21                        ;Invalid control/status code
XNOTOPEN    .EQU    23                        ;Device not open
XNOTAVIL    .EQU    24                        ;Device not available
XNORESRC    .EQU    25                        ;Resouce not available
XBADOP      .EQU    26                        ;Invalid operation for device


;-----------------------------------------------------------------------
;
;       Misecllaneous Equates
;
;-----------------------------------------------------------------------

TRUE        .EQU    80
FALSE       .EQU    00
ASC_LF      .EQU    0A
ASC_CR      .EQU    0D
ASC_HASH    .EQU    023
ASC_A       .EQU    041
ASC_C       .EQU    043
ASC_D       .EQU    044
ASC_E       .EQU    045
ASC_F       .EQU    046
ASC_G       .EQU    047
ASC_H       .EQU    048
ASC_I       .EQU    049
ASC_L       .EQU    04C
ASC_N       .EQU    04E
ASC_P       .EQU    050
ASC_R       .EQU    052
ASC_S       .EQU    053
ASC_T       .EQU    054
ASC_U       .EQU    055
ASC_Y       .EQU    059
BITON7      .EQU    80
BITOFF7     .EQU    7F

            .PAGE

;
;Zeropage variables
;
L00E0       .EQU    000E0
L00E1       .EQU    000E1
L00E2       .EQU    000E2
L00E3       .EQU    000E3
L00E4       .EQU    000E4
L00E5       .EQU    000E5
L00E6       .EQU    000E6
L00E7       .EQU    000E7
L00E8       .EQU    000E8
L00E9       .EQU    000E9
L00EA       .EQU    000EA
L00EB       .EQU    000EB
L00EC       .EQU    000EC
L00ED       .EQU    000ED
L00EE       .EQU    000EE
L00EF       .EQU    000EF
L00F0       .EQU    000F0
L00F1       .EQU    000F1
L00F2       .EQU    000F2
L00F3       .EQU    000F3
L00F4       .EQU    000F4
L00F5       .EQU    000F5
L00F6       .EQU    000F6
L00F7       .EQU    000F7
L00F8       .EQU    000F8
L00F9       .EQU    000F9
L00FA       .EQU    000FA
L00FB       .EQU    000FB
L00FC       .EQU    000FC
L00FD       .EQU    000FD
L00FE       .EQU    000FE
L00FF       .EQU    000FF


;-----------------------------------------------------------------------
;
;       Local Variables
;
;-----------------------------------------------------------------------

OPENFLG     .BYTE   FALSE                     ;Device 0 open flag
            .BYTE   FALSE                     ;Device 1 open flag
ERROR       .BYTE   0FF     ;output error code	
INPUTBUF    .BLOCK  0100
READNUM     .BYTE   000     ;flag to determine number of reads after write, 0=none
;
;sinus table
;
SINET       .BYTE   000,000,000,010,010,010,010,010
            .BYTE   010,020,020,020,020,020,020,030
            .BYTE   030,030,030,030,030,030,040,040
            .BYTE   040,040,040,040,040,050,050,050
            .BYTE   050,050,050,050,050,060,060,060
            .BYTE   060,060,060,060,060,060,060,060
            .BYTE   060,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   060,060,060,060,060,060,060,060
            .BYTE   060,060,060,060,050,050,050,050
            .BYTE   050,050,050,050,040,040,040,040
            .BYTE   040,040,040,030,030,030,030,030
            .BYTE   030,030,020,020,020,020,020,020
            .BYTE   010,010,010,010,010,010,000,000
            .BYTE   000,000,000,0F0,0F0,0F0,0F0,0F0
            .BYTE   0F0,0E0,0E0,0E0,0E0,0E0,0E0,0D0
            .BYTE   0D0,0D0,0D0,0D0,0D0,0D0,0C0,0C0
            .BYTE   0C0,0C0,0C0,0C0,0C0,0B0,0B0,0B0
            .BYTE   0B0,0B0,0B0,0B0,0B0,0A0,0A0,0A0
            .BYTE   0A0,0A0,0A0,0A0,0A0,0A0,0A0,0A0
            .BYTE   0A0,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   0A0,0A0,0A0,0A0,0A0,0A0,0A0,0A0
            .BYTE   0A0,0A0,0A0,0A0,0B0,0B0,0B0,0B0
            .BYTE   0B0,0B0,0B0,0B0,0C0,0C0,0C0,0C0
            .BYTE   0C0,0C0,0C0,0D0,0D0,0D0,0D0,0D0
            .BYTE   0D0,0D0,0E0,0E0,0E0,0E0,0E0,0E0
            .BYTE   0F0,0F0,0F0,0F0,0F0,0F0,000,000
;
; rectangle table
;
RECTT       .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   090,090,090,090,090,090,090,090
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
            .BYTE   070,070,070,070,070,070,070,070
;
; mult table
;
MULTT       .BYTE   000,000,000,000,000,000,000,000
            .BYTE   000,000,000,000,000,000,000,000
            .BYTE   000,000,001,001,002,002,003,003
            .BYTE   004,004,005,005,006,006,007,007
            .BYTE   000,001,002,003,004,005,006,007
            .BYTE   008,009,00A,00B,00C,00D,00E,00F
            .BYTE   000,001,003,004,006,007,009,00A
            .BYTE   00C,00D,00F,010,012,013,015,016
            .BYTE   000,002,004,006,008,00A,00C,00E
            .BYTE   010,012,014,016,018,01A,01C,01E
            .BYTE   000,002,005,007,00A,00C,00F,011
            .BYTE   014,016,019,01B,01E,020,023,025
            .BYTE   000,003,006,009,00C,00F,012,015
            .BYTE   018,01B,01E,021,024,027,02A,02D
            .BYTE   000,003,007,00A,00E,011,015,018
            .BYTE   01C,01F,023,026,02A,02D,031,034
            .BYTE   000,0FC,0F8,0F4,0F0,0EC,0E8,0E4
            .BYTE   0E0,0DC,0D8,0D4,0D0,0CC,0C8,0C4
            .BYTE   000,0FC,0F9,0F5,0F2,0EE,0EB,0E7
            .BYTE   0E4,0E0,0DD,0D9,0D6,0D2,0CF,0CB
            .BYTE   000,0FD,0FA,0F7,0F4,0F1,0EE,0EB
            .BYTE   0E8,0E5,0E2,0DF,0DC,0D9,0D6,0D3
            .BYTE   000,0FD,0FB,0F8,0F6,0F3,0F1,0EE
            .BYTE   0EC,0E9,0E7,0E4,0E2,0DF,0DD,0DA
            .BYTE   000,0FE,0FC,0FA,0F8,0F6,0F4,0F2
            .BYTE   0F0,0EE,0EC,0EA,0E8,0E6,0E4,0E2
            .BYTE   000,0FE,0FD,0FB,0FA,0F8,0F7,0F5
            .BYTE   0F4,0F2,0F1,0EF,0EE,0EC,0EB,0E9
            .BYTE   000,0FF,0FE,0FD,0FC,0FB,0FA,0F9
            .BYTE   0F8,0F7,0F6,0F5,0F4,0F3,0F2,0F1
            .BYTE   000,0FF,0FF,0FE,0FE,0FD,0FD,0FC
            .BYTE   0FC,0FB,0FB,0FA,0FA,0F9,0F9,0F8
;
; Buffers
;			
BUFFER1     .BLOCK  0100
BUFFER2     .BLOCK  0100
BUFFER3     .BLOCK  0100
BUFFER4     .BLOCK  0100
BUFFER5     .BLOCK  0100
BUFFER6     .BLOCK  0100
BUFFER7     .BLOCK  0100     
BUFFER8     .BLOCK  0100

;Frequency 1 table		
FREQ1T      .BYTE   000,013,013,013,013,00A,00E,013
            .BYTE   018,01B,017,015,010,014,00E,012
            .BYTE   00E,012,012,010,00D,00F,00B,012
            .BYTE   00E,00B,009,006,006,006,006,011
            .BYTE   006,006,006,006,00E,010,009,00A
            .BYTE   008,00A,006,006,006,005,006,000
            .BYTE   013,01B,015,01B,012,00D,006,006
            .BYTE   006,006,006,006,006,006,006,006
            .BYTE   006,006,006,006,006,006,006,006
            .BYTE   006,00A,00A,006,006,006,02C,013
			
;Frequency 2 table		
FREQ2T      .BYTE   000,043,043,043,043,054,049,043
            .BYTE   03F,028,02C,01F,025,02C,049,031
            .BYTE   024,01E,033,025,01D,045,018,032
            .BYTE   01E,018,053,02E,036,056,036,043
            .BYTE   049,04F,01A,042,049,025,033,042
            .BYTE   028,02F,04F,04F,042,04F,06E,000
            .BYTE   048,027,01F,02B,01E,022,01A,01A
            .BYTE   01A,042,042,042,06E,06E,06E,054
            .BYTE   054,054,01A,01A,01A,042,042,042
            .BYTE   06D,056,06D,054,054,054,07F,07F

;Frequency 3 table
FREQ3T      .BYTE   000,05B,05B,05B,05B,06E,05D,05B
            .BYTE   058,059,057,058,052,057,05D,03E
            .BYTE   052,058,03E,06E,050,05D,05A,03C
            .BYTE   06E,05A,06E,051,079,065,079,05B
            .BYTE   063,06A,051,079,05D,052,05D,067
            .BYTE   04C,05D,065,065,079,065,079,000
            .BYTE   05A,058,058,058,058,052,051,051
            .BYTE   051,079,079,079,070,06E,06E,05E
            .BYTE   05E,05E,051,051,051,079,079,079
            .BYTE   065,065,070,05E,05E,05E,008,001
			
;amplitude1 table
AMPL1T      .BYTE   000,000,000,000,000,00D,00D,00E
            .BYTE   00F,00F,00F,00F,00F,00E,00D,00C
            .BYTE   00F,00F,00D,00D,00D,00E,00D,00C
            .BYTE   00D,00D,00D,00C,009,009,000,000
            .BYTE   000,000,000,000,000,000,00B,00B
            .BYTE   00B,00B,000,000,001,00B,000,002
            .BYTE   00E,00F,00F,00F,00F,00D,002,004
            .BYTE   000,002,004,000,001,004,000,001
            .BYTE   004,000,000,000,000,000,000,000
            .BYTE   000,00C,000,000,000,000,00F,00F

;amplitude2 table
AMPL2T      .BYTE   000,000,000,000,000,00A,00B,00D
            .BYTE   00E,00D,00C,00C,00B,00B,00B,00B
            .BYTE   00C,00C,00C,008,008,00C,008,00A
            .BYTE   008,008,00A,003,009,006,000,000
            .BYTE   000,000,000,000,000,000,003,005
            .BYTE   003,004,000,000,000,005,00A,002
            .BYTE   00E,00D,00C,00D,00C,008,000,001
            .BYTE   000,000,001,000,000,001,000,000
            .BYTE   001,000,000,000,000,000,000,000
            .BYTE   000,00A,000,000,00A,000,000,000

;amplitude3 table
AMPL3T      .BYTE   000,000,000,000,000,008,007,008
            .BYTE   008,001,001,000,001,000,007,005
            .BYTE   001,000,006,001,000,007,000,005
            .BYTE   001,000,008,000,000,003,000,000
            .BYTE   000,000,000,000,000,000,000,001
            .BYTE   000,000,000,000,000,001,00E,001
            .BYTE   009,001,000,001,000,000,000,000
            .BYTE   000,000,000,000,000,000,000,000
            .BYTE   000,000,000,000,000,000,000,000
            .BYTE   000,007,000,000,005,000,013,010

;Phoneme Stressed Length Table
PHOSTRLT    .BYTE   000,012,012,012,008,00B,009,00B
            .BYTE   00E,00F,00B,010,00C,006,006,00E
            .BYTE   00C,00E,00C,00B,008,008,00B,00A
            .BYTE   009,008,008,008,008,008,003,005
            .BYTE   002,002,002,002,002,002,006,006
            .BYTE   008,006,006,002,009,004,002,001
            .BYTE   00E,00F,00F,00F,00E,00E,008,002
            .BYTE   002,007,002,001,007,002,002,007
            .BYTE   002,002,008,002,002,006,002,002
            .BYTE   007,002,004,007,001,004,005,005

;Phoneme Length Table			
PHONLENT    .BYTE   000,012,012,012,008,008,008,008
            .BYTE   008,00B,006,00C,00A,005,005,00B
            .BYTE   00A,00A,00A,009,008,007,009,007
            .BYTE   006,008,006,007,007,007,002,005
            .BYTE   002,002,002,002,002,002,006,006
            .BYTE   007,006,006,002,008,003,001,01E
            .BYTE   00D,00C,00C,00C,00E,009,006,001
            .BYTE   002,005,001,001,006,001,002,006
            .BYTE   001,002,008,002,002,004,002,002
            .BYTE   006,001,004,006,001,004,0C7,0FF

; Number of frames at the end of a phoneme devoted to
; interpolating to next phoneme's final value			
OUTBLENT    .BYTE   000,002,002,002,002,004,004,004
            .BYTE   004,004,004,004,004,004,004,004
            .BYTE   004,004,003,002,004,004,002,002
            .BYTE   002,002,002,001,001,001,001,001
            .BYTE   001,001,001,001,001,001,002,002
            .BYTE   002,001,000,001,000,001,000,005
            .BYTE   005,005,005,005,004,004,002,000
            .BYTE   001,002,000,001,002,000,001,002
            .BYTE   000,001,002,000,002,002,000,001
            .BYTE   003,000,002,003,000,002,0A0,0A0

; Number of frames at beginning of a phoneme devoted
; to interpolating to phoneme's final value			
INBLENDT    .BYTE   000,002,002,002,002,004,004,004
            .BYTE   004,004,004,004,004,004,004,004
            .BYTE   004,004,003,003,004,004,003,003
            .BYTE   003,003,003,001,002,003,002,001
            .BYTE   003,003,003,003,001,001,003,003
            .BYTE   003,002,002,003,002,003,000,000
            .BYTE   005,005,005,005,004,004,002,000
            .BYTE   002,002,000,003,002,000,004,002
            .BYTE   000,003,002,000,002,002,000,002
            .BYTE   003,000,003,003,000,003,0B0,0A0

; Used to decide which phoneme's blend lengths. 
; The candidate with the lower score is selected.
BLENRNKT    .BYTE   000,01F,01F,01F,01F,002,002,002
            .BYTE   002,002,002,002,002,002,005,005
            .BYTE   002,00A,002,008,005,005,00B,00A
            .BYTE   009,008,008,0A0,008,008,017,01F
            .BYTE   012,012,012,012,01E,01E,014,014
            .BYTE   014,014,017,017,01A,01A,01D,01D
            .BYTE   002,002,002,002,002,002,01A,01D
            .BYTE   01B,01A,01D,01B,01A,01D,01B,01A
            .BYTE   01D,01B,017,01D,017,017,01D,017
            .BYTE   017,01D,017,017,01D,017,017,017

;sampledConsonantFlags table
SAMCONST    .BYTE   000,000,000,000,000,000,000,000
            .BYTE   000,000,000,000,000,000,000,000
            .BYTE   000,000,000,000,000,000,000,000
            .BYTE   000,000,000,000,000,000,000,000
			.BYTE   0F1,0E2,0D3,0BB,07C,095,001,002
            .BYTE   003,003,000,072,000,002,000,000
            .BYTE   000,000,000,000,000,000,000,000
            .BYTE   000,000,000,000,000,000,000,000
            .BYTE   000,000,000,01B,000,000,019,000
            .BYTE   000,000,000,000,000,000,000,000

;sample data?           
SAMPLDAT    .BYTE   038,084,06B,019,0C6,063,018,086
            .BYTE   073,098,0C6,0B1,01C,0CA,031,08C
            .BYTE   0C7,031,088,0C2,030,098,046,031
            .BYTE   018,0C6,035,00C,0CA,031,00C,0C6
            .BYTE   021,010,024,069,012,0C2,031,014
            .BYTE   0C4,071,008,04A,022,049,0AB,06A
            .BYTE   0A8,0AC,049,051,032,0D5,052,088
            .BYTE   093,06C,094,022,015,054,0D2,025
                    
            .BYTE   096,0D4,050,0A5,046,021,008,085
            .BYTE   06B,018,0C4,063,010,0CE,06B,018
            .BYTE   08C,071,019,08C,063,035,00C,0C6
            .BYTE   033,099,0CC,06C,0B5,04E,0A2,099
            .BYTE   046,021,028,082,095,02E,0E3,030
            .BYTE   09C,0C5,030,09C,0A2,0B1,09C,067
            .BYTE   031,088,066,059,02C,053,018,084
            .BYTE   067,050,0CA,0E3,00A,0AC,0AB,030
                    
            .BYTE   0AC,062,030,08C,063,010,094,062
            .BYTE   0B1,08C,082,028,096,033,098,0D6
            .BYTE   0B5,04C,062,029,0A5,04A,0B5,09C
            .BYTE   0C6,031,014,0D6,038,09C,04B,0B4
            .BYTE   086,065,018,0AE,067,01C,0A6,063
            .BYTE   019,096,023,019,084,013,008,0A6
            .BYTE   052,0AC,0CA,022,089,06E,0AB,019
            .BYTE   08C,062,034,0C4,062,019,086,063
                    
            .BYTE   018,0C4,023,058,0D6,0A3,050,042
            .BYTE   054,04A,0AD,04A,025,011,06B,064
            .BYTE   089,04A,063,039,08A,023,031,02A
            .BYTE   0EA,0A2,0A9,044,0C5,012,0CD,042
            .BYTE   034,08C,062,018,08C,063,011,048
            .BYTE   066,031,09D,044,033,01D,046,031
            .BYTE   09C,0C6,0B1,00C,0CD,032,088,0C4
            .BYTE   073,018,086,073,008,0D6,063,058
                    
            .BYTE   007,081,0E0,0F0,03C,007,087,090
            .BYTE   03C,07C,00F,0C7,0C0,0C0,0F0,07C
            .BYTE   01E,007,080,080,000,01C,078,070
            .BYTE   0F1,0C7,01F,0C0,00C,0FE,01C,01F
            .BYTE   01F,00E,00A,07A,0C0,071,0F2,083
            .BYTE   08F,003,00F,00F,00C,000,079,0F8
            .BYTE   061,0E0,043,00F,083,0E7,018,0F9
            .BYTE   0C1,013,0DA,0E9,063,08F,00F,083
                    
            .BYTE   083,087,0C3,01F,03C,070,0F0,0E1
            .BYTE   0E1,0E3,087,0B8,071,00E,020,0E3
            .BYTE   08D,048,078,01C,093,087,030,0E1
            .BYTE   0C1,0C1,0E4,078,021,083,083,0C3
            .BYTE   087,006,039,0E5,0C3,087,007,00E
            .BYTE   01C,01C,070,0F4,071,09C,060,036
            .BYTE   032,0C3,01E,03C,0F3,08F,00E,03C
            .BYTE   070,0E3,0C7,08F,00F,00F,00E,03C
                    
            .BYTE   078,0F0,0E3,087,006,0F0,0E3,007
            .BYTE   0C1,099,087,00F,018,078,070,070
            .BYTE   0FC,0F3,010,0B1,08C,08C,031,07C
            .BYTE   070,0E1,086,03C,064,06C,0B0,0E1
            .BYTE   0E3,00F,023,08F,00F,01E,03E,038
            .BYTE   03C,038,07B,08F,007,00E,03C,0F4
            .BYTE   017,01E,03C,078,0F2,09E,072,049
            .BYTE   0E3,025,036,038,058,039,0E2,0DE
                    
            .BYTE   03C,078,078,0E1,0C7,061,0E1,0E1
            .BYTE   0B0,0F0,0F0,0C3,0C7,00E,038,0C0
            .BYTE   0F0,0CE,073,073,018,034,0B0,0E1
            .BYTE   0C7,08E,01C,03C,0F8,038,0F0,0E1
            .BYTE   0C1,08B,086,08F,01C,078,070,0F0
            .BYTE   078,0AC,0B1,08F,039,031,0DB,038
            .BYTE   061,0C3,00E,00E,038,078,073,017
            .BYTE   01E,039,01E,038,064,0E1,0F1,0C1
                    
            .BYTE   04E,00F,040,0A2,002,0C5,08F,081
            .BYTE   0A1,0FC,012,008,064,0E0,03C,022
            .BYTE   0E0,045,007,08E,00C,032,090,0F0
            .BYTE   01F,020,049,0E0,0F8,00C,060,0F0
            .BYTE   017,01A,041,0AA,0A4,0D0,08D,012
            .BYTE   082,01E,01E,003,0F8,03E,003,00C
            .BYTE   073,080,070,044,026,003,024,0E1
            .BYTE   03E,004,04E,004,01C,0C1,009,0CC
                    
            .BYTE   09E,090,021,007,090,043,064,0C0
            .BYTE   00F,0C6,090,09C,0C1,05B,003,0E2
            .BYTE   01D,081,0E0,05E,01D,003,084,0B8
            .BYTE   02C,00F,080,0B1,083,0E0,030,041
            .BYTE   01E,043,089,083,050,0FC,024,02E
            .BYTE   013,083,0F1,07C,04C,02C,0C9,00D
            .BYTE   083,0B0,0B5,082,0E4,0E8,006,09C
            .BYTE   007,0A0,099,01D,007,03E,082,08F
                    
            .BYTE   070,030,074,040,0CA,010,0E4,0E8
            .BYTE   00F,092,014,03F,006,0F8,084,088
            .BYTE   043,081,00A,034,039,041,0C6,0E3
            .BYTE   01C,047,003,0B0,0B8,013,00A,0C2
            .BYTE   064,0F8,018,0F9,060,0B3,0C0,065
            .BYTE   020,060,0A6,08C,0C3,081,020,030
            .BYTE   026,01E,01C,038,0D3,001,0B0,026
            .BYTE   040,0F4,00B,0C3,042,01F,085,032
                    
            .BYTE   026,060,040,0C9,0CB,001,0EC,011
            .BYTE   028,040,0FA,004,034,0E0,070,04C
            .BYTE   08C,01D,007,069,003,016,0C8,004
            .BYTE   023,0E8,0C6,09A,00B,01A,003,0E0
            .BYTE   076,006,005,0CF,01E,0BC,058,031
            .BYTE   071,066,000,0F8,03F,004,0FC,00C
            .BYTE   074,027,08A,080,071,0C2,03A,026
            .BYTE   006,0C0,01F,005,00F,098,040,0AE
                    
            .BYTE   001,07F,0C0,007,0FF,000,00E,0FE
            .BYTE   000,003,0DF,080,003,0EF,080,01B
            .BYTE   0F1,0C2,000,0E7,0E0,018,0FC,0E0
            .BYTE   021,0FC,080,03C,0FC,040,00E,07E
            .BYTE   000,03F,03E,000,00F,0FE,000,01F
            .BYTE   0FF,000,03E,0F0,007,0FC,000,07E
            .BYTE   010,03F,0FF,000,03F,038,00E,07C
            .BYTE   001,087,00C,0FC,0C7,000,03E,004
                    
            .BYTE   00F,03E,01F,00F,00F,01F,00F,002
            .BYTE   083,087,0CF,003,087,00F,03F,0C0
            .BYTE   007,09E,060,03F,0C0,003,0FE,000
            .BYTE   03F,0E0,077,0E1,0C0,0FE,0E0,0C3
            .BYTE   0E0,001,0DF,0F8,003,007,000,07E
            .BYTE   070,000,07C,038,018,0FE,00C,01E
            .BYTE   078,01C,07C,03E,00E,01F,01E,01E
            .BYTE   03E,000,07F,083,007,0DB,087,083
                    
            .BYTE   007,0C7,007,010,071,0FF,000,03F
            .BYTE   0E2,001,0E0,0C1,0C3,0E1,000,07F
            .BYTE   0C0,005,0F0,020,0F8,0F0,070,0FE
            .BYTE   078,079,0F8,002,03F,00C,08F,003
            .BYTE   00F,09F,0E0,0C1,0C7,087,003,0C3
            .BYTE   0C3,0B0,0E1,0E1,0C1,0E3,0E0,071
            .BYTE   0F0,000,0FC,070,07C,00C,03E,038
            .BYTE   00E,01C,070,0C3,0C7,003,081,0C1
                    
            .BYTE   0C7,0E7,000,00F,0C7,087,019,009
            .BYTE   0EF,0C4,033,0E0,0C1,0FC,0F8,070
            .BYTE   0F0,078,0F8,0F0,061,0C7,000,01F
            .BYTE   0F8,001,07C,0F8,0F0,078,070,03C
            .BYTE   07C,0CE,00E,021,083,0CF,008,007
            .BYTE   08F,008,0C1,087,08F,080,0C7,0E3
            .BYTE   000,007,0F8,0E0,0EF,000,039,0F7
            .BYTE   080,00E,0F8,0E1,0E3,0F8,021,09F
                    
            .BYTE   0C0,0FF,003,0F8,007,0C0,01F,0F8
            .BYTE   0C4,004,0FC,0C4,0C1,0BC,087,0F0
            .BYTE   00F,0C0,07F,005,0E0,025,0EC,0C0
            .BYTE   03E,084,047,0F0,08E,003,0F8,003
            .BYTE   0FB,0C0,019,0F8,007,09C,00C,017
            .BYTE   0F8,007,0E0,01F,0A1,0FC,00F,0FC
            .BYTE   001,0F0,03F,000,0FE,003,0F0,01F
            .BYTE   000,0FD,000,0FF,088,00D,0F9,001
                    
            .BYTE   0FF,000,070,007,0C0,03E,042,0F3
            .BYTE   00D,0C4,07F,080,0FC,007,0F0,05E
            .BYTE   0C0,03F,000,078,03F,081,0FF,001
            .BYTE   0F8,001,0C3,0E8,00C,0E4,064,08F
            .BYTE   0E4,00F,0F0,007,0F0,0C2,01F,000
            .BYTE   07F,0C0,06F,080,07E,003,0F8,007
            .BYTE   0F0,03F,0C0,078,00F,082,007,0FE
            .BYTE   022,077,070,002,076,003,0FE,000
                    
            .BYTE   0FE,067,000,07C,0C7,0F1,08E,0C6
            .BYTE   03B,0E0,03F,084,0F3,019,0D8,003
            .BYTE   099,0FC,009,0B8,00F,0F8,000,09D
            .BYTE   024,061,0F9,00D,000,0FD,003,0F0
            .BYTE   01F,090,03F,001,0F8,01F,0D0,00F
            .BYTE   0F8,037,001,0F8,007,0F0,00F,0C0
            .BYTE   03F,000,0FE,003,0F8,00F,0C0,03F
            .BYTE   000,0FA,003,0F0,00F,080,0FF,001
                    
            .BYTE   0B8,007,0F0,001,0FC,001,0BC,080
            .BYTE   013,01E,000,07F,0E1,040,07F,0A0
            .BYTE   07F,0B0,000,03F,0C0,01F,0C0,038
            .BYTE   00F,0F0,01F,080,0FF,001,0FC,003
            .BYTE   0F1,07E,001,0FE,001,0F0,0FF,000 
            .BYTE   07F,0C0,01D,007,0F0,00F,0C0,07E 
            .BYTE   006,0E0,007,0E0,00F,0F8,006,0C1 
            .BYTE   0FE,001,0FC,003,0E0,00F,000,0FC
;
; more buffers..
L8521       .BLOCK  03C
L855D       .BLOCK  03C
L8599       .BLOCK  03C

;			
PHOINDEX    .BLOCK  0100
L8AC4       .EQU    PHOINDEX+254
PHOLENGT    .BLOCK  0100
PHOSTRES    .BLOCK  0100
			


;amplitudeRescale
L85FD       .BYTE   000,001,002,002,002,003,003,004
            .BYTE   004,005,006,008,009,00B,00D,00F
                    
L860D       .BYTE   000,000,0E0,0E6,0EC,0F3,0F9,000
            .BYTE   006,00C,006
                    
L89C1       .BYTE   080,0A4,070,070,06C

;stressInputTable
;           		
STRESINT    .ASCII  "*12345678"

;signInputTable1
FICHRTAB:
            .ASCII  " "
            .ASCII  "."
            .ASCII  "?"
            .ASCII  ","
            .ASCII  "-"
            .ASCII  "I"
            .ASCII  "I"
            .ASCII  "E"
            .ASCII  "A"
            .ASCII  "A"
            .ASCII  "A"
            .ASCII  "A"
            .ASCII  "U"
            .ASCII  "A"
            .ASCII  "I"
            .ASCII  "E"
            .ASCII  "U"
            .ASCII  "O"
            .ASCII  "R"
            .ASCII  "L"
            .ASCII  "W"
            .ASCII  "Y"
            .ASCII  "W"
            .ASCII  "R"
            .ASCII  "L"
            .ASCII  "W"
            .ASCII  "Y"
            .ASCII  "M"
            .ASCII  "N"
            .ASCII  "N"
            .ASCII  "D"
            .ASCII  "Q"
            .ASCII  "S"
            .ASCII  "S"
            .ASCII  "F"
            .ASCII  "T"
            .ASCII  "/"
            .ASCII  "/"
            .ASCII  "Z"
            .ASCII  "Z"
            .ASCII  "V"
            .ASCII  "D"
            .ASCII  "C"
            .ASCII  "*"
            .ASCII  "J"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "E"
            .ASCII  "A"
            .ASCII  "O"
            .ASCII  "A"
            .ASCII  "O"
            .ASCII  "U"
            .ASCII  "B"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "D"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "G"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "G"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "P"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "T"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "K"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "K"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "U"
            .ASCII  "U"
            .ASCII  "U"

;signInputTable2
SECHRTAB:
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "Y"
            .ASCII  "H"
            .ASCII  "H"
            .ASCII  "E"
            .ASCII  "A"
            .ASCII  "H"
            .ASCII  "O"
            .ASCII  "H"
            .ASCII  "X"
            .ASCII  "X"
            .ASCII  "R"
            .ASCII  "X"
            .ASCII  "H"
            .ASCII  "X"
            .ASCII  "X"
            .ASCII  "X"
            .ASCII  "X"
            .ASCII  "H"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "X"
            .ASCII  "X"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "H"
            .ASCII  "*"
            .ASCII  "H"
            .ASCII  "H"
            .ASCII  "X"
            .ASCII  "*"
            .ASCII  "H"
            .ASCII  "*"
            .ASCII  "H"
            .ASCII  "H"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "Y"
            .ASCII  "Y"
            .ASCII  "Y"
            .ASCII  "W"
            .ASCII  "W"
            .ASCII  "W"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "X"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "X"
            .ASCII  "*"
            .ASCII  "*"
            .ASCII  "L"
            .ASCII  "M"
            .ASCII  "N"
;
;flags
;			
L8D72       .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   0A4
            .BYTE   0A4
            .BYTE   0A4
            .BYTE   0A4
            .BYTE   0A4
            .BYTE   0A4
            .BYTE   084
            .BYTE   084
            .BYTE   0A4
            .BYTE   0A4
            .BYTE   084
            .BYTE   084
            .BYTE   084
            .BYTE   084
            .BYTE   084
            .BYTE   084
            .BYTE   084
            .BYTE   044
            .BYTE   044
            .BYTE   044
            .BYTE   044
            .BYTE   044
            .BYTE   04C
            .BYTE   04C
            .BYTE   04C
            .BYTE   048
            .BYTE   04C
            .BYTE   040
            .BYTE   040
            .BYTE   040
            .BYTE   040
            .BYTE   040
            .BYTE   040
            .BYTE   044
            .BYTE   044
            .BYTE   044
            .BYTE   044
            .BYTE   048
            .BYTE   040
            .BYTE   04C
            .BYTE   044
            .BYTE   000
            .BYTE   000
            .BYTE   0B4
            .BYTE   0B4
            .BYTE   0B4
            .BYTE   094
            .BYTE   094
            .BYTE   094
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04E
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
            .BYTE   04B
;            .BYTE   080  table overlaps??
;            .BYTE   0C1
;            .BYTE   0C1
;
;flags2
;			
L8DC0       .BYTE   080
            .BYTE   0C1
            .BYTE   0C1
            .BYTE   0C1
            .BYTE   0C1
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   010
            .BYTE   010
            .BYTE   010
            .BYTE   010
            .BYTE   008
            .BYTE   00C
            .BYTE   008
            .BYTE   004
            .BYTE   040
            .BYTE   024
            .BYTE   020
            .BYTE   020
            .BYTE   024
            .BYTE   000
            .BYTE   000
            .BYTE   024
            .BYTE   020
            .BYTE   020
            .BYTE   024
            .BYTE   020
            .BYTE   020
            .BYTE   000
            .BYTE   020
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   004
            .BYTE   004
            .BYTE   004
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   004
            .BYTE   004
            .BYTE   004
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000
            .BYTE   000

BUFF5ADR	.WORD   BUFFER5     ;used for relocatable code
BUFF1ADR    .WORD   BUFFER1     ;used for relocatable code
BUFF8ADR    .WORD   BUFFER8     ;used for relocatable code
SAMPDADR    .WORD   SAMPLDAT    ;used for relocatable code

;
; Reciter tables
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

CHRFLAGS    .BYTE 000     ;%00000000    ;NUL
            .BYTE 000     ;%00000000    ;SOH
            .BYTE 000     ;%00000000    ;STX
            .BYTE 000     ;%00000000    ;ETX
            .BYTE 000     ;%00000000    ;EOT
            .BYTE 000     ;%00000000    ;ENQ
            .BYTE 000     ;%00000000    ;ACK
            .BYTE 000     ;%00000000    ;BEL
            .BYTE 000     ;%00000000    ;BS
            .BYTE 000     ;%00000000    ;TAB
            .BYTE 000     ;%00000000    ;LF
            .BYTE 000     ;%00000000    ;VT
            .BYTE 000     ;%00000000    ;FF
            .BYTE 000     ;%00000000    ;CR
            .BYTE 000     ;%00000000    ;SO
            .BYTE 000     ;%00000000    ;SI
            .BYTE 000     ;%00000000    ;DLE
            .BYTE 000     ;%00000000    ;DC1
            .BYTE 000     ;%00000000    ;DC2
            .BYTE 000     ;%00000000    ;DC3
            .BYTE 000     ;%00000000    ;DC4
            .BYTE 000     ;%00000000    ;NAK
            .BYTE 000     ;%00000000    ;SYN
            .BYTE 000     ;%00000000    ;ETB
            .BYTE 000     ;%00000000    ;CAN
            .BYTE 000     ;%00000000    ;EM
            .BYTE 000     ;%00000000    ;SUB
            .BYTE 000     ;%00000000    ;ESC
            .BYTE 000     ;%00000000    ;FS
            .BYTE 000     ;%00000000    ;GS
            .BYTE 000     ;%00000000    ;RS
            .BYTE 000     ;%00000000    ;US
            .BYTE 000     ;%00000000    ;(space)
            .BYTE 002     ;%00000010    ;!
            .BYTE 002     ;%00000010    ;"
            .BYTE 002     ;%00000010    ;#
            .BYTE 002     ;%00000010    ;$
            .BYTE 002     ;%00000010    ;%
            .BYTE 002     ;%00000010    ;&
            .BYTE 082     ;%10000010    ;'
            .BYTE 000     ;%00000000    ;(
            .BYTE 000     ;%00000000    ;)
            .BYTE 002     ;%00000010    ;*
            .BYTE 002     ;%00000010    ;+
            .BYTE 002     ;%00000010    ;,
            .BYTE 002     ;%00000010    ;-
            .BYTE 002     ;%00000010    ;.
            .BYTE 002     ;%00000010    ;/
            .BYTE 003     ;%00000011    ;0
            .BYTE 003     ;%00000011    ;1
            .BYTE 003     ;%00000011    ;2
            .BYTE 003     ;%00000011    ;3
            .BYTE 003     ;%00000011    ;4
            .BYTE 003     ;%00000011    ;5
            .BYTE 003     ;%00000011    ;6
            .BYTE 003     ;%00000011    ;7
            .BYTE 003     ;%00000011    ;8
            .BYTE 003     ;%00000011    ;9
            .BYTE 002     ;%00000010    ;:
            .BYTE 002     ;%00000010    ;;
            .BYTE 002     ;%00000010    ;<
            .BYTE 002     ;%00000010    ;=
            .BYTE 002     ;%00000010    ;>
            .BYTE 002     ;%00000010    ;?
            .BYTE 002     ;%00000010    ;@
            .BYTE 0C0     ;%11000000    ;A
            .BYTE 0A8     ;%10101000    ;B
            .BYTE 0B0     ;%10110000    ;C
            .BYTE 0AC     ;%10101100    ;D
            .BYTE 0C0     ;%11000000    ;E
            .BYTE 0A0     ;%10100000    ;F
            .BYTE 0B8     ;%10111000    ;G
            .BYTE 0A0     ;%10100000    ;H
            .BYTE 0C0     ;%11000000    ;I
            .BYTE 0BC     ;%10111100    ;J
            .BYTE 0A0     ;%10100000    ;K
            .BYTE 0AC     ;%10101100    ;L
            .BYTE 0A8     ;%10101000    ;M
            .BYTE 0AC     ;%10101100    ;N
            .BYTE 0C0     ;%11000000    ;O
            .BYTE 0A0     ;%10100000    ;P
            .BYTE 0A0     ;%10100000    ;Q
            .BYTE 0AC     ;%10101100    ;R
            .BYTE 0B4     ;%10110100    ;S
            .BYTE 0A4     ;%10100100    ;T
            .BYTE 0C0     ;%11000000    ;U
            .BYTE 0A8     ;%10101000    ;V
            .BYTE 0A8     ;%10101000    ;W
            .BYTE 0B0     ;%10110000    ;X
            .BYTE 0C0     ;%11000000    ;Y
            .BYTE 0BC     ;%10111100    ;Z
            .BYTE 000     ;%00000000    ;[
            .BYTE 000     ;%00000000    ;\
            .BYTE 000     ;%00000000    ;]
            .BYTE 002     ;%00000010    ;^
            .BYTE 000     ;%00000000    ;_
;
;Reciter buffer
RECTBUFF    .BLOCK  0100
;            
;lookup table to optimse rule table start point
;address of position in table for rule start 
;for characters A to Z
RULECHAR    .WORD   RULESA
            .WORD   RULESB
            .WORD   RULESC
            .WORD   RULESD
            .WORD   RULESE
            .WORD   RULESF
            .WORD   RULESG
            .WORD   RULESH
            .WORD   RULESI
            .WORD   RULESJ
            .WORD   RULESK
            .WORD   RULESL
            .WORD   RULESM
            .WORD   RULESN
            .WORD   RULESO
            .WORD   RULESP
            .WORD   RULESQ
            .WORD   RULESR
            .WORD   RULESS
            .WORD   RULEST
            .WORD   RULESU
            .WORD   RULESV
            .WORD   RULESW
            .WORD   RULESX
            .WORD   RULESY
            .WORD   RULESZ
;
;Reciter translation rules
RULES       .ASCII "(A)"
            .BYTE 0BD          ;'=' msb set
            .ASCII "(!)="
            .BYTE 0AE          ;'.' msb set
            .BYTE 028,022
            .ASCII ") =-AH5NKWOWT-"  ;does not like quote "(") =-AH5NKWOWT-"
            .BYTE 0A0          ;' ' msb set
            .BYTE 028,022
            .ASCII ")=KWOW4T"        ;does not like quote "(")=KWOW4T"
            .BYTE 0AD          ;'-' msb set
            .ASCII "(#)= NAH4MBE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "($)= DAA4LE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(%)= PERSEH4N"
            .BYTE 0D4          ;'T' msb set
            .ASCII "(&)= AEN"
            .BYTE 0C4          ;'D' msb set
            .ASCII "(')"
            .BYTE 0BD          ;'=' msb set
            .ASCII "(*)= AE4STERIHS"
            .BYTE 0CB          ;'K' msb set
            .ASCII "(+)= PLAH4"
            .BYTE 0D3          ;'S' msb set
            .ASCII "(,)="
            .BYTE 0AC          ;',' msb set
            .ASCII " (-) ="
            .BYTE 0AD          ;'-' msb set
            .ASCII "(-)"
            .BYTE 0BD          ;'=' msb set
            .ASCII "(.)= POYN"
            .BYTE 0D4          ;'T' msb set
            .ASCII "(/)= SLAE4S"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(0)= ZIY4RO"
            .BYTE 0D7          ;'W' msb set
            .ASCII " (1ST)=FER4S"
            .BYTE 0D4          ;'T' msb set
            .ASCII " (10TH)=TEH4NT"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(1)= WAH4"
            .BYTE 0CE          ;'N' msb set
            .ASCII " (2ND)=SEH4KUN"
            .BYTE 0C4          ;'D' msb set
            .ASCII "(2)= TUW"
            .BYTE 0B4          ;'4' msb set
            .ASCII " (3RD)=THER4"
            .BYTE 0C4          ;'D' msb set
            .ASCII "(3)= THRIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(4)= FOH4"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (5TH)=FIH4FT"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(5)= FAY4"
            .BYTE 0D6          ;'V' msb set
            .ASCII "(6)= SIH4K"
            .BYTE 0D3          ;'S' msb set
            .ASCII "(7)= SEH4VU"
            .BYTE 0CE          ;'N' msb set
            .ASCII " (8TH)=EY4T"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(8)= EY4"
            .BYTE 0D4          ;'T' msb set
            .ASCII "(9)= NAY4"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(:)=."
            .BYTE 0A0          ;' ' msb set
            .ASCII "(;)="
            .BYTE 0AE          ;'.' msb set
            .ASCII "(<)= LEH4S DHAE"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(=)= IY4KWUL"
            .BYTE 0DA          ;'Z' msb set
            .ASCII "(>)= GREY4TER DHAE"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(?)="
            .BYTE 0AE          ;'.' msb set
            .ASCII "(@)= AE6"
            .BYTE 0D4          ;'T' msb set
            .ASCII "(^)= KAE4RIX"
            .BYTE 0D4          ;'T' msb set
RULESA      .ASCII "]"
            .BYTE 0C1          ;'A' msb set
            .ASCII " (A.)=EH4Y."
            .BYTE 0A0          ;' ' msb set
            .ASCII "(A) =AH"
            .BYTE 0A0          ;' ' msb set
            .ASCII " (ARE) =AA"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (AR)O=AX"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(AR)#=EH4R"
            .BYTE 0A0          ;' ' msb set
            .ASCII " ^(AS)#=EY4"
            .BYTE 0D3          ;'S' msb set
            .ASCII "(A)WA=A"
            .BYTE 0D8          ;'X' msb set
            .ASCII "(AW)=AO5"
            .BYTE 0A0          ;' ' msb set
            .ASCII " :(ANY)=EH4NI"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(A)^+#=EY5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "#:(ALLY)=ULI"
            .BYTE 0D9          ;'Y' msb set
            .ASCII " (AL)#=U"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(AGAIN)=AXGEH4"
            .BYTE 0CE          ;'N' msb set
            .ASCII "#:(AG)E=IH"
            .BYTE 0CA          ;'J' msb set
            .ASCII "(A)^%=E"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(A)^+:#=A"
            .BYTE 0C5          ;'E' msb set
            .ASCII " :(A)^+ =EY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII " (ARR)=AX"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(ARR)=AE4"
            .BYTE 0D2          ;'R' msb set
            .ASCII " ^(AR) =AA5"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(AR)=AA5"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(AIR)=EH4"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(AI)=EY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(AY)=EY5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(AU)=AO4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "#:(AL) =U"
            .BYTE 0CC          ;'L' msb set
            .ASCII "#:(ALS) =UL"
            .BYTE 0DA          ;'Z' msb set
            .ASCII "(ALK)=AO4"
            .BYTE 0CB          ;'K' msb set
            .ASCII "(AL)^=AO"
            .BYTE 0CC          ;'L' msb set
            .ASCII " :(ABLE)=EY4BU"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(ABLE)=AXBU"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(A)VO=EY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(ANG)+=EY4N"
            .BYTE 0CA          ;'J' msb set
            .ASCII "(ATARI)=AHTAA4RI"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(A)TOM=A"
            .BYTE 0C5          ;'E' msb set
            .ASCII "(A)TTI=A"
            .BYTE 0C5          ;'E' msb set
            .ASCII " (AT) =AE"
            .BYTE 0D4          ;'T' msb set
            .ASCII " (A)T=A"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(A)=A"
            .BYTE 0C5          ;'E' msb set
RULESB      .ASCII "]"
            .BYTE 0C2          ;'B' msb set
            .ASCII " (B) =BIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII " (BE)^#=BI"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(BEING)=BIY4IHN"
            .BYTE 0D8          ;'X' msb set
            .ASCII " (BOTH) =BOW4T"
            .BYTE 0C8          ;'H' msb set
            .ASCII " (BUS)#=BIH4Z"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(BREAK)=BREY5"
            .BYTE 0CB          ;'K' msb set
            .ASCII "(BUIL)=BIH4"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(B)="
            .BYTE 0C2          ;'B' msb set
RULESC      .ASCII "]"
            .BYTE 0C3          ;'C' msb set
            .ASCII " (C) =SIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII " (CH)^="
            .BYTE 0CB          ;'K' msb set
            .ASCII "^E(CH)="
            .BYTE 0CB          ;'K' msb set
            .ASCII "(CHA)R#=KEH"
            .BYTE 0B5          ;'5' msb set
            .ASCII "(CH)=C"
            .BYTE 0C8          ;'H' msb set
            .ASCII " S(CI)#=SAY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(CI)A=S"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(CI)O=S"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(CI)EN=S"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(CITY)=SIHTI"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(C)+="
            .BYTE 0D3          ;'S' msb set
            .ASCII "(CK)="
            .BYTE 0CB          ;'K' msb set
            .ASCII "(COM)=KAH"
            .BYTE 0CD          ;'M' msb set
            .ASCII "(CUIT)=KIH"
            .BYTE 0D4          ;'T' msb set
            .ASCII "(CREA)=KRIYE"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(C)="
            .BYTE 0CB          ;'K' msb set
RULESD      .ASCII "]"
            .BYTE 0C4          ;'D' msb set
            .ASCII " (D) =DIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII " (DR.) =DAA4KTE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "#:(DED) =DIH"
            .BYTE 0C4          ;'D' msb set
            .ASCII ".E(D) ="
            .BYTE 0C4          ;'D' msb set
            .ASCII "#:^E(D) ="
            .BYTE 0D4          ;'T' msb set
            .ASCII " (DE)^#=DI"
            .BYTE 0C8          ;'H' msb set
            .ASCII " (DO) =DU"
            .BYTE 0D7          ;'W' msb set
            .ASCII " (DOES)=DAH"
            .BYTE 0DA          ;'Z' msb set
            .ASCII "(DONE) =DAH5"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(DOING)=DUW4IHN"
            .BYTE 0D8          ;'X' msb set
            .ASCII " (DOW)=DA"
            .BYTE 0D7          ;'W' msb set
            .ASCII "#(DU)A=JU"
            .BYTE 0D7          ;'W' msb set
            .ASCII "#(DU)^#=JAX"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(D)="
            .BYTE 0C4          ;'D' msb set
RULESE      .ASCII "]"
            .BYTE 0C5          ;'E' msb set
            .ASCII " (E) =IYIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "#:(E) "
            .BYTE 0BD          ;'=' msb set
            .ASCII "':^(E) "
            .BYTE 0BD          ;'=' msb set
            .ASCII " :(E) =I"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "#(ED) ="
            .BYTE 0C4          ;'D' msb set
            .ASCII "#:(E)D "
            .BYTE 0BD          ;'=' msb set
            .ASCII "(EV)ER=EH4"
            .BYTE 0D6          ;'V' msb set
            .ASCII "(E)^%=IY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(ERI)#=IY4RI"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(ERI)=EH4RI"
            .BYTE 0C8          ;'H' msb set
            .ASCII "#:(ER)#=E"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(ERROR)=EH4ROH"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(ERASE)=IHREY5S"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(ER)#=EH"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(ER)=E"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (EVEN)=IYVEH"
            .BYTE 0CE          ;'N' msb set
            .ASCII "#:(E)W"
            .BYTE 0BD          ;'=' msb set
            .ASCII "@(EW)=U"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(EW)=YU"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(E)O=I"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "#:&(ES) =IH"
            .BYTE 0DA          ;'Z' msb set
            .ASCII "#:(E)S "
            .BYTE 0BD          ;'=' msb set
            .ASCII "#:(ELY) =LI"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "#:(EMENT)=MEHN"
            .BYTE 0D4          ;'T' msb set
            .ASCII "(EFUL)=FUH"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(EE)=IY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(EARN)=ER5"
            .BYTE 0CE          ;'N' msb set
            .ASCII " (EAR)^=ER5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(EAD)=EH"
            .BYTE 0C4          ;'D' msb set
            .ASCII "#:(EA) =IYA"
            .BYTE 0D8          ;'X' msb set
            .ASCII "(EA)SU=EH5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(EA)=IY5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(EIGH)=EY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(EI)=IY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII " (EYE)=AY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(EY)=I"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(EU)=YUW5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(EQUAL)=IY4KWU"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(E)=E"
            .BYTE 0C8          ;'H' msb set
RULESF      .ASCII "]"
            .BYTE 0C6          ;'F' msb set
            .ASCII " (F) =EH4"
            .BYTE 0C6          ;'F' msb set
            .ASCII "(FUL)=FUH"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(FRIEND)=FREH5N"
            .BYTE 0C4          ;'D' msb set
            .ASCII "(FATHER)=FAA4DHE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(F)F"
            .BYTE 0BD          ;'=' msb set
            .ASCII "(F)="
            .BYTE 0C6          ;'F' msb set
RULESG      .ASCII "]"
            .BYTE 0C7          ;'G' msb set
            .ASCII " (G) =JIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(GIV)=GIH5"
            .BYTE 0D6          ;'V' msb set
            .ASCII " (G)I^="
            .BYTE 0C7          ;'G' msb set
            .ASCII "(GE)T=GEH5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "SU(GGES)=GJEH4S"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(GG)="
            .BYTE 0C7          ;'G' msb set
            .ASCII " B#(G)="
            .BYTE 0C7          ;'G' msb set
            .ASCII "(G)+="
            .BYTE 0CA          ;'J' msb set
            .ASCII "(GREAT)=GREY4T"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(GON)E=GAO5"
            .BYTE 0CE          ;'N' msb set
            .ASCII "#(GH)"
            .BYTE 0BD          ;'=' msb set
            .ASCII " (GN)="
            .BYTE 0CE          ;'N' msb set
            .ASCII "(G)="
            .BYTE 0C7          ;'G' msb set
RULESH      .ASCII "]"
            .BYTE 0C8          ;'H' msb set
            .ASCII " (H) =EY4C"
            .BYTE 0C8          ;'H' msb set
            .ASCII " (HAV)=/HAE6"
            .BYTE 0D6          ;'V' msb set
            .ASCII " (HERE)=/HIY"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (HOUR)=AW5E"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(HOW)=/HA"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(H)#=/"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(H)"
            .BYTE 0BD          ;'=' msb set
RULESI      .ASCII "]"
            .BYTE 0C9          ;'I' msb set
            .ASCII " (IN)=IH"
            .BYTE 0CE          ;'N' msb set
            .ASCII " (I) =AY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(I) =A"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(IN)D=AY5"
            .BYTE 0CE          ;'N' msb set
            .ASCII "SEM(I)=IY"
            .BYTE 0A0          ;' ' msb set
            .ASCII " ANT(I)=A"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(IER)=IYE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "#:R(IED) =IY"
            .BYTE 0C4          ;'D' msb set
            .ASCII "(IED) =AY5"
            .BYTE 0C4          ;'D' msb set
            .ASCII "(IEN)=IYEH"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(IE)T=AY4E"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(I')=AY"
            .BYTE 0B5          ;'5' msb set
            .ASCII " :(I)^%=AY5"
            .BYTE 0A0          ;' ' msb set
            .ASCII " :(IE) =AY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(I)%=I"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(IE)=IY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII " (IDEA)=AYDIY5A"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(I)^+:#=I"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(IR)#=AY"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(IZ)%=AY"
            .BYTE 0DA          ;'Z' msb set
            .ASCII "(IS)%=AY"
            .BYTE 0DA          ;'Z' msb set
            .ASCII "I^(I)^#=I"
            .BYTE 0C8          ;'H' msb set
            .ASCII "+^(I)^+=AY"
            .BYTE 0A0          ;' ' msb set
            .ASCII "#:^(I)^+=I"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(I)^+=A"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(IR)=E"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(IGH)=AY4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(ILD)=AY5LD"
            .BYTE 0A0          ;' ' msb set
            .ASCII " (IGN)=IHG"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(IGN) =AY4"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(IGN)^=AY4N"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(IGN)%=AY4"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(ICRO)=AY4KRO"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(IQUE)=IY4"
            .BYTE 0CB          ;'K' msb set
            .ASCII "(I)=I"
            .BYTE 0C8          ;'H' msb set
RULESJ      .ASCII "]"
            .BYTE 0CA          ;'J' msb set
            .ASCII " (J) =JEY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(J)="
            .BYTE 0CA          ;'J' msb set
RULESK      .ASCII "]"
            .BYTE 0CB          ;'K' msb set
            .ASCII " (K) =KEY"
            .BYTE 0B4          ;'4' msb set
            .ASCII " (K)N"
            .BYTE 0BD          ;'=' msb set
            .ASCII "(K)="
            .BYTE 0CB          ;'K' msb set
RULESL      .ASCII "]"
            .BYTE 0CC          ;'L' msb set
            .ASCII " (L) =EH4"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(LO)C#=LO"
            .BYTE 0D7          ;'W' msb set
            .ASCII "L(L)"
            .BYTE 0BD          ;'=' msb set
            .ASCII "#:^(L)%=U"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(LEAD)=LIY"
            .BYTE 0C4          ;'D' msb set
            .ASCII " (LAUGH)=LAE4"
            .BYTE 0C6          ;'F' msb set
            .ASCII "(L)="
            .BYTE 0CC          ;'L' msb set
RULESM      .ASCII "]"
            .BYTE 0CD          ;'M' msb set
            .ASCII " (M) =EH4"
            .BYTE 0CD          ;'M' msb set
            .ASCII " (MR.) =MIH4STE"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (MS.)=MIH5"
            .BYTE 0DA          ;'Z' msb set
            .ASCII " (MRS.) =MIH4SIX"
            .BYTE 0DA          ;'Z' msb set
            .ASCII "(MOV)=MUW4"
            .BYTE 0D6          ;'V' msb set
            .ASCII "(MACHIN)=MAHSHIY5"
            .BYTE 0CE          ;'N' msb set
            .ASCII "M(M)"
            .BYTE 0BD          ;'=' msb set
            .ASCII "(M)="
            .BYTE 0CD          ;'M' msb set
RULESN      .ASCII "]"
            .BYTE 0CE          ;'N' msb set
            .ASCII " (N) =EH4"
            .BYTE 0CE          ;'N' msb set
            .ASCII "E(NG)+=N"
            .BYTE 0CA          ;'J' msb set
            .ASCII "(NG)R=NX"
            .BYTE 0C7          ;'G' msb set
            .ASCII "(NG)#=NX"
            .BYTE 0C7          ;'G' msb set
            .ASCII "(NGL)%=NXGU"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(NG)=N"
            .BYTE 0D8          ;'X' msb set
            .ASCII "(NK)=NX"
            .BYTE 0CB          ;'K' msb set
            .ASCII " (NOW) =NAW4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "N(N)"
            .BYTE 0BD          ;'=' msb set
            .ASCII "(NON)E=NAH4"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(N)="
            .BYTE 0CE          ;'N' msb set
RULESO      .ASCII "]"
            .BYTE 0CF          ;'O' msb set
            .ASCII " (O) =OH4"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(OF) =AH"
            .BYTE 0D6          ;'V' msb set
            .ASCII " (OH) =OW5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(OROUGH)=ER4O"
            .BYTE 0D7          ;'W' msb set
            .ASCII "#:(OR) =E"
            .BYTE 0D2          ;'R' msb set
            .ASCII "#:(ORS) =ER"
            .BYTE 0DA          ;'Z' msb set
            .ASCII "(OR)=AO"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (ONE)=WAH"
            .BYTE 0CE          ;'N' msb set
            .ASCII "#(ONE) =WAH"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(OW)=O"
            .BYTE 0D7          ;'W' msb set
            .ASCII " (OVER)=OW5VE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "PR(O)V=UW"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(OV)=AH4"
            .BYTE 0D6          ;'V' msb set
            .ASCII "(O)^%=OW5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(O)^EN=O"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(O)^I#=OW5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(OL)D=OW4"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(OUGHT)=AO5T"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(OUGH)=AH5"
            .BYTE 0C6          ;'F' msb set
            .ASCII " (OU)=A"
            .BYTE 0D7          ;'W' msb set
            .ASCII "H(OU)S#=AW4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(OUS)=AX"
            .BYTE 0D3          ;'S' msb set
            .ASCII "(OUR)=OH"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(OULD)=UH5D"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(OU)^L=AH5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(OUP)=UW5P"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(OU)=A"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(OY)=O"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(OING)=OW4IHN"
            .BYTE 0D8          ;'X' msb set
            .ASCII "(OI)=OY5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(OOR)=OH5"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(OOK)=UH5"
            .BYTE 0CB          ;'K' msb set
            .ASCII "F(OOD)=UW5"
            .BYTE 0C4          ;'D' msb set
            .ASCII "L(OOD)=AH5D"
            .BYTE 0A0          ;' ' msb set
            .ASCII "M(OOD)=UW5"
            .BYTE 0C4          ;'D' msb set
            .ASCII "(OOD)=UH5"
            .BYTE 0C4          ;'D' msb set
            .ASCII "F(OOT)=UH5"
            .BYTE 0D4          ;'T' msb set
            .ASCII "(OO)=UW5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(O')=O"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(O)E=O"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(O) =O"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(OA)=OW4"
            .BYTE 0A0          ;' ' msb set
            .ASCII " (ONLY)=OW4NLI"
            .BYTE 0D9          ;'Y' msb set
            .ASCII " (ONCE)=WAH4N"
            .BYTE 0D3          ;'S' msb set
            .ASCII "(ON'T)=OW4N"
            .BYTE 0D4          ;'T' msb set
            .ASCII "C(O)N=A"
            .BYTE 0C1          ;'A' msb set
            .ASCII "(O)NG=A"
            .BYTE 0CF          ;'O' msb set
            .ASCII " :^(O)N=A"
            .BYTE 0C8          ;'H' msb set
            .ASCII "I(ON)=U"
            .BYTE 0CE          ;'N' msb set
            .ASCII "#:(ON) =U"
            .BYTE 0CE          ;'N' msb set
            .ASCII "#^(ON)=U"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(O)ST =O"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(OF)^=AO4"
            .BYTE 0C6          ;'F' msb set
            .ASCII "(OTHER)=AH5DHE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "R(O)B=RA"
            .BYTE 0C1          ;'A' msb set
            .ASCII "PR(O):#=ROW"
            .BYTE 0B5          ;'5' msb set
            .ASCII "(OSS) =AO5"
            .BYTE 0D3          ;'S' msb set
            .ASCII "#:^(OM)=AH"
            .BYTE 0CD          ;'M' msb set
            .ASCII "(O)=A"
            .BYTE 0C1          ;'A' msb set
RULESP      .ASCII "]"
            .BYTE 0D0          ;'P' msb set
            .ASCII " (P) =PIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(PH)="
            .BYTE 0C6          ;'F' msb set
            .ASCII "(PEOPL)=PIY5PUL"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(POW)=PAW4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(PUT) =PUH"
            .BYTE 0D4          ;'T' msb set
            .ASCII "(P)P"
            .BYTE 0BD          ;'=' msb set
            .ASCII " (P)N"
            .BYTE 0BD          ;'=' msb set
            .ASCII " (P)S"
            .BYTE 0BD          ;'=' msb set
            .ASCII " (PROF.)=PROHFEH4SE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(P)="
            .BYTE 0D0          ;'P' msb set
RULESQ      .ASCII "]"
            .BYTE 0D1          ;'Q' msb set
            .ASCII " (Q) =KYUW"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(QUAR)=KWOH5R"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(QU)=K"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(Q)="
            .BYTE 0CB          ;'K' msb set
RULESR      .ASCII "]"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (R) =AA4"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (RE)^#=RI"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(R)R"
            .BYTE 0BD          ;'=' msb set
            .ASCII "(R)="
            .BYTE 0D2          ;'R' msb set
RULESS      .ASCII "]"
            .BYTE 0D3          ;'S' msb set
            .ASCII " (S) =EH4"
            .BYTE 0D3          ;'S' msb set
            .ASCII "(SH)=S"
            .BYTE 0C8          ;'H' msb set
            .ASCII "#(SION)=ZHU"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(SOME)=SAH"
            .BYTE 0CD          ;'M' msb set
            .ASCII "#(SUR)#=ZHE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(SUR)#=SHE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "#(SU)#=ZHU"
            .BYTE 0D7          ;'W' msb set
            .ASCII "#(SSU)#=SHU"
            .BYTE 0D7          ;'W' msb set
            .ASCII "#(SED) =Z"
            .BYTE 0C4          ;'D' msb set
            .ASCII "#(S)#="
            .BYTE 0DA          ;'Z' msb set
            .ASCII "(SAID)=SEH"
            .BYTE 0C4          ;'D' msb set
            .ASCII "^(SION)=SHU"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(S)S"
            .BYTE 0BD          ;'=' msb set
            .ASCII ".(S) ="
            .BYTE 0DA          ;'Z' msb set
            .ASCII "#:.E(S) ="
            .BYTE 0DA          ;'Z' msb set
            .ASCII "#:^#(S) ="
            .BYTE 0D3          ;'S' msb set
            .ASCII "U(S) ="
            .BYTE 0D3          ;'S' msb set
            .ASCII " :#(S) ="
            .BYTE 0DA          ;'Z' msb set
            .ASCII "##(S) ="
            .BYTE 0DA          ;'Z' msb set
            .ASCII " (SCH)=S"
            .BYTE 0CB          ;'K' msb set
            .ASCII "(S)C+"
            .BYTE 0BD          ;'=' msb set
            .ASCII "#(SM)=ZU"
            .BYTE 0CD          ;'M' msb set
            .ASCII "#(SN)'=ZU"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(STLE)=SU"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(S)="
            .BYTE 0D3          ;'S' msb set
RULEST      .ASCII "]"
            .BYTE 0D4          ;'T' msb set
            .ASCII " (T) =TIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII " (THE) #=DHI"
            .BYTE 0D9          ;'Y' msb set
            .ASCII " (THE) =DHA"
            .BYTE 0D8          ;'X' msb set
            .ASCII "(TO) =TU"
            .BYTE 0D8          ;'X' msb set
            .ASCII " (THAT)=DHAE"
            .BYTE 0D4          ;'T' msb set
            .ASCII " (THIS) =DHIH"
            .BYTE 0D3          ;'S' msb set
            .ASCII " (THEY)=DHE"
            .BYTE 0D9          ;'Y' msb set
            .ASCII " (THERE)=DHEH"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(THER)=DHE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(THEIR)=DHEH"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (THAN) =DHAE"
            .BYTE 0CE          ;'N' msb set
            .ASCII " (THEM) =DHEH"
            .BYTE 0CD          ;'M' msb set
            .ASCII "(THESE) =DHIY"
            .BYTE 0DA          ;'Z' msb set
            .ASCII " (THEN)=DHEH"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(THROUGH)=THRUW4"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(THOSE)=DHOH"
            .BYTE 0DA          ;'Z' msb set
            .ASCII "(THOUGH) =DHO"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(TODAY)=TUXDE"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(TOMO)RROW=TUMAA"
            .BYTE 0B5          ;'5' msb set
            .ASCII "(TO)TAL=TOW"
            .BYTE 0B5          ;'5' msb set
            .ASCII " (THUS)=DHAH4S"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(TH)=T"
            .BYTE 0C8          ;'H' msb set
            .ASCII "#:(TED) =TIX"
            .BYTE 0C4          ;'D' msb set
            .ASCII "S(TI)#N=C"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(TI)O=S"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(TI)A=S"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(TIEN)=SHU"
            .BYTE 0CE          ;'N' msb set
            .ASCII "(TUR)#=CHE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(TU)A=CHU"
            .BYTE 0D7          ;'W' msb set
            .ASCII " (TWO)=TU"
            .BYTE 0D7          ;'W' msb set
            .ASCII "&(T)EN"
            .BYTE 0BD          ;'=' msb set
            .ASCII "F(T)EN"
            .BYTE 0BD          ;'=' msb set
            .ASCII "(T)="
            .BYTE 0D4          ;'T' msb set
RULESU      .ASCII "]"
            .BYTE 0D5          ;'U' msb set
            .ASCII " (U) =YUW"
            .BYTE 0B4          ;'4' msb set
            .ASCII " (UN)I=YUW"
            .BYTE 0CE          ;'N' msb set
            .ASCII " (UN)=AH"
            .BYTE 0CE          ;'N' msb set
            .ASCII " (UPON)=AXPAO"
            .BYTE 0CE          ;'N' msb set
            .ASCII "@(UR)#=UH4"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(UR)#=YUH4"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(UR)=E"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(U)^ =A"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(U)^^=AH5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(UY)=AY5"
            .BYTE 0A0          ;' ' msb set
            .ASCII " G(U)#"
            .BYTE 0BD          ;'=' msb set
            .ASCII "G(U)%"
            .BYTE 0BD          ;'=' msb set
            .ASCII "G(U)#="
            .BYTE 0D7          ;'W' msb set
            .ASCII "#N(U)=YU"
            .BYTE 0D7          ;'W' msb set
            .ASCII "@(U)=U"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(U)=YU"
            .BYTE 0D7          ;'W' msb set
RULESV      .ASCII "]"
            .BYTE 0D6          ;'V' msb set
            .ASCII " (V) =VIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(VIEW)=VYUW5"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(V)="
            .BYTE 0D6          ;'V' msb set
RULESW      .ASCII "]"
            .BYTE 0D7          ;'W' msb set
            .ASCII " (W) =DAH4BULYU"
            .BYTE 0D7          ;'W' msb set
            .ASCII " (WERE)=WE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(WA)SH=WA"
            .BYTE 0C1          ;'A' msb set
            .ASCII "(WA)ST=WE"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(WA)S=WA"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(WA)T=WA"
            .BYTE 0C1          ;'A' msb set
            .ASCII "(WHERE)=WHEH"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(WHAT)=WHAH"
            .BYTE 0D4          ;'T' msb set
            .ASCII "(WHOL)=/HOW"
            .BYTE 0CC          ;'L' msb set
            .ASCII "(WHO)=/HU"
            .BYTE 0D7          ;'W' msb set
            .ASCII "(WH)=W"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(WAR)#=WEH"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(WAR)=WAO"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(WOR)^=WE"
            .BYTE 0D2          ;'R' msb set
            .ASCII "(WR)="
            .BYTE 0D2          ;'R' msb set
            .ASCII "(WOM)A=WUH"
            .BYTE 0CD          ;'M' msb set
            .ASCII "(WOM)E=WIH"
            .BYTE 0CD          ;'M' msb set
            .ASCII "(WEA)R=WE"
            .BYTE 0C8          ;'H' msb set
            .ASCII "(WANT)=WAA5N"
            .BYTE 0D4          ;'T' msb set
            .ASCII "ANS(WER)=ER"
            .BYTE 0A0          ;' ' msb set
            .ASCII "(W)="
            .BYTE 0D7          ;'W' msb set
RULESX      .ASCII "]"
            .BYTE 0D8          ;'X' msb set
            .ASCII " (X) =EH4K"
            .BYTE 0D3          ;'S' msb set
            .ASCII " (X)="
            .BYTE 0DA          ;'Z' msb set
            .ASCII "(X)=K"
            .BYTE 0D3          ;'S' msb set
RULESY      .ASCII "]"
            .BYTE 0D9          ;'Y' msb set
            .ASCII " (Y) =WAY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(YOUNG)=YAHN"
            .BYTE 0D8          ;'X' msb set
            .ASCII " (YOUR)=YOH"
            .BYTE 0D2          ;'R' msb set
            .ASCII " (YOU)=YU"
            .BYTE 0D7          ;'W' msb set
            .ASCII " (YES)=YEH"
            .BYTE 0D3          ;'S' msb set
            .ASCII " (Y)="
            .BYTE 0D9          ;'Y' msb set
            .ASCII "F(Y)=A"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "PS(YCH)=AYK"
            .BYTE 0A0          ;' ' msb set
            .ASCII "#:^(Y) =I"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "#:^(Y)I=I"
            .BYTE 0D9          ;'Y' msb set
            .ASCII " :(Y) =A"
            .BYTE 0D9          ;'Y' msb set
            .ASCII " :(Y)#=A"
            .BYTE 0D9          ;'Y' msb set
            .ASCII " :(Y)^+:#=I"
            .BYTE 0C8          ;'H' msb set
            .ASCII " :(Y)^#=A"
            .BYTE 0D9          ;'Y' msb set
            .ASCII "(Y)=I"
            .BYTE 0C8          ;'H' msb set
RULESZ      .ASCII "]"
            .BYTE 0DA          ;'Z' msb set
            .ASCII " (Z) =ZIY"
            .BYTE 0B4          ;'4' msb set
            .ASCII "(Z)="
            .BYTE 0DA          ;'Z' msb set
            
RULESADR    .WORD   RULES      ;used for relocatable code

;-----------------------------------------------------------------------
;
;       Hardware I/O Addresses
;
;-----------------------------------------------------------------------

B_REG       .EQU    0FFEF               ;Bank Register
E_REG       .EQU    0FFDF               ;Environment Register
ANYSLOT     .EQU    0FFDD               ;Any Slot Interrupt Flag


;-----------------------------------------------------------------------
;
;       SAM Interface Card
;       (N/A - just use Apple3 6 bit dac for output)
;
;-----------------------------------------------------------------------

DACOUT      .EQU    0FFE0               ;DAC Output port for Apple3
;            .PAGE

;-----------------------------------------------------------------------
;
;       SAM Driver -- Mainline
;
;-----------------------------------------------------------------------

SAM_MAIN    SWITCH  REQCODE,8,SAM_TBL

BADREQ      LDA     #XREQCODE           ;Invalid request code
            JSR     SYSERR
NOTOPEN     LDA     #XNOTOPEN           ;Device not open
            JSR     SYSERR

SAM_TBL     .WORD   SAM_READ-1
            .WORD   SAM_WRITE-1
            .WORD   SAM_STAT-1
            .WORD   SAM_CNTL-1
            .WORD   BADREQ-1
            .WORD   BADREQ-1
            .WORD   SAM_OPEN-1
            .WORD   SAM_CLOSE-1
            .WORD   SAM_INIT-1



;-----------------------------------------------------------------------
;
;       SAM Driver -- Initialization
;
;-----------------------------------------------------------------------

SAM_INIT    .EQU    *
;            LDY     SLOT                ;Check for valid slot #
;            DEY
;            CPY     #04                 ;If carry set out of range
            RTS                          ;SOS will mark inactive
            .PAGE
;-----------------------------------------------------------------------
;
;       SAM Driver -- Open
;
;-----------------------------------------------------------------------

SAM_OPEN    .EQU    *
            LDX     SOSUNIT 
			LDA     OPENFLG,X
            BPL     $010                 ;not open
            LDA     #XNOTAVIL
            JSR     SYSERR

$010        LDA     #TRUE                ;set open now
            STA     OPENFLG,X
            RTS
            .PAGE
;-----------------------------------------------------------------------
;
;       SAM Driver -- Close
;
;-----------------------------------------------------------------------

SAM_CLOSE   .EQU    *
            LDX     SOSUNIT 
			LDA     OPENFLG,X
            BMI     $010                ;SAM or RECITER open ?
            JMP     NOTOPEN             ;No, error request

$010        LDA     #FALSE
            STA     OPENFLG,X           ;Yes, closed now
            RTS


;-----------------------------------------------------------------------
;
;       SAM Driver -- Read
;
;-----------------------------------------------------------------------

SAM_READ    .EQU    *
            LDX     SOSUNIT 
			LDA     OPENFLG,X           ;SAM or RECITER open ?
            BMI     $010                ;Yes
            JMP     NOTOPEN             ;No, return error

$010        LDA     READNUM             ;check number of previous reads
            BNE     RETPHONM            ;yes, there has been, return converted string
                                        ;otherwise, return error code
;
;return error code
;
            LDY     #00
            STY     L00F0               ;temp output hundreds digit
            STY     L00F1               ;temp output tens digit
            STY     L00F2               ;temp output ones digit
            LDA     ERROR

;convert to decimal, bit slow and long, but at least i can follow this one..
HUNDREDS    CMP     #100.               ;compare to 100
            BCC     TENS                ;if < 100, all done with hundreds digit
            SEC                      
            SBC     #100.             
            INC     L00F0               ;increment the hundreds digit
            JMP     HUNDREDS            ;run the hundreds loop again
                                     
TENS        CMP     #10.                ;compare to 10
            BCC     ONES                ;if < 10, all done with hundreds digit
            SEC                      
            SBC     #10.              
            INC     L00F1               ;increment the tens digit
            JMP     TENS                ;run the tens loop again
                                     
ONES        STA     L00F2               ;result is under 10, can copy directly to result  

            LDA     L00F0               ;hundreds digit 
            ORA     #030                ;convert to ascii
            STA     (BUFFER),Y          ;store in read buffer
            INY
            LDA     L00F1               ;tens digit
            ORA     #030                ;convert to ascii    
            STA     (BUFFER),Y          ;store in read buffer
            INY
            LDA     L00F2               ;ones digit
            ORA     #030                ;convert to ascii    
            STA     (BUFFER),Y          ;store in read buffer
            INY
            LDA     #ASC_CR             ;add CR
            STA     (BUFFER),Y          ;store in read buffer
            INY
            TYA
            LDY     #00
            STA     (RTNCNT),Y          ;actual characters read count, low byte
            LDA     #00
            INY
            STA     (RTNCNT),Y          ;actual characters read count, high byte
            RTS
;
;return converted string containing Phonemes
;
RETPHONM    LDY     #00
$020        LDA     INPUTBUF,Y          ;read converted text from INPUTBUF
            STA     (BUFFER),Y          ;store in read buffer
            INY
            CMP     #ASC_CR             ;if CR then this is the end of the string
            BNE     $020                ;no, next
            TYA                         ;yes, ret count = index +1
            LDY     #00
            STA     (RTNCNT),Y          ;actual characters read count, low byte
            LDA     #00
            INY
            STA     (RTNCNT),Y          ;actual characters read count, high byte
            RTS

            .PAGE

;-----------------------------------------------------------------------
;
;       SAM Driver -- Write
;
;-----------------------------------------------------------------------

SAM_WRITE   .EQU    *
            LDX     SOSUNIT 
			LDA     OPENFLG,X           ;SAM or RECITER open ?
            BMI     $010                ;Yes
            JMP     NOTOPEN             ;No, return error
;
; check for CR or LF as prints from Business basic
; seem to send CR and LF in seperate writes to the driver
; we just return and ignore these
;
$010        LDY     #000
            LDA     (BUFFER),Y          ;extended addressing read buffer
            CMP     #ASC_CR             
            BEQ     $030                ;yes, is CR, check reqcnt=1 also
            CMP     #ASC_LF
            BNE     $040                ;no keep going
$030        LDA     REQCNT              ;either CR or LF
            CMP     #01                 ;now check if reqcnt=1
            BNE     $040
            RTS                         ;yes, return write request doing nothing    
;
;copy extended addressing buffer to local input buffer
;to make it easily work with the existing apple ii code
;
$040        LDA     (BUFFER),Y          ;extended addressing read buffer
            CMP     #061                ;lower case 'a'
            BCC     $045                ;less than ascii 'a', keep going
            CMP     #07B                ;lower case 'z' + 1
            BCS     $045                ;greater/equal to ascii 'z' + 1,keep going
            AND     #05F                ;convert to upper case            
$045        STA     INPUTBUF,Y          ;copy to local input buffer
            INY
            CPY     REQCNT
            BNE     $040			
            LDA     #ASC_CR
            STA     INPUTBUF,Y          ;write CR to mark end of incoming string
;
; lets check for Apple3 specific pitch or speed command
; #P<decimal> sets Pitch (255 max)
; #S<decimal> sets Speed (255 max)
;
			LDY     #000
			LDA     INPUTBUF,Y          ;get first char
			CMP     #ASC_HASH           ;Change of Pitch or Speed?
			BNE     SPEAK                ;no, then go say the input string
			INY                         ;yes, get next char
            LDA     INPUTBUF,Y

            CMP     #ASC_P              ;is it a P, then pitch
            BNE     $050                ;no, check next
            JSR     GETVALUE            ;yes, get the value from the input string
            BCS     SPEAK               ;not valid value, try to say it
            STA     PITCH               ;update pitch
            RTS       
			
$050        CMP     #ASC_S              ;is it an S, then speed
            BNE     SPEAK               ;no, try to say the input string
            JSR     GETVALUE            ;get the value from the input string
            BCS     SPEAK               ;not valid value, try to say it
            STA     SPEED               ;update speed
            RTS       

GETVALUE    LDA     #000
            STA     L00E0               ;temp digit storage
            LDY     #02                 ;index to first digit
            LDA     REQCNT
            CMP     #03                 ;reqcnt starts from 1
            BEQ     ONEDIG              ;one digit
            CMP     #04
            BEQ     TWODIG              ;two digits
            CMP     #05
            BEQ     THREEDIG            ;three digits
            RTS                         ;error
            
THREEDIG    JSR     CHKCHAR
            BCS     ERRORRET            ;not a valid digit
            CMP     #001                ;is it a 1?
            BNE     $070
            LDA     #100.               ;yes, then add decimal 100
            STA     L00E0
            BPL     $080                ;always branch     
$070        CMP     #002                ;is it a 2?
            BNE     ERRORRET
            LDA     #200.
            STA     L00E0
$080        INY

TWODIG      JSR     CHKCHAR
            BCS     ERRORRET            ;not a valid digit
            ASL     A                   ;multiply by 2
            STA     L00E1               ;temp store in L00E1
            ASL     A                   ;again multiply by 2 (*4)
            ASL     A                   ;again multiply by 2 (*8)
            CLC
            ADC     L00E1               ;as result, A = x*8 + x*2
            ADC     L00E0               ;add to previous number
            STA     L00E0
            INY          
            
ONEDIG      JSR     CHKCHAR
            BCS     ERRORRET            ;not a valid digit
            ADC     L00E0               ;add previous value to A
            CLC                         ;no error
            RTS

;buff index in Y, return number in A
CHKCHAR		LDA     INPUTBUF,Y
            CMP     #030                ;ascii '0'
			BCC     ERRORRET            ;invalid char, set error and return
			CMP     #040                ;greater than ascii '9'
			BCS     ERRORRET            ;invalid char, set error and return
			AND     #00F                ;valid char, mask of high nibble
            CLC                         ;no error
            RTS

ERRORRET    SEC      
            RTS
            
SPEAK       LDA     #000
            STA     014FC               ;disable extended indirect addressing for FB/FC
            STA     READNUM             ;clear previous reads number
            LDA     EReg
            ORA     #BITON7
            STA     EReg                ;set 1MHz

            LDA     SOSUNIT
            BNE     RECTITER            ;Unit 1 = Reciter
            JSR     SAMML               ;Go say it, phonemes
            LDA     E_REG
            AND     #BITOFF7
            STA     E_REG               ;Restore Full Speed
            RTS
            
RECTITER    JSR     RECTML              ;go say it, english
            LDA     E_REG
            AND     #BITOFF7
            STA     E_REG               ;Restore Full Speed
            RTS
				
; code from apple ii sam
L8618       LDY     #000
            BIT     L00F2
            BPL     L8627
            SEC     
            LDA     #000
            SBC     L00F2
            STA     L00F2
            LDY     #080
L8627       STY     L00EF
            LDA     #000
            LDX     #008
L862D       ASL     L00F2
            ROL     A
            CMP     L00F1
            BCC     L8638
            SBC     L00F1
            INC     L00F2
L8638       DEX     
            BNE     L862D
            STA     L00F0
            BIT     L00EF
            BPL     L8648
            SEC     
            LDA     #000
            SBC     L00F2
            STA     L00F2
L8648       RTS
            
L8671       LDA     L8521
            CMP     #0FF
            BNE     L8679
            RTS     
			        
L8679       LDA     #000
            TAX     
            STA     L00E9
L867E       LDY     L00E9
            LDA     L8521,Y
            STA     L00F5
            CMP     #0FF
            BNE     L868C
            JMP     L86E9
L868C       CMP     #001
            BNE     L8693
            JMP     L8985
L8693       CMP     #002
            BNE     L869A
            JMP     L898B
L869A       LDA     L855D,Y
            STA     L00E8
            LDA     L8599,Y
            STA     L00E7
            LDY     L00E8
            INY     
            LDA     L860D,Y
            STA     L00E8
            LDY     L00F5
L86AE       LDA     FREQ1T,Y
            STA     BUFFER2,X
            LDA     FREQ2T,Y
            STA     BUFFER3,X
            LDA     FREQ3T,Y
            STA     BUFFER4,X
            LDA     AMPL1T,Y
            STA     BUFFER5,X
            LDA     AMPL2T,Y
            STA     BUFFER6,X
            LDA     AMPL3T,Y
            STA     BUFFER7,X
            LDA     SAMCONST,Y
            STA     BUFFER8,X
            CLC
			
L86DA       .EQU    *+1			; pitch modifier
            LDA     #040        ; pitch
            ADC     L00E8
            STA     BUFFER1,X
            INX     
            DEC     L00E7
            BNE     L86AE
            INC     L00E9
            BNE     L867E
L86E9       LDA     #000
            STA     L00E9
            STA     L00EE
            TAX     
L86F0       LDY     L8521,X
            INX     
            LDA     L8521,X
            CMP     #0FF
            BNE     L86FE
            JMP     L87FD
L86FE       TAX     
            LDA     BLENRNKT,X
            STA     L00F5
            LDA     BLENRNKT,Y
            CMP     L00F5
            BEQ     L8727
            BCC     L871A
            LDA     OUTBLENT,Y
            STA     L00E8
            LDA     INBLENDT,Y
            STA     L00E7
            JMP     L8731
L871A       LDA     INBLENDT,X
            STA     L00E8
            LDA     OUTBLENT,X
            STA     L00E7
            JMP     L8731
L8727       LDA     OUTBLENT,Y
            STA     L00E8
            LDA     OUTBLENT,X
            STA     L00E7
L8731       CLC     
            LDA     L00EE
            LDY     L00E9
            ADC     L8599,Y
            STA     L00EE
            ADC     L00E7
            STA     L00EA
            LDA     BUFF1ADR      ;>;#061 BUFFER1 pointer low byte
            STA     L00EB
            LDA     BUFF1ADR+1    ;<;#074 BUFFER1 pointer high byte
            STA     L00EC
            SEC     
            LDA     L00EE
            SBC     L00E8
            STA     L00E6
            CLC     
            LDA     L00E8
            ADC     L00E7
            STA     L00E3
            TAX
            DEX
            DEX
            BPL     L875D
            JMP     L87F6
L875D       LDA     L00E3
            STA     L00E5
            LDA     L00EC
            CMP     BUFF1ADR+1      ;<;#074
            BNE     L87A4
            LDY     L00E9
            LDA     L8599,Y
            LSR     A
            STA     L00E1
            INY     
            LDA     L8599,Y
            LSR     A
            STA     L00E2
            CLC     
            LDA     L00E1
            ADC     L00E2
            STA     L00E5
            CLC     
            LDA     L00EE
            ADC     L00E2
            STA     L00E2
            SEC     
            LDA     L00EE
            SBC     L00E1
            STA     L00E1
            LDY     L00E2
            LDA     (L00EB),Y
            SEC     
            LDY     L00E1
            SBC     (L00EB),Y
            STA     L00F2
            LDA     L00E5
            STA     L00F1
            JSR     L8618
            LDX     L00E5
            LDY     L00E1
            JMP     L87BA
L87A4       LDY     L00EA
            SEC
            LDA     (L00EB),Y
            LDY     L00E6
            SBC     (L00EB),Y
            STA     L00F2
            LDA     L00E5
            STA     L00F1
            JSR     L8618
            LDX     L00E5
            LDY     L00E6
L87BA       LDA     #000
            STA     L00F5
            CLC     
L87BF       LDA     (L00EB),Y
            ADC     L00F2
            STA     L00ED
            INY     
            DEX     
            BEQ     L87EB
            CLC     
            LDA     L00F5
            ADC     L00F0
            STA     L00F5
            CMP     L00E5
            BCC     L87E4
            LDA     L00F5
            SBC     L00E5
            STA     L00F5
            BIT     L00EF
            BMI     L87E2
            INC     L00ED
            BNE     L87E4
L87E2       DEC     L00ED
L87E4       LDA     L00ED
            STA     (L00EB),Y
            CLC     
            BCC     L87BF
L87EB       INC     L00EC
            LDA     L00EC
            CMP     BUFF8ADR+1      ;<;#07B  Buffer8 high byte
            BEQ     L87F6
            JMP     L875D
L87F6       INC     L00E9
            LDX     L00E9
            JMP     L86F0
L87FD       LDA     L00EE
            CLC     
            LDY     L00E9
            ADC     L8599,Y
            STA     L00ED
            LDX     #000
L8809       LDA     BUFFER2,X
            LSR     A
            STA     L00F5
            SEC     
            LDA     BUFFER1,X
            SBC     L00F5
            STA     BUFFER1,X
            DEX     
            BNE     L8809
            LDA     #000
            STA     L00E8
            STA     L00E7
            STA     L00E6
            STA     L00EE
            LDA     #048
            STA     L00EA
            LDA     #003
            STA     L00F5
			LDA     BUFF5ADR     ;>;#061 another pointer low byte
            STA     L00EB
            LDA     BUFF5ADR+1   ;<;#078 another pointer high byte
            STA     L00EC
L8835       LDY     #000
L8837       LDA     (L00EB),Y
            TAX     
            LDA     L85FD,X
            STA     (L00EB),Y
            DEY     
            BNE     L8837
            INC     L00EC
            DEC     L00F5
            BNE     L8835
            LDY     #000
            LDA     BUFFER1,Y
            STA     L00E9
            TAX     
            LSR     A
            LSR     A
            STA     L00F5
            SEC     
            TXA     
            SBC     L00F5
            STA     L00E3
            JMP     L8869
L885D       JSR     L88FA
            INY     
            INY     
            DEC     L00ED
            DEC     L00ED
            JMP     L88AB
L8869       LDA     BUFFER8,Y
            STA     L00E4
            AND     #0F8
            BNE     L885D
            LDX     L00E8       ; get phase
            CLC     
            LDA     SINET,X     ; load sine value (high 4 BITs)
            ORA     BUFFER5,Y   ; get amplitude (in low 4 BITs)
            TAX     
            LDA     MULTT,X     ; multiplication table
            STA     L00F5       ; store
            LDX     L00E7       ; get phase
            LDA     SINET,X     ; load sine value (high 4 BITs)
            ORA     BUFFER6,Y   ; get amplitude (in low 4 BITs)
            TAX     
            LDA     MULTT,X     ; multiplication table
            ADC     L00F5       ; add with previous values
            STA     L00F5       ; store
            LDX     L00E6       ; get phase
            LDA     RECTT,X     ; load rect value (high 4 BITs)
            ORA     BUFFER7,Y   ; get amplitude (in low 4 BITs)
            TAX     
            LDA     MULTT,X     ; multiplication table
            ADC     L00F5       ; add with previous values
            ADC     #080
                    
            LSR     A           ;A3 6bit dac
            LSR     A           ;A3 6bit dac
                    
            STA     DACOUT      ; output to DAC
            DEC     L00EA
            BNE     L88B2
            INY     
            DEC     L00ED
L88AB       BNE     L88AE
            RTS     
			        
L88AF       .EQU     *+1         ; speed modifier			
L88AE       LDA     #048        ; speed
            STA     L00EA
L88B2       DEC     L00E9
            BNE     L88D1
L88B6       LDA     BUFFER1,Y
            STA     L00E9
            TAX     
            LSR     A
            LSR     A
            STA     L00F5
            SEC     
            TXA     
            SBC     L00F5
            STA     L00E3
            LDA     #000
            STA     L00E8
            STA     L00E7
            STA     L00E6
            JMP     L8869
L88D1       DEC     L00E3
            BNE     L88DF
            LDA     L00E4
            BEQ     L88DF
            JSR     L88FA
            JMP     L88B6
L88DF       CLC     
            LDA     L00E8
            ADC     BUFFER2,Y
            STA     L00E8
            CLC     
            LDA     L00E7
            ADC     BUFFER3,Y
            STA     L00E7
            CLC     
            LDA     L00E6
            ADC     BUFFER4,Y
            STA     L00E6
            JMP     L8869
L88FA       STY     L00EE
            LDA     L00E4
            TAY     
            AND     #007
            TAX     
            DEX     
            STX     L00F5
            LDA     L89C1,X

            LSR     A                 ; A3 DAC, do it here before the loops
            LSR     A                 ; A3 DAC

            STA     L00F2
            CLC     
            LDA     SAMPDADR+1        ;<;sample data pointer high byte?
            ADC     L00F5
            STA     L00EC
            LDA     SAMPDADR          ;>;sample data pointer low byte?
            STA     L00EB
            TYA     
            AND     #0F8
            BNE     L8926
            LDY     L00EE
            LDA     BUFFER1,Y
            LSR     A
            LSR     A
            LSR     A
            LSR     A
            JMP     L8952
L8926       EOR     #0FF
            TAY     
L8929       LDA     #008
            STA     L00F5
            LDA     (L00EB),Y
L892F       ASL     A
            BCC     L8939
            LDX     L00F2
            STX     DACOUT      ; output to DAC
            BNE     L893F
L8939       LDX     #015          ; A3 DAC >2 bits  #054   01010100 -> 00010101
            STX     DACOUT      ; output to DAC
            NOP     
L893F       LDX     #007
L8941       DEX     
            BNE     L8941
            DEC     L00F5
            BNE     L892F
            INY     
            BNE     L8929
            LDA     #001
            STA     L00E9
            LDY     L00EE
            RTS     
L8952       EOR     #0FF
            STA     L00E8
            LDY     L00FF
L8958       LDA     #008
            STA     L00F5
            LDA     (L00EB),Y
L895E       ASL     A
            BCC     L8968
            LDX     #026             ; A3 dac #09A        10011010 -> 00100110        
            STX     DACOUT           ; output to DAC
            BMI     L896E
L8968       LDX     #019             ; A3 dac #064        01100100 -> 00011001
            STX     DACOUT           ; output to DAC
            NOP     
L896E       LDX     #006
L8970       DEX     
            BNE     L8970
            DEC     L00F5
            BNE     L895E
            INY     
            INC     L00E8
            BNE     L8958
            LDA     #001
            STA     L00E9
            STY     L00FF
            LDY     L00EE
            RTS     
L8985       LDA     #001
            STA     L00ED
            BNE     L898F
L898B       LDA     #0FF
            STA     L00ED
L898F       STX     L00EE
            TXA     
            SEC     
            SBC     #01E
            BCS     L8999
            LDA     #000
L8999       TAX     
L899A       LDA     BUFFER1,X
            CMP     #07F
            BNE     L89A5
            INX     
            JMP     L899A
L89A5       CLC     
            ADC     L00ED
            STA     L00E8
            STA     BUFFER1,X
L89AD       INX     
            cpx     L00EE
            BEQ     L89BE
            LDA     BUFFER1,X
            CMP     #0FF
            BEQ     L89AD
            LDA     L00E8
            JMP     L89A5
L89BE       JMP     L869A

;
;save registers			
;
SAVEREGS    STA     L00FC    
            STX     L00FB
            STY     L00FA
            RTS
;
;restore registers			
;
RESTREGS    LDA     L00FC
            LDX     L00FB
            LDY     L00FA
            RTS     
			        
L8E1C       JSR     SAVEREGS
            LDX     #0C7
            LDY     #0C8
L8E23       DEX     
            DEY     
            LDA     PHOINDEX,X
            STA     PHOINDEX,Y
            LDA     PHOLENGT,X
            STA     PHOLENGT,Y
            LDA     PHOSTRES,X
            STA     PHOSTRES,Y
            cpx     L00F6
            BNE     L8E23
            LDA     L00F9
            STA     PHOINDEX,X
            LDA     L00F8
            STA     PHOLENGT,X
            LDA     L00F7
            STA     PHOSTRES,X
            JSR     RESTREGS
            RTS     
			        
L8E4E       LDX     #000           ;clear all regs
            TXA     
            TAY     
            STA     L00FF          ;clear $00FF 
L8E54       STA     PHOSTRES,Y      ;clear buffer at $8BC6 to 0, $C7 bytes
            INY     
            CPY     #0C7
            BNE     L8E54
L8E5C       cpx     #0C8
            BCC     L8E66
            LDA     #ASC_CR
            STA     INPUTBUF,X
            RTS     
			        
L8E66       LDA     INPUTBUF,X
            CMP     #ASC_CR        ;CR
            BEQ     L8EE1          ;yes, then end of input string
            STA     L00FE          ;first char
            INX     
            LDA     INPUTBUF,X
            STA     L00FD          ;second char
            LDY     #000
L8E77       LDA     FICHRTAB,Y     ;lookup table for first char? $50 chars  8CD0-8D20
            CMP     L00FE          ;compare to first char
            BNE     L8E89          ;no match, try next
            LDA     SECHRTAB,Y     ;lookup table for second char? $50 chars  8D21-8D71
            CMP     #02A           ;ascii '*' indicates single char phoneme
            BEQ     L8E89
            CMP     L00FD
            BEQ     L8E90
L8E89       INY     
            CPY     #051           ;$50 char's to check
            BNE     L8E77          ;check next table entry for first char
            BEQ     L8E9C          ;not found in first char, try to match with second
L8E90       TYA     
            LDY     L00FF
            STA     PHOINDEX,Y
            INC     L00FF
            INX     
            JMP     L8E5C
L8E9C       LDY     #000
L8E9E       LDA     SECHRTAB,Y     ;lookup table for second char
            CMP     #02A           ;ascii '*'
            BNE     L8EAC
            LDA     FICHRTAB,Y
            CMP     L00FE
            BEQ     L8EB3
L8EAC       INY     
            CPY     #051
            BNE     L8E9E
            BEQ     L8EBE
L8EB3       TYA     
            LDY     L00FF
            STA     PHOINDEX,Y
            INC     L00FF
            JMP     L8E5C
L8EBE       LDA     L00FE
            LDY     #008
L8EC2       CMP     STRESINT,Y
            BEQ     L8ED7
            DEY     
            BNE     L8EC2
            STX     ERROR        ;error, phoneme no recognised
            RTS
			
L8ED7       TYA
            LDY     L00FF
            DEY     
            STA     PHOSTRES,Y
            JMP     L8E5C
L8EE1       LDA     #0FF
            LDY     L00FF
            STA     PHOINDEX,Y
            RTS     
			        
L8EE9       LDY     #000
L8EEB       LDA     PHOINDEX,Y
            CMP     #0FF
            BEQ     L8F0D
            TAX     
            LDA     PHOSTRES,Y
            BEQ     L8F03
            BMI     L8F03
            LDA     PHOSTRLT,X
            STA     PHOLENGT,Y
            JMP     L8F09
L8F03       LDA     PHONLENT,X
            STA     PHOLENGT,Y
L8F09       INY     
            JMP     L8EEB
L8F0D       RTS     
L8F0E       LDA     #000
            STA     L00FF
L8F12       LDX     L00FF
            LDA     PHOINDEX,X
            CMP     #0FF
            BNE     L8F1C
            RTS     
L8F1C       STA     L00F9
            TAY     
            LDA     L8D72,Y
            TAY     
            AND     #002
            BNE     L8F2C
            INC     L00FF
            JMP     L8F12
L8F2C       TYA     
            AND     #001
            BNE     L8F5D
            INC     L00F9
            LDY     L00F9
            LDA     PHOSTRES,X
            STA     L00F7
            LDA     PHONLENT,Y
            STA     L00F8
            INX     
            STX     L00F6
            JSR     L8E1C
            INC     L00F9
            LDY     L00F9
            LDA     PHONLENT,Y
            STA     L00F8
            INX     
            STX     L00F6
            JSR     L8E1C
            INC     L00FF
            INC     L00FF
            INC     L00FF
            JMP     L8F12
L8F5D       INX     
            LDA     PHOINDEX,X
            BEQ     L8F5D
            STA     L00F5
            CMP     #0FF
            BNE     L8F6C
            JMP     L8F7E
L8F6C       TAY     
            LDA     L8D72,Y
            AND     #008
            BNE     L8FA6
            LDA     L00F5
            CMP     #024
            BEQ     L8FA6
            CMP     #025
            BEQ     L8FA6
L8F7E       LDX     L00FF
            LDA     PHOSTRES,X
            STA     L00F7
            INX     
            STX     L00F6
            LDX     L00F9
            INX     
            STX     L00F9
            LDA     PHONLENT,X
            STA     L00F8
            JSR     L8E1C
            INC     L00F6
            INX     
            STX     L00F9
            LDA     PHONLENT,X
            STA     L00F8
            JSR     L8E1C
            INC     L00FF
            INC     L00FF
L8FA6       INC     L00FF
            JMP     L8F12
L8FAB       LDA     #000
            STA     L00FF
L8FAF       LDX     L00FF
L8FB1       LDA     PHOINDEX,X
            BNE     L8FBB
            INC     L00FF
            JMP     L8FAF
L8FBB       CMP     #0FF
            BNE     L8FC0
            RTS     
L8FC0       TAY     
            LDA     L8D72,Y
            AND     #010
            BEQ     L8FE7
            LDA     PHOSTRES,X
            STA     L00F7
            INX     
            STX     L00F6
            LDA     L8D72,Y
            AND     #020
            BEQ     L8FE3
            LDA     #015
L8FD9       STA     L00F9
            JSR     L8E1C
            LDX     L00FF
            JMP     L910B
L8FE3       LDA     #014
            BNE     L8FD9
L8FE7       LDA     PHOINDEX,X
            CMP     #04E
            BNE     L9005
            LDA     #018
L8FF0       STA     L00F9
            LDA     PHOSTRES,X
            STA     L00F7
            LDA     #00D
            STA     PHOINDEX,X
            INX     
            STX     L00F6
            JSR     L8E1C
            JMP     L918C
L9005       CMP     #04F
            BNE     L900D
            LDA     #01B
            BNE     L8FF0
L900D       CMP     #050
            BNE     L9015
            LDA     #01C
            BNE     L8FF0
L9015       TAY     
            LDA     L8D72,Y
            AND     #080
            BEQ     L9048
            LDA     PHOSTRES,X
            BEQ     L9048
            INX     
            LDA     PHOINDEX,X
            BNE     L9048
            INX     
            LDY     PHOINDEX,X
            LDA     L8D72,Y
            AND     #080
            BEQ     L9048
            LDA     PHOSTRES,X
            BEQ     L9048
            STX     L00F6
            LDA     #000
            STA     L00F7
            LDA     #01F
            STA     L00F9
            JSR     L8E1C
            JMP     L918C
L9048       LDX     L00FF
            LDA     PHOINDEX,X
            CMP     #017
            BNE     L9081
            DEX     
            LDA     PHOINDEX,X
            CMP     #045
            BNE     L9061
            LDA     #02A
            STA     PHOINDEX,X
            JMP     L9129
L9061       CMP     #039
            BNE     L906D
            LDA     #02C
            STA     PHOINDEX,X
            JMP     L9132
L906D       TAY     
            INX     
            LDA     L8D72,Y
            AND     #080
            BNE     L9079
            JMP     L918C
L9079       LDA     #012
            STA     PHOINDEX,X
            JMP     L918C
L9081       CMP     #018
            BNE     L909C
            DEX     
            LDY     PHOINDEX,X
            INX     
            LDA     L8D72,Y
            AND     #080
            BNE     L9094
            JMP     L918C
L9094       LDA     #013
            STA     PHOINDEX,X
            JMP     L918C
L909C       CMP     #020
L909E       BNE     L90B4
            DEX     
            LDA     PHOINDEX,X
            CMP     #03C
            BEQ     L90AB
            JMP     L918C
L90AB       INX     
            LDA     #026
            STA     PHOINDEX,X
            JMP     L918C
L90B4       CMP     #048
            BNE     L90CF
            INX     
            LDY     PHOINDEX,X
            DEX     
            LDA     L8D72,Y
            AND     #020
            BEQ     L90C7
            JMP     L90EA
L90C7       LDA     #04B
            STA     PHOINDEX,X
            JMP     L90EA
L90CF       CMP     #03C
            BNE     L90EA
            INX     
            LDY     PHOINDEX,X
            DEX     
            LDA     L8D72,Y
            AND     #020
            BEQ     L90E2
            JMP     L918C
L90E2       LDA     #03F
            STA     PHOINDEX,X
            JMP     L918C
L90EA       LDY     PHOINDEX,X
            LDA     L8D72,Y
            AND     #001
            BEQ     L910B
            DEX     
            LDA     PHOINDEX,X
            INX     
            CMP     #020
            BEQ     L9101
            TYA     
            JMP     L914A
L9101       SEC     
            TYA     
            SBC     #00C
            STA     PHOINDEX,X
            JMP     L918C
L910B       LDA     PHOINDEX,X
            CMP     #035
            BNE     L9129
            DEX     
            LDY     PHOINDEX,X
            INX     
            LDA     L8DC0,Y
            AND     #004
            BNE     L9121
            JMP     L918C
L9121       LDA     #010
            STA     PHOINDEX,X
            JMP     L918C
L9129       CMP     #02A
            BNE     L9132
L912D       TAY     
            INY     
            JMP     L9139
L9132       CMP     #02C
            BEQ     L912D
            JMP     L914A
L9139       STY     L00F9
            INX     
            STX     L00F6
            DEX     
            LDA     PHOSTRES,X
            STA     L00F7
            JSR     L8E1C
            JMP     L918C
L914A       CMP     #045
            BNE     L9150
            BEQ     L9157
L9150       CMP     #039
            BEQ     L9157
            JMP     L918C
L9157       DEX     
            LDY     PHOINDEX,X
            INX     
            LDA     L8D72,Y
            AND     #080
            BEQ     L918C
            INX     
            LDA     PHOINDEX,X
            BEQ     L9180
            TAY     
            LDA     L8D72,Y
            AND     #080
            BEQ     L918C
            LDA     PHOSTRES,X
            BNE     L918C
L9176       LDX     L00FF
            LDA     #01E
            STA     PHOINDEX,X
            JMP     L918C
L9180       INX     
            LDA     PHOINDEX,X
            TAY     
            LDA     L8D72,Y
            AND     #080
            BNE     L9176
L918C       INC     L00FF
            JMP     L8FAF
L9191       LDA     #000
            STA     L00FF
L9195       LDX     L00FF
            LDY     PHOINDEX,X
            CPY     #0FF
            BNE     L919F
            RTS     
L919F       LDA     L8D72,Y
            AND     #040
            BEQ     L91BE
            INX     
            LDY     PHOINDEX,X
            LDA     L8D72,Y
            AND     #080
            BEQ     L91BE
            LDY     PHOSTRES,X
            BEQ     L91BE
            BMI     L91BE
            INY     
            DEX     
            TYA     
            STA     PHOSTRES,X
L91BE       INC     L00FF
            JMP     L9195
L91C3       LDX     #0FF
            STX     L00F3
            INX     
            STX     L00F4
            STX     L00FF
L91CC       LDX     L00FF
            LDY     PHOINDEX,X
            CPY     #0FF
            BNE     L91D6
            RTS     
L91D6       CLC     
            LDA     L00F4
            ADC     PHOLENGT,X
            STA     L00F4
            CMP     #0E8
            BCC     L91E5
            JMP     L920E
L91E5       LDA     L8DC0,Y
            AND     #001
            BEQ     L9203
            INX     
            STX     L00F6
            LDA     #000
            STA     L00F4
            STA     L00F7
            LDA     #0FE
            STA     L00F9
            JSR     L8E1C
            INC     L00FF
            INC     L00FF
            JMP     L91CC
L9203       CPY     #000
            BNE     L9209
            STX     L00F3
L9209       INC     L00FF
            JMP     L91CC
L920E       LDX     L00F3
            LDA     #01F
            STA     PHOINDEX,X
            LDA     #004
            STA     PHOLENGT,X
            LDA     #000
            STA     PHOSTRES,X
            INX     
            STX     L00F6
            LDA     #0FE
            STA     L00F9
            LDA     #000
            STA     L00F4
            STA     L00F7
            JSR     L8E1C
            INX     
            STX     L00FF
            JMP     L91CC
			
L9235       .BYTE   02C

L9236       LDA     #000
            TAX     
            TAY     
L923A       LDA     PHOINDEX,X
            CMP     #0FF
            BNE     L924A
            LDA     #0FF
            STA     L8521,Y
            JSR     L8671
            RTS     
L924A       CMP     #0FE
            BNE     L9262
            INX     
            STX     L9235
            LDA     #0FF
            STA     L8521,Y
            JSR     L8671
            LDX     L9235
            LDY     #000
            JMP     L923A
L9262       CMP     #000
            BNE     L926A
            INX     
            JMP     L923A
L926A       STA     L8521,Y
            LDA     PHOLENGT,X
            STA     L8599,Y
            LDA     PHOSTRES,X
            STA     L855D,Y
            INX     
            INY     
            JMP     L923A
L927E       LDX     #000
L9280       LDY     PHOINDEX,X
            CPY     #0FF
            BNE     L928A
L9287       JMP     L92CC
L928A       LDA     L8DC0,Y
            AND     #001
            BNE     L9295
            INX     
            JMP     L9280
L9295       STX     L00FF
L9297       DEX     
            BEQ     L9287
            LDY     PHOINDEX,X
            LDA     L8D72,Y
            AND     #080
            BEQ     L9297
L92A4       LDY     PHOINDEX,X
            LDA     L8DC0,Y
            AND     #020
            BEQ     L92B5
            LDA     L8D72,Y
            AND     #004
            BEQ     L92C3
L92B5       LDA     PHOLENGT,X
            STA     L00F5
            LSR     A
            CLC     
            ADC     L00F5
            ADC     #001
            STA     PHOLENGT,X
L92C3       INX     
            cpx     L00FF
            BNE     L92A4
            INX     
            JMP     L9280
L92CC       LDX     #000
            STX     L00FF
L92D0       LDX     L00FF
            LDY     PHOINDEX,X
            CPY     #0FF
            BNE     L92DA
            RTS     
L92DA       LDA     L8D72,Y
            AND     #080
            BNE     L92E4
            JMP     L9348
L92E4       INX     
            LDY     PHOINDEX,X
            LDA     L8D72,Y
            STA     L00F5
            AND     #040
            BEQ     L9324
            LDA     L00F5
            AND     #004
            BEQ     L930A
            DEX     
            LDA     PHOLENGT,X
            STA     L00F5
            LSR     A
            LSR     A
            CLC     
            ADC     L00F5
            ADC     #001
            STA     PHOLENGT,X
L9307       JMP     L93B4
L930A       LDA     L00F5
            AND     #001
            BEQ     L9307
            DEX     
            LDA     PHOLENGT,X
            TAY     
            LSR     A
            LSR     A
            LSR     A
            STA     L00F5
            SEC     
            TYA     
            SBC     L00F5
            STA     PHOLENGT,X
            JMP     L93B4
L9324       CPY     #012
            BEQ     L932F
            CPY     #013
            BEQ     L932F
L932C       JMP     L93B4
L932F       INX     
            LDY     PHOINDEX,X
            LDA     L8D72,Y
            AND     #040
            BEQ     L932C
            LDX     L00FF
            LDA     PHOLENGT,X
            SEC     
            SBC     #001
            STA     PHOLENGT,X
            JMP     L93B4
L9348       LDA     L8DC0,Y
            AND     #008
            BEQ     L936B
            INX     
            LDY     PHOINDEX,X
            LDA     L8D72,Y
            AND     #002
            BNE     L935D
L935A       JMP     L93B4
L935D       LDA     #006
            STA     PHOLENGT,X
            DEX     
            LDA     #005
            STA     PHOLENGT,X
            JMP     L93B4
L936B       LDA     L8D72,Y
            AND     #002
            BEQ     L9398
L9372       INX     
            LDY     PHOINDEX,X
            BEQ     L9372
            LDA     L8D72,Y
            AND     #002
            BEQ     L935A
            LDA     PHOLENGT,X
            LSR     A
            CLC     
            ADC     #001
            STA     PHOLENGT,X
            LDX     L00FF
            LDA     PHOLENGT,X
            LSR     A
            CLC     
            ADC     #001
            STA     PHOLENGT,X
L9395       JMP     L93B4
L9398       LDA     L8DC0,Y
            AND     #010
            BEQ     L9395
            DEX     
            LDY     PHOINDEX,X
            LDA     L8D72,Y
            AND     #002
            BEQ     L9395
            INX     
            LDA     PHOLENGT,X
            SEC     
            SBC     #002
            STA     PHOLENGT,X
L93B4       INC     L00FF
            JMP     L92D0
;
;S.A.M. from machine language			
;
SAMML       LDA     #0FF           ; set no error    
            STA     ERROR
            JSR     L8E4E
            LDA     ERROR
            CMP     #0FF
            BNE     L946F
            JSR     L8FAB
            JSR     L9191
            JSR     L8EE9
            JSR     L927E
            JSR     L8F0E
            CLC     
            LDA     PITCH
            STA     L86DA
            LDA     SPEED
            STA     L88AF
            LDX     #000
L9453       LDA     PHOINDEX,X
            CMP     #050
            BCS     L945F
            INX     
            BNE     L9453
            BEQ     L9464
L945F       LDA     #0FF
            STA     PHOINDEX,X
L9464       JSR     L91C3
            LDA     #0FF
            STA     L8AC4
            JSR     L9236
L946F       RTS

;            .PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Reciter Machine Language entry
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RECTML      LDA     #020         ;' ' space char
            STA     RECTBUFF     ;store in first char of reciter buffer
            LDX     #001
            LDY     #000
L5A10       LDA     INPUTBUF,Y   ;copy input buffer to reciter buffer
            STA     RECTBUFF,X
            INX     
            INY     
            CPY     #0FF
            BNE     L5A10
            JSR     L5A23        ;process input string
L5A1F       JSR     SAMML        ;Go say it, SAM machine language entry
            RTS
;
; Translate the text to phonemes
;			
L5A23       LDA     #0FF
            STA     L00FA        ;input string index
L5A27       LDA     #0FF
            STA     L00F5        ;output string index
L5A2B       INC     L00FA
            LDX     L00FA
            LDA     RECTBUFF,X   ;get char
            STA     L00FD
            CMP     #ASC_CR      ;CMP to CR
            BNE     L5A40        ;no continue
            INC     L00F5        ;yes
            LDX     L00F5
            STA     INPUTBUF,X   ;store CR in output string
            RTS                  ;all done

L5A40       CMP     #02E         ;is it '.'
            BNE     L5A5E
            INX                  ;yes
            LDA     RECTBUFF,X   ;get next char
            AND     #07F         ;mask of high BIT
            TAY     
            LDA     CHRFLAGS,Y   ;get flags for this char?
            AND     #001         ;check flag BIT 0
            BNE     L5A5E        ;not set continue processing
            INC     L00F5        ;yes
            LDX     L00F5
            LDA     #02E         ;'.' 
            STA     INPUTBUF,X   ;store in output string
            JMP     L5A2B        ;continue with next char
                    
L5A5E       LDA     L00FD        ;load current char
            AND     #07F         ;mask of high BIT
            TAY     
            LDA     CHRFLAGS,Y   ;get flags for this char?
            STA     L00F6
            AND     #002         ;check flag BIT 1
            BEQ     L5A77        ;
            LDA     RULESADR     ;setup pointer to rules  #06A
            STA     L00FB        ;16bit pointer is in FB FC
            LDA     RULESADR+1   ;                        #05E
            STA     L00FC
            JMP     L5ABB        ;parse rule
                    
L5A77       LDA     L00F6        ;load from temp charflag
            BNE     L5AA4        ;if flag 0, invalid char
            LDA     #020         ;replace with ascii ' ';' '
            STA     RECTBUFF,X
            INC     L00F5
            LDX     L00F5
            CPX     #078         ;max string length?
            BCS     L5A8F
            STA     INPUTBUF,X
            JMP     L5A2B
			
L5A8E       .BLOCK  1,0B1

L5A8F       LDA     #ASC_CR         ;CR
            STA     INPUTBUF,X
			LDA     L00FA
            STA     L5A8E
            JSR     L5A1F
            LDA     L5A8E
            STA     L00FA
            JMP     L5A27

L5AA4       LDA     L00F6        ;load from temp charflag;load from temp charflag
            AND     #080         ;check bit 7;check bit 7
            BNE     L5AAB        ;yes set, so is char from A-Z
            .BYTE   000          ;BRK - error, to do;BRK   error, todo
                               
L5AAB       LDA     L00FD        ;load current char
            SEC                
            SBC     #ASC_A       ;subtract ascii 'A', this gives us an index from 0
            ASL     A            ;multiply by 2, as we have 2 byte pointers
            TAX                  ;
            LDA     RULECHAR,X   ;get the rules table low byte address for that letter
            STA     L00FB        ;store in the lookup pointer - low byte
            LDA     RULECHAR+1,X ;get the rules table high byte address for that letter
            STA     L00FC        ;store in the lookup pointer - high byte
;
; parse rule
;			
L5ABB       LDY     #000
L5ABD       CLC                  ;inc 16bit rules pointer
            LDA     L00FB        ;in FB/FC
            ADC     #001
            STA     L00FB
            LDA     L00FC
            ADC     #000
            STA     L00FC
            LDA     (L00FB),Y    ;load char from rules
            BPL     L5ABD        ;check if last char of rule (msb=1)
            INY                  ;yes MSB set, inc and we are at the start of a rule
L5ACF       LDA     (L00FB),Y
            CMP     #028         ;check if '('
            BEQ     L5AD9        ;yes
            INY     
            JMP     L5ACF
L5AD9       STY     L00FF        ;index to ( in FF
L5ADB       INY     
            LDA     (L00FB),Y
            CMP     #029         ;check if ')'
            BNE     L5ADB
            STY     L00FE        ;index to ) in FE
L5AE4       INY     
            LDA     (L00FB),Y
            AND     #07F         ;clear MSB
            CMP     #03D         ;'='
            BNE     L5AE4
            STY     L00FD        ;index to '=' in FD
            LDX     L00FA        ;current index to input char in FA?
            STX     L00F9
            LDY     L00FF
            INY     
L5AF6       LDA     RECTBUFF,X   ;current char in input
            STA     L00F6
            LDA     (L00FB),Y    ;get first char of current rule
            CMP     L00F6        ;is it match
            BEQ     L5B04        ;yes
            JMP     L5ABB        ;no, next rule
;                   
L5B04       INY     
            CPY     L00FE        ;check against ) position
            BNE     L5B0C        ;no
            JMP     L5B12        ;yes, all matches up to )
L5B0C       INX     
            STX     L00F9
            JMP     L5AF6        ;check next
L5B12       LDA     L00FA
            STA     L00F8
L5B16       LDY     L00FF
            DEY     
            STY     L00FF
            LDA     (L00FB),Y
            STA     L00F6
            BPL     L5B24        ;is it last char of rule
            JMP     L5CB9        ;yes
                    
L5B24       AND     #07F         ;no
            TAX     
            LDA     CHRFLAGS,X
            AND     #080         ; check BIT 7
            BEQ     L5B40
            LDX     L00F8
            DEX     
            LDA     RECTBUFF,X
            CMP     L00F6
            BEQ     L5B3B
            JMP     L5ABB

L5B3B       STX     L00F8
            JMP     L5B16
L5B40       LDA     L00F6
            CMP     #020       ;' '
            BNE     L5B49
            JMP     L5B84
L5B49       CMP     #023       ;'#'
            BNE     L5B50
            JMP     L5B93
L5B50       CMP     #02E       ;'.'
            BNE     L5B57
            JMP     L5B9D
L5B57:      CMP     #026       ;'&'
            BNE     L5B5E
            JMP     L5BAC
L5B5E       CMP     #040       ;'@'
            BNE     L5B65
            JMP     L5BCC
L5B65       CMP     #05E       ;'^'
            BNE     L5B6C
            JMP     L5BF1
L5B6C       CMP     #02B       ;'+'
            BNE     L5B73
            JMP     L5C00
L5B73       CMP     #03A       ;':'
            BNE     L5B7A
            JMP     L5C15
L5B7A       ;JSR     LFF3A         ;bell
            ;JSR     LFF3A
            ;JSR     LFF3A
            ;.BYTE   000         ;BRK
			RTS                ;error, todo

L5B84       JSR     L5C24
            AND     #080
            BEQ     L5B8E
            JMP     L5ABB
L5B8E       STX     L00F8
            JMP     L5B16
L5B93       JSR     L5C24
            AND     #040
            BNE     L5B8E
            JMP     L5ABB
L5B9D       JSR     L5C24
            AND     #008
            BNE     L5BA7
            JMP     L5ABB
L5BA7       STX     L00F8
            JMP     L5B16
L5BAC       JSR     L5C24
            AND     #010
            BNE     L5BA7
            LDA     RECTBUFF,X
            CMP     #ASC_H          ;'H'
            BEQ     L5BBD
            JMP     L5ABB
L5BBD       DEX     
            LDA     RECTBUFF,X
            CMP     #ASC_C          ;'C'
            BEQ     L5BA7
            CMP     #ASC_S          ;'S'
            BEQ     L5BA7
            JMP     L5ABB
L5BCC       JSR     L5C24
            AND     #004
            BNE     L5BA7
            LDA     RECTBUFF,X
            CMP     #ASC_H          ;'H'
            BEQ     L5BDD
            JMP     L5ABB
L5BDD       CMP     #ASC_T          ;'T'
            BEQ     L5BEC
            CMP     #ASC_C          ;'C'
            BEQ     L5BEC
            CMP     #ASC_S          ;'S'
            BEQ     L5BEC
            JMP     L5ABB
L5BEC       STX     L00F8
            JMP     L5B16
L5BF1       JSR     L5C24
            AND     #020
            BNE     L5BFB
            JMP     L5ABB
L5BFB:      STX     L00F8
            JMP     L5B16
L5C00:      LDX     L00F8
            DEX     
            LDA     RECTBUFF,X
            CMP     #ASC_E           ;'E'
            BEQ     L5BFB
            CMP     #ASC_I           ;'I'
            BEQ     L5BFB
L5C0E       CMP     #ASC_Y           ;'Y'
            BEQ     L5BFB
            JMP     L5ABB
L5C15       JSR     L5C24
            AND     #020
            BNE     L5C1F
            JMP     L5B16
L5C1F       STX     L00F8
            JMP     L5C15

L5C24       LDX     L00F8
            DEX     
            LDA     RECTBUFF,X
            AND     #07F
            TAY     
            LDA     CHRFLAGS,Y
            RTS     
;
; get flags
;			        
L5C43       LDX     L00F7
            INX     
            LDA     RECTBUFF,X
            AND     #07F
            TAY     
            LDA     CHRFLAGS,Y
            RTS
			
L5C50       LDX     L00F7         ;is a '%'
            INX     
            LDA     RECTBUFF,X
            CMP     #ASC_E          ;'E'
            BNE     L5CA2
            INX     
            LDA     RECTBUFF,X
            AND     #07F
            TAY     
            DEX     
            LDA     CHRFLAGS,Y
            AND     #080
            BEQ     L5C71
            INX     
            LDA     RECTBUFF,X
            CMP     #ASC_R          ;'R'
            BNE     L5C76
L5C71       STX     L00F7
            JMP     L5CBD
L5C76       CMP     #ASC_S          ;'S'
            BEQ     L5C71
            CMP     #ASC_D          ;'D'
            BEQ     L5C71
            CMP     #ASC_L          ;'L'
            BNE     L5C8C
            INX     
            LDA     RECTBUFF,X
            CMP     #ASC_Y         ;'Y'
            BNE     L5CB6
            BEQ     L5C71
L5C8C       CMP     #ASC_F         ;'F'
            BNE     L5CB6
            INX     
            LDA     RECTBUFF,X
            CMP     #ASC_U         ;'U'
            BNE     L5CB6
            INX     
            LDA     RECTBUFF,X
            CMP     #ASC_L         ;'L'
            BEQ     L5C71
            BNE     L5CB6
L5CA2       CMP     #ASC_I         ;'I'
            BNE     L5CB6
            INX     
            LDA     RECTBUFF,X
            CMP     #ASC_N         ;'N'
            BNE     L5CB6
            INX     
            LDA     RECTBUFF,X
            CMP     #ASC_G         ;'G'
            BEQ     L5C71
L5CB6       JMP     L5ABB
;
;matching rule?
;
L5CB9       LDA     L00F9
            STA     L00F7
L5CBD       LDY     L00FE
            INY     
            CPY     L00FD
            BNE     L5CC7
            JMP     L5DD4
L5CC7       STY     L00FE
            LDA     (L00FB),Y
            STA     L00F6
            AND     #07F
            TAX     
            LDA     CHRFLAGS,X
            AND     #080             ;check flag bit7
            BEQ     L5CE9
            LDX     L00F7
            INX     
            LDA     RECTBUFF,X
            CMP     L00F6
            BEQ     L5CE4
            JMP     L5ABB
L5CE4       STX     L00F7
            JMP     L5CBD
L5CE9       LDA     L00F6
            CMP     #020      ;' '
            BNE     L5CF2
            JMP     L5D34
L5CF2       CMP     #023      ;'#'
            BNE     L5CF9
            JMP     L5D43
L5CF9       CMP     #02E      ;'.'
            BNE     L5D00
            JMP     L5D4D
L5D00       CMP     #026      ;'&'
            BNE     L5D07
            JMP     L5D5C
L5D07       CMP     #040      ;'@'
            BNE     L5D0E
            JMP     L5D7C
L5D0E       CMP     #05E      ;'^'
            BNE     L5D15
            JMP     L5DA1
L5D15       CMP     #02B      ;'+'
            BNE     L5D1C
            JMP     L5DB0
L5D1C       CMP     #03A      ;':'
            BNE     L5D23
            JMP     L5DC5
L5D23       CMP     #025      ;'%'
            BNE     L5D2A
            JMP     L5C50
L5D2A       RTS               ;error, todo
;
;char is a ' '
L5D34       JSR     L5C43     ;get char flags
            AND     #080      ;check flag bit7
            BEQ     L5D3E
            JMP     L5ABB     ;check next rule
L5D3E       STX     L00F7
            JMP     L5CBD
;char is a '#'
L5D43       JSR     L5C43     ;get char flags
            AND     #040
            BNE     L5D3E
            JMP     L5ABB     ;check next rule
;char is a '.'
L5D4D       JSR     L5C43     ;get char flags
            AND     #008
            BNE     L5D57
            JMP     L5ABB     ;check next rule
L5D57       STX     L00F7
            JMP     L5CBD
;char is a '&'
L5D5C       JSR     L5C43     ;get char flags
            AND     #010
            BNE     L5D57
            LDA     RECTBUFF,X
            CMP     #ASC_H
            BEQ     L5D6D
            JMP     L5ABB     ;check next rule

L5D6D       INX     
            LDA     RECTBUFF,X
            CMP     #ASC_C
            BEQ     L5D57
            CMP     #ASC_S
            BEQ     L5D57
            JMP     L5ABB
L5D7C       JSR     L5C43     ;is a '@'
            AND     #004
            BNE     L5D57
            LDA     RECTBUFF,X
            CMP     #ASC_H
            BEQ     L5D8D
            JMP     L5ABB
L5D8D       CMP     #ASC_T
            BEQ     L5D9C
            CMP     #ASC_C
            BEQ     L5D9C
            CMP     #ASC_S
            BEQ     L5D9C
            JMP     L5ABB     ;check next rule
L5D9C       STX     L00F7
            JMP     L5CBD
;
;char is a '^'
L5DA1       JSR     L5C43     ;get char flags
            AND     #020
            BNE     L5DAB
            JMP     L5ABB     ;check next rule
L5DAB       STX     L00F7
            JMP     L5CBD
;
;char is a '+'
L5DB0       LDX     L00F7 
            INX     
            LDA     RECTBUFF,X
            CMP     #ASC_E
            BEQ     L5DAB
            CMP     #ASC_I
            BEQ     L5DAB
            CMP     #ASC_Y
            BEQ     L5DAB
            JMP     L5ABB     ;check next rule
;
;char is a ';'
L5DC5       JSR     L5C43      ;get char flags
            AND     #020
            BNE     L5DCF
            JMP     L5CBD
L5DCF       STX     L00F7
            JMP     L5DC5
                    
L5DD4       LDY     L00FD
            LDA     L00F9
            STA     L00FA
L5DDA       LDA     (L00FB),Y
            STA     L00F6
            AND     #07F       ;was ora 80 for a2
            CMP     #03D       ;'="
            BEQ     L5DEB
            INC     L00F5
            LDX     L00F5
            STA     INPUTBUF,X
L5DEB       BIT     L00F6
            BPL     L5DF2      ;was bmi for a2
            JMP     L5A2B
L5DF2       INY     
            BNE     L5DDA    ; assume y is never zero?

            .PAGE            
            
;-----------------------------------------------------------------------
;
;       SAM Driver -- Status
;
;-----------------------------------------------------------------------

SAM_STAT    LDX     SOSUNIT 
			LDA     OPENFLG,X                 ;SAM or RECITER open ?
            BMI     $010
            JMP     NOTOPEN                   ;No, return error

$010        LDY     #00
            LDX     CTLSTAT
            BEQ     STAT00
            DEX
            BEQ     STAT01
            DEX
            BEQ     STAT02
            DEX
            BEQ     STAT03
BADCTL      LDA     #XCTLCODE                 ;Invalid control code
            JSR     SYSERR

STAT00      RTS                               ;0 -- NOP

STAT01      TYA                               ;1 -- Status table
            STA     (CSLIST),Y
            RTS

STAT02      TYA                               ;2 -- New line
            STA     (CSLIST),Y
            RTS

STAT03      RTS
            .PAGE
;-----------------------------------------------------------------------
;
;       SAM Driver -- Control
;
;-----------------------------------------------------------------------

SAM_CNTL    LDX     SOSUNIT 
			LDA     OPENFLG,X                 ;SAM or RECITER open ?
            BMI     $010                      ;Yes
            JMP     NOTOPEN

$010        LDX     CTLSTAT
            BEQ     CNTL00
            DEX
            BEQ     CNTL01
            DEX
            BEQ     CNTL02
            JMP     BADCTL                    ;Invalid request number

CNTL00      RTS


CNTL01      RTS


CNTL02      RTS                               ;2 New line
            .END

