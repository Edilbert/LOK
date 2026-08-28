   .CPU 6502
   .LOAD  $0401
   .STORE $0401,EOP-$0401,"lords.prg"

F          = $04 ; ENDCHR, COUNT
I          = $06 ; DIMFLG
J          = $07 ; VALTYP
K          = $08 ; INTFLG
DEBUG      = $09 ; GARBFL
CODE       = $0a ; SUBFLG, INPFLG
SECP       = $0c ; TANSGN, DS_1
THIP       = $0e ; DS_2, DS_3
LENA       = $20 ; INDEXA+1
LENG       = $21 ; INDEXB
REGA       = $22 ; INDEXB+1
REGX       = $23 ; FAC3EX
REGY       = $24 ; FAC3M1
DATAX      = $25 ; FAC3M2
R          = $26 ; FAC3M3
GRP        = $36 ; CURLIN
ITM        = $37 ; CURLIN+1
OBJ        = $38 ; OLDLIN
CCOL       = $39 ; OLDLIN+1
RCOL       = $3a ; OLDTXT

STATUS     = $96 ; I/O
VERCK      = $9d ; load / verify flag
EAL        = $c9 ; end address for save
FNLEN      = $d1 ; filename length
SA         = $d3 ; secondary address
FA         = $d4 ; DOS unit
FNADR      = $da ; filename address
STAL       = $fb ; start address for load/save

CR         = 13

BASIC      = $D3B6

MONITOR    = $d472 ; BASIC2 = $fd11

TIMER      = $e844 ; CBM

LOAD       = $f356
SAVE       = $f6e3
OPEN       = $ffc0
CLOSE      = $ffc3
CHKIN      = $ffc6
CHKOUT     = $ffc9
CLRCHN     = $ffcc
CHRIN      = $ffcf
CHROUT     = $ffd2
STOP       = $ffe1
GETIN      = $ffe4
CLALL      = $ffe7
UDTIM      = $ffea

    * = $0401

        .WORD Link
        .WORD 2026              ; line number
        .BYTE $9e               ; SYS  token
        .BYTE "1037",0          ; PET  start
Link    .WORD 0

***************
* START ; $040d
***************
        LDX #40
        STX RCOL
        LDX #0
        STX CCOL
        LDA #$93      ;clear screen
        JSR CHROUT
        LDA #$0e      ;lower case charset
        JSR CHROUT
        LDA #$b2      ;lords of karma
        JSR PRINOA
        JSR RESET
        JMP ACCEPT_INPUT

************
MODULE NEG_X
************
        BPL _ret
        SEC
        LDA #0
        SBC 0,X
        STA 0,X
        LDA #0
        SBC 1,X
        STA 1,X
_ret    RTS

*************
MODULE DIVIDE
*************
; Input : CODE = dividend
;         SECP = divisor
; Output: CODE = quotient
;         THIP = remainder

; CODE = CODE / SECP (remainder THIP)

        LDA #0
        STA THIP        ; clear remainder
        STA THIP+1

        LDA SECP+1
        STA LENA        ; sign of divisor
        ORA SECP
        BEQ _err        ; division by zero

        LDX #SECP
        LDA LENA
        JSR NEG_X       ; make divisor positive

        LDX #CODE
        LDA CODE+1
        STA LENG        ; sign of dividend
        JSR NEG_X       ; make dividend positive

        LDY #16
_loop   ASL CODE
        ROL CODE+1
        ROL THIP
        ROL THIP+1
        SEC
        LDA THIP
        SBC SECP
        TAX
        LDA THIP+1
        SBC SECP+1
        BCC _next
        STX THIP
        STA THIP+1
        INC CODE
_next   DEY
        BNE _loop

        LDX #CODE
        LDA LENA        ; sign of divisor
        EOR LENG        ; sign of dividend
        JSR NEG_X       ; sign of quotient
        LDX #THIP
        LDA LENG        ; sign of dividend
        JMP NEG_X       ; sign of remainder
_err    BRK
ENDMOD

*****************
MODULE PRINT_FOXY
*****************
; Input : (X/Y) = value
        LDA #$80
        PHA             ; end marker
        STX CODE
        STY CODE+1
        TYA
        BPL _laba
        LDA #'-'
        JSR BUFPRI
        SEC
        LDA #0
        SBC CODE
        STA CODE
        LDA #0
        SBC CODE+1
        STA CODE+1
_laba   LDA #10
        STA SECP
        LDA #0
        STA SECP+1
_labb   JSR DIVIDE
        LDA THIP        ; remainder
        ORA #'0'
        PHA
        LDA CODE
        ORA CODE+1
        BNE _labb
        PLA
_labc   JSR BUFPRI
        PLA
        BPL _labc
        RTS
ENDMOD

****************
MODULE PRINT_HEX
****************
        PHA
        LSR A
        LSR A
        LSR A
        LSR A
        JSR BIN_HEX
        PLA
        AND #15

BIN_HEX CMP #10
        BCC _lab
        ADC #6
_lab    ADC #'0'
        JMP BUFPRI
ENDMOD


***************
MODULE MULTIPLY
***************
; Input : CODE * SECP
; Output: THIP
        LDA #0
        STA THIP
        STA THIP+1
        LDY #16
_loop   LSR CODE+1
        ROR CODE
        BCC _skip
        CLC
        LDA SECP
        ADC THIP
        STA THIP
        LDA SECP+1
        ADC THIP+1
        STA THIP+1
_skip   ASL SECP
        ROL SECP+1
        DEY
        BNE _loop
        RTS
ENDMOD

*************
MODULE PRINOX
*************
        ASL A
        TAX
        LDA PTR_MSG+513,X
        LDY PTR_MSG+512,X
        BNE PRIYA

******
PRINOA
******
        TAX
        BEQ _ret
        ASL A
        TAX
        BCC _lopage
        LDA PTR_MSG+257,X
        LDY PTR_MSG+256,X
        BCS PRIYA
_lopage LDA PTR_MSG+1,X
        LDY PTR_MSG,X

*****
PRIYA
*****
        STA CODE+1
        STY CODE
        ORA CODE
        BEQ _ret

        LDY #0
_loop   LDA (CODE),Y
        CMP #13
        BCC _end
        JSR BUFPRI
        INY
        BNE _loop
_end    CMP #10
        BNE _ret
        LDA #13
        JMP BUFPRI
_ret    RTS
ENDMOD

*************
MODULE BUFPRI
*************
        CMP #$40
        BCC _labb
        CMP #$60
        BCS _laba
        ORA #$80
        .BYTE $2c
_laba   SBC #$20
_labb   STA DATAX
        PHA
        TXA
        PHA
        TYA
        PHA
        LDX CCOL
        INC CCOL
        LDA DATAX
        STA FORBUF,X
        INX
        CMP #CR
        BEQ _flush
        CPX RCOL        ; 40 or 80
        BCC _exit

_find   DEX
        BMI _exit       ; safety
        LDA FORBUF,X
        CMP #' '
        BNE _find
        LDA #CR
        STA FORBUF,X
        INX             ; chars to print
        .BYTE $2c       ; skip next

_flush  LDX CCOL
        LDY #0
_pril   LDA FORBUF,Y
        JSR CHROUT
        INY
        DEX
        BNE _pril
        CPY CCOL
        BCS _cr

        LDX #0
_scroll LDA FORBUF,Y
        STA FORBUF,X
        INX
        INY
        CPY CCOL
        BCC _scroll
_cr     STX CCOL

_exit   PLA
        TAY
        PLA
        TAX
        PLA
        RTS

************
MODULE DELAY
************
        LDY #0
_a      LDA #0
_b      CLC
        ADC #1
        BNE _b
        INY
        BNE _a
        DEX
        BNE DELAY
        RTS
ENDMOD

*************
MODULE PROMPT
*************
        LDA #'>'
        JSR CHROUT
        LDA #0
        LDX #40
_clear  STA BUFFER-1,X
        DEX
        BNE _clear

_loop   JSR CHRIN
        CMP #CR
        BEQ _done
        CMP #'#'
        BNE _laba
        LDA DEBUG
        EOR #$ff
        STA DEBUG
        JMP _loop
_laba   CMP #'&'
        BNE _labb
        BRK
_labb   CMP #'A'
        BCC _blank
        CMP #'Z'+1
        BCC _store
_blank  LDA #0
_store  AND #$1f
        STA BUFFER,X
        INX
        CPX #39
        BCC _loop
_done   LDA #CR
        JSR BUFPRI
        LDA #-1         ; EOR
        STA BUFFER,X
        RTS
ENDMOD

****************
MODULE HASH_WORD
****************
        LDA #<729
        STA F
        LDA #>729
        STA F+1
        LDY #0
        STY R           ; hash value
        STY R+1

        DEX
_blanks INX
        LDA BUFFER,X
        BEQ _blanks


_xloop  LDA BUFFER,X    ; BUFFER[X]
        BMI _ret        ; end of text
        BEQ _ret
        INX             ; ++X
        STA CODE
        LDA #0
        STA CODE+1      ; (CODE) = character
        LDA F
        STA SECP
        LDA F+1
        STA SECP+1      ; (SECP) = factor
        JSR MULTIPLY
        CLC
        LDA THIP
        ADC R
        STA R
        LDA THIP+1
        ADC R+1
        STA R+1         ; R += character * factor

        LDA F+1
        BEQ _fa
        LDA #27         ; 2nd. factor = 27
        STA F
        LDA #0
        STA F+1
        BEQ _xloop

_fa     LDA F
        CMP #27
        BNE _rest
        LDA #1          ; 3rd. factor = 1
        STA F
        BNE _xloop

_skip   INX
_rest   LDA BUFFER,X    ; 4th. and more
        BMI _ret
        BNE _skip
_ret    RTS

ENDMOD

*******************
MODULE PARSE_BUFFER
*******************
        LDX #0
        STX OBJECT
        JSR HASH_WORD   ; 1st. word

        LDY #NVERBS     ; # of verb bytes
_verbl  LDA R
        CMP VERBTAB,Y
        BNE _verbn
        LDA R+1
        CMP VERBTAB+1,Y
        BEQ _vmatch
_verbn  DEY
        DEY
        DEY
        BNE _verbl

_vmatch LDA VERBTAB+2,Y
        STA VERB

_fob    JSR HASH_WORD
        LDY #NOBJECTS   ; # of object bytes
_vloop  LDA R
        CMP OBJTAB,Y
        BNE _vnext
        LDA R+1
        CMP OBJTAB+1,Y
        BEQ _omatch
_vnext  DEY
        DEY
        DEY
        BNE _vloop

_omatch LDA OBJTAB+2,Y
        BEQ _none
        STA OBJECT

_none   LDA BUFFER,X
        BPL _fob


***********
* MATCHES *
***********
        LDA VERB
        CMP #16         ; fight
        BNE ACTION_GO
        LDA OBJECT
        CMP #18         ; matches
        BNE ACTION_GO
        INC VERB        ; light (not fight) matches

*********
ACTION_GO
*********
        LDA VERB
        CMP #7          ; go
        BNE ACTION_PICK
        LDA OBJECT
        CMP #100
        BCC ACTION_PICK
        SBC #100
        STA VERB        ; GO WEST -> WEST

***********
ACTION_PICK
***********
        LDA VERB
        LDX OBJECT
        CMP #8          ; pick
        BNE _put
        CPX #105        ; up
        BEQ _move
        BNE _ret

_put    CMP #9          ; put
        BNE _ret
        CPX #106        ; down
        BNE _ret

_move   LDA OBJECT+1
        STA OBJECT
_ret    LDA #0
        STA OBJECT+1
        RTS
ENDMOD

***********
MODULE RANA
***********
        LDX #0
        PHA
        TXA
        PHA
        LDA SEED
        STA CODE
        LDA SEED+1
        STA CODE+1
        LDA #<$3fd3
        STA SECP
        LDA #>$3fd3
        STA SECP+1
        JSR MULTIPLY
        LDA THIP
        STA SEED
        LDA THIP+1
        STA SEED+1
        STA CODE
        LDA #0
        STA CODE+1
        PLA
        STA SECP+1
        PLA
        STA SECP
        JSR MULTIPLY
        INC THIP+1
        LDA THIP+1
        RTS
ENDMOD

*********
HEAR_MOVE
*********
        LDA #$f2
        .BYTE $2C

******
CANNOT
******
        LDA #$f4
        .BYTE $2C

***
THE
***
        LDA #$f7
        .BYTE $2C

****
SAYS
****
        LDA #$ef
        .BYTE $2C

**********
IMPOSSIBLE
**********
        LDA #$f8
        JMP PRINOA

******************
MODULE INSCRIPTION
******************
        LDY #2          ; detail message
        LDA (F),Y
        BEQ _ret
        PHA
        LDA #$b3
        JSR PRINOA
        PLA
        JSR PRINOA
        JMP QUOTECR
_ret    RTS
ENDMOD

***************
MODULE GET_PATH
***************
; Input : A = path number (1 - PATH_TAB_NUM)
; Output: PATH (4 byte array)

        AND #$7f
        BEQ _err
        CMP #PATH_TAB_NUM+1
        BCS _err
        ASL A           ; * 2
        ASL A           ; * 4
        TAX
        LDY #3
_loop   DEX
        LDA PATH_TAB_START,X
        STA PATH,Y
        DEY
        BPL _loop
        RTS
_err    BRK
ENDMOD

*****************
MODULE LOC_TO_F
*****************
        LDA LOC ; item
        LDX #2  ; group
ENDMOD

**************
MODULE AX_TO_F
**************
; Input : A = item
;       : X = group
        TAY
        BEQ _err
        CMP GROUPE,X
        BEQ _ok
        BCS _err
_ok     LDY #0
        STY F+1
        LDY #4
_loop   ASL A
        ROL F+1
        DEY
        BNE _loop
        ADC GROLO,X
        STA F
        LDA F+1
        ADC GROHI,X
        STA F+1
        LDY #8
        LDA (F),Y
        RTS
_err    BRK
ENDMOD

******************
MODULE OBJECT_TO_F
******************
        LDA OBJECT
*******
AO_TO_F
*******
        LDX #<NULLOBJ
        STX F
        LDX #>NULLOBJ
        STX F+1
        LDX #3
        CMP #0
        BEQ _ret
        CMP #OBJ_TAB_NUM+1
        BCS _ret
        JSR AX_TO_F
        CLC
_ret    RTS             ; C=1 -> error
ENDMOD

************
MODULE GODIR
************
        BEQ _ret
        CMP #7
        BCS _ret
        ADC #$b6    ; b7:north, b8:south, ...
        JMP PRINOA
_ret    RTS
ENDMOD

******
ABLANK
******
        LDA #'a'
        JSR BUFPRI
*****
BLANK
*****
        LDA #' '
        JMP BUFPRI
*****
DOTCR
*****
        LDA #'.'
        JSR BUFPRI
******
RETURN
******
        LDA #CR
        JMP BUFPRI

*******
QUOTECR
*******
        LDA #'"'
        JSR BUFPRI
        JMP RETURN

**************
MODULE A_OR_AN
**************
; print indefinite article
; print "AN " before EMERALD, EGG, AXE
; print amount for MATCHES
; Input : A = object
        CMP #18           ; matches
        BNE _labb
        LDX MATCHES+7       ; amount
        LDY #0
        JSR PRINT_FOXY
        JMP BLANK

