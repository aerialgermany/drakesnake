Program DrakeSnakeVorspann;

Uses Crt;

Type  Farbtyp = Array[0..47] of Byte;

Const Hires  = $12; Lores = $0D; MultiColour = $13; EndGraphic = $03;
      Screen = $A000;

Var Palette,
    Pal2    : Farbtyp;
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

  Begin
    ASM
      xor    AH,AH      { Modus $12 }
      mov    AL,Modus
      int    10h
    End
  End;

Procedure SetHiresPalette(Farb : Farbtyp);

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

Begin
  InitMode(Hires);
  For p:=0 to 47 do Palette[p]:=0;
  SetHiresPalette(Palette);
  Assign(f,'DR_SNAKE.BLD');
  Reset(f,1);
  BlockRead(f,Palette,48);
  For p:=0 to 3 do Begin
    WritePlane(p);
    BlockRead(f,Mem[Screen:$0000],38400);
  End;
  Close(f);
{  Sound(5000); Delay(50); NoSound;
  Repeat Until KeyPressed;
  While KeyPressed do ch:=ReadKey;}
  For x:=0 to 128 do Begin
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 7;
    SetHiresPalette(Pal2);
  End;
  i:=0;
  Repeat
    Inc(i);
    Delay(1);
  Until ((KeyPressed) OR (i>9000)); { Warte bis Tastendruck oder ca. 9 sek. }
  While KeyPressed do ch:=ReadKey;
  For x:=128 downto 0 do Begin
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 7;
    SetHiresPalette(Pal2);
  End;
  InitMode(EndGraphic);
End.