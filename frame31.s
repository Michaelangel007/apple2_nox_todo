; === Aux ===
        sta $c005          ; AUXWRON
        LDA #$00
        STA $202E
        LDA #$20
        STA $2057
        LDA #$00
        STA $206F
        LDA #$26
        STA $20AF
        LDA #$00
        STA $20EF
        LDA #$60
        STA $212F
        LDA #$00
        STA $2147
        LDA #$00
        STA $2158
        LDA #$00
        STA $222F
        LDA #$20
        STA $2247
        LDA #$62
        STA $22C7
        LDA #$00
        STA $22D7
        LDA #$20
        STA $232F
        LDA #$00
        STA $2357
        LDA #$60
        STA $236F
        LDA #$60
        STA $23AF
        LDA #$00
        STA $23C7
        LDA #$00
        STA $242E
        LDA #$62
        STA $2457
        LDA #$00
        STA $246F
        LDA #$36
        STA $24AF
        LDA #$1C
        STA $24C8
        LDA #$60
        STA $252F
        LDA #$00
        STA $2547
        LDA #$00
        STA $2558
        LDA #$00
        STA $262F
        LDA #$20
        STA $2647
        LDA #$62
        STA $26C7
        LDA #$00
        STA $26D7
        LDA #$26
        STA $26EF
        LDA #$20
        STA $272F
        LDA #$00
        STA $2757
        LDA #$00
        STA $27C7
        LDA #$00
        STA $282E
        LDA #$62
        STA $2857
        LDA #$00
        STA $286F
        LDA #$22
        STA $28AF
        LDA #$60
        STA $292F
        LDA #$00
        STA $2947
        LDA #$00
        STA $2A2F
        LDA #$20
        STA $2A47
        LDA #$20
        STA $2AC7
        LDA #$00
        STA $2AD7
        LDA #$66
        STA $2AEF
        LDA #$20
        STA $2B2F
        LDA #$00
        STA $2B57
        LDA #$20
        STA $2BAF
        LDA #$00
        STA $2BC7
        LDA #$00
        STA $2C2E
        LDA #$62
        STA $2C57
        LDA #$00
        STA $2C6F
        LDA #$26
        STA $2CAF
        LDA #$08
        STA $2D30
        LDA #$00
        STA $2D47
        LDA #$00
        STA $2DB0
        LDA #$00
        STA $2DD8
        LDA #$00
        STA $2E2F
        LDA #$22
        STA $2E47
        LDA #$20
        STA $2EC7
        LDA #$00
        STA $2ED7
        LDA #$66
        STA $2EEF
        LDA #$20
        STA $2F2F
        LDA #$00
        STA $2FC7
        LDA #$00
        STA $302E
        LDA #$20
        STA $3057
        LDA #$00
        STA $306F
        LDA #$22
        STA $30AF
        LDA #$20
        STA $30C7
        LDA #$00
        STA $30D8
        LDA #$00
        STA $3147
        LDA #$00
        STA $31AF
        LDA #$00
        STA $31D8
        LDA #$00
        STA $322F
        LDA #$22
        STA $3247
        LDA #$00
        STA $32D8
        LDA #$62
        STA $32EF
        LDA #$20
        STA $332F
        LDA #$00
        STA $33C7
        LDA #$00
        STA $342E
        LDA #$20
        STA $3457
        LDA #$00
        STA $346F
        LDA #$62
        STA $34AF
        LDA #$20
        STA $34C7
        LDA #$00
        STA $34D8
        LDA #$00
        STA $35AF
        LDA #$00
        STA $35D8
        LDA #$00
        STA $362F
        LDA #$62
        STA $3647
        LDA #$00
        STA $3657
        LDA #$00
        STA $36D7
        LDA #$62
        STA $36EF
        LDA #$20
        STA $372F
        LDA #$00
        STA $3786
        LDA #$00
        STA $37C7
        LDA #$12
        STA $382F
        LDA #$00
        STA $386F
        LDA #$62
        STA $38AF
        LDA #$60
        STA $38C7
        LDA #$00
        STA $38D8
        LDA #$00
        STA $39AF
        LDA #$20
        STA $39C7
        LDA #$00
        STA $39D8
        LDA #$62
        STA $3A47
        LDA #$00
        STA $3A57
        LDA #$00
        STA $3AD7
        LDA #$20
        STA $3AEF
        LDA #$60
        STA $3B2F
        LDA #$00
        STA $3B86
        LDA #$00
        STA $3BC7
        LDA #$00
        STA $3C6F
        LDA #$60
        STA $3CAF
        LDA #$00
        STA $3CD8
        LDA #$00
        STA $3DAF
        LDA #$20
        STA $3DC7
        LDA #$00
        STA $3DD8
        LDA #$62
        STA $3E47
        LDA #$00
        STA $3E57
        LDA #$00
        STA $3ED7
        LDA #$60
        STA $3EEF
        LDA #$60
        STA $3F2F
        LDA #$00
        STA $3F86
        LDA #$20
        STA $3FAF
        LDA #$00
        STA $3FC7
