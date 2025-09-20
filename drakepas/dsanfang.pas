Unit DSAnfang;

Interface

Uses Crt;

Procedure Vorspann;

Implementation

Type  FarbHirestyp  = Array[0..47] of Byte;
      FarbLowrestyp = Array[0..95] of Byte;

Const Hires   = $12; Lores = $0D; MultiColour = $13; EndGraphic = $03;
      Spezial = 00;
      Screen = $A000;

Var Palette,
    Pal2    : FarbHirestyp;
    LPalette,
    LPal2   : FarbLowrestyp;
    f       : File;
    p       : Byte;
    i,x,y   : Word;
    ch      : Char;

Procedure WritePlane(Nr : Byte);

  Begin
    Nr:=Nr AND 3;
    Port[$3C4]:=2;
    Port[$3C5]:=1 shl Nr;
  End;

Procedure ReadPlane(Nr : Byte);

  Begin
    Nr:=Nr AND 3;
    Port[$3CE]:=4;
    Port[$3CF]:=Nr;
  End;

Procedure InitMode(Modus : Byte);

  Type  CRTCAr = Array[0..23] of Byte;

  Const CRTC320x240 : CRTCAr =
        ($5F,$4F,$50,$82,$54,$80,$0D,$3E,$00,$41,$00,$00,
         $00,$00,$00,$00,$EA,$AC,$DF,$28,$00,$E7,$06,$E3);

  Var   I : Byte;


  Begin
    If Modus>0 then Begin
      ASM
        xor    AH,AH      { Modus $12 }
        mov    AL,Modus
        int    10h
      End
    End Else
    Begin
      ASM
        xor    AH,AH
        mov    AL,13h
        int    10h
      End;
      Port[$3C4]:=4;      { Sequenzer-Controller : Memory Mode }
      Port[$3C5]:=6;
                            { Extended Memory ein, Odd/Even aus  }
      Port[$3D4] := $11;                { CRTC: Register $11     }
      Port[$3D5] := Port[$3D5] and $7F; { Schreibschutz aufheben }

      Port[$3C4]:=0;        { Seq.Controller: Reset Register }
      Port[$3C5]:=1;        { Synchroner Reset, Seq. aus     }
      Port[$3C2]:=$E3;      { 480 Scan-Zeilen }
      Port[$3C4]:=0;        { Synchroner Reset, Seq. ein     }
      Port[$3C5]:=3;
      For I := 0 to 23 do Begin  { CRTC-Registerwerte setzen }
        Port[$3D4]:=I;
        Port[$3D5]:=CRTC320x240[I];
      End;
    End;
  End;

Procedure SetHiresPalette(Farb : FarbHirestyp);

  Var Segment,
      Off         : Word;

  Begin
    Segment:=Seg(Farb);
    Off:=Ofs(Farb);
    ASM                        { Warten auf Bildwechsel }
      mov  DX,3DAh
    @WaitVS:
      in    AL,DX
      test  AL,08h
      jz    @WaitVS
      mov   DX,3C4h            { Bildschirm abschalten }
      mov   AL,1
      out   DX,AL
      inc   DX
      in    AL,DX
      or    AL,20h
      xchg  AL,AH
      dec   DX
      mov   AL,1
      out   DX,AX
      push  DS
      mov   DS,Segment
      mov   BX,Off
      cli

      mov   CX,6                    { 0,1,2,3,4,5 }
      mov   DX,3C8h
      mov   AL,0
      out   DX,AL
      inc   DX
    @PalZaehler:
      mov   AX,[BX]                 { Lade Rot und Grnanteil }
      out   DX,AL                   { Rot ausgeben }
      xchg  AL,AH
      out   DX,AL                   { Grn ausgeben }
      inc   BX                      { Zeiger erh”hen }
      inc   BX
      mov   AL,[BX]                 { Lade Blauanteil }
      out   DX,AL                   { Blau ausgeben }
      inc   BX                      { Zeiger erh”hen }
      loop  @PalZaehler

      mov   DX,3C8h                 { 20 }
      mov   AL,20
      out   DX,AL
      inc   DX
      mov   AX,[BX]                 { Lade Rot und Grnanteil }
      out   DX,AL                   { Rot ausgeben }
      xchg  AL,AH
      out   DX,AL                   { Grn ausgeben }
      inc   BX                      { Zeiger erh”hen }
      inc   BX
      mov   AL,[BX]                 { Lade Blauanteil }
      out   DX,AL                   { Blau ausgeben }
      inc   BX                      { Zeiger erh”hen }

      mov   DX,3C8h                 { 7 }
      mov   AL,7
      out   DX,AL
      inc   DX
      mov   AX,[BX]                 { Lade Rot und Grnanteil }
      out   DX,AL                   { Rot ausgeben }
      xchg  AL,AH
      out   DX,AL                   { Grn ausgeben }
      inc   BX                      { Zeiger erh”hen }
      inc   BX
      mov   AL,[BX]                 { Lade Blauanteil }
      out   DX,AL                   { Blau ausgeben }
      inc   BX                      { Zeiger erh”hen }

      mov   CX,8                    { 56,57,58,59,60,61,62,63 }
      mov   DX,3C8h
      mov   AL,56
      out   DX,AL
      inc   DX
    @PalZaehler1:
      mov   AX,[BX]                 { Lade Rot und Grnanteil }
      out   DX,AL                   { Rot ausgeben }
      xchg  AL,AH
      out   DX,AL                   { Grn ausgeben }
      inc   BX                      { Zeiger erh”hen }
      inc   BX
      mov   AL,[BX]                 { Lade Blauanteil }
      out   DX,AL                   { Blau ausgeben }
      inc   BX                      { Zeiger erh”hen }
      loop  @PalZaehler1

      sti
      pop   DS
      mov   DX,3C4h                 { Bildschirm wieder anschalten }
      mov   AL,1
      out   DX,AL
      inc   DX
      in    AL,DX
      and   AL,223
      xchg  AL,AH
      dec   DX
      mov   AL,1
      out   DX,AX
    End;
  End;