_labb   TAX
        LDA #'a'
        JSR BUFPRI
        CPX #6             ; emerald
        BEQ _an
        CPX #10            ; egg
        BEQ _an
        CPX #20            ; axe
        BNE _blank

_an     LDA #'n'
        JSR BUFPRI
_blank  JMP BLANK
ENDMOD

****************
MODULE PRINT_YOU
****************
        LDA #$02
        JMP PRINOX
ENDMOD

**************
MODULE YOU_SEE
**************
        JSR PRINT_YOU
        LDA #$03
        JMP PRINOX
ENDMOD

****************
MODULE YOU_SEE_A
****************
        JSR YOU_SEE
        JMP ABLANK
ENDMOD

***************
MODULE SEE_MSG
***************
        PHA
        JSR YOU_SEE_A
        PLA
        JSR PRINOA
        JMP DOTCR
ENDMOD

*******************
MODULE PRINT_MOVE
*******************
        TAX
        BEQ _err
        CMP #7
        BCS _err
        PHA
        LDA #$bd
        JSR PRINOA  ; "YOU GO "
        PLA
        JSR GODIR
        JMP RETURN
_err    BRK
ENDMOD

***********
MODULE DARK
***********
        LDA LITMAT        ; match burning
        BNE _light
        LDA LAMP+7       ; lamp on
        BMI _light
        LDA TORCH+7       ; torch burning
        BMI _light
        LDA F
        PHA
        LDA F+1
        PHA
        JSR LOC_TO_F
        LDY #3            ; light status
        LDA (F),Y
        TAX
        PLA
        STA F+1
        PLA
        STA F
        CPX #-1
        BNE _light        ; branch if light
        LDX #0            ; darkness
        RTS
_light  LDX #1            ; light
        RTS
ENDMOD

**************
MODULE YOU_ARE
**************
        LDA #$04
        JMP PRINOX
ENDMOD

*******************
MODULE PRINT_STATUS
*******************
        BIT DEBUG
        BPL _laba
        LDA LOC
        JSR PRINT_HEX
        JSR BLANK
_laba   JSR YOU_ARE
        JSR DARK
        BNE _loc
        LDA #$ff        ; dark place
        BNE _print
_loc    JSR LOC_TO_F
        LDY #0
        LDA (F),Y
_print  JMP PRINOA
ENDMOD

****************
MODULE VERB_FIND
****************
        JSR DARK
        BNE _light
        RTS

_light  JSR LOC_TO_F
        LDY #1
        LDA (F),Y            ; detail
        JSR PRINOA

        LDY #3
        LDA (F),Y            ; light
        BEQ _smell
        CMP #$ff
        BEQ _smell
        JSR PRINOA

_smell  LDY #5          ; North index
        LDA #1
        STA I
_iloop  STY J
        LDA I
        JSR GODIR
        LDA #':'
        JSR BUFPRI
        LDY J
        LDA (F),Y
        PHA
        JSR GET_PATH
        PLA
        BPL _labb

        LDA #255
        JSR RANA
        CMP PATH+2      ; hidden value
        BCC _laba       ; unveil hidden path
        LDA CRYSTAL+8   ; holding crystal ball
        BEQ _laba

        LDA PATH        ; hidden msg: unclimbable, impenetrable
        JMP _labc

_laba   LDY J
        LDA (F),Y
        AND #$7f        ; unveil path
        STA (F),Y

_labb   LDA PATH+1
_labc   JSR PRINOA
        JSR DOTCR
        INC I
        LDY J
        INY
        INY
        CPY #17
        BCC _iloop

***********
* objects *
***********

        LDA #<[OBJ_TAB_START+16]
        STA F
        LDA #>[OBJ_TAB_START+16]
        STA F+1
        LDX #1          ; object #
_oloop  TXA
        PHA
        LDY #8          ; LOC index
        LDA (F),Y
        CMP LOC
        BNE _onext
        JSR YOU_SEE
        PLA
        PHA             ; A = object
        JSR A_OR_AN
        LDY #0
        LDA (F),Y
        JSR PRINOA
        JSR DOTCR
_onext  PLA
        TAX
        CLC
        LDA F
        ADC #16
        STA F
        BCC _oskip
        INC F+1
_oskip  INX
        CPX #OBJ_TAB_NUM+1
        BCC _oloop

************
* princess *
************

        LDA PRINCESS+7
        CMP LOC
        BNE _monster
        LDA PRINCESS+1
        JSR SEE_MSG

********
_monster
********

        LDA #<MONTAB
        STA F
        LDA #>MONTAB
        STA F+1
_mloop  LDY #8          ; LOC index
        LDA (F),Y
        CMP LOC
        BNE _mnext
        LDY #1
        LDA (F),Y
        JSR SEE_MSG
_mnext  CLC
        LDA F
        ADC #16
        STA F
        TAX
        LDA F+1
        ADC #0
        STA F+1
        CMP #>MON_TAB_END
        BNE _mloop
        CPX #<MON_TAB_END
        BNE _mloop

*******
* NPC *
*******

        LDA #<NPCTAB
        STA F
        LDA #>NPCTAB
        STA F+1
_nloop  LDY #11        ; LOC index
        LDA (F),Y
        CMP LOC
        BNE _nnext
        LDY #1
        LDA (F),Y
        JSR SEE_MSG
_nnext  CLC
        LDA F
        ADC #16
        STA F
        TAX
        LDA F+1
        ADC #0
        STA F+1
        CMP #>NPC_TAB_END
        BNE _nloop
        CPX #<NPC_TAB_END
        BNE _nloop

        RTS
ENDMOD

*********************
MODULE MONSTER_ACTION
*********************
        LDA I
        PHA
        LDA J
        PHA
        LDA #MON_TAB_NUM
        STA I
        LDA #MON_TAB_NUM * 16
        STA J

_mloop  SEC
        LDA J
        SBC #16
        STA J
        TAX
        LDA MONTAB+8,X  ; LOC
        CMP LOC
        BNE _mnext      ; branch if not here

        JSR DARK
        BEQ _labe       ; branch if darkness

        LDX J
        LDA MONTAB+1,X  ; attack message
        JSR SEE_MSG

        LDX I
        DEX
        BNE _labf       ; branch if not knave

        LDA PRINCESS+7  ; LOC
        CMP LOC
        bne _labf       ; branch if princess not here

        LDA PRINCESS+1
        JSR SEE_MSG
        JMP _labf

_labe   JSR HEAR_MOVE
_labf   LDA I
        STA MONSTER

_mnext  DEC I
        BNE _mloop

        LDA MONSTER
        BNE _ret

        LDA #NPC_TAB_NUM
        STA I
        LDA #NPC_TAB_NUM * 16
        STA J

_nloop  SEC
        LDA J
        SBC #16
        STA J
        TAX
        LDA NPCTAB+11,X ; LOC
        CMP LOC
        BNE _next       ; not here

        JSR DARK
        BEQ _labi

        JSR YOU_SEE_A
        LDX J
        LDA NPCTAB+1,X
        JSR PRINOA
        JSR DOTCR
        JMP _labj

_labi   JSR HEAR_MOVE
_labj   LDA I
        STA NPC

_next   DEC I
        BNE _nloop
_ret    PLA
        STA J
        PLA
        STA I
        RTS
ENDMOD

***************
MODULE TELEPORT
***************
        STA LOC
        LDA #0
        STA MONSTER
        STA NPC
        STA BRAVE
        JMP MONSTER_ACTION
ENDMOD

****************
MODULE VERB_LOOK
****************
        JSR DARK
        BEQ _impos
        JSR OBJECT_TO_F
        BCS _path
        BEQ _labb       ; holding
        CMP LOC
        BNE _impos

_labb   JSR YOU_SEE
        LDA OBJECT
        JSR A_OR_AN
        LDY #1
        LDA (F),Y
        BNE _labc
        DEY
        LDA (F),Y
_labc   JSR PRINOA

        LDA OBJECT
        CMP #22         ; sphere/bomb
        BNE _labd
        LDX #$a7        ; bomb
        STX SPHERE      ; rename sphere to bomb

_labd   JSR DOTCR
        JSR INSCRIPTION
        LDA OBJECT
        CMP #23         ; crystal ball
        BEQ _path
        CMP #24         ; mirror
        BEQ _mirror
        RTS
_mirror LDA #LOC_TAB_NUM
        JSR RANA
        JMP TELEPORT
_path   JMP VERB_FIND
_impos  JMP IMPOSSIBLE
ENDMOD

****************
MODULE VERB_READ
****************
        JSR DARK
        BEQ _impos
        JSR OBJECT_TO_F
        BCS _impos
        BEQ _labc       ; holding
        CMP LOC
        BNE _impos

_labc   LDA OBJECT
        CMP #13         ; book
        BNE _labe
        LDA #'"'
        JSR BUFPRI
        LDA BOOK+2
        JSR PRINOA
        JSR QUOTECR
        LDA #$f0        ; chapter
        JSR PRINOA
        LDA BOOK+7      ; chapter
        CMP #4
        BCC _labd
        LDX #-1
        STX BOOK+7      ; reset chapter counter
_labd   INC BOOK+7
        CLC
        ADC #$92
        JMP PRINOA

_labe   JSR INSCRIPTION
        LDA #$be        ; you read
        JSR PRINOA
        LDA #$b4        ; nothing
        JMP PRINOA
_impos  JMP IMPOSSIBLE
ENDMOD

******************
MODULE NEW_MATCHES
******************
        LDX #6
        STX MATCHES+7   ; 6 new matches
        LDX #2
        STX MATCHES+8   ; at market
        RTS
ENDMOD

****************
MODULE NEW_TORCH
****************
        LDX #$1e
        STX TORCH+7     ; burn time
        LDX #2
        STX TORCH+8     ; at market
        RTS
ENDMOD

*******************
MODULE VERB_LIGHT
*******************
; Input : A = object
        STA OBJ         ; object
        JSR DARK
        STX I           ; remember state
        LDA OBJ
        LDX LITMAT      ; match burning
        BNE _labb
        LDX MATCHES+8
        BNE _impos      ; not holding
        LDX MATCHES+7   ; # of matches
        BEQ _impos      ; none left
        DEC MATCHES+7   ; use one
        BNE _laba
        JSR NEW_MATCHES
_laba   LDX #3
        STX LITMAT      ; let it burn for 3 turns

_labb   CMP #18         ; light match ?
        BNE _labc
        JSR THE         ; the
        LDA #$f6        ; match
        JSR PRINOA
        LDA #$f5        ; is lit
        JMP PRINOA

_labc   CMP #15         ; lamp
        BEQ _labd
        CMP #16         ; torch
        BEQ _labd
        CMP #22         ; bomb
        BNE _impos      ; impossible

_labd   LDA OBJ
        JSR AO_TO_F     ; get object pointer
        BNE _impos      ; not holding

        JSR THE         ; the
        LDY #0
        LDA (F),Y
        JSR PRINOA      ; object
        LDA #$f5        ; IS LIT
        JSR PRINOA

        LDY #7          ; burn time
        LDA (F),Y
        ORA #$80        ; use flag
        STA (F),Y

        LDX I
        BNE _ret
        JSR VERB_FIND   ; darkness to light
_ret    RTS
_impos  JMP IMPOSSIBLE
ENDMOD

***************
MODULE VERB_OFF
***************
        TXA             ; object
        LDX #0          ; lamp offset
        CMP #15         ; lamp
        BEQ _laba
        LDX #TORCH-LAMP
        CMP #16         ; torch
        BEQ _laba
        LDX #SPHERE-LAMP
        CMP #22         ; bomb
        BNE _cannot

_laba   LDA LAMP+8,X    ; loc
        BEQ _labb       ; holding
        CMP LOC
        BEQ _labb       ; here
        JMP IMPOSSIBLE

_labb   LDA LAMP+7,X    ; burn time
        AND #$7f
        STA LAMP+7,X    ; off
        TXA
        PHA
        JSR THE
        PLA
        TAX
        LDA LAMP,X
        JSR PRINOA
        LDA #$bf
        JMP PRINOA
_cannot JMP CANNOT
ENDMOD

*****************
MODULE DROP_LIGHT
*****************
        CPX #15         ; lamp
        BEQ VERB_OFF
        CPX #16         ; torch
        BEQ VERB_OFF
        RTS
ENDMOD

****************
MODULE ADD_KARMA
****************
; Input : A = bonus
        CLC
        ADC KARMPT
        STA KARMPT
        BCC _ret
        INC KARMPT+1
_ret    RTS
ENDMOD

****************
MODULE SUB_KARMA
****************
; Input : A = penalty
        TAX
        SEC
        LDA KARMPT
        STX KARMPT
        SBC KARMPT
        STA KARMPT
        BCS _ret
        DEC KARMPT+1
_ret    RTS
ENDMOD

*****************
MODULE ADD_WEIGHT
*****************
; Input : A = weight
        CLC
        ADC WEIGHT
        STA WEIGHT
        BCC _ret
        INC WEIGHT+1
_ret    RTS
ENDMOD

*****************
MODULE SUB_WEIGHT
*****************
; Input : A = weight
        TAX
        SEC
        LDA WEIGHT
        STX WEIGHT
        SBC WEIGHT
        STA WEIGHT
        BCS _ret
        DEC WEIGHT+1
        BMI _err
_ret    RTS
_err    BRK
ENDMOD

****************
MODULE EXPLOSION
****************
        LDA SPHERE+8    ; bomb's loc
        BNE _laba
        LDA SPHERE+3    ; subtract bomb's weight
        JSR SUB_WEIGHT
        LDA LOC

_laba   STA LOC         ; bomb's loc
        LDA #$ca
        JSR PRINOA      ; explosion
        LDX #-1
        STX SPHERE+8    ; delete bomb's loc
        INX             ; X=0
        STX SPHERE+7    ; fuse out

; blown up princess ?

        LDA LOC         ; explosion loc
        CMP PRINCESS+7
        BNE _labb
        LDX #-1
        STX PRINCESS+7  ; killed
        DEC KARMPT+1    ; 256 KP penalty

; killed monster

_labb   LDA #MON_TAB_NUM
_loopm  STA I
        LDX #5
        JSR AX_TO_F     ; A=item, X=group
        CMP LOC
        BNE _nextm      ; not here
        LDA #$ff
        STA (F),Y       ; dead
        LDY #3
        LDA (F),Y       ; kill bonus monster[3]
        JSR ADD_KARMA
        LDY #6
        LDA (F),Y       ; carried object
        BEQ _nextm

        LDX #2          ; object group
        JSR AX_TO_F
        LDA LOC
        STA (F),Y

_nextm  LDX I
        DEX
        TXA
        BNE _loopm

; killed NPC

        LDA #NPC_TAB_NUM
_loopn  STA I
        LDX #6
        JSR AX_TO_F     ; A=item, X=group
        LDY #11         ; NPC's loc index
        LDA (F),Y       ; NPC's loc
        CMP LOC
        BNE _nextn      ; not here
        LDA #$ff
        STA (F),Y       ; dead
        LDA #100        ; penalty
        JSR SUB_KARMA
        LDY #7
        LDA (F),Y       ; carried object
        BEQ _nextm

        LDX #2          ; object group
        JSR AX_TO_F
        LDA LOC
        STA (F),Y

_nextn  LDX I
        DEX
        TXA
        BNE _loopn

        JSR LOC_TO_F    ; bomb loc
        LDY #1
        LDA #$ad        ; rubble
        STA (F),Y

        INY
        LDA #$ac        ; smoke
        STA (F),Y

; branch if player not at bomb loc

