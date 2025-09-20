Program Flug_auf_Karte;

Uses Graph,Crt;

Type  FarbHirestyp  = Array[0..47] of Byte;
      Koord = Record
                X,Y : Integer;
              End;

Const Driver    : Integer = VGA;
      Mode      : Integer = VGAHi;
      SpriteOR  : Array[0..35] of Byte = (07,00,07,00,
                                        $00,$00,$18,$18,
                                        $00,$00,$7E,$7E,
                                        $00,$00,$7E,$7E,
                                        $00,$00,$FF,$FF,
                                        $00,$00,$FF,$FF,
                                        $00,$00,$7E,$7E,
                                        $00,$00,$7E,$7E,
                                        $00,$00,$18,$18);
      SpriteAND : Array[0..35] of Byte = (07,00,07,00,
                                        $E7,$E7,$E7,$E7,
                                        $81,$81,$81,$81,
                                        $81,$81,$81,$81,
                                        $00,$00,$00,$00,
                                        $00,$00,$00,$00,
                                        $81,$81,$81,$81,
                                        $81,$81,$81,$81,
                                        $E7,$E7,$E7,$E7);
      Menge  = 491;

Var dr        : Integer;
    x,y,B,Z,i : Word;
    Palette,
    Pal2      : FarbHiresTyp;
    Pos       : Array[0..500] of Koord;
    f         : File;

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

Procedure WritePlane(Nr : Byte);

  Begin
    Nr:=Nr AND 3;
    Port[$3C4]:=2;
    Port[$3C5]:=1 shl Nr;
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
      BlockRead(f,Mem[$A000:$0000],38400);
    End;
    Close(f);
  End;

Procedure VGADriver; External;
  {$L VGA.OBJ }

Begin
  dr:=RegisterBGIDriver(@VGADriver);
  InitGraph(Driver,Mode,'');
  For i:=0 to 47 do Pal2[i]:=0;
  SetHiresPalette(Pal2);

  LoadHiresPic('C:\TP6\PICSHERO\MAP2.BLD',Palette);
  Assign(f,'FlyKoord.map');
  Reset(f,1);
  BlockRead(f,Pos,(Menge*4));
  Close(f);
  For y:=0 to 64 do Begin
    For x:=0 to 49 do
      Pal2[x]:=(Palette[x]*y) shr 6;
    SetHiresPalette(Pal2);
  End;

  Delay(700);

  For i:=1 to Menge-1 do Begin
    PutImage(Pos[i].X,Pos[i].Y,SpriteAND,ANDPut);
    PutImage(Pos[i].X,Pos[i].Y,SpriteOR,ORPut);
    If Abs(Pos[i].Y-Pos[i+1].Y)>30 then Delay(500);
    Delay(14);
  End;
  Delay(1500);
  For y:=64 downto 0 do Begin
    For x:=0 to 49 do
      Pal2[x]:=(Palette[x]*y) shr 6;
    SetHiresPalette(Pal2);
  End;
{  Repeat Until KeyPressed;
  CloseGraph;}
End.