.import __PRACTISE_WRAMCODE_LOAD__, __PRACTISE_WRAMCODE_RUN__, __PRACTISE_WRAMCODE_SIZE__


; ===========================================================================
;  Copy bankswitching code to WRAM
; ---------------------------------------------------------------------------
InitBankSwitchingCode:
    ldx #0                                    ; init X
:   lda __PRACTISE_WRAMCODE_LOAD__,x          ; load byte from ROM
    sta __PRACTISE_WRAMCODE_RUN__,x           ; and copy to WRAM
    lda __PRACTISE_WRAMCODE_LOAD__+$100,x     ; load byte from ROM
    sta __PRACTISE_WRAMCODE_RUN__+$100,x      ; and copy to WRAM
    inx                                       ; increment to copy full page
    bne :-                                    ;
    rts                                       ;
; ===========================================================================

; this code is copied into WRAM and used to jump between banks
.pushseg
.segment "PRACTISE_WRAMCODE"
; export symbols so that we can call them from smb1 and title screen as needed
.export BANK_PractiseNMI
.export BANK_PractiseReset
.export BANK_PractiseWriteBottomStatusLine
.export BANK_PractiseWriteTopStatusLine
.export BANK_PractisePrintScore
.export BANK_PractiseEnterStage

; these values can get replaced during patching
WorldCount: .byte 13
LevelCount: .byte 4
RELOCATE_GetAreaDataAddrs: jmp GetAreaDataAddrs
RELOCATE_LoadAreaPointer: jmp LoadAreaPointer
RELOCATE_PlayerEndWorld: jmp EndWorld1Thru7
RELOCATE_NonMaskableInterrupt: jmp NMIHandler
RELOCATE_GL_ENTER: jmp GL_ENTER

; wrappers around some title screen routines to be called from the game
BANK_PractiseNMI:
jsr BANK_TITLE_RTS
jsr PractiseNMI
jmp BANK_GAME_RTS

BANK_PractiseReset:
jsr BANK_TITLE_RTS
jmp HotReset

BANK_PractiseWriteBottomStatusLine:
jsr BANK_TITLE_RTS
jsr PractiseWriteBottomStatusLine
jmp BANK_GAME_RTS

BANK_PractiseWriteTopStatusLine:
jsr BANK_TITLE_RTS
jsr PractiseWriteTopStatusLine
jmp BANK_GAME_RTS

BANK_PractisePrintScore:
jsr BANK_TITLE_RTS
jsr RedrawLowFreqStatusbar
jmp BANK_GAME_RTS

BANK_PractiseEnterStage:
jsr BANK_TITLE_RTS
jsr PractiseEnterStage
jmp BANK_GAME_RTS
rts

; ===========================================================================
;  Attempt to find the level selected on the menu screen
; ---------------------------------------------------------------------------
BANK_AdvanceToLevel:
    lda WorldNumber                     ; check selected world number
    cmp #$09                            ; did we select a letter world?
    bcc @NumberWorlds                   ; if not, branch ahead
    sbc #$09                            ; otherwise subtract 9 for internal number
    sta WorldNumber                     ; store the result in the world number
    inc HardWorldFlag                   ; and set letter worlds flag
@NumberWorlds:
    cmp #World9                         ; check if we're on world 9
    bne @InitAreaNumber                 ; branch ahead if we're not
    lda LevelNumber                     ; otherwise, check if we're on 9-1
    beq @InitAreaNumber                 ; if we are, display world 9 message
    inc FantasyW9MsgFlag                ; otherwise, increment flag to skip message
@InitAreaNumber:
    jsr BANK_LEVELBANK_RTS              ; switch to the level banks
    @AreaNumber = $0                    ;
    ldx #0                              ;
    stx @AreaNumber                     ; clear temp area number
    stx AreaNumber                      ; clear area number
    ldx LevelNumber                     ; get how many levels to advance
    beq @LevelFound                     ; if we're on the first level, we're done
@NextArea:                              ;
    jsr RELOCATE_LoadAreaPointer        ; otherwise, load the area pointer
    jsr RELOCATE_GetAreaDataAddrs       ; then get the pointer to the area data
    inc AreaNumber                      ; advance area pointer
    lda PlayerEntranceCtrl              ; get what kind of entry this level has
    and #%00000100                      ; check if it's a controllable area
    beq @AreaOK                         ; yes - advance to next level
    inc @AreaNumber                     ; yes - increment temp area number
    bvc @NextArea                       ; and check next area
@AreaOK:                                ;
    dex                                 ; decrement number of levels we need to advance
    bne @NextArea                       ; and keep running if we haven't reached our level
@LevelFound:                            ;
    clc                                 ;
    lda LevelNumber                     ; get level we are starting on
    adc @AreaNumber                     ; and add how many areas we needed to skip
    sta AreaNumber                      ; and store that as the area number
    lda #0                              ; clear sound
    sta SND_DELTA_REG+1                 ;
    jsr RELOCATE_LoadAreaPointer        ; reload pointers for this area
    jsr RELOCATE_GetAreaDataAddrs       ;
    jsr BANK_GAME_RTS                   ; load game bank
    lda #$a5                            ;
    jmp RELOCATE_GL_ENTER               ; then start the game
; ===========================================================================

; return to previous segment
.popseg
