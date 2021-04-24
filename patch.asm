; Build params: ------------------------------------------------------------------------------
CHEAT set 0
; Constants: ---------------------------------------------------------------------------------
	MD_PLUS_OVERLAY_PORT:			equ $0003F7FA
	MD_PLUS_CMD_PORT:				equ $0003F7FE
	MD_PLUS_RESPONSE_PORT:			equ $0003F7FC

	VECTOR_TABLE:					equ $00000000
	ORIGINAL_ENTRY_POINT:			equ	$00000260

	GAME_PAUSED_LOOP:				equ $00005E34

	IGNORE_SOUND_COMMAND:			equ	$000BA5C2
	PAUSE_MUSIC_FUNCTION:			equ $000BA074
	RESUME_MUSIC_FUNCTION:			equ $000BA0D2
	PLAY_MUSIC_FUNCTION:			equ $000BA4E8
	SILENCE_FM_FUNCTION:			equ $000BA7B4
	INIT_FADE_OUT_MUSIC_FUNCTION:	equ $000BA6CE
	FADE_OUT_MUSIC_FUNCTION:		equ $000BA726

	RAM_SOUND_COMMAND:				equ $00FFD003
	RAM_PAUSED_MODE:				equ $00FFD012

; Overrides: ---------------------------------------------------------------------------------

	if CHEAT

	org $6D9C								; Walk through walls while pressing B
	jsr		WALK_DETOUR

	org $2814								; One hit kills
	dc.b $4E,$71

	org $2B0C								; No damage from physical strikes
	dc.b $60,$12

	org $2C14								; No damage from venom strikes
	dc.b $60,$12

	org $716E								; No damage from damage zones
	dc.b $60,$14

	org $1175C
	jsr		ENCOUNTER_RATE_DETOUR

	endif

	org	VECTOR_TABLE+$4						; Offset $4 in the vector table specifies the program entry point
	dc.l	NEW_ENTRY_POINT

	org GAME_PAUSED_LOOP+$2E
	jsr		GAME_UNPAUSE_DETOUR				; This detours the exit routine of the GAME PAUSE LOOP

	org	PAUSE_MUSIC_FUNCTION
	move	#$1300,D1
	jsr		WRITE_MD_PLUS_FUNCTION
	rts

	org	RESUME_MUSIC_FUNCTION
	move	#$1400,D1
	jsr		WRITE_MD_PLUS_FUNCTION
	rts

	org PLAY_MUSIC_FUNCTION+$10				; The PLAY_MUSIC_FUNCTION does some important stuff, like silence all SFX/music in the first $10 bytes.
	move	#$1201,D1						; Also, there are points in the game that actually branch directly to PLAY_MUSIC_FUNCTION+$10.
	add.b	D0,D1							; Therefore, we hijack the function with an offset of $10 bytes
	jsr		WRITE_MD_PLUS_FUNCTION
	bra		IGNORE_SOUND_COMMAND

	org SILENCE_FM_FUNCTION					; Since this function's purpose is also to stop SFX we need to execute the rest of the
	jsr		SILENCE_FM_DETOUR				; function as well, therefore we simply call our detour function and then continue

	org INIT_FADE_OUT_MUSIC_FUNCTION		; This function sets up the RAM values so that the FADE_OUT_MUSIC_FUNCTION can actually
	move	#$13FF,D1						; fade out the music. With MD+, this is not necessary so we simply call the
	jsr		WRITE_MD_PLUS_FUNCTION			; MD+ fade out command here and make the FADE_OUT_MUSIC_FUNCTION do nothing
	rts

	org FADE_OUT_MUSIC_FUNCTION
	rts

; Detours: -----------------------------------------------------------------------------------
	org $000BF700

	if CHEAT
WALK_DETOUR
	move.w	#$FFFF,($FFFFC622)				; Move $FFFF into the RAM address containing the players current money
	jsr		$6DA4
	bne		NOT_WALKABLE
	jmp		$71D0
NOT_WALKABLE
	move.b	($FFFFF602),D1
	eori.b	#$FF,D1
	btst	#$4,D1							; This wil set the zero flag if the B button was pressed, allowing it to walk through walls
	rts

ENCOUNTER_RATE_DETOUR
	move.b	(A1),D2
	move.b	($FFFFF602),D1
	btst	#$4,D1
	bne		ZERO_ENCOUNTER_RATE
	addq.w	#$1,D2
	rts
ZERO_ENCOUNTER_RATE
	move.w	#$0,($FFFFCB0C)					; If the B button was pressed, zero the current encounter rate
	rts
	endif

GAME_UNPAUSE_DETOUR
	jsr RESUME_MUSIC_FUNCTION
	move.b	#$0,(RAM_PAUSED_MODE)			; Resume ingame FM playback
	rts

SILENCE_FM_DETOUR
	move	#$1300,D1
	jsr		WRITE_MD_PLUS_FUNCTION
	move.w	#$0,D7							; Original game code
	rts

NEW_ENTRY_POINT
	jsr		PAUSE_MUSIC_FUNCTION			; Stops any cd audio playback on reset/bootup
	jmp		ORIGINAL_ENTRY_POINT			; Jump to the actual entry point of the game

; Helper Functions: --------------------------------------------------------------------------

WRITE_MD_PLUS_FUNCTION:
	move.w  #$CD54,(MD_PLUS_OVERLAY_PORT)	; Open interface
	move.w  D1,(MD_PLUS_CMD_PORT)			; Send command to interface
	move.w  #$0000,(MD_PLUS_OVERLAY_PORT)	; Close interface
	rts

; Data: --------------------------------------------------------------------------------------
