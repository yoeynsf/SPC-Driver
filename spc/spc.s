.import communicate_snes

.setcpu "none"
.include "inc/spc-65c02.inc"
.include "inc/spc_defines.inc" 

.segment "SPCZEROPAGE"    
tmp0:               .res 1
tmp1:               .res 1
tmp2:               .res 1
tmp3:               .res 1
buf_CONTROL:        .res 1
buf_CPU0:           .res 1
buf_CPU1:           .res 1
buf_CPU2:           .res 1
buf_CPU3:           .res 1

; ----- DSP Buffer ----- ;
buf_CLVOL:          .res NUM_CHANNELS
buf_CRVOL:          .res NUM_CHANNELS
buf_CFREQLO:        .res NUM_CHANNELS
buf_CFREQHI:        .res NUM_CHANNELS
buf_LVOL:           .res NUM_CHANNELS
buf_RVOL:           .res NUM_CHANNELS
buf_LECHOVOL:       .res NUM_CHANNELS
buf_RECHOVOL:       .res NUM_CHANNELS
buf_KEYON:          .res NUM_CHANNELS
buf_KEYOFF:         .res NUM_CHANNELS

.segment "SPCDRIVER"
;--------------------------------------
spc_entrypoint:
    CALL !driver_init
wait_tick:
; TODO: INSERT CODE TO CHECK IF SNES IS ATTEMPTING HANDSHAKE

    MOV A, T0OUT                ; Wait for Timer 0 to change
    BEQ wait_tick

    CLR1 $09.(SPC_BUSY)         ; Signal SPC is not available for communication
    MOV A, buf_CPU3
    MOV CPU3, A

    CALL !driver_update
    JMP wait_tick 
;--------------------------------------
.proc driver_init    
    MOV X, #0                   ; zero out DSP regs
    MOV Y, #0      
:
    MOV DSPADDR, X  
    MOV DSPDATA, Y 
    INC X 
    BPL :-

    MOV A, buf_CONTROL          ; Disable IPL ROM and timers
    MOV CONTROL, A
    
    MOV A, #UPDATE_DIV          ; Set 30ms timer
    MOV T0DIV, A
    MOV A, #1
    MOV CONTROL, A
    RET
.endproc
;--------------------------------------
.proc driver_update ; unload shadow buffers
    INC tmp0

    SET1 $09.(SPC_BUSY)         ; Signal SPC available for communication
    MOV A, buf_CPU3
    MOV CPU3, A

    RET
.endproc
;--------------------------------------