;           .WORD _idol

        LDA #0
        STA LOC
        STA NPC
        STA MONSTER

; branch if bomb not in idol room

        LDA LOC
        CMP #$62
        BNE _ret

        LDA #0
        STA IDOL
        LDA #$ff
        STA LOC61+3     ; dry cavern is now dark
        STA LOC62+3     ; idol room  is now dark
        LDA #$42
        STA LOC62       ; idol room -> dry cavern
        INC KARMPT+1    ; add 256 karma points

_ret    RTS
ENDMOD

*****************
MODULE DISAPPEARS
*****************
        PHA
        JSR THE
        PLA
        JSR PRINOA
        LDA #$cd
        JMP PRINOA
ENDMOD

***************
MODULE TIMESTEP
***************
        LDA LITMAT
        BEQ _torch
        DEC LITMAT      ; match burns down
        JSR DARK
        BNE _torch
        LDA #$cb        ; match burns out
        JSR PRINOA

_torch  LDX TORCH+7     ; burning
        CPX #$81
        BCC _tora
        DEX
        STX TORCH+7     ; update

_tora   CPX #$8a
        BNE _torb
        JSR THE
        LDA TORCH
        JSR PRINOA
        LDA #$cc        ; burning low
        JSR PRINOA

_torb   CPX #$80
        BNE _bomb
        JSR THE
        LDA TORCH
        JSR PRINOA
        LDA #$ce        ; burns out
        JSR PRINOA

        LDX #$1e
        STX TORCH+7     ; new torch
        LDX #2
        STX TORCH+8     ; at market

        LDA TORCH+3     ; weight
        JSR SUB_WEIGHT
        LDA WEAPON
        CMP #16         ; torch
        BNE _bomb
        LDA #0
        STA WEAPON

_bomb   LDX SPHERE+7
        CPX #$81
        BCS _boma      ; fuse is burning
        RTS
_boma   DEX
        STX SPHERE+7
        LDX SPHERE+8    ; loc
        BNE _bomc       ; branch if not holding
        LDX LOC

_bomc   STX REGX
        CPX WITCHER+8   ; witcher at bomb's loc
        BNE _npc
        LDA #LOC_TAB_NUM
        JSR RANA        ; teleport witcher
        STA WITCHER+8
        LDA MONSTER
        CMP #8          ; witcher
        BNE _witch
        LDA #0
        STA MONSTER
        JSR MONSTER_ACTION

_witch  JSR DARK
        BEQ _npc
        LDA WITCHER
        JSR DISAPPEARS

_npc    LDX REGX        ; bomb's loc
        CPX WIZARD+11   ; wizard at bomb's loc
        BNE _deto       ; check bomb
        LDA #LOC_TAB_NUM
        JSR RANA        ; teleport wizard
        STA WIZARD+11
        LDA NPC
        CMP #2
        BNE _wiz
        LDA #0
        STA NPC
        JSR MONSTER_ACTION

_wiz    JSR DARK
        BEQ _deto
        LDA WIZARD
        JSR DISAPPEARS

_deto   LDA SPHERE+7    ; bomb fuse
        CMP #$80
        BNE _ret
        JSR EXPLOSION
_ret    RTS
ENDMOD

************************
MODULE PRINT_KARMA_SCORE
************************
        LDA #$da        ; you have
        JSR PRINOA
        LDX KARMPT
        LDY KARMPT+1
        JSR PRINT_FOXY
        LDA #$db        ; karma points
        JMP PRINOA
ENDMOD

*******************
MODULE PRINT_WEIGHT
*******************
        LDA #$00        ; you carry
        JSR PRINOX
        LDX WEIGHT
        LDY WEIGHT+1
        JSR PRINT_FOXY
        LDA #$01        ; pounds
        JMP PRINOX
ENDMOD

**************
MODULE YOU_DIE
**************
        JSR YOU_ARE      ; you are
        LDA #$cf         ; dead
        JSR PRINOA
        LDA SPHERE+7     ; bomb
        CMP #$81
        BCC _laba
        JSR EXPLOSION    ; having bomb

_laba   JSR PRINT_KARMA_SCORE
        LDA KARMPT+1
        BPL _pos

        LDA #16         ; add 16 if negative
        JSR ADD_KARMA

        LDA #$d0        ; burn in hell
        JSR PRINOA

_pos    LDX #4
        JSR DELAY
        JSR YOU_ARE
        LDA #$d1        ; reborn
        JSR PRINOA

        LDX #OBJ_TAB_NUM
_loopi  STX OBJ
        TXA
        LDX #3
        JSR AX_TO_F
        BNE _next          ; branch if not carried

        LDX OBJ
        CMP #9
        BCC _cavern        ; branch for objects < 9

        LDA #11
        JSR RANA
        JMP _put

_cavern LDA #$64        ; very large cavern

_put    LDY #8
        STA (F),Y

_next   LDX OBJ
        DEX
        BNE _loopi

        LDA #2
        JSR RANA
        CLC
        ADC #$38
        JSR TELEPORT    ; mountain top $39 or $3a
        LDA #0
        STA LITMAT      ; no match burning
        STA QUEST

        LDA PRINCESS+7  ; loc
        BNE _match

        LDX #$62        ; put to idol
        STX PRINCESS+7

_match  JSR NEW_MATCHES ; 6 at market
        JSR NEW_TORCH   ; 1 at market
        LDA #0
        STA LAMP+7      ; lamp off


        LDX #3          ; monsters 3 - 7
_mloop  STX I
        TXA             ; monster
        LDX #5          ; group
        JSR AX_TO_F
        CMP #-1
        BNE _mnext      ; branch if alive

        LDA #$26        ; respawn monster
        JSR RANA        ; at loc $38 + ranf($26)
        CLC
        ADC #$3d
        LDY #8
        STA (F),Y

_mnext  LDX I
_minc   INX
        CPX #5          ; skip goblin
        BEQ _minc
        CPX #6          ; skip troll
        BEQ _minc
        CPX #8
        BCC _mloop

        LDA #0
        STA WEIGHT
        STA WEIGHT+1
        STA WEAPON
        JMP MONSTER_ACTION
ENDMOD

******************
MODULE HIT_MONSTER
******************
; Input : A = item
;         X = group
        STX GRP
        STA ITM
        JSR AX_TO_F

        LDA #$d2
        JSR PRINOA      ; you hit the
        LDY #0
        LDA (F),Y
        JSR PRINOA
        JSR DOTCR

        LDA GRP
        CMP #4          ; princess
        BNE _monst

        LDX #-1
        STX PRINCESS+7  ; kill princess
        DEC KARMPT+1    ; -256 karma points
        LDA PRINCESS+6  ; diamond
        PHA
        JMP _msg

_monst  CMP #5
        BNE _npc

        LDY #8
        LDA #-1
        STA (F),Y       ; kill monster
        LDY #3
        LDA (F),Y
        JSR ADD_KARMA   ; kill bonus
        LDA #0
        STA MONSTER
        STA BRAVE
        LDY #6
        LDA (F),Y       ; weapon
        PHA
        JMP _msg

_npc    CMP #6
        BNE _msg

        LDY #11
        LDA #-1
        STA (F),Y       ; kill npc
        LDA #$80
        JSR SUB_KARMA   ; -128 karma points
        LDA #0
        STA NPC
        LDY #10
        LDA (F),Y       ; obkect
        PHA

_msg    JSR THE
        LDY #0
        LDA (F),Y
        JSR PRINOA
        LDA #$d3        ; is dead
        JSR PRINOA

        PLA             ; carried object
        BEQ _score
        LDX #3          ; group
        JSR AX_TO_F
        LDA LOC
        STA (F),Y       ; drop object

_score  JSR PRINT_KARMA_SCORE
        JMP MONSTER_ACTION
ENDMOD

***************
MODULE IDOLATRY
***************
        JSR YOU_ARE
        DEC KARMPT+1    ; -256 karma points
        LDA #$c0
        JSR PRINOA      ; idolatry
        JMP YOU_DIE

****************
MODULE VERB_PRAY
****************
        LDA LOC
        CMP #$62        ; idol room
        BNE _labb
        LDA IDOL
        BEQ _laba
        JMP IDOLATRY

_laba   LDA #$c1
        JMP PRINOA      ; unclean

_labb   CMP #$0b        ; chapel
        BNE VOICE_TALK

        LDA #$c2        ; you pray
        JSR PRINOA
        LDA #1
        JSR ADD_KARMA
        JSR PRINT_KARMA_SCORE
        LDA #3
        JSR RANA
        CMP #1
        BEQ _labd
        RTS

_labd   LDA KARMPT+1
        BMI _labe       ; negative
        BNE _heaven
        LDA #255
        JSR RANA        ; ranf(255)
        CMP KARMPT
        LDA #0
        SBC KARMPT+1
        BCS _labe

_heaven LDA #$c3        ; go to heaven
        JSR PRINOA
        JMP VERB_QUIT        ; game over

_labe   LDA #$c4        ; blissed off
        JSR PRINOA
        LDA TORCH+8
        BEQ _labf       ; already holding
        LDA #0
        STA TORCH+8     ; hold torch
        CLC
        LDA WEIGHT
        ADC TORCH+3     ; weight of torch
        STA WEIGHT
        BCC _labf
        INC WEIGHT+1
_labf   LDX #$b4
        STX TORCH+7     ; burn time & burn flag
        LDX #$10        ; torch
        STX WEAPON
        LDA #$27
        JSR RANA        ; teleport to loc ($3e - $64)
        CLC
        ADC #$3d
        JMP TELEPORT
ENDMOD

*****************
MODULE VOICE_TALK
*****************
        LDA #$c5        ; a voice
        JSR PRINOA
        JSR SAYS
        LDA #0
        STA BRAVE
        LDA NPC
        BNE HINT_TALK
        LDA MONSTER
        BNE HINT_SLAY
        LDA #$c6        ; examine objects
        JMP PRINOA
ENDMOD

****************
MODULE HINT_TALK
****************
        LDA #$c7        ; talk to this person
        JMP PRINOA
ENDMOD

****************
MODULE HINT_SLAY
****************
        LDA WEAPON
        BEQ HINT_RUN
        LDA #$c8        ; slay this monster
        JMP PRINOA
ENDMOD

***************
MODULE HINT_RUN
***************
        LDA #$c9
        JMP PRINOA
ENDMOD

*********************
MODULE PRINCESS_QUEST
*********************
        LDA NPC
        CMP #1          ; king
        BNE _ret        ; branch if not king
        LDA PRINCESS+7  ; loc
        BNE _ret        ; not with player

        JSR THE         ; the
        LDA KING        ; king
        JSR PRINOA
        JSR SAYS        ; says
        LDA KING+3      ; my daughter
        JSR PRINOA
        JSR QUOTECR

        JSR THE         ; the
        LDA KING        ; king
        JSR PRINOA
        LDA #$d4        ; embraces the
        JSR PRINOA
        LDA PRINCESS    ; princess
        JSR PRINOA
        JSR DOTCR

        LDX #0
        STX NPC
        STX BRAVE
        STX QUEST
        LDX #$ff         ; remove princess
        STX PRINCESS+7
        STX KING+11      ; remove king
        LDX #$02
        JSR DELAY

        JSR THE          ; the
        LDA KING         ; king
        JSR PRINOA
        JSR SAYS         ; says
        LDA KING+4       ; your reward...
        JSR PRINOA
        JSR QUOTECR

        LDA KING+9       ; karma bonus
        JSR ADD_KARMA
        JSR PRINT_KARMA_SCORE

        LDA KING+10      ; treasure
        LDX #3
        JSR AX_TO_F
        LDA LOC
        STA (F),Y        ; drop it at loc

        JSR MONSTER_ACTION
_ret    RTS
ENDMOD

***************
MODULE MISS_MSG
***************
; Input : X = group
;         A = item

        JSR AX_TO_F
        LDA #$05        ; you miss the
        JSR PRINOX
        LDY #0
        LDA (F),Y
        JSR PRINOA
        JMP DOTCR
ENDMOD

********************
MODULE MONSTER_FORCE
********************
; Input : X = group
;         A = opponent

        STX GRP
        JSR AX_TO_F
        LDX GRP
        CPX #6           ; npc
        BNE _labe

        LDY #5
        .BYTE $2c
_labe   LDY #4
        LDA (F),Y       ; monster force
        CMP #2
        BCS _ret
        LDA #2
_ret    RTS
ENDMOD

*******************
MODULE PLAYER_FORCE
*******************
        LDA WEAPON
        BNE _laba

        LDA KARMPT+1
        STA I
        LDA KARMPT
        LSR I
        ROR A
        LSR I
        ROR A           ; if weapon == 0
        JMP _labc       ; force = karma points / 4

_laba   LDA WEAPON
        LDX #3
        JSR AX_TO_F

        LDX WEAPON
        CPX #16         ; torch
        BNE _labb

        LDX TORCH+7     ; burns
        CPX #$81
        BCC _labb

        LDA #$1e        ; torch/club force
        RTS

_labb   LDY #6
        LDA (F),Y       ; penalty of use
        JSR SUB_KARMA   ; penalty     20    40     1      1    1
        LDY #4          ; weapon[6] = ring, staff, knife, axe, mace
        LDA (F),Y       ; weapon force
_labc   CMP #2
        BCS _ret
        LDA #2          ; minimum foce
_ret    RTS
ENDMOD

*********************
MODULE MONSTER_ATTACK
*********************
        STX GRP
        STA ITM

        JSR DARK
        BEQ _clob

;       compute defence

        JSR PLAYER_FORCE
        JSR RANA
        STA R

;       compute offence

        LDX GRP
        LDA ITM
        JSR MONSTER_FORCE
        JSR RANA
        STA R+1

;       "THE "<monster>

        JSR THE         ; the
        LDY #0
        LDA (F),Y       ; <name>
        JSR PRINOA
        JSR BLANK

        LDA GRP
        CMP #6
        BNE _labb

;       continue of group == 6 (NPC)

        LDY #6
        .BYTE $c

_labb   LDY #5
        LDA (F),Y       ; print MSG Attack
        JSR PRINOA

;       offence > defence : HIT

        LDA R
        CMP R+1
        BCC _miss

        LDA #$dc        ; it hits you
        JSR PRINOA
        LDA GRP
        CMP #5
        BNE _die

;       continue for monster group

        LDX ITM
        CPX #7          ; spider
        BNE _labd

        LDA TORCH+7
        CMP #$81
        BCC _die

        LDA #12
        JSR RANA
        CMP #2
        BCC _die

        LDA #$d6         ; torch burns web
        JMP PRINOA

_labd   CPX #8           ; witcher
        BEQ _labe
        CPX #9           ; dragon
        BNE _die

_labe   LDA EGG+8
        BNE _die         ; branch if not holding
        LDA #5
        JSR RANA
        CMP #2
        BCC _die

        LDA #$d7        ; egg absorbs heat
        JMP PRINOA

_miss   LDA #$d8        ; it misses you
        JMP PRINOA

_clob   LDA #$d9        ; clobbers you
        JSR PRINOA
_die    JSR YOU_DIE
        LDX #$01
        JMP DELAY
ENDMOD

*****************
MODULE OBJECT_IJK
*****************
; I : start index
; J : end   index
; K : step  value (2 for coins or gems) 1 else

