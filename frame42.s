; === Aux ===
        sta $c005          ; AUXWRON
        LDA #$08
        STA $4058
        LDA #$30
        STA $40AF
        LDA #$00
        STA $40EF
        LDA #$60
        STA $4147
        LDA #$00
        STA $416F
        LDA #$60
        STA $41AF
        LDA #$00
        STA $41C7
        LDA #$70
        STA $41D7
        LDA #$00
        STA $41EF
        LDA #$60
        STA $4257
        LDA #$00
        STA $42AF
        LDA #$00
        STA $432F
        LDA #$20
        STA $4347
        LDA #$20
        STA $436F
        LDA #$62
        STA $43C7
        LDA #$03
        STA $442F
        LDA #$08
        STA $4458
        LDA #$00
        STA $44AF
        LDA #$0C
        STA $44C8
        LDA #$00
        STA $44EF
        LDA #$20
        STA $4547
        LDA #$00
        STA $456F
        LDA #$60
        STA $45AF
        LDA #$00
        STA $45C7
        LDA #$20
        STA $45D7
        LDA #$60
        STA $4657
        LDA #$00
        STA $46AF
        LDA #$00
        STA $472F
        LDA #$20
        STA $4747
        LDA #$60
        STA $476F
        LDA #$22
        STA $47C7
        LDA #$01
        STA $482F
        LDA #$00
        STA $48AF
        LDA #$08
        STA $48C8
        LDA #$00
        STA $48EF
        LDA #$20
        STA $4947
        LDA #$00
        STA $496F
        LDA #$60
        STA $49AF
        LDA #$00
        STA $49C7
        LDA #$08
        STA $49D8
        LDA #$40
        STA $4A57
        LDA #$00
        STA $4AAF
        LDA #$20
        STA $4B47
        LDA #$60
        STA $4B6F
        LDA #$20
        STA $4BC7
        LDA #$00
        STA $4C2E
        LDA #$00
        STA $4CAF
        LDA #$08
        STA $4CC8
        LDA #$00
        STA $4CEF
        LDA #$00
        STA $4D47
        LDA #$00
        STA $4D6F
        LDA #$60
        STA $4DAF
        LDA #$00
        STA $4DC7
        LDA #$20
        STA $4DD7
        LDA #$08
        STA $4E58
        LDA #$00
        STA $4EAF
        LDA #$20
        STA $4EC7
        LDA #$20
        STA $4F47
        LDA #$20
        STA $4FC7
        LDA #$03
        STA $502F
        LDA #$00
        STA $50AF
        LDA #$08
        STA $50C8
        LDA #$08
        STA $50D8
        LDA #$00
        STA $50EF
        LDA #$00
        STA $5147
        LDA #$00
        STA $516F
        LDA #$60
        STA $51AF
        LDA #$00
        STA $51C7
        LDA #$20
        STA $51D7
        LDA #$00
        STA $52AF
        LDA #$20
        STA $52C7
        LDA #$20
        STA $52EF
        LDA #$20
        STA $5347
        LDA #$08
        STA $53B0
        LDA #$01
        STA $542F
        LDA #$20
        STA $54C7
        LDA #$08
        STA $54D8
        LDA #$00
        STA $54EF
        LDA #$08
        STA $5530
        LDA #$00
        STA $5547
        LDA #$00
        STA $556F
        LDA #$60
        STA $55AF
        LDA #$00
        STA $55C7
        LDA #$60
        STA $55D7
        LDA #$00
        STA $56AF
        LDA #$20
        STA $56C7
        LDA #$00
        STA $56D8
        LDA #$20
        STA $56EF
        LDA #$22
        STA $5747
        LDA #$08
        STA $57B0
        LDA #$13
        STA $582F
        LDA #$00
        STA $586F
        LDA #$60
        STA $58C7
        LDA #$09
        STA $58D8
        LDA #$00
        STA $58EF
        LDA #$20
        STA $592F
        LDA #$00
        STA $5947
        LDA #$20
        STA $5957
        LDA #$00
        STA $596F
        LDA #$20
        STA $59AF
        LDA #$00
        STA $59C7
        LDA #$60
        STA $59D7
        LDA #$00
        STA $5AAF
        LDA #$20
        STA $5AC7
        LDA #$00
        STA $5AD8
        LDA #$20
        STA $5AEF
        LDA #$62
        STA $5B47
        LDA #$08
        STA $5BB0
        LDA #$00
        STA $5C6F
        LDA #$60
        STA $5CC7
        LDA #$00
        STA $5CEF
        LDA #$20
        STA $5D2F
        LDA #$00
        STA $5D47
        LDA #$60
        STA $5D57
        LDA #$00
        STA $5D6F
        LDA #$20
        STA $5DAF
        LDA #$60
        STA $5DD7
        LDA #$00
        STA $5E30
        LDA #$00
        STA $5EAF
        LDA #$20
        STA $5EC7
        LDA #$00
        STA $5ED8
        LDA #$20
        STA $5EEF
        LDA #$62
        STA $5F47
        LDA #$08
        STA $5FB0