Procedure SetLowresPalette(Farb : FarbLowrestyp);

Var Segment,
    Off         : Word;

Begin
  Segment:=Seg(Farb);
  Off:=Ofs(Farb);
  ASM                        { Warten auf Bildwechsel }
    mov  DX,3DAh
  @WaitVS:
    in    AL,DX
    test  AL,08h
    jz    @WaitVS
    mov   DX,3C4h            { Bildschirm abschalten }
    mov   AL,1
    out   DX,AL
    inc   DX
    in    AL,DX
    or    AL,20h
    xchg  AL,AH
    dec   DX
    mov   AL,1
    out   DX,AX
    push  DS
    mov   DS,Segment
    mov   BX,Off
    mov   CX,32                   { 32 Farbeintr„ge }
    mov   DX,3C8h
    mov   AL,0
    cli
    out   DX,AL
    inc   DX
  @PalZaehler:
    mov   AX,[BX]                 { Lade Rot und Grnanteil }
    out   DX,AL                   { Rot ausgeben }
    xchg  AL,AH
    out   DX,AL                   { Grn ausgeben }
    inc   BX                      { Zeiger erh”hen }
    inc   BX
    mov   AL,[BX]                 { Lade Blauanteil }
    out   DX,AL                   { Blau ausgeben }
    inc   BX                      { Zeiger erh”hen }
    loop  @PalZaehler
    sti
    pop   DS
    mov   DX,3C4h                 { Bildschirm wieder anschalten }
    mov   AL,1
    out   DX,AL
    inc   DX
    in    AL,DX
    and   AL,223
    xchg  AL,AH
    dec   DX
    mov   AL,1
    out   DX,AX
  End;
End;


Procedure LoadHiresPic(Name : String;Var Farben : FarbHirestyp);

  Var f : File;
      p : Byte;

  Begin
    Assign(f,Name);
    Reset(f,1);
    BlockRead(f,Farben,48);
    For p:=0 to 3 do Begin
      WritePlane(p);
      BlockRead(f,Mem[Screen:$0000],38400);
    End;
    Close(f);
  End;

Procedure LoadLowresPic(Name : String;Var Farben : FarbLowrestyp; Ofset : Word);

  Var f : File;
      p : Byte;

  Begin
    Assign(f,Name);
    Reset(f,1);
    For p:=0 to 3 do Begin
      WritePlane(p);
      BlockRead(f,Mem[Screen:Ofset],19200);
    End;
    BlockRead(f,Farben,96);
    Close(f);
  End;

Procedure WaitKey(BisWann : Word);

  Var i  : Word;
      ch : Char;

  Begin
    i:=0;
    Repeat
      Inc(i);
      Delay(1);
    Until ((KeyPressed) OR (i>BisWann)); { Warte bis Tastendruck }
    While KeyPressed do ch:=ReadKey;
  End;

Procedure SetMode(r,w : Byte); ASSEMBLER;

  ASM
    mov  AH,r
    and  AH,1h
    shl  AH,1
    shl  AH,1
    shl  AH,1
    mov  AL,w
    and  AL,3h
    add  AH,AL
    or   AH,40h
    mov  DX,03CEh
    mov  AL,5h
    out  DX,AX
  End;

Procedure VgaCopy(vx,vy,w,h,nx,ny : Word);

  Var i,a,b,c,d,e : Word;

  Begin
    Port[$3C4]:=2;
    Port[$3C5]:=$F;
    SetMode(0,1);
    a:=(vx shr 2)+vy*80; b:=(nx shr 2)+ny*80; c:=w shr 2;
    PortW[$3CE]:=$1803;
    For i:=0 to h do Begin
      Move(Mem[$A000:a],
           Mem[$A000:b],c);
      Inc(a,80); Inc(b,80);
    End;
    SetMode(0,0);
  End;

Procedure Vorspann;

Begin
  ASM
    xor  AH,AH
    mov  AL,12h
    int  10h
  End;
  InitMode(Spezial);
  LoadLowresPic('COD.BLD',LPalette,19200);
  SetLowresPalette(LPalette);
  For x:=0 to 159 do Begin
    VgaCopy(159-x,360,x shl 1,1,159-x,120);
    Delay(1);
  End;
  For y:=0 to 119 do Begin
    VgaCopy(0,360+y,320,1,0,120+y);
    VgaCopy(0,360-y,320,1,0,120-y);
    Delay(1);
  End;
  WaitKey(4000);
  For x:=128 downto 0 do Begin
    For y:=0 to 95 do
      LPal2[y]:=(LPalette[y]*x) shr 7;
    SetLowresPalette(LPal2);
  End;

  InitMode(Hires);
  For p:=0 to 47 do Palette[p]:=0;
  SetHiresPalette(Palette);
  LoadHiresPic('DR_SNAKE.BLD',Palette);
  For x:=0 to 128 do Begin
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 7;
    SetHiresPalette(Pal2);
  End;
  WaitKey(9000);
  For x:=128 downto 0 do Begin
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 7;
    SetHiresPalette(Pal2);
  End;

  InitMode(EndGraphic);
End;

End.