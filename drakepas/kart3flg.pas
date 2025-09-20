Unit Kart3Flg;

Interface

Uses Graph,Crt,GrafikOn;

Procedure Flug_ueber_Weltkarte;

Implementation

Type  FarbHirestyp  = Array[0..47] of Byte;
      Koord = Record
                X,Y : Integer;
              End;
     FuenfKB    = Array[0..5119] of Byte;
     SegBuffer = Array[0..2000] of Byte;

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

Procedure ErrorMessage(Message : String);

Begin
  TextMode(CO80);
  WriteLn(Message,#7);
  Halt;
End;

Procedure LoadHires(BildName : String; Var Palette : Paltyp);

Type Zeiger = Record
                S,O     : Word;
                Zaehler : LongInt;
              End;

Var Buffer     : ^SegBuffer;
    BODYBig    : LongInt;
    Start      : Zeiger;
    GrossesRAM : Array[1..128] of ^FuenfKB;
    WievielRAM : Word;
    Z          : ShortInt;
    i          : Word;
    FDest      : File;
    s,result   : Word;
    Spalte     : Word;
    Page       : Byte;
    Zeile      : Word;
    SmallBuf   : Array[0..320] of Byte;
    Noch       : LongInt;

  Procedure ADD_Pointer(Var PP : Zeiger;Menge : Integer);

  Var o : Word;

  Begin
    PP.Zaehler:=PP.Zaehler+Menge;
    o:=PP.O Div 16;
    PP.O:=PP.O Mod 16;
    PP.S:=PP.S+o;
    PP.O:=PP.O+(Menge Mod 16);
    PP.S:=PP.S+(Menge Div 16);
  End;

  Procedure ADD_BitPlanePointer(Menge : Word);

  Begin
    Inc(Spalte,Menge);
    If Spalte>79 then
      Begin
        Inc(Page);
        Spalte:=Spalte Mod 80;
      End;
    If Page>3 then
      Begin
        Inc(Zeile);
        Page:=Page Mod 4;
      End;
    InitBitMap(Page);
  End;

Begin
  WievielRAM:=0;
  Assign(FDest,BildName);
  Reset(FDest,1);
  BODYBig:=FileSize(FDest)-48;
  Noch:=BODYBig;
  If MemAvail<(Noch+48) then
    Begin
      Close(FDest);
      ErrorMessage('Zuwenig Speicher frei !');
    End;
  s:=(Noch Div 5119)+1;
  WievielRAM:=s;
  BlockRead(FDest,Palette,48,result);
  If result<>768 then Write(#7);
  For i:=1 to s do
    Begin
      New(GrossesRAM[i]);
      If Noch>5120 then
        BlockRead(FDest,GrossesRAM[i]^,5120,result)
      Else
        BlockRead(FDest,GrossesRAM[i]^,Noch,result);
      Noch:=Noch-5120
    End;
  Close(FDest);
  Start.S:=Seg(GrossesRAM[1]^);
  Start.O:=Ofs(GrossesRAM[1]^);

  Start.Zaehler:=0;

  Spalte:=0; Page:=0; Zeile:=0;
  InitBitMap(Page);

  Repeat
    Mem[Seg(Z):Ofs(Z)]:=Mem[Start.S:Start.O];
    ADD_Pointer(Start,1);
    If Z>0 then
      Begin
        Move(Mem[Start.S:Start.O],Mem[$A000:(Zeile*80)+Spalte],(Z+1));
        ADD_Pointer(Start,(Z+1));
        ADD_BitPlanePointer(Z+1);
      End
    Else
      Begin
        FillChar(Mem[$A000:(Zeile*80)+Spalte],Abs(Z)+1,Mem[Start.S:Start.O]);
        ADD_BitPlanePointer(Abs(Z)+1);
        ADD_Pointer(Start,1);
      End;
  Until Start.Zaehler>=BODYBig;
  For i:=1 to WievielRAM do
    Dispose(GrossesRAM[i]);

End;


Procedure LoadHiresPic(Name : String;Var Farben : FarbHirestyp);

  Var f    : File;
      p    : Byte;
      Farb : Paltyp;

  Begin
    LoadHires(Name,Farb);
    Move(Farb,Farben,48);
  End;

Procedure VGADriver; External;
  {$L VGA.OBJ }

Procedure PutScreenOff;

Begin
  ASM
    push DS
    mov  DX,3DAh             { Auf Bildwechsel warten }
  @WaitVS:
    in    AL,DX
    test  AL,08h
    jz    @WaitVS
  @WaitDE:
    in   AL,DX
    test AL,01h
    jz   @WaitDE
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
    pop   DS
  End;
End;

Procedure PutScreenOn;

Begin
  ASM
    push DS
    mov  DX,3DAh                  { Bildwechsel abwarten }
  @WaitVS:
    in    AL,DX
    test  AL,08h
    jz    @WaitVS
  @WaitDE:
    in   AL,DX
    test AL,01h
    jz   @WaitDE
    mov   DX,3C4h                 { Bildschirm anschalten }
    mov   AL,1
    out   DX,AL
    inc   DX
    in    AL,DX
    and   AL,223
    xchg  AL,AH
    dec   DX
    mov   AL,1
    out   DX,AX
    pop   DS
  End;
End;

Procedure Flug_ueber_Weltkarte;

Begin
  PutScreenOff;
  dr:=RegisterBGIDriver(@VGADriver);
  InitGraph(Driver,Mode,'');
  PutScreenOff;
  For i:=0 to 47 do Pal2[i]:=0;
  SetHiresPalette(Pal2);

  LoadHiresPic('MAP2.BLD',Palette);
  Assign(f,'FlyKoord.map');
  Reset(f,1);
  BlockRead(f,Pos,(Menge*4));
  Close(f);
  PutScreenOn;
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
  PutScreenOff;
End;

End.