; 51 (coins) : 1 (farthing), 3 (penny), 5 (dollar) , 7 (ducat)
; 52 (gems ) : 2 (garnet)  , 4 (topaz), 6 (emerald), 8 (diamond)
; 99 all

        LDA OBJECT
        CMP #51         ; coins, money
        BNE _laba
        LDA #1
        LDX #9
        LDY #2
        BNE _labd

_laba   CMP #52         ; gems
        BNE _labb
        LDA #2
        LDX #9
        TAY
        BNE _labd

_labb   CMP #99         ; all
        BNE _labc
        LDA #1
        LDX #OBJ_TAB_NUM+1
        TAY
        BNE _labd

_labc   TAX             ; single
        TAY

_labd   STA I
        STX J
        STY K
        LDA #0
        STA REGA        ; objects handled
        RTS
ENDMOD

***************
MODULE VERB_GET
***************
; I : start index
; J : end   index
; K : step  value (2 for coins or gems) 1 else


; 51 (coins) : 1 (farthing), 3 (penny), 5 (dollar) , 7 (ducat)
; 52 (gems ) : 2 (garnet)  , 4 (topaz), 6 (emerald), 8 (diamond)
; 99 all

        JSR OBJECT_IJK

_loop   LDA I
        LDX #3
        JSR AX_TO_F
        CMP LOC         ; old loc
        BNE _next       ; next k

        LDA #0
        STA (F),Y       ; carry object
        LDA #$df        ; you pick up
        JSR PRINOA
        LDA I
        JSR A_OR_AN
        LDY #0
        LDA (F),Y
        JSR PRINOA      ; object name
        JSR DOTCR
        INC REGA        ; count
        LDY #3          ; weight index
        LDA (F),Y       ; weight
        JSR ADD_WEIGHT
        INY             ; force index
        LDA (F),Y       ; force
        BEQ _next
        LDA I
        STA WEAPON

_next   CLC
        LDA I
        ADC K
        STA I
        CMP J
        BCC _loop

        LDA REGA
        BNE _laba
        LDA #$df        ; you pick up
        JSR PRINOA
        LDA #$b4        ; nothing.
        JMP PRINOA

_laba   LDA IDOL
        BEQ _ret
        LDA LOC
        CMP #$62        ; idol room
        BNE _ret
        LDA #$f1        ; zapped
        JSR PRINOA
        JMP YOU_DIE
_ret    RTS
ENDMOD

***************
MODULE VERB_PUT
***************
; I : start index
; J : end   index
; K : step  value (2 for coins or gems) 1 else


; 51 (coins) : 1 (farthing), 3 (penny), 5 (dollar) , 7 (ducat)
; 52 (gems ) : 2 (garnet)  , 4 (topaz), 6 (emerald), 8 (diamond)
; 99 all

        JSR OBJECT_IJK

_loop   LDA I
        LDX #3
        JSR AX_TO_F
        BNE _next       ; branch if not carried

        LDA LOC
        STA (F),Y       ; drop at loc
        LDA #$e0        ; you put down
        JSR PRINOA
        LDA I
        JSR A_OR_AN
        LDY #0
        LDA (F),Y       ; name
        JSR PRINOA      ; object name
        JSR DOTCR
        INC REGA        ; count
        LDY #3
        LDA (F),Y
        JSR SUB_WEIGHT

        LDA I
        CMP WEAPON
        BNE _labj
        LDA #0
        STA WEAPON

_labj   LDX I
        JSR DROP_LIGHT

_next   CLC
        LDA I
        ADC K
        STA I
        CMP J
        BCC _loop

        LDA REGA
        BNE _ret
        LDA #$e0        ; you put down
        JSR PRINOA
        LDA #$b4        ; nothing.
        JSR PRINOA
_ret    RTS
ENDMOD

*****************
MODULE VERB_THROW
*****************
; I : start index
; J : end   index
; K : step  value (2 for coins or gems) 1 else


; 51 (coins) : 1 (farthing), 3 (penny), 5 (dollar) , 7 (ducat)
; 52 (gems ) : 2 (garnet)  , 4 (topaz), 6 (emerald), 8 (diamond)
; 99 all

        JSR OBJECT_IJK

_loop   LDA I
        LDX #3
        JSR AX_TO_F
        BEQ _laba
        JMP _next       ; branch if not carried

_laba   LDA LOC
        STA (F),Y       ; drop at loc
        LDA #$e1        ; you throw
        JSR PRINOA
        LDA I
        JSR A_OR_AN
        LDY #0
        LDA (F),Y       ; name
        JSR PRINOA      ; object name
        JSR DOTCR
        INC REGA        ; count
        LDY #3
        LDA (F),Y
        JSR SUB_WEIGHT

        LDA I
        CMP WEAPON
        BNE _labj
        LDA #0
        STA WEAPON

_labj   LDA MONSTER
        ORA NPC
        BEQ _next

        LDA #1
        STA BRAVE
        LDY #6          ; penalty
        LDA (F),Y
        JSR SUB_KARMA

        LDA #255
        JSR RANA
        LDY #10         ; throw force
        CMP (F),Y
        BCS _mimo       ; missed
        LDA MONSTER
        BEQ _hitnpc

        LDX #5
        LDA MONSTER
        JSR HIT_MONSTER
        JMP _throw

_hitnpc LDX #6
        LDA NPC
        JSR HIT_MONSTER
        JMP _throw

_mimo   LDA MONSTER        ; monster number
        BEQ _minpc
        LDX #5             ; monster group
        JSR MISS_MSG
        JMP _throw

_minpc  LDX #6             ; NPC group
        LDA NPC            ; NPC number
        JSR MISS_MSG

_throw  LDA I
        CMP #25            ; warhammer
        BNE _ttor

        STA WEAPON
        LDA HAMMER+3
        JSR ADD_WEIGHT
        LDA #0
        STA HAMMER+8    ; carrying
        JSR THE
        LDA HAMMER
        JSR PRINOA
        LDA #$dd        ; returns to you
        JSR PRINOA
        JMP _next

_ttor   LDX I
        JSR DROP_LIGHT

_next   CLC
        LDA I
        ADC K
        STA I
        CMP J
        BCS _exit
        JMP _loop

_exit   LDA REGA
        BNE _ret
        LDA #$e1        ; you throw
        JSR PRINOA
        LDA #$b4        ; nothing.
        JSR PRINOA
_ret    RTS
ENDMOD

****************
MODULE VERB_GIVE
****************
; I : start index
; J : end   index
; K : step  value (2 for coins or gems) 1 else


; 51 (coins) : 1 (farthing), 3 (penny), 5 (dollar) , 7 (ducat)
; 52 (gems ) : 2 (garnet)  , 4 (topaz), 6 (emerald), 8 (diamond)
; 99 all

        JSR OBJECT_IJK

_loop   LDA I
        BEQ _nobj
        LDX #3
        JSR AX_TO_F
        BEQ _laba
_nobj   JMP _next       ; branch if not carried

_laba   LDA #-1
        STA (F),Y       ; give away
        LDA #$e2        ; you give
        JSR PRINOA
        LDA I
        JSR A_OR_AN
        LDY #0
        LDA (F),Y       ; name
        JSR PRINOA      ; object name
        JSR DOTCR
        INC REGA        ; count
        LDY #3
        LDA (F),Y
        JSR SUB_WEIGHT

        LDA I
        CMP WEAPON
        BNE _labj
        LDA #0
        STA WEAPON

_labj   LDA NPC
        BEQ _idol
        LDX #6
        LDA NPC
        JSR AX_TO_F

        JSR THE         ; the
        LDY #0
        LDA (F),Y       ; <name>
        JSR PRINOA
        JSR SAYS        ; says

        LDA I
        LDY #7
        CMP (F),Y       ; wanted object
        BEQ _reply

        LDA #$de        ; thank you
        JSR PRINOA

        LDA I
        CMP #16         ; torch
        BEQ _qcr
        CMP #18         ; matches
        BEQ _qcr

        LDA #1
        JSR ADD_KARMA
        JMP _qcr

_reply  LDY #4          ; reward
        LDA (F),Y
        JSR PRINOA
        LDY #10
        LDA (F),Y
        STA OBJ
        DEY             ; Y = 9
        LDA (F),Y
        JSR ADD_KARMA   ; bonus

        LDY #11         ; loc
        LDA #-1
        STA (F),Y       ; remove npc

        LDX #3
        LDA OBJ
        JSR AX_TO_F
        LDA LOC
        STA (F),Y

_qcr    JSR QUOTECR
        JSR PRINT_KARMA_SCORE
        LDA #0
        STA BRAVE
        STA NPC
        JSR MONSTER_ACTION
        JMP _next

_idol   LDA LOC
        CMP #$62        ; idol room
        BNE _prayer
        LDA IDOL
        BEQ _noid
        JSR IDOLATRY
_noid   JMP _next

_prayer LDA LOC
        CMP #10         ; entrance
        BEQ _appr
        CMP #11         ; chapel
        BNE _greml

_appr   LDA #$ed        ; contribution
        JSR PRINOA
        LDA I
        CMP #9
        BCS _nogem
        ASL A
        ASL A
        ASL A
        JSR ADD_KARMA
        JMP _prik

_nogem  LDA I
        CMP #16         ; torch
        BEQ _prik
        CMP #18         ; matches
        BEQ _prik
        LDA #10
        JSR ADD_KARMA

_prik   JSR PRINT_KARMA_SCORE
        JMP _next

_greml  LDA #$ee        ; gremlin
        JSR PRINOA
        LDA I
        LDX #3
        JSR AX_TO_F
        LDA #$64
        STA (F),Y

_next   CLC
        LDA I
        ADC K
        STA I
        CMP J
        BCS _exit
        JMP _loop

_exit   LDA REGA
        BNE _ret

        LDA #$e2        ; you give
        JSR PRINOA
        LDA #$b4        ; nothing.
        JSR PRINOA
_ret    RTS
ENDMOD

***************
MODULE VERB_DIR
***************
; North =  4
; South =  6
; East  =  8
; West  = 10
; Up    = 12
; Down  = 14

        JSR LOC_TO_F
        LDX VERB
        LDY DIRINX,X
        LDA (F),Y       ; path loc
        BEQ _impos

        STA I           ; new loc
        INY             ; path type
        LDA (F),Y
        BMI _impos
        JSR GET_PATH
        LDA PATH+3
        CMP WEIGHT
        BCS _labb
        LDA #$f3        ; too much
        JMP PRINOA
_impos  JMP IMPOSSIBLE

_labb   LDA I
        STA LOC         ; move
        LDA VERB
        JSR PRINT_MOVE
        JSR LOC_TO_F    ; update F
        LDY #2          ; smell msg
        LDA (F),Y
        JSR PRINOA

        LDY #5          ; north index
_loopd  STY J
        LDA (F),Y
        BPL _nextd
        JSR GET_PATH
        LDA #255
        JSR RANA
        CMP PATH+2      ; hidden
        LDY J
        BCS _nextd

        LDA (F),Y
        AND #$7f        ; unveil
        STA (F),Y

_nextd  INY
        INY
        CPY #16
        BCC _loopd

        LDA MONSTER
        BEQ _fin
        LDA #100
        JSR RANA
        PHA             ; save random
        LDA MONSTER     ; does it chase?
        STA CODE
        STA SECP
        LDA #0
        STA CODE+1
        STA SECP+1
        JSR MULTIPLY
        PLA
        CMP THIP
        BCS _fin       ; ranf(100) > M*M

        LDX #5
        LDA MONSTER
        JSR AX_TO_F
        LDA LOC
        STA (F),Y       ; place monster

        JSR DARK
        BEQ _labc

        JSR THE
        LDY #0
        LDA (F),Y
        .BYTE $2c

_labc   LDA #$e7        ; something
        JSR PRINOA
        LDA #$e8        ; is chasing
        JSR PRINOA
        LDA #4
        JSR RANA
        CMP #1
        BNE _fin

        LDX #5
        LDA MONSTER
        JSR MONSTER_ATTACK

_fin    LDA LOC
        JMP TELEPORT
ENDMOD

****************
MODULE FIGHT_ALL
****************
        LDX #5
        LDA MONSTER
        BNE VERB_FIGHT
        INX
        LDA NPC
        BNE VERB_FIGHT
        RTS
ENDMOD

*****************
MODULE VERB_FIGHT
*****************
; Input : X : target group (5:monster, 6:NPC)
;         A : target item

        STX GRP
        STA ITM
        JSR DARK
        BNE _laba
        JMP _cannot

_laba   LDA #1
        STA BRAVE
        LDX GRP
        LDA ITM
        JSR MONSTER_FORCE
        JSR RANA
        STA I
        JSR PLAYER_FORCE
        JSR RANA
        STA J

        JSR PRINT_YOU     ; "YOU "
        LDA WEAPON
        BEQ _karate
        LDY #5
        LDA (F),Y         ; weapon message
        BNE _labb

_karate LDA #$f9
_labb   JSR PRINOA       ; no weapon attack

        LDA J            ; player force
        CMP I            ; monster force
        BCC _miss

        LDX GRP
        LDA ITM
        JMP HIT_MONSTER

_miss   LDX GRP
        LDA ITM
        JMP MISS_MSG

_cannot LDA #$e9
        JMP PRINOA
ENDMOD

*****************
MODULE RANDOM_LOC
*****************
; Input : y = index of L1 (location 1)

        STY REGY        ; save
        LDA (F),Y       ; L1
        INY
        CMP (F),Y       ; L2
        BEQ _ret
        BCC _move

;       continue if [L1] > [L2]

        LDA #2
        JSR RANA
        CMP #1
        BNE _ret

;       continue at 50% chance

        LDY REGY
        INY
        LDA (F),Y
        DEY
        STA (F),Y
        RTS

;       choose a random location between L1 and L2

_move   CLC             ; increment result
        LDA (F),Y
        DEY
        SBC (F),Y       ; (L2-L1)+1
        JSR RANA
        LDY REGY
        CLC
        ADC (F),Y       ; L1 + random diff
        STA (F),Y
_ret    RTS

ENDMOD

************
MODULE RESET
************
        LDX #1
        STX LOC
        STX IDOL

        LDA TIMER
        STA SEED
        LDA TIMER+1
        STA SEED+1

        LDX #OBJ_TAB_NUM
        STX OBJ
_loopo  LDA OBJ
        LDX #3
        JSR AX_TO_F
        JSR RANDOM_LOC
        DEC OBJ
        BNE _loopo

        LDX #MON_TAB_NUM
        STX OBJ
_loopm  LDA OBJ
        LDX #5
        JSR AX_TO_F
        JSR RANDOM_LOC

        LDY #6          ; weapon index
        LDA (F),Y       ; weapon
        BEQ _nextm
        LDX #3          ; object group
        JSR AX_TO_F
        LDA #-1
        STA (F),Y       ; not avalaible

_nextm  DEC OBJ
        BNE _loopm

        LDX #NPC_TAB_NUM
        STX OBJ
_loopn  LDA OBJ
        LDX #6
        JSR AX_TO_F
        LDY #11         ; npc index of L1
        JSR RANDOM_LOC

        LDY #10         ; treasure index
        LDA (F),Y       ; treasure
        BEQ _nextn
        LDX #3          ; object group
        JSR AX_TO_F
        LDA #-1
        STA (F),Y       ; not avalaible

_nextn  DEC OBJ
        BNE _loopn

        LDA #1
        STA LOC
        LDA KNAVE+8
        STA PRINCESS+7  ; at knave
        LDA PRINCESS+6  ; treasure
        LDX #3
        JSR AX_TO_F
        LDA #-1
        STA (F),Y       ; hide treasure
        RTS

