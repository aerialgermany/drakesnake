{------------------------------------------------------------------------}
{ SetzPalette - Setzt fÅr die 256-Farb Modis die Farbpalette.            }
{               "AnzFarben" setzt die gewÅnschte Menge an FarbeintrÑgen  }
{               (normal 256).                                            }
{------------------------------------------------------------------------}
Procedure SetzPalette(Pal : Paltyp; AnzFarben : Word);

Var Segment,
    Off         : Word;

Begin
  Segment:=Seg(Pal);
  Off:=Ofs(Pal);
  ASM                        { Warten auf Bildwechsel }
    mov  DX,CRTCStat
  @WaitVS:
    in    AL,DX
    test  AL,08h
    jz    @WaitVS

    push  DS
    mov   CX,AnzFarben            { 256 FarbeintrÑge }
    mov   DS,Segment
    mov   BX,Off
    mov   DX,3C8h
    mov   AL,0
    cli
    out   DX,AL
    inc   DX
  @PalZaehler:
    mov   AX,[BX]                 { Lade Rot und GrÅnanteil }
    out   DX,AL                   { Rot ausgeben }
    xchg  AL,AH
    out   DX,AL                   { GrÅn ausgeben }
    inc   BX                      { Zeiger erhîhen }
    inc   BX
    mov   AL,[BX]                 { Lade Blauanteil }
    out   DX,AL                   { Blau ausgeben }
    inc   BX                      { Zeiger erhîhen }
    loop  @PalZaehler
    sti
    pop   DS
  End;
End;
