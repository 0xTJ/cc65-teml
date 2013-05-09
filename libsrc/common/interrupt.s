;
; Oliver Schmidt, 2012-01-18
;
; void __fastcall__ set_irq (irq_handler f, void *stack_addr, size_t stack_size);
; void reset_irq (void);
;

        .export         _set_irq, _reset_irq
        .interruptor    clevel_irq, 1           ; Export as low priority IRQ handler
        .import         popax
        .importzp       __ZP_START__

        .include        "zeropage.inc"

        .macpack        generic


; ---------------------------------------------------------------------------

.data

irqvec: jmp     $00FF           ; Patched at runtime

; ---------------------------------------------------------------------------

.bss

irqsp:  .res    2

zpsave: .res    zpsavespace

; ---------------------------------------------------------------------------

.proc   _set_irq

        ; Keep clevel_irq from being called right now
        sei

        ; Set irq stack pointer to stack_addr + stack_size
        sta     irqsp
        stx     irqsp+1
        jsr     popax
        add     irqsp
        sta     irqsp
        txa
        adc     irqsp+1
        sta     irqsp+1

        ; Set irq vector to irq_handler
        jsr     popax
        sta     irqvec+1
        stx     irqvec+2        ; Set the user vector

        ; Restore interrupt requests and return
        cli
        rts

.endproc


.proc   _reset_irq

        lda     #$00
        sta     irqvec+2        ; High byte is enough
        rts

.endproc


.proc   clevel_irq

        ; Is C level interrupt request vector set?
        lda     irqvec+2        ; High byte is enough
        bne     @L1
        clc                     ; Interrupt not handled
        rts

        ; Save our zero page locations
@L1:    ldx     #.sizeof(::zpsave)-1
@L2:    lda     __ZP_START__,x
        sta     zpsave,x
        dex
        bpl     @L2

        ; Set C level interrupt stack
        lda     irqsp
        ldx     irqsp+1
        sta     sp
        stx     sp+1

        ; Call C level interrupt request handler
        jsr     irqvec

        ; Copy back our zero page content
        ldx     #.sizeof(::zpsave)-1
@L3:    ldy     zpsave,x
        sty     __ZP_START__,x
        dex
        bpl     @L3

        ; Mark interrupt handled / not handled and return
        lsr
        rts

.endproc