***************
MODULE NPC_SAYS
***************
; Input : A = item
;         X = group
;         Y = index

        STY REGY
        JSR AX_TO_F

        JSR THE         ; the
        LDY #0
        LDA (F),Y       ; <name>
        JSR PRINOA
        JSR SAYS        ; says
        LDY REGY
        LDA (F),Y
        JSR PRINOA
        JMP QUOTECR
ENDMOD

****************
MODULE VERB_TALK
****************
        LDA MONSTER
        BEQ _laba
        LDX #5          ; monster group
        LDY #2          ; index
        JSR NPC_SAYS

_laba   LDA NPC
        BEQ _labb
        LDX #6          ; npc group
        JSR AX_TO_F
        LDY #7          ; wanted
        LDA (F),Y
        BEQ _quest
        LDX #3          ; object group
        JSR AX_TO_F
        BNE _quest      ; branch if not carried

        LDA NPC
        LDX #6
        LDY #3
        JSR NPC_SAYS
        JMP _labb

_quest  LDA NPC
        LDX #6
        LDY #2
        JSR NPC_SAYS
        LDA NPC
        CMP #1          ; king = 1
        BNE _labb
        STA QUEST
        JSR TELEPORT

_labb   LDA NPC
        ORA MONSTER
        BNE _ret
        LDA PRINCESS+7
        BNE _ret
        LDA PRINCESS+2  ; I demand
        JSR PRINOA
_ret    RTS
ENDMOD

*********************
MODULE VERB_INV
*********************
        LDA #0
        STA J
        LDX #OBJ_TAB_NUM
_loop   STX I
        TXA
        LDX #3
        JSR AX_TO_F
        BNE _next

        LDA #$da        ; you have
        JSR PRINOA
        LDA I
        JSR A_OR_AN
        LDY #0
        LDA (F),Y
        JSR PRINOA
        JSR DOTCR
        INC J
_next   LDX I
        DEX
        BNE _loop

        LDA J
        BNE _pri
        LDA #$e4        ; not carrying
        JSR PRINOA

_pri    LDA PRINCESS+7
        BNE _ret
        JSR THE
        LDA PRINCESS
        JSR PRINOA
        LDA #$e5        ; tagging along
        JSR PRINOA
_ret    RTS
ENDMOD

***************
MODULE VERB_USE
***************
        LDX #3
        LDA OBJECT
        JSR AX_TO_F
        BNE _impos
        LDA OBJECT
        CMP #23         ; crystal ball
        BEQ _look
        CMP #24         ; mirror
        BEQ _look

        LDY #4          ; attack force
        LDA (F),Y
        BEQ _laba
        LDA OBJECT
        STA WEAPON
        LDA #$e3        ; you use
        JSR PRINOA
        LDA WEAPON
        JSR A_OR_AN
        LDY #0
        LDA (F),Y
        JSR PRINOA
        JSR DOTCR
        LDA MONSTER
        BEQ _ret
        LDX #5
        JMP VERB_FIGHT

_laba   LDA #$eb        ; nothing happens
        JMP PRINOA
_impos  JMP IMPOSSIBLE
_look   JMP VERB_LOOK
_ret    RTS
ENDMOD

****************
MODULE VERB_MAKE
****************
        TXA
        CMP #16         ; torch
        BNE _impos

        JSR LOC_TO_F
        LDY #3
        LDA (F),Y
        CMP #$fc        ; wood
        BNE _impos

        LDA TORCH+8
        BNE _laba
        LDA #$ea        ; already have one
        JMP PRINOA

_laba   LDA #15
        STA TORCH+7     ; burn time
        LDA #0
        STA TORCH+8     ; holding
        LDA #16         ; torch
        STA WEAPON
        LDA TORCH+3     ; weight
        JSR ADD_WEIGHT

        LDA #$e6        ; you make
        JSR PRINOA
        JSR ABLANK
        LDA TORCH
        JSR PRINOA
        JMP DOTCR
_impos  JMP IMPOSSIBLE
ENDMOD

**************
MODULE VERB_GO
**************
; scan for a direction to go

        JSR LOC_TO_F
        LDX #6
        STX VERB
        LDY #15         ; index for down

_loop   LDA (F),Y
        TAX
        DEY
        LDA (F),Y
        BEQ _next
        TXA
        BMI _go
_next   DEY
        DEC VERB
        BNE _loop
        JMP IMPOSSIBLE
_go     JMP VERB_DIR
ENDMOD

*****************
MODULE VERB_SCORE
*****************
        JSR PRINT_KARMA_SCORE
        JMP PRINT_WEIGHT
ENDMOD

*******************
MODULE ACCEPT_INPUT
*******************
        JSR PRINT_STATUS
        JSR PROMPT
        JSR PARSE_BUFFER

        LDA VERB
        ASL A
        TAX
        LDA ACTAB,X
        STA CODE
        LDA ACTAB+1,X
        STA CODE+1
        LDA #>_cont
        PHA
        LDA #<_cont
        PHA
        LDA VERB
        LDX OBJECT
        JMP (CODE)

_cont   NOP
        JSR TIMESTEP
        LDA LOC
        BNE _mon
        JSR YOU_DIE

_mon    LDA BRAVE
        BEQ _quest
        LDA MONSTER
        BEQ _npc
        LDX #5
        LDA MONSTER
        JSR MONSTER_ATTACK

_npc    LDA NPC
        BEQ _quest
        LDX #6
        LDA NPC
        JSR MONSTER_ATTACK

_quest  LDA BRAVE
        BNE _bat
        LDA NPC
        BEQ _bat
        JSR PRINCESS_QUEST ; npc && !brave

_bat    JSR DARK
        BNE _dung
        LDA MONSTER
        BNE _dung
        LDA #3
        JSR RANA
        CMP #1
        BNE _dung

        LDA LOC
        STA BAT+8       ; bat appears
        JSR MONSTER_ACTION

_dung   LDA QUEST
        BEQ _tag       ; not started
        LDA LOC
        CMP #5
        BNE _tag       ; not at palace
        LDA #$d5
        JSR PRINOA      ; to dungeon
        LDX #OBJ_TAB_NUM
        STX OBJECT

_loopd  LDX #3
        LDA OBJECT
        JSR AX_TO_F
        BNE _nextd
        LDA #5          ; drop at palace
        STA (F),Y

_nextd  DEC OBJECT
        BNE _loopd

        LDA #0
        STA WEIGHT
        STA WEIGHT+1
        LDA #6          ; dungeon
        JSR TELEPORT

_tag    LDA MONSTER
        BNE _labw
        LDA PRINCESS+7
        CMP LOC
        BNE _labw

        JSR THE
        LDA PRINCESS
        JSR PRINOA
        LDA #$ec        ; tag along
        JSR PRINOA
        LDA #0
        STA PRINCESS+7

_labw   LDA MONSTER
        BEQ _rpt
        LDA #1
        STA BRAVE

_rpt    JMP ACCEPT_INPUT
ENDMOD

****************
MODULE VERB_QUIT
****************
        JSR PRINT_KARMA_SCORE
        JSR RETURN
        JMP BASIC
ENDMOD

******************
MODULE FILE_DIALOG
******************
        LDX #0
_floop  LDA _file,X
        JSR CHROUT
        INX
        CPX #14
        BCC _floop

        LDX #0
_iloop  JSR CHRIN
        STA FILENAME,X
        CMP #' '
        BCC _laba
        INX
        CPX #16
        BCC _iloop

_laba   STX FNLEN
        LDA #8
        STA FA
        LDA #<FILENAME
        STA FNADR
        LDA #>FILENAME
        STA FNADR+1
        LDA #6
        JMP PRINOX
_file   .BYTE "\rFILE:SAVE",$9d,$9d,$9d,$9d
ENDMOD

****************
MODULE VERB_LOAD
****************
         JSR FILE_DIALOG
         LDA #0
         STA VERCK      ; load flag
         STA STATUS
         JMP LOAD
ENDMOD
****************
MODULE VERB_SAVE
****************
         JSR FILE_DIALOG
         LDA #<LOC_TAB_START
         STA STAL
         LDA #>LOC_TAB_START
         STA STAL+1
         LDA #<EOP
         STA EAL
         LDA #>EOP
         STA EAL+1
         JMP SAVE
ENDMOD

*****************************
PTR_MSG ; pointer to messages
*****************************
.word 0
.word mes01,mes02,mes03,mes04
.word mes05,mes06,mes07,mes08
.word mes09,mes0a,mes0b,mes0c
.word mes0d,mes0e,mes0f,mes10
.word mes11,mes12,mes13,mes14
.word mes15,mes16,mes17,mes18
.word mes19,mes1a,mes1b,mes1c
.word mes1d,mes1e,mes1f,mes20
.word mes21,mes22,mes23,mes24
.word mes25,mes26,mes27,mes28
.word mes29,mes2a,mes2b,mes2c
.word mes2d,mes2e,mes2f,mes30
.word mes31,mes32,mes33,mes34
.word mes35,mes36,mes37,mes38
.word mes39,mes3a,mes3b,mes3c
.word mes3d,mes3e,mes3f,mes40
.word mes41,mes42,mes43,mes44
.word mes45,mes46,mes47,mes48
.word mes49,mes4a,mes4b,mes4c
.word mes4d,mes4e,mes4f,mes50
.word mes51,mes52,mes53,mes54
.word mes55,mes56,mes57,mes58
.word mes59,mes5a,mes5b,mes5c
.word mes5d,mes5e,mes5f,mes60
.word mes61,mes62,mes63,mes64
.word mes65,mes66,mes67,mes68
.word mes69,mes6a,mes6b,mes6c
.word mes6d,mes6e,mes6f,mes70
.word mes71,mes72,mes73,mes74
.word mes75,mes76,mes77,mes78
.word mes79,mes7a,mes7b,mes7c
.word mes7d,mes7e,mes7f,mes80
.word mes81,mes82,mes83,mes84
.word mes85,mes86,mes87,mes88
.word mes89,mes8a,mes8b,mes8c
.word mes8d,mes8e,mes8f,mes90
.word mes91,mes92,mes93,mes94
.word mes95,mes96,mes97,mes98
.word mes99,mes9a,mes9b,mes9c
.word mes9d,mes9e,mes9f,mesa0
.word mesa1,mesa2,mesa3,mesa4
.word mesa5,mesa6,mesa7,mesa8
.word mesa9,mesaa,mesab,mesac
.word mesad,mesae,mesaf,mesb0
.word mesb1,mesb2,mesb3,mesb4
.word mesb5,mesb6,mesb7,mesb8
.word mesb9,mesba,mesbb,mesbc
.word mesbd,mesbe,mesbf,mesc0
.word mesc1,mesc2,mesc3,mesc4
.word mesc5,mesc6,mesc7,mesc8
.word mesc9,mesca,mescb,mescc
.word mescd,mesce,mescf,mesd0
.word mesd1,mesd2,mesd3,mesd4
.word mesd5,mesd6,mesd7,mesd8
.word mesd9,mesda,mesdb,mesdc
.word mesdd,mesde,mesdf,mese0
.word mese1,mese2,mese3,mese4
.word mese5,mese6,mese7,mese8
.word mese9,mesea,meseb,mesec
.word mesed,mesee,mesef,mesf0
.word mesf1,mesf2,mesf3,mesf4
.word mesf5,mesf6,mesf7,mesf8
.word mesf9,mesfa,mesfb,mesfc
.word mesfd,mesfe,mesff
.word mex00,mex01,mex02,mex03
.word mex04,mex05,mex06

mes01 .byte "a gate",0
mes02 .byte "a wall",0
mes03 .byte "a street",0
mes04 .byte "a golden door",0
mes05 .byte "a crack in the wall",0
mes06 .byte "the ground",0
mes07 .byte "a small hole",0
mes08 .byte "the sky",0
mes09 .byte "the ceiling",0
mes0a .byte "a road",0
mes0b .byte "a path",0
mes0c .byte "more forest",0
mes0d .byte "impenetrable forest",0
mes0e .byte "an unclimbable slope",0
mes0f .byte "stalactites",0

mes10 .byte "stalagmites",0
mes11 .byte "an unclimbable shaft",0
mes12 .byte "a shaft with hand-holds",0
mes13 .byte "darkness",0
mes14 .byte "the floor",0
mes15 .byte "a door",0
mes16 .byte "a secret door",0
mes17 .byte "a storm drain",0
mes18 .byte "in Golconda's central square.\n"
mes19 .byte "at the north gate of Golconda.\n"
mes1a .byte "a forest",0
mes1b .byte "in the market of Golconda.\n"
mes1c .byte "at the south gate of Golconda.\n"
mes1d .byte "in a garbage dump.\n"
mes1e .byte "There is a foul smell here!\n"
mes1f .byte "brass farthing",0

mes20 .byte "garnet",0
mes21 .byte "mud",0
mes22 .byte "a stairway",0
mes23 .byte "an ocean",0
mes24 .byte "a swamp",0
mes25 .byte "more swamp",0
mes26 .byte "in the royal palace.\n"
mes27 .byte "in the royal dungeon.\n"
mes28 .byte "in a sewer.\n"
mes29 .byte "in a narrow valley.\n"
mes2a .byte "at the prayer chapel entrance.\n"
mes2b .byte "A sign reads:\"Abandon all material possessions, "
      .byte "go up the stairs, and pray. "
      .byte "Contributions will be gratefully accepted.\"\n"
mes2c .byte "in the chapel of prayer.\n"
mes2d .byte "in a maple forest.\n"
mes2e .byte "in a cyprus swamp.\n"
mes2f .byte "there are sticky webs all around!\n"

mes30 .byte "on the trail of tears.\n"
mes31 .byte "on a promontory by the ocean of storms.\n"
mes32 .byte "in a redwood forest.\n"
mes33 .byte "There is an unfriendly atmosphere here.\n"
mes34 .byte "in an oak forest.\n"
mes35 .byte "in an aspen forest.\n"
mes36 .byte "There is a fresh scent here.\n"
mes37 .byte "in a pine forest.\n"
mes38 .byte "on a mountain trail.\n"
mes39 .byte "on a mountain top.\n"
mes3a .byte "Golconda is visible to the south through haze.\n"
mes3b .byte "in a damp cavern.\n"
mes3c .byte "climbing a vertical shaft.\n"
mes3d .byte "in a room with obsidian walls.\n"
mes3e .byte "crawling in a tunnel.\n"
mes3f .byte "in a limestone cavern.\n"

mes40 .byte "Stalactites and stalagmites prevent you from seeing very far.\n"
mes41 .byte "in a room with a slate floor.\n"
mes42 .byte "in a dry cavern.\n"
mes43 .byte "in a very large cavern filled with bones, "
      .byte "rotting carcases, and dragon droppings.\n"
mes44 .byte "in a room with a large iron idol of baal in the center.\n"
mes45 .byte "a sign reads: \"offer your gifts to baal.\"\n"
mes46 .byte "You smell pungent incense.\n"
mes47 .byte "E PLURIBUS UNUM",0
mes48 .byte "copper penny",0
mes49 .byte "topaz",0
mes4a .byte "silver dollar",0
mes4b .byte "emerald",0
mes4c .byte "gold ducat",0
mes4d .byte "diamond",0
mes4e .byte "sapling",0
mes4f .byte "red sapling tree",0

mes50 .byte "egg",0
mes51 .byte "egg with a colored shell. "
      .byte "The egg is cold to the touch",0
