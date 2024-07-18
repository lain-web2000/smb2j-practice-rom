; # GreatEd Startup code
;
; This is used for hacks made with greated
;

.segment "PRACTISE_PRG0"
TitleReset2:
    lda #%10000000     ; enable battery backed wram
    sta $A001          ;
; include title file
.include "title.asm"

.segment "INES"
; MMC3 INES header
INES_MAPPER = 4 << 4
INES_BATTERY = %00000010
INES_VERTICAL_MIRROR = %00000001
.byte $4E,$45,$53,$1A ; NES
.byte 8               ; prg banks
.byte 2               ; chr banks
.byte INES_MAPPER | INES_BATTERY | INES_VERTICAL_MIRROR

;.segment "PRACTISE_PRG0"
;TitleMMC3NMI:
;    jsr BANK_GAME_RTS
;    jmp RELOCATE_NonMaskableInterrupt

.segment "PRACTISE_PRG2"
; ================================================================
;  Boot game into title screen
; ----------------------------------------------------------------
ColdTitleReset:
    sei                       ; 6502 init
    cld                       ;
    ldx #$FF                  ; clear stack
    txs                       ;
    lda #$c0                  ; disable APU IRQs
	sta JOYPAD_PORT2          ;
    lda #PractiseBank         ; init greated mapper state
    ldx #$06                  ;
    stx $8000                 ;
    sta $8001                 ;
    jsr InitializeBG_CHR      ; init CHR banks
    jsr InitializeSPR_CHR     ;
    jmp TitleReset2           ; and prepare the title screen
; ----------------------------------------------------------------

; the following code is copied to battery backed ram
.segment "PRACTISE_WRAMCODE"

BANK_GAME_NMI:
    lda IsPlaying
    bne @InGameMode
    jsr BANK_TITLE_RTS
    jmp TitleNMI
@InGameMode:
    jsr BANK_GAME_RTS
    jmp RELOCATE_NonMaskableInterrupt

; ================================================================
;  Handle loading new level banks
; ----------------------------------------------------------------
BANK_LEVELBANK_RTS:
    pha                     ; save whatever A value we were called with
    lda #6                  ; set mmc state
    sta $8000               ;
    lda #LevelsBank         ;
    sta $8001               ; set bank
    lda #7                  ;
    sta $8000               ;
    lda #LevelsBank+1       ;
    sta $8001               ;
    pla                     ; restore the A value we were called with
    rts                     ;
; ================================================================

; ================================================================
;  Load into game bank and return control
; ----------------------------------------------------------------
BANK_GAME_RTS:
    pha                     ; push our current A value to not disturb it
    lda #6                  ; set mmc3 state for game mode
    sta $8000               ;
    lda #GameBank           ;
    sta $8001               ;
    lda #7                  ;
    sta $8000               ;
    lda #GameBank+1         ;
    sta $8001               ;
    pla                     ; restore previous A value
    rts                     ;
; ================================================================

; ================================================================
;  Load into title screen and return control
; ----------------------------------------------------------------
BANK_TITLE_RTS:
    pha                     ; push our current A value to not disturb it
    lda #6                  ; set mmc3 state for title mode
    sta $8000               ;
    lda #PractiseBank       ;
    sta $8001               ;
    lda #7                  ;
    sta $8000               ;
    lda #PractiseBank+1     ;
    sta $8001               ;
    pla                     ; restore previous A value
    rts                     ;
; ================================================================

; interrupt handlers
.segment "PRACTISE_VEC"
.word BANK_GAME_NMI
.word ColdTitleReset
.word IRQHandler