; === Main ===
        sta $c004          ; AUXWROFF
        LDA #$44
        STA $2057
        LDA #$00
        STA $206F
        LDA #$20
        STA $20AE
        LDA #$13
        STA $20C8
        LDA #$00
        STA $20EF
        LDA #$4C
        STA $212F
        LDA #$00
        STA $2157
        LDA #$00
        STA $21AF
        LDA #$00
        STA $222F
        LDA #$44
        STA $2247
        LDA #$4C
        STA $22C7
        LDA #$00
        STA $22D7
        LDA #$44
        STA $232F
        LDA #$44
        STA $2357
        LDA #$4E
        STA $236F
        LDA #$4E
        STA $23AF
        LDA #$00
        STA $23C7
        LDA #$08
        STA $242E
        LDA #$44
        STA $2457
        LDA #$00
        STA $246F
        LDA #$46
        STA $24AF
        LDA #$11
        STA $24C8
        LDA #$00
        STA $24D7
        LDA #$00
        STA $24EF
        LDA #$4E
        STA $252F
        LDA #$00
        STA $2547
        LDA #$00
        STA $2557
        LDA #$00
        STA $25AF
        LDA #$04
        STA $25C7
        LDA #$00
        STA $25D7
        LDA #$00
        STA $262F
        LDA #$44
        STA $2647
        LDA #$4E
        STA $26C7
        LDA #$00
        STA $26D7
        LDA #$44
        STA $26EF
        LDA #$44
        STA $272F
        LDA #$6C
        STA $276F
        LDA #$4E
        STA $27AF
        LDA #$00
        STA $27C7
        LDA #$18
        STA $282E
        LDA #$4D
        STA $2857
        LDA #$00
        STA $286F
        LDA #$44
        STA $28AF
        LDA #$11
        STA $28C8
        LDA #$00
        STA $28D7
        LDA #$4E
        STA $292F
        LDA #$00
        STA $2947
        LDA #$00
        STA $2957
        LDA #$00
        STA $29AF
        LDA #$04
        STA $29C7
        LDA #$00
        STA $29D7
        LDA #$00
        STA $2A2F
        LDA #$4C
        STA $2A47
        LDA #$04
        STA $2AAF
        LDA #$4E
        STA $2AC7
        LDA #$00
        STA $2AD7
        LDA #$44
        STA $2AEF
        LDA #$4C
        STA $2B2F
        LDA #$7E
        STA $2B57
        LDA #$04
        STA $2B6F
        LDA #$4E
        STA $2BAF
        LDA #$00
        STA $2BC7
        LDA #$18
        STA $2C2E
        LDA #$4E
        STA $2C57
        LDA #$00
        STA $2C6F
        LDA #$44
        STA $2CAF
        LDA #$44
        STA $2CC7
        LDA #$00
        STA $2CD7
        LDA #$4E
        STA $2D2F
        LDA #$00
        STA $2D47
        LDA #$00
        STA $2DAF
        LDA #$04
        STA $2DC7
        LDA #$00
        STA $2DD7
        LDA #$00
        STA $2E2F
        LDA #$4C
        STA $2E47
        LDA #$04
        STA $2EAF
        LDA #$5E
        STA $2EC7
        LDA #$40
        STA $2ED7
        LDA #$4C
        STA $2EEF
        LDA #$4C
        STA $2F2F
        LDA #$00
        STA $2F47
        LDA #$44
        STA $2FAF
        LDA #$00
        STA $2FC7
        LDA #$18
        STA $302E
        LDA #$4C
        STA $3057
        LDA #$00
        STA $306F
        LDA #$44
        STA $30AF
        LDA #$01
        STA $30C8
        LDA #$00
        STA $30D7
        LDA #$44
        STA $312F
        LDA #$00
        STA $3147
        LDA #$00
        STA $31AF
        LDA #$04
        STA $31C7
        LDA #$00
        STA $31D7
        LDA #$00
        STA $322F
        LDA #$4C
        STA $3247
        LDA #$00
        STA $3257
        LDA #$44
        STA $32AF
        LDA #$44
        STA $32C7
        LDA #$40
        STA $32D7
        LDA #$4C
        STA $32EF
        LDA #$4C
        STA $332F
        LDA #$00
        STA $3347
        LDA #$00
        STA $33C7
        LDA #$10
        STA $342E
        LDA #$44
        STA $3457
        LDA #$00
        STA $346F
        LDA #$44
        STA $34AF
        LDA #$4C
        STA $34C7
        LDA #$00
        STA $34D7
        LDA #$00
        STA $352F
        LDA #$00
        STA $3547
        LDA #$00
        STA $35AF
        LDA #$44
        STA $35C7
        LDA #$00
        STA $35D7
        LDA #$00
        STA $362F
        LDA #$4C
        STA $3647
        LDA #$00
        STA $3657
        LDA #$44
        STA $36AF
        LDA #$40
        STA $36D7
        LDA #$4C
        STA $36EF
        LDA #$4C
        STA $372F
        LDA #$00
        STA $3747
        LDA #$00
        STA $37C7
        LDA #$30
        STA $382E
        LDA #$11
        STA $3848
        LDA #$44
        STA $3857
        LDA #$00
        STA $386F
        LDA #$44
        STA $38AF
        LDA #$4E
        STA $38C7
        LDA #$00
        STA $38D7
        LDA #$00
        STA $392F
        LDA #$00
        STA $39AF
        LDA #$44
        STA $39C7
        LDA #$00
        STA $39D7
        LDA #$00
        STA $3A2F
        LDA #$4C
        STA $3A47
        LDA #$00
        STA $3A57
        LDA #$44
        STA $3AAF
        LDA #$40
        STA $3AD7
        LDA #$4C
        STA $3AEF
        LDA #$4C
        STA $3B2F
        LDA #$00
        STA $3B47
        LDA #$00
        STA $3BC7
        LDA #$20
        STA $3C2E
        LDA #$11
        STA $3C48
        LDA #$00
        STA $3C6F
        LDA #$44
        STA $3CAF
        LDA #$6E
        STA $3CC7
        LDA #$00
        STA $3CD7
        LDA #$00
        STA $3D2F
        LDA #$00
        STA $3DAF
        LDA #$44
        STA $3DC7
        LDA #$00
        STA $3DD7
        LDA #$4C
        STA $3E47
        LDA #$00
        STA $3E57
        LDA #$44
        STA $3EAF
        LDA #$40
        STA $3ED7
        LDA #$4E
        STA $3EEF
        LDA #$4C
        STA $3F2F
        LDA #$00
        STA $3F47
        LDA #$10
        STA $3F86
        LDA #$04
        STA $3FAF
        LDA #$00
        STA $3FC7
        rts
; Total Bytes Aux.: 310
; Total Bytes Main: 392