mes52 .byte "ring",0
mes53 .byte "MADE IN HADES",0
mes54 .byte "throw a bolt of lightning from the ring!\n"
mes55 .byte "staff",0
mes56 .byte "shoot a ball of fire from the staff!\n"
mes57 .byte "book",0
mes58 .byte "the story of my life by maharathi",0
mes59 .byte "sword",0
mes5a .byte "MADE IN VALHALLA",0
mes5b .byte "slash with a singing sword!\n"
mes5c .byte "lamp",0
mes5d .byte "Everlasting Lamp Works, INC.",0
mes5e .byte "torch",0
mes5f .byte "use the torch as a club.\n"

mes60 .byte "dagger",0
mes61 .byte "stab and slash at close quarters.\n"
mes62 .byte "matches",0
mes63 .byte "spider",0
mes64 .byte "giant spider running along web strands",0
mes65 .byte "throws a web at you!\n"
mes66 .byte "crocodile",0
mes67 .byte "very hungry crocodile",0
mes68 .byte "takes a big bite!\n"
mes69 .byte "dragon",0
mes6a .byte "large red dragon with smoking nostrils",0
mes6b .byte "A tastey morsel for dessert!",0
mes6c .byte "breathes fire on you!\n"
mes6d .byte "wizard",0
mes6e .byte "man in shimmering robes with a staff",0
mes6f .byte "Prepare to die!",0

mes70 .byte "shoots a ball of fire from his staff!\n"
mes71 .byte "knave",0
mes72 .byte "surly knave",0
mes73 .byte "Leave me and me wench alone!",0
mes74 .byte "slashes at you with a switchblade knife.\n"
mes75 .byte "princess",0
mes76 .byte "young woman in soiled but expensive clothes",0
mes77 .byte "I demand to be taken back to my "
      .byte "father, the king of Golconda!",0
mes78 .byte "xx",0
mes79 .byte "switchblade knife",0
mes7a .byte "Knave Armaments, INC.",0
mes7b .byte "king",0
mes7c .byte "man with a diamond sceptre sitting on a throne",0
mes7d .byte "You have entered my throne room without permission. "
      .byte "Since you are so brave, you must rescue my daughter from "
      .byte "her abductor. If you return without her, "
      .byte "you will be thrown in the dungeon. "
      .byte "Guard, escort him out!",0
mes7e .byte "My daughter!",0
mes7f .byte "Your reward shall be this diamond. "
      .byte "Go in peace, and feel free to enter "
      .byte "here whenever you wish. I think the "
      .byte "princess and i shall take a long vacation.",0

mes80 .byte "swings his diamond sceptre.\n"
mes81 .byte "man in grey robes with a crystal ball",0
mes82 .byte "Return to me the staff of the evil "
      .byte "shimmering wizard, but do not use "
      .byte "it yourself!",0
mes83 .byte "Give me the staff!",0
mes84 .byte "Thank you. you are wiser than you "
      .byte "appear. Speaking of appearance, "
      .byte "time for me to disappear!",0
mes85 .byte "conjures a whirlwind that heads your way!\n"
mes86 .byte "beggar",0
mes87 .byte "man in rags",0
mes88 .byte "Alms for the poor?",0
mes89 .byte "Can you spare a silver dollar?",0
mes8a .byte "Thank you. Take this lamp that it "
      .byte "might light your way in dark places. "
      .byte "I will beg no more.",0
mes8b .byte "tries desperately to defend himself with a lamp.\n"
mes8c .byte "giant",0
mes8d .byte "green giant clothed in leaves "
      .byte "with a very unfriendly expression on his face",0
mes8e .byte "Humans are not welcome in this "
      .byte "primeval forest. Win your place "
      .byte "here by bringing a sapling to "
      .byte "renew the forest. Now go!",0
mes8f .byte "Give me the sapling.",0

mes90 .byte "Take this egg as a symbol of defense "
      .byte "against evil and walk this forest without fear.",0
mes91 .byte "swings his massive fist.\n"
mes92 .byte "I. Putting the torch to cobwebs\"\n"
mes93 .byte "II. Give a beggar a silver dollar\"\n"
mes94 .byte "III. A cooling egg\"\n"
mes95 .byte "IV. Secrets found in a crystal ball\"\n"
mes96 .byte "V. An idol destroyed\"\n"
mes97 .byte "worm",0
mes98 .byte "large, slimy worm",0
mes99 .byte "tries to swallow you!\n"
mes9a .byte "goblin",0
mes9b .byte "hairy goblin coming toward you and snarling",0
mes9c .byte "chops at you with his axe.\n"
mes9d .byte "axe",0
mes9e .byte "chop with the axe.\n"
mes9f .byte "troll",0

mesa0 .byte "repulsive troll charging",0
mesa1 .byte "swings a large mace at you.\n"
mesa2 .byte "mace",0
mesa3 .byte "swing a mace.\n"
mesa4 .byte "bat",0
mesa5 .byte "vampire bat flying at you",0
mesa6 .byte "goes for your neck.\n"
mesa7 .byte "bomb",0
mesa8 .byte "metallic sphere",0
mesa9 .byte "bomb with a fuse",0
mesaa .byte "crystal ball",0
mesab .byte "crystal ball with many confusing images of hidden "
      .byte "paths and secret passages",0
mesac .byte "it smells of smoke here.\n"
mesad .byte "lots of rubble here.\n"
mesae .byte "mirror",0
mesaf .byte "your own image with swirling and shifting shapes behind",0

mesb0 .byte "warhammer",0
mesb1 .byte "bring a warhammer crashing down.\n"
mesb2 .byte "*** Lords  Of  Karma ***\r"
      .byte "*** Bit Shifter 2026 ***\r\n"
mesb3 .byte "An inscription reads:\"",0
mesb4 .byte "nothing.\n"
mesb5 .byte "impossible right now.\n"
mesb6 .byte "xxb6",0
mesb7 .byte "north",0
mesb8 .byte "south",0
mesb9 .byte "east ",0
mesba .byte "west ",0
mesbb .byte "up   ",0
mesbc .byte "down ",0
mesbd .byte "You go ",0
mesbe .byte "You read ",0
mesbf .byte " is out.\n"
mesc0 .byte "struck down for idolatry!\n"
mesc1 .byte "This place is unclean.\n"
mesc2 .byte "You pray\n"
mesc3 .byte "You go directly to heaven!\n"
mesc4 .byte "You get \"blissed-out\" and wander off. "
      .byte "You have a lit torch.\n"
mesc5 .byte "A voice",0
mesc6 .byte "Examine objects and look around.\"\n"
mesc7 .byte "Talk with this person.\"\n"
mesc8 .byte "Slay this evil creature!\"\n"
mesc9 .byte "Run!\"\n"
mesca .byte "A loud explosion shakes the ground!\n"
mescb .byte "The match burns out.\n"
mescc .byte " is burning low.\n"
mescd .byte " laughs and disappears.\n"
mesce .byte " burns out and disintegrates.\n"
mescf .byte "dead\n"
mesd0 .byte "You burn in hell to cleanse your sins.\n"
mesd1 .byte "reborn!\n"
mesd2 .byte "You hit the ",0
mesd3 .byte " is dead.\n"
mesd4 .byte " embraces the ",0
mesd5 .byte "The palace guards whisk you off to the royal dungeon!\n"
mesd6 .byte "Luckily, the torch burns up the web!\n"
mesd7 .byte "However, the egg absorbs all the heat!\n"
mesd8 .byte "It misses you.\n"
mesd9 .byte "In the darkness, something clobbers you!\n"
mesda .byte "You have ",0
mesdb .byte " karma points.\n"
mesdc .byte "It hits you!\n"
mesdd .byte " returns to you!\n"
mesde .byte "Thank you.",0
mesdf .byte "You pick up ",0

mese0 .byte "You put down ",0
mese1 .byte "You throw ",0
mese2 .byte "You give ",0
mese3 .byte "You use ",0
mese4 .byte "You are not carrying anything.\n"
mese5 .byte " is tagging along.\n"
mese6 .byte "You make ",0
mese7 .byte "something",0
mese8 .byte " is chasing you!\n"
mese9 .byte "You cannot see to fight.\n"
mesea .byte "You already have one.\n"
meseb .byte "nothing happens.\n"
mesec .byte " will tag along.\n"
mesed .byte "Your contribution is appreciated.\n"
mesee .byte "A gremlin runs away with it!\n"
mesef .byte " says:\r\"",0

mesf0 .byte "\"Chapter ",0
mesf1 .byte "A searing red light from the idol's eyes zaps you!\n"
mesf2 .byte "You hear movement in the dark!\n"
mesf3 .byte "You are carrying too much.\n"
mesf4 .byte "I cannot translate that.\n"
mesf5 .byte " is lit\n"
mesf6 .byte "match",0
mesf7 .byte "The ",0
mesf8 .byte "Impossible right now.\n"
mesf9 .byte "throw a karate chop.\n"
mesfa .byte "A bright red glow emanates from ruby eyes in the idol.\n"
mesfb .byte "A dim red light comes from below.\n"
mesfc .byte "Soft green light filters down through the leaves.\n"
mesfd .byte "Soft colored light enters through stained-glass windows.\n"
mesfe .byte "Dim light penetrates from above.\n"
mesff .byte "in a very dark place!\n"
mex00 .byte "You carry ",0
mex01 .byte " pounds.\n"
mex02 .byte "You ",0
mex03 .byte "see ",0
mex04 .byte "You are ",0
mex05 .byte "You miss the ",0
mex06 .byte "Wait...\n"

*******
VERBTAB
*******

.BYTE 0,0   ,  0
.BYTE #"NOR",  1 ; NORTH
.BYTE #"N@@",  1 ; N
.BYTE #"SOU",  2 ; SOUTH
.BYTE #"S@@",  2 ; S
.BYTE #"EAS",  3 ; EAST
.BYTE #"E@@",  3 ; E
.BYTE #"WES",  4 ; WEST
.BYTE #"W@@",  4 ; W
.BYTE #"UP@",  5 ; UP
.BYTE #"U@@",  5 ; U
.BYTE #"DOW",  6 ; DOWN
.BYTE #"D@@",  6 ; D
.BYTE #"GO@",  7 ; GO
.BYTE #"MOV",  7 ; MOVE
.BYTE #"WAL",  7 ; WALK
.BYTE #"RUN",  7 ; RUN
.BYTE #"GET",  8 ; GET
.BYTE #"PIC",  8 ; PICK UP
.BYTE #"TAK",  8 ; TAKE
.BYTE #"PUT",  9 ; PUT
.BYTE #"DRO",  9 ; DROP
.BYTE #"THR", 10 ; THROW
.BYTE #"GIV", 11 ; GIVE
.BYTE #"DON", 11 ; DONATE
.BYTE #"USE", 12 ; USE
.BYTE #"CAR", 12 ; CARRY
.BYTE #"HOL", 12 ; HOLD
.BYTE #"SWI", 12 ; SWING
.BYTE #"WEA", 12 ; WEAR
.BYTE #"LOO", 13 ; LOOK
.BYTE #"L@@", 13 ; L
.BYTE #"EXA", 13 ; EXAMINE
.BYTE #"REA", 14 ; READ
.BYTE #"PRA", 15 ; PRAY
.BYTE #"WOR", 15 ; WORSHIP
.BYTE #"HEL", 15 ; HELP
.BYTE #"FIG", 16 ; FIGHT
.BYTE #"ATT", 16 ; ATTACK
.BYTE #"KIL", 16 ; KILL
.BYTE #"HIT", 16 ; HIT
.BYTE #"STA", 16 ; STAB
.BYTE #"SLA", 16 ; SLASH
.BYTE #"STR", 16 ; STRIKE
.BYTE #"LIG", 17 ; LIGHT
.BYTE #"LIT", 17 ; LITE
.BYTE #"OFF", 18 ; OFF
.BYTE #"EXT", 18 ; EXTINGUISH
.BYTE #"OUT", 18 ; OUT
.BYTE #"INV", 19 ; INVENTORY
.BYTE #"I@@", 19 ; I
.BYTE #"SEA", 20 ; SEARCH
.BYTE #"TAL", 21 ; TALK
.BYTE #"ASK", 21 ; ASK
.BYTE #"QUE", 21 ; QUERY
.BYTE #"SPE", 21 ; SPEAK
.BYTE #"MAK", 22 ; MAKE
.BYTE #"SCO", 23 ; SCORE
.BYTE #"QUI", 24 ; QUIT
.BYTE #"LOA", 25 ; LOAD
.BYTE #"SAV", 26 ; SAVE

NVERBS = * - VERBTAB-3

*****
ACTAB
*****
.WORD CANNOT     ;  0
.WORD VERB_DIR   ;  1 north
.WORD VERB_DIR   ;  2 south
.WORD VERB_DIR   ;  3 east
.WORD VERB_DIR   ;  4 west
.WORD VERB_DIR   ;  5 up
.WORD VERB_DIR   ;  6 down
.WORD VERB_GO    ;  7 go
.WORD VERB_GET   ;  8 get
.WORD VERB_PUT   ;  9 put
.WORD VERB_THROW ; 10 throw
.WORD VERB_GIVE  ; 11 give
.WORD VERB_USE   ; 12 use
.WORD VERB_LOOK  ; 13 look
.WORD VERB_READ  ; 14 read
.WORD VERB_PRAY  ; 15 pray
.WORD FIGHT_ALL  ; 16 fight
.WORD VERB_LIGHT ; 17 light
.WORD VERB_OFF   ; 18 off
.WORD VERB_INV   ; 19 inventory
.WORD VERB_FIND  ; 20 find
.WORD VERB_TALK  ; 21 talk
.WORD VERB_MAKE  ; 22 make
.WORD VERB_SCORE ; 23 score
.WORD VERB_QUIT  ; 24 quit
.WORD VERB_LOAD  ; 25 load
.WORD VERB_SAVE  ; 26 save

******
OBJTAB
******
.BYTE 0,0   ,  0 ; NOTHING
.BYTE #"BRA",  1 ; BRASS
.BYTE #"FAR",  1 ; FARTHING
.BYTE #"GAR",  2 ; GARNET
.BYTE #"COP",  3 ; COPPER
.BYTE #"PEN",  3 ; PENNY
.BYTE #"TOP",  4 ; TOPAZ
.BYTE #"SIL",  5 ; SILVER
.BYTE #"DOL",  5 ; DOLLAR
.BYTE #"EME",  6 ; EMERALD
.BYTE #"GOL",  7 ; GOLD
.BYTE #"DUC",  7 ; DUCAT
.BYTE #"DIA",  8 ; DIAMOND
.BYTE #"SAP",  9 ; SAPLING
.BYTE #"TRE",  9 ; TREE
.BYTE #"EGG", 10 ; EGG
.BYTE #"RIN", 11 ; RING
.BYTE #"STA", 12 ; STAFF
.BYTE #"BOO", 13 ; BOOK
.BYTE #"SWO", 14 ; SWORD
.BYTE #"LAM", 15 ; LAMP
.BYTE #"TOR", 16 ; TORCH
.BYTE #"CLU", 16 ; CLUB
.BYTE #"DAG", 17 ; DAGGER
.BYTE #"MAT", 18 ; MATCHES
.BYTE #"SWI", 19 ; SWITCH BLADE
.BYTE #"KNI", 19 ; KNIFE
.BYTE #"AXE", 20 ; AXE
.BYTE #"AX@", 20 ; AX
.BYTE #"MAC", 21 ; MACE
.BYTE #"SPH", 22 ; SPHERE
.BYTE #"BOM", 22 ; BOMB
.BYTE #"FUS", 22 ; FUSE
.BYTE #"MET", 22 ; METALLIC
.BYTE #"CRY", 23 ; CRYSTAL
.BYTE #"BAL", 23 ; BALL
.BYTE #"MIR", 24 ; MIRROR
.BYTE #"WAR", 25 ; WARHAMMER
.BYTE #"HAM", 25 ; HAMMER
.BYTE #"COI", 51 ; COINS
.BYTE #"MON", 51 ; MONEY
.BYTE #"GEM", 52 ; GEM
.BYTE #"ALL", 99 ; ALL
.BYTE #"EVE", 99 ; EVERYTHING
.BYTE #"NOR",101 ; NORTH
.BYTE #"N@@",101 ; N
.BYTE #"SOU",102 ; SOUTH
.BYTE #"S@@",102 ; S
.BYTE #"EAS",103 ; EAST
.BYTE #"E@@",103 ; E
.BYTE #"WES",104 ; WEST
.BYTE #"W@@",104 ; W
.BYTE #"UP@",105 ; UP
.BYTE #"U@@",105 ; U
.BYTE #"DOW",106 ; DOWN
.BYTE #"D@@",106 ; D