; === Main ===
        sta $c004          ; AUXWROFF
        LDA #$7E
        STA $4057
        LDA #$00
        STA $40AE
        LDA #$00
        STA $40C8
        LDA #$00
        STA $40EF
        LDA #$04
        STA $412F
        LDA #$4E
        STA $4147
        LDA #$00
        STA $416F
        LDA #$44
        STA $41AF
        LDA #$00
        STA $41C7
        LDA #$6F
        STA $41D7
        LDA #$54
        STA $41EF
        LDA #$44
        STA $422F
        LDA #$47
        STA $4257
        LDA #$00
        STA $42AF
        LDA #$04
        STA $42C7
        LDA #$00
        STA $432F
        LDA #$44
        STA $4347
        LDA #$4C
        STA $436F
        LDA #$5F
        STA $43C7
        LDA #$08
        STA $442E
        LDA #$6E
        STA $4457
        LDA #$00
        STA $446F
        LDA #$02
        STA $44AF
        LDA #$00
        STA $44C8
        LDA #$00
        STA $44EF
        LDA #$44
        STA $452F
        LDA #$4E
        STA $4547
        LDA #$00
        STA $456F
        LDA #$44
        STA $45AF
        LDA #$00
        STA $45C7
        LDA #$44
        STA $45D7
        LDA #$00
        STA $462F
        LDA #$4D
        STA $4657
        LDA #$00
        STA $46AF
        LDA #$04
        STA $46C7
        LDA #$00
        STA $472F
        LDA #$44
        STA $4747
        LDA #$4C
        STA $476F
        LDA #$40
        STA $47AF
        LDA #$4E
        STA $47C7
        LDA #$18
        STA $482E
        LDA #$44
        STA $4857
        LDA #$00
        STA $486F
        LDA #$00
        STA $48AF
        LDA #$00
        STA $48C8
        LDA #$00
        STA $48EF
        LDA #$44
        STA $492F
        LDA #$5E
        STA $4947
        LDA #$00
        STA $496F
        LDA #$44
        STA $49AF
        LDA #$00
        STA $49C7
        LDA #$42
        STA $49D7
        LDA #$00
        STA $4A2F
        LDA #$4C
        STA $4A57
        LDA #$00
        STA $4AAF
        LDA #$04
        STA $4AC7
        LDA #$00
        STA $4B2F
        LDA #$4C
        STA $4B47
        LDA #$44
        STA $4B6F
        LDA #$40
        STA $4BAF
        LDA #$4C
        STA $4BC7
        LDA #$18
        STA $4C2E
        LDA #$00
        STA $4C6F
        LDA #$00
        STA $4CAF
        LDA #$44
        STA $4CC7
        LDA #$00
        STA $4CEF
        LDA #$44
        STA $4D2F
        LDA #$40
        STA $4D57
        LDA #$00
        STA $4D6F
        LDA #$44
        STA $4DAF
        LDA #$00
        STA $4DC7
        LDA #$44
        STA $4DD7
        LDA #$00
        STA $4E2F
        LDA #$00
        STA $4EAF
        LDA #$04
        STA $4EC7
        LDA #$04
        STA $4EEF
        LDA #$4C
        STA $4F47
        LDA #$40
        STA $4FAF
        LDA #$44
        STA $4FC7
        LDA #$18
        STA $502E
        LDA #$00
        STA $506F
        LDA #$00
        STA $50AF
        LDA #$44
        STA $50C7
        LDA #$58
        STA $50D7
        LDA #$00
        STA $50EF
        LDA #$44
        STA $512F
        LDA #$00
        STA $5147
        LDA #$44
        STA $5157
        LDA #$00
        STA $516F
        LDA #$4D
        STA $51AF
        LDA #$00
        STA $51C7
        LDA #$44
        STA $51D7
        LDA #$00
        STA $522F
        LDA #$44
        STA $5257
        LDA #$00
        STA $52AF
        LDA #$04
        STA $52C7
        LDA #$04
        STA $52EF
        LDA #$4C
        STA $5347
        LDA #$40
        STA $53AF
        LDA #$44
        STA $53C7
        LDA #$10
        STA $542E
        LDA #$00
        STA $546F
        LDA #$44
        STA $54C7
        LDA #$4C
        STA $54D7
        LDA #$00
        STA $54EF
        LDA #$44
        STA $552F
        LDA #$00
        STA $5547
        LDA #$44
        STA $5557
        LDA #$40
        STA $556F
        LDA #$4E
        STA $55AF
        LDA #$00
        STA $55C7
        LDA #$44
        STA $55D7
        LDA #$00
        STA $562F
        LDA #$40
        STA $5657
        LDA #$00
        STA $56AF
        LDA #$04
        STA $56C7
        LDA #$00
        STA $56D7
        LDA #$04
        STA $56EF
        LDA #$4C
        STA $5747
        LDA #$40
        STA $57AF
        LDA #$00
        STA $582E
        LDA #$01
        STA $5848
        LDA #$00
        STA $586F
        LDA #$04
        STA $58AF
        LDA #$44
        STA $58C7
        LDA #$68
        STA $58D7
        LDA #$00
        STA $58EF
        LDA #$44
        STA $592F
        LDA #$00
        STA $5947
        LDA #$44
        STA $5957
        LDA #$50
        STA $596F
        LDA #$4C
        STA $59AF
        LDA #$00
        STA $59C7
        LDA #$46
        STA $59D7
        LDA #$00
        STA $5A2F
        LDA #$04
        STA $5A47
        LDA #$00
        STA $5AAF
        LDA #$44
        STA $5AC7
        LDA #$00
        STA $5AD7
        LDA #$04
        STA $5AEF
        LDA #$4E
        STA $5B47
        LDA #$44
        STA $5BAF
        LDA #$00
        STA $5C2E
        LDA #$01
        STA $5C48
        LDA #$00
        STA $5C6F
        LDA #$04
        STA $5CAF
        LDA #$4C
        STA $5CC7
        LDA #$00
        STA $5CEF
        LDA #$44
        STA $5D2F
        LDA #$00
        STA $5D47
        LDA #$46
        STA $5D57
        LDA #$50
        STA $5D6F
        LDA #$44
        STA $5DAF
        LDA #$00
        STA $5DC7
        LDA #$00
        STA $5E2F
        LDA #$04
        STA $5E47
        LDA #$00
        STA $5EAF
        LDA #$44
        STA $5EC7
        LDA #$00
        STA $5ED7
        LDA #$4C
        STA $5EEF
        LDA #$4F
        STA $5F47
        LDA #$44
        STA $5FAF
        rts
; Total Bytes Aux.: 312
; Total Bytes Main: 388