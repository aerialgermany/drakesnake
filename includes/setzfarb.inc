{------------------------------------------------------------------------}
{ SetzFarben - Setzt fÅr die 256-Farb Modis die Farbpalette.             }
{              "AnzFarben" setzt die gewÅnschte Menge an FarbeintrÑgen   }
{              (normal 256).                                             }
{------------------------------------------------------------------------}
Procedure SetzFarben(Pal : Paltyp; AnzFarben : Word);

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
    mov   AX,3
    mul   CX
    mov   CX,AX
    mov   DS,Segment
    mov   SI,Off
    mov   DX,3C8h
    mov   AL,0
    cli
    out   DX,AL
    inc   DX

    rep
    outsb

    sti
    pop   DS
  End;
End;