NOBJECTS = * - OBJTAB-3

******
GROUPE
******
        .BYTE   0 ; 0
        .BYTE  36 ; 1
        .BYTE 100 ; 2
        .BYTE  25 ; 3
        .BYTE   1 ; 4
        .BYTE   9 ; 5
        .BYTE   4 ; 6

*****
GROLO
*****
        .BYTE  0                  ; 0
        .BYTE <[PATH_TAB_START-4] ; 1
        .BYTE <[LOC_TAB_START-16] ; 2
        .BYTE <[OBJ_TAB_START] ; 3
        .BYTE <[PRI_TAB_START-16] ; 4
        .BYTE <[MONTAB-16] ; 5
        .BYTE <[NPCTAB-16] ; 6

*****
GROHI
*****
        .BYTE  0                  ; 0
        .BYTE >[PATH_TAB_START-4] ; 1
        .BYTE >[LOC_TAB_START-16] ; 2
        .BYTE >[OBJ_TAB_START] ; 3
        .BYTE >[PRI_TAB_START-16] ; 4
        .BYTE >[MONTAB-16]        ; 5
        .BYTE >[NPCTAB-16] ; 6

;             -  N  S  E  W  U  D
DIRINX  .BYTE 0, 4, 6, 8,10,12,14

**************
PATH_TAB_START
**************
;             T1 T2 HD SC
;-----------------------------------------------
        .BHEX 00,01,00,ff ;  1 gate
        .BHEX 00,02,00,00 ;  2 wall
        .BHEX 00,03,00,ff ;  3 street
        .BHEX 02,04,80,ff ;  4 golden door
        .BHEX 02,05,80,60 ;  5 crack in the wall
        .BHEX 00,06,00,00 ;  6 ground
        .BHEX 06,07,c4,80 ;  7 small hole
        .BHEX 00,08,00,00 ;  8 sky
        .BHEX 00,09,00,00 ;  9 ceiling
        .BHEX 09,07,c0,64 ; 10 hole in ceiling
        .BHEX 00,0a,00,ff ; 11 road
        .BHEX 00,0b,00,ff ; 12 path
        .BHEX 00,0c,00,ff ; 13 more forest
        .BHEX 00,0d,00,00 ; 14 impenetrable
        .BHEX 0d,0b,80,ff ; 15 impenetrable path
        .BHEX 00,0e,00,00 ; 16 unclimbable slope
        .BHEX 0e,0b,80,c0 ; 17 unclimbable path
        .BHEX 00,0f,00,ff ; 18 stalactites
        .BHEX 00,10,00,ff ; 19 stalagmites
        .BHEX 02,07,c0,ff ; 20 hole in wall
        .BHEX 02,07,40,80 ; 21 hole in wall
        .BHEX 00,11,00,00 ; 22 unclimbable shaft
        .BHEX 11,12,c4,c8 ; 23 shaft
        .BHEX 00,13,00,ff ; 24 darkness
        .BHEX 00,14,00,00 ; 25 floor
        .BHEX 00,15,00,ff ; 26 door
        .BHEX 02,16,40,ff ; 27 secret door
        .BHEX 03,17,80,64 ; 28 storm drain
        .BHEX 00,1a,00,ff ; 29 forest
        .BHEX 00,21,00,ff ; 30 mud
        .BHEX 00,22,00,00 ; 31 stairway
        .BHEX 00,23,00,00 ; 32 ocean
        .BHEX 21,07,60,c8 ; 33 mud hole
        .BHEX 00,24,00,ff ; 34 swamp
        .BHEX 00,25,00,ff ; 35 more swamp
        .BHEX 00,22,00,ff ; 36 stairway

************
PATH_TAB_END
************
PATH_TAB_NUM = (PATH_TAB_END - PATH_TAB_START) >> 2

*************
LOC_TAB_START
*************
;             NA DT    LT
; 01 Central Square        N     S     -     W     -     -
LOC01   .BHEX 18,00,00,00,03,01,02,03,00,02,05,84,00,08,00,06
; 02 Market                N     S     E     -     -     D
LOC02   .BHEX 1b,00,00,00,01,03,04,01,07,95,00,02,00,08,08,9c
; 03 North Gate            N     S     E     W     -     -
LOC03   .BHEX 19,00,00,00,09,0c,01,01,0d,1d,24,1d,00,08,00,06
; 04 South Gate            N     S     E     W     -     -
LOC04   .BHEX 1c,00,00,00,02,01,1d,0b,0e,1d,25,1d,00,08,00,06
; 05 Royal Palace          -     -     E     -     -     -
LOC05   .BHEX 26,00,00,fd,00,02,00,02,01,1a,00,02,00,09,00,19
; 06 Royal Dungeon         -     -     E     -     -     -
LOC06   .BHEX 27,00,1e,fe,00,02,00,02,08,9b,00,02,00,09,00,19
; 07 Garbage Dump          N     S     E     W     -     -
LOC07   .BHEX 1d,00,1e,00,0c,1d,0c,1d,0c,1d,02,95,00,08,00,06
; 08 Sewer                 -     S     -     W     U     -
LOC08   .BHEX 28,00,1e,fe,00,02,14,0c,00,02,06,9b,02,9c,00,1e
; 09 Narrow Valley         N     S     -     -     -     -
LOC09   .BHEX 29,00,00,00,0a,0c,03,0c,00,10,00,10,00,08,00,06
; 0a Prayer Entrance       -     S     E     W     U     -
LOC0A   .BHEX 2a,2b,00,00,00,02,09,0c,33,1d,30,1d,0b,1f,00,06
; 0b Chapel                -     -     -     -     -     D
LOC0B   .BHEX 2c,00,00,fd,00,02,00,02,00,02,00,02,00,09,0a,24
; 0c Maple Forest          N     S     E     W     -     -
LOC0C   .BHEX 2d,00,00,fc,0d,0d,0e,0d,0f,0d,07,0c,00,08,00,06
; 0d Maple Forest          -     S     E     W     -     -
LOC0D   .BHEX 2d,00,00,fc,00,10,0c,0d,0f,0d,03,0c,00,08,00,06
; 0e Maple Forest          N     -     E     W     -     -
LOC0E   .BHEX 2d,00,00,fc,0c,0d,00,0e,0f,0d,04,0c,00,08,00,06
; 0f Maple Forest          -     -     E     W     -     -
LOC0F   .BHEX 2d,00,00,fc,00,10,00,0e,10,0d,0c,0d,00,08,00,06
; 10 Maple Forest          -     -     E     W     -     -
LOC10   .BHEX 2d,00,00,fc,00,10,00,0e,11,0d,0f,0d,00,08,00,06
; 11 Maple Forest          N     -     E     W     -     -
LOC11   .BHEX 2d,00,00,fc,38,91,00,0e,12,0d,10,0d,00,08,00,06
; 12 Maple Forest          -     -     E     W     -     -
LOC12   .BHEX 2d,00,00,fc,00,10,00,0e,13,0d,11,0d,00,08,00,06
; 13 Maple Forest          -     S     -     W     -     -
LOC13   .BHEX 2d,00,00,fc,00,10,1c,8f,00,0e,12,0d,00,08,00,06
; 14 Sewer                 N     -     -     -     U     -
LOC14   .BHEX 28,00,1e,fe,08,0c,00,02,00,02,00,02,15,97,00,1e
; 15 Cyprus Swamp          -     -     E     W     -     D
LOC15   .BHEX 2e,00,1e,fc,00,0e,00,20,16,23,1d,85,00,08,14,a1
; 16 Cyprus Swamp          -     -     E     W     -     -
LOC16   .BHEX 2e,00,00,fc,00,0e,00,20,17,23,15,23,00,08,00,1e
; 17 Cyprus Swamp          -     -     E     W     -     -
LOC17   .BHEX 2e,2f,00,fc,00,0e,00,20,18,23,16,23,00,08,00,1e
; 18 Cyprus Swamp          -     S     E     W     -     -
LOC18   .BHEX 2e,2f,1e,fc,00,0e,19,23,1b,23,17,23,00,08,00,1e
; 19 Cyprus Swamp          N     S     E     W     -     -
LOC19   .BHEX 2e,2f,1e,fc,18,23,1a,23,18,23,1a,23,00,08,00,1e
; 1a Cyprus Swamp          N     -     E     W     -     -
LOC1A   .BHEX 2e,2f,1e,fc,19,23,00,20,1b,23,17,23,00,08,00,1e
; 1b Cyprus Swamp          -     -     E     W     -     D
LOC1B   .BHEX 2e,2f,00,fc,00,0e,00,20,1c,23,1a,23,00,08,58,a1
; 1c Cyprus Swamp          N     -     -     W     -     -
LOC1C   .BHEX 2e,00,00,fc,13,8f,00,20,00,20,1b,23,00,08,00,1e
; 1d Trail Of Tears        N     S     E     W     -     -
LOC1D   .BHEX 30,00,00,00,04,0b,1e,0b,15,85,1f,1d,00,08,00,06
; 1e Promontory            N     -     -     -     -     D
LOC1E   .BHEX 31,00,00,00,1d,0b,00,20,00,20,00,20,00,08,3d,87
; 1f Redwood Forest        -     -     E     W     -     -
LOC1F   .BHEX 32,00,00,fc,00,0e,00,20,1d,0b,20,0d,00,08,00,06
; 20 Redwood forest        -     -     E     W     -     -
LOC20   .BHEX 32,00,00,fc,00,0e,00,20,1f,0d,21,0d,00,08,00,06
; 21 Redwood forest        -     -     E     W     -     -
LOC21   .BHEX 32,00,33,fc,00,0e,00,20,20,0d,22,0d,00,08,00,06
; 22 Redwood forest        -     -     E     -     -     -
LOC22   .BHEX 32,00,33,fc,00,0e,00,20,21,0d,00,20,00,08,00,06
; 23 Oak forest            N     S     -     W     -     -
LOC23   .BHEX 34,00,00,fc,24,0d,25,0d,00,02,26,0d,00,08,00,06
; 24 Oak forest            -     S     E     W     -     -
LOC24   .BHEX 34,00,00,fc,00,10,23,0d,03,0c,26,0d,00,08,00,06
; 25 Oak forest            N     -     E     W     -     -
LOC25   .BHEX 34,00,00,fc,23,0d,00,0e,04,0c,26,0d,00,08,00,06
; 26 Oak forest            -     -     E     W     -     -
LOC26   .BHEX 34,00,00,fc,00,10,00,0e,23,0d,27,0d,00,08,00,06
; 27 Oak forest            N     -     E     -     -     -
LOC27   .BHEX 34,00,00,fc,2a,91,00,0e,26,0d,00,0e,00,08,00,06
; 28 Aspen forest          N     S     E     -     -     -
LOC28   .BHEX 35,00,36,fc,3c,0c,29,0d,2b,0d,00,10,00,08,00,06
; 29 Aspen forest          N     S     E     -     -     -
LOC29   .BHEX 35,00,36,fc,28,0d,2a,0d,2c,0d,00,10,00,08,00,06
; 2a Aspen forest          N     S     E     -     -     -
LOC2A   .BHEX 35,00,36,fc,29,0d,27,91,2d,0d,00,10,00,08,00,06
; 2b Aspen forest          -     S     E     W     -     -
LOC2B   .BHEX 35,00,36,fc,00,10,2c,0d,2e,0d,28,0d,00,08,00,06
; 2c Aspen forest          N     S     E     W     -     -
LOC2C   .BHEX 35,00,36,fc,2b,0d,2d,0d,2f,0d,29,0d,00,08,00,06
; 2d Aspen forest          N     -     E     W     -     -
LOC2D   .BHEX 35,00,36,fc,2c,0d,00,10,30,0d,2a,0d,00,08,00,06
; 2e Aspen forest          -     S     -     W     -     -
LOC2E   .BHEX 35,00,36,fc,00,10,2f,0d,00,10,2b,0d,00,08,00,06
; 2f Aspen forest          N     S     -     W     -     -
LOC2F   .BHEX 35,00,36,fc,2e,0d,30,0d,00,10,2c,0d,00,08,00,06
; 30 Aspen forest          N     -     E     W     -     -
LOC30   .BHEX 35,00,36,fc,2f,0d,00,10,0a,0c,2d,0d,00,08,00,06
; 31 Pine forest           -     S     -     -     -     -
LOC31   .BHEX 37,00,36,fc,00,10,32,0d,00,0e,00,10,00,08,00,06
; 32 Pine forest           -     S     E     -     -     -
LOC32   .BHEX 37,00,36,fc,00,0e,33,0d,39,91,00,10,00,08,00,06
; 33 Pine forest           -     -     E     W     -     -
LOC33   .BHEX 37,00,36,fc,00,0e,00,10,35,8f,0a,0c,00,08,00,06
; 34 Pine forest           -     S     -     W     -     -
LOC34   .BHEX 37,00,36,fc,00,10,39,91,00,0e,31,0d,00,08,00,06
; 35 Pine forest           N     -     E     -     -     -
LOC35   .BHEX 37,00,36,fc,39,91,00,10,38,0d,00,0e,00,08,00,06
; 36 Pine forest           -     -     -     W     -     -
LOC36   .BHEX 37,00,36,fc,00,10,00,0e,00,10,34,0d,00,08,00,06
; 37 Pine forest           N     -     -     W     -     -
LOC37   .BHEX 37,00,36,fc,36,0d,00,0e,00,10,39,91,00,08,00,06
; 38 Pine forest           N     S     -     -     -     -
LOC38   .BHEX 37,00,36,fc,37,0d,11,91,00,10,00,0e,00,08,00,06
; 39 Mountain top          N     S     E     W     -     -
LOC39   .BHEX 39,3a,00,00,34,0c,35,91,37,91,32,91,00,08,00,16
; 3a Mountain top          -     S     -     -     -     D
LOC3A   .BHEX 39,3a,00,00,00,10,3b,0c,00,10,00,10,00,08,52,97
; 3b Mountain trail        N     S     -     -     -     -
LOC3B   .BHEX 38,00,00,00,3a,0c,3c,0c,00,10,00,10,00,08,00,06
; 3c Mountain trail        N     S     -     -     -     -
LOC3C   .BHEX 38,00,00,00,3b,0c,28,0c,00,10,00,10,00,08,00,06
; 3d Damp cavern           -     -     E     -     U     -
LOC3D   .BHEX 3b,00,00,fe,00,02,00,02,3e,18,00,02,1e,8a,00,19
; 3e Damp cavern           -     -     -     W     -     D
LOC3E   .BHEX 3b,00,00,ff,00,02,00,02,00,02,3d,18,00,12,3f,97
; 3f Climbing a vertical   -     -     -     -     U     D
LOC3F   .BHEX 3c,00,00,ff,00,02,00,02,00,02,00,02,3e,18,40,18
; 40 Climbing a vertical   -     -     -     -     U     D
LOC40   .BHEX 3c,00,00,ff,00,02,00,02,00,02,00,02,3f,18,41,18
; 41 Climbing a vertical   -     -     -     -     U     D
LOC41   .BHEX 3c,00,00,ff,00,02,00,02,00,02,00,02,40,18,42,18
; 42 Room with obsidian    -     -     E     -     U     D
LOC42   .BHEX 3d,00,00,ff,00,02,00,02,43,9b,00,02,41,97,59,24
; 43 Crawling in a tunnel  -     -     E     W     -     -
LOC43   .BHEX 3e,00,00,ff,00,02,00,02,44,18,42,9b,00,09,00,19
; 44 Crawling in a tunnel  -     -     E     W     -     -
LOC44   .BHEX 3e,00,00,ff,00,02,00,02,45,18,43,18,00,09,00,19
; 45 Crawling in a tunnel  N     -     E     W     -     -
LOC45   .BHEX 3e,00,00,ff,48,85,00,02,46,18,44,18,00,09,00,19
; 46 Crawling in a tunnel  -     -     E     W     -     -
LOC46   .BHEX 3e,00,00,ff,00,02,00,02,47,18,45,18,00,09,00,19
; 47 Crawling in a tunnel  -     -     E     W     -     -
LOC47   .BHEX 3e,00,00,ff,00,02,00,02,55,18,46,18,00,09,00,19
; 48 Crawling in a tunnel  N     S     E     W     -     -
LOC48   .BHEX 3e,00,00,ff,54,9b,45,85,53,9b,49,18,00,09,00,19
; 49 Crawling in a tunnel  -     -     E     W     -     -
LOC49   .BHEX 3e,00,00,ff,00,02,00,02,48,18,4a,18,00,09,00,19
; 4a Crawling in a tunnel  N     -     E     -     -     -
LOC4A   .BHEX 3e,00,00,ff,4b,18,00,02,49,18,00,02,00,09,00,19
; 4b Crawling in a tunnel  N     S     -     -     -     -
LOC4B   .BHEX 3e,00,00,ff,4c,18,4a,18,00,02,00,02,00,09,00,19
; 4c Crawling in a tunnel  N     S     -     -     -     -
LOC4C   .BHEX 3e,00,00,ff,4d,18,4b,18,00,02,00,02,00,09,00,19
; 4d Crawling in a tunnel  -     S     -     -     U     -
LOC4D   .BHEX 3e,00,00,ff,00,02,4c,18,00,02,00,02,4e,97,00,19
; 4e Climbing a vertical   -     -     -     -     U     D
LOC4E   .BHEX 3c,00,00,ff,00,02,00,02,00,02,00,02,4f,18,4d,18
; 4f Climbing a vertical   -     -     -     -     U     D
LOC4F   .BHEX 3c,00,00,ff,00,02,00,02,00,02,00,02,50,18,4e,18
; 50 Climbing a vertical   -     -     -     -     U     D
LOC50   .BHEX 3c,00,00,ff,00,02,00,02,00,02,00,02,51,18,4f,18
; 51 Climbing a vertical   -     -     -     -     U     D
LOC51   .BHEX 3c,00,00,ff,00,02,00,02,00,02,00,02,52,18,50,18
; 52 Climbing a vertical   -     -     -     -     U     D
LOC52   .BHEX 3c,00,00,fe,00,02,00,02,00,02,00,02,3a,97,51,18
; 53 Room with obsidian    -     -     -     W     -     -
LOC53   .BHEX 3d,00,00,ff,00,02,00,02,00,02,48,9b,00,09,00,19
; 54 Room with obsidian    -     S     -     -     -     -
LOC54   .BHEX 3d,00,00,ff,00,02,48,9b,00,02,00,02,00,09,00,19
; 55 Crawling in a tunnel  N     -     -     W     -     -
LOC55   .BHEX 3e,00,00,ff,56,18,00,02,00,02,47,18,00,09,00,19
; 56 Crawling in a tunnel  -     S     -     -     U     -
LOC56   .BHEX 3e,00,00,ff,00,02,55,18,00,02,00,02,57,97,00,19
; 57 Climbing a vertical   -     -     -     -     U     D
LOC57   .BHEX 3c,00,00,ff,00,02,00,02,00,02,00,02,58,18,56,18
; 58 Climbing a vertical   -     -     -     -     U     D
LOC58   .BHEX 3c,00,00,fe,00,02,00,02,00,02,00,02,1b,97,57,18
; 59 Limestone cavern      N     S     E     W     U     -
LOC59   .BHEX 3f,40,00,ff,5a,12,5d,12,5e,12,5b,13,42,24,00,13
; 5a Limestone cavern      -     S     E     -     -     -
LOC5A   .BHEX 3f,40,00,ff,00,13,5b,12,5f,13,00,12,00,12,00,13
; 5b Limestone cavern      N     -     E     -     -     -
LOC5B   .BHEX 3f,40,00,ff,5a,12,00,12,5c,13,00,13,00,12,00,13
; 5c Limestone cavern      N     -     E     W     -     -
LOC5C   .BHEX 3f,40,00,ff,59,13,00,13,5d,12,5b,12,00,12,00,13
; 5d Limestone cavern      N     -     -     W     -     -
LOC5D   .BHEX 3f,40,00,ff,5e,12,00,13,00,12,5c,13,00,12,00,13
; 5e Limestone cavern      N     S     -     W     -     -
LOC5E   .BHEX 3f,40,00,ff,60,13,5d,13,00,13,5f,12,00,12,00,13
; 5f Limestone cavern      -     S     E     W     -     -
LOC5F   .BHEX 3f,40,00,ff,00,12,59,13,5e,13,5a,13,00,12,00,13
; 60 Room with a slate     -     S     -     -     -     D
LOC60   .BHEX 41,00,00,ff,00,02,5e,13,00,02,00,02,00,09,61,24
; 61 Dry cavern            -     -     E     -     U     D
LOC61   .BHEX 42,00,00,fb,00,02,00,02,63,94,00,02,60,24,62,24
; 62 Room with a large iron-     -     -     -     U     -
LOC62   .BHEX 44,45,46,fa,00,02,00,02,00,02,00,02,61,24,00,19
; 63 Crawling in a tunnel  -     -     E     W     -     -
LOC63   .BHEX 3e,00,1e,ff,00,02,00,02,64,95,61,94,00,09,00,19
; 64 Very large cavern     -     -     -     W     -     -
LOC64   .BHEX 43,00,1e,ff,00,02,00,02,00,02,63,94,00,09,00,19

************
LOC_TAB_END
************
LOC_TAB_NUM = (LOC_TAB_END - LOC_TAB_START) >> 4

*************
OBJ_TAB_START
*************
;             M0 message 0 standard
;             |  M1 message 1 evolution
;             |  |  M2 message 2 detail
;             |  |  |  WT weight
;             |  |  |  |  AF attack force
;             |  |  |  |  |  AM attack message
;             |  |  |  |  |  |  PE penalty
;             |  |  |  |  |  |  |  BU burn time
;             |  |  |  |  |  |  |  |  L1 location 1
;             |  |  |  |  |  |  |  |  |  L2 location 2
;             |  |  |  |  |  |  |  |  |  |  TF throw force
;             0  1  2  3  4  5  6  7  8  9 10
; ---------------------------------------------------
NULLOBJ .BHEX  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0,0,0,0,0 ;  0 null object
BRASS   .BHEX 1f, 0,47,01, 0, 0, 0, 0,01,04, 2,0,0,0,0,0 ;  1 brass farthing
GARNET  .BHEX 20, 0, 0,01, 0, 0, 0, 0,07,08, 2,0,0,0,0,0 ;  2 garnet
PENNY   .BHEX 48, 0,47,01, 0, 0, 0, 0,14,08, 2,0,0,0,0,0 ;  3 copper penny
TOPAZ   .BHEX 49, 0, 0,01, 0, 0, 0, 0,1e,09, 2,0,0,0,0,0 ;  4 topaz
DOLLAR  .BHEX 4a, 0,47,01, 0, 0, 0, 0,0c,13, 2,0,0,0,0,0 ;  5 silver dollar
EMERALD .BHEX 4b, 0, 0,01, 0, 0, 0, 0,23,38, 2,0,0,0,0,0 ;  6 emerald
DUCAT   .BHEX 4c, 0,47,01, 0, 0, 0, 0,53,54, 2,0,0,0,0,0 ;  7 gold ducat
DIAMOND .BHEX 4d, 0, 0,01, 0, 0, 0, 0,05,05, 2,0,0,0,0,0 ;  8 diamond
SAPLING .BHEX 4e,4f, 0,ff, 0, 0, 0, 0,1c,1c, 2,0,0,0,0,0 ;  9 sapling
EGG     .BHEX 50,51, 0,04, 0, 0, 0, 0,ff,ff, 2,0,0,0,0,0 ; 10 egg
RING    .BHEX 52, 0,53,02,c8,54,20, 0,63,63, 2,0,0,0,0,0 ; 11 ring
STAFF   .BHEX 55, 0,53,40,96,56,40, 0,ff,ff, 2,0,0,0,0,0 ; 12 staff
BOOK    .BHEX 57, 0,58,08, 0, 0, 0, 0,39,3a, 2,0,0,0,0,0 ; 13 book
SWORD   .BHEX 59, 0,5a,2b,5a,5b, 0, 0,19,19,20,0,0,0,0,0 ; 14 sword
LAMP    .BHEX 5c, 0,5d,0c, 0, 0, 0, 0,ff,ff, 2,0,0,0,0,0 ; 15 lamp
TORCH   .BHEX 5e, 0, 0,0a,08,5f, 0,1e,02,02,20,0,0,0,0,0 ; 16 torch
DAGGER  .BHEX 60, 0,5a,0c,2d,61, 0, 0,20,16,40,0,0,0,0,0 ; 17 dagger
MATCHES .BHEX 62, 0, 0,01, 0, 0, 0,06,02,02, 2,0,0,0,0,0 ; 18 matches
KNIFE   .BHEX 79, 0,7a,08,10,61,01, 0,ff,ff,2c,0,0,0,0,0 ; 19 knife
AXE     .BHEX 9d, 0,7a,4b,3c,9e,01, 0,ff,ff,36,0,0,0,0,0 ; 20 axe
MACE    .BHEX a2, 0,7a,64,46,a3,01, 0,ff,ff,10,0,0,0,0,0 ; 21 mace
SPHERE  .BHEX a8,a9,5a,38, 0, 0, 0,0a,31,2c, 2,0,0,0,0,0 ; 22 bomb
CRYSTAL .BHEX aa,ab, 0,10, 0, 0, 0, 0,ff,ff, 2,0,0,0,0,0 ; 23 crystal ball
MIRROR  .BHEX ae,af, 0,08, 0, 0, 0, 0,06,06, 2,0,0,0,0,0 ; 24 mirror
HAMMER  .BHEX b0, 0,5a,50,5a,b1, 0, 0,48,51,a4,0,0,0,0,0 ; 25 warhammer

************
OBJ_TAB_END
************
OBJ_TAB_NUM = (OBJ_TAB_END - OBJ_TAB_START - 16) >> 4

*************
PRI_TAB_START
*************
;              M0 M1 M2  3  4  5 TR L1
; -----------------------------------------------------
PRINCESS .BHEX 75,76,77,00,04,78,08,00,00,0,0,0,0,0,0,0

*************
MONTAB
*************
;              0  1  2  3  4  5  6  7  8  9
;             M0 M1 M2 KP R  AT WP
; ---------------------------------------------------
KNAVE   .BHEX 71,72,73,1e,08,74,13,01,23,27,0,0,0,0,0,0 ; 1
CROCO   .BHEX 66,67,00,06,24,68,00,00,1b,1c,0,0,0,0,0,0 ; 2
BAT     .BHEX a4,a5,00,02,04,a6,00,00,3e,3e,0,0,0,0,0,0 ; 3
WORM    .BHEX 97,98,00,04,1e,99,00,00,43,4d,0,0,0,0,0,0 ; 4
GOBLIN  .BHEX 9a,9b,6f,28,3c,9c,14,00,53,42,0,0,0,0,0,0 ; 5
TROLL   .BHEX 9f,a0,6f,32,50,a1,15,00,60,61,0,0,0,0,0,0 ; 6
SPIDER  .BHEX 63,64,00,50,b4,65,00,00,19,19,0,0,0,0,0,0 ; 7
WITCHER .BHEX 6d,6e,6f,64,c8,70,0c,00,43,61,0,0,0,0,0,0 ; 8
DRAGON  .BHEX 69,6a,6b,80,ff,6c,00,00,64,64,0,0,0,0,0,0 ; 9

************
MON_TAB_END
************
MON_TAB_NUM = (MON_TAB_END - MONTAB) >> 4

*************
NPCTAB
*************
;             NA name
;             |  M1 message 1
;             |  |  M2 message 2
;             |  |  |  M3 message 3
;             |  |  |  |  M4 message 4
;             |  |  |  |  |  DS Defense strength
;             |  |  |  |  |  |  AM attack message
;             |  |  |  |  |  |  |  WO wanted object
;             |  |  |  |  |  |  |  |  KI king
;             |  |  |  |  |  |  |  |  |  KB Karma bonus
;             |  |  |  |  |  |  |  |  |  |  TR treasure
;             |  |  |  |  |  |  |  |  |  |  |  L1 location 1
;             |  |  |  |  |  |  |  |  |  |  |  | L2 location 2
;             0  1  2  3  4  5  6  7  8  9  10 11 12
; ------------------------------------------------------------
KING    .BHEX 7b,7c,7d,7e,7f,ff,80,00,01,40,08,05,05,0,0,0 ; 1
WIZARD  .BHEX 6d,81,82,83,84,ff,85,0c,00,40,17,01,3c,0,0,0 ; 2
BEGGAR  .BHEX 86,87,88,89,8a,01,8b,05,00,04,0f,1d,09,0,0,0 ; 3
GIANT   .BHEX 8c,8d,8e,8f,90,ff,91,09,00,10,0a,22,22,0,0,0 ; 4

************
NPC_TAB_END
************
NPC_TAB_NUM = (NPC_TAB_END - NPCTAB) >> 4

PATH    .BYTE 0,0,0,0

KARMPT  .WORD 0
WEIGHT  .WORD 0
SEED    .WORD 0
LOC     .BYTE 0
QUEST   .BYTE 0
VERB    .BYTE 0
OBJECT  .BYTE 0
IDOL    .BYTE 0
LITMAT  .BYTE 0
MONSTER .BYTE 0
NPC     .BYTE 0
WEAPON  .BYTE 0
BRAVE   .BYTE 0
***
EOP
***
FILENAME .BYTE "SAVE"
         .FILL 16 (0)

BUFFER  .FILL 40 (0)
FORBUF  .BYTE 0
