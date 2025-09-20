Unit DieSeq;

Interface

Uses GrafikOn,Crt,HeroSpiel;

Const Bombenexplosion = 0;
      Scorpionstich   = 1;
      Spinnenbiss     = 2;
      Fresspflanze    = 3;
      KeineKraft      = 1;

Procedure DieHard(Woran : Byte);

Implementation

Type FuenfKB    = Array[0..5119] of Byte;
     SegBuffer = Array[0..2000] of Byte;

Var  BildStruk : IFFStruct;

Procedure ErrorMessage(Message : String);

Begin
  TextMode(CO80);
  WriteLn(Message,#7);
  Halt;
End;

Procedure LoadMultiColour(BildName : String; Var Palette : Paltyp; Plus : Word);

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
    OfsScreen  : Word;
    Zaehl      : Word;
    SmallBuf   : Array[0..160] of Byte;
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
    If Spalte>39 then
      Begin
        Inc(Page);
        Spalte:=Spalte Mod 40;
      End;
    If Page>7 then
      Begin
        Inc(Zeile);
        Page:=Page Mod 8;
      End;
  End;

Begin
  WievielRAM:=0;
  Assign(FDest,BildName);
  Reset(FDest,1);
  BODYBig:=FileSize(FDest)-768;
  Noch:=BODYBig;
  If MemAvail<(Noch+768) then
    Begin
      Close(FDest);
      ErrorMessage('Zuwenig Speicher frei !');
    End;
  s:=(Noch Div 5119)+1;
  WievielRAM:=s;
  BlockRead(FDest,Palette,768,result);
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

  Spalte:=0; Page:=0; Zeile:=Plus;
  InitBitMap(Page);

  Repeat
    Mem[Seg(Z):Ofs(Z)]:=Mem[Start.S:Start.O];
    ADD_Pointer(Start,1);
    If Z>0 then
      Begin
        OfsScreen:=Zeile*40+Spalte;
        For Zaehl:=0 to Abs(Z) do
          Begin
            InitBitMap(Page);
            WriteToMap((OfsScreen+Zaehl),Mem[Start.S:Start.O]);
            CloseBitMap;
            ADD_Pointer(Start,1);
            ADD_BitPlanePointer(1);
          End;
      End
    Else
      Begin
        OfsScreen:=Zeile*40+Spalte;
        InitBitMap(Page);
        For Zaehl:=0 to Abs(Z) do
          WriteToMap((OfsScreen+Zaehl),Mem[Start.S:Start.O]);
        CloseBitMap;
        ADD_BitPlanePointer(Abs(Z)+1);
        ADD_Pointer(Start,1);
      End;
  Until Start.Zaehler>=BODYBig;
  CloseBitMap;
  For i:=1 to WievielRAM do
    Dispose(GrossesRAM[i]);
End;

Procedure LoadPicture(Name : String;Offset : Word);

Var f         : File;
    a         : Word;
    Farb      : Paltyp;

Begin
  LoadMultiColour(Name+'.BLD',Farb,(Offset Div 80));
  Move(Farb,BildStruk.Farben,768);
End;

Procedure ZoomIn(XP,YP,Breite,Hoehe,XOffs,YOffs : Word);

Var XB,YH : Word;
    Hor   : Array[0..80] of LongInt;
    Ver   : Array[0..200] of LongInt;

  Procedure SetPoint (X, Y : Word; Color : Byte);

  Begin
    ASM
      mov   BX,Y
      mov   AX,80
      mul   BX
      mov   BX,X
      shr   BX,1
      shr   BX,1
      add   AX,BX
      xchg  AX,BX            { BX = Offset = (Y*ZB4+(X shr 2)) }
      mov   DX,3C4h
      mov   AL,2
      mov   AH,1
      mov   CX,X
      and   CL,3
      shl   AH,CL
      out   DX,AX
      push  DS
      mov   DS,Bildadresse   { Bildschirmspeicheranfang ($A000) in DS }
      mov   AL,Color
      mov   [BX],AL          { Punkt setzen }
      pop   DS
    End;
  End;

  Function GetPoint (X, Y : Word) : Byte;

  Var Color : Byte;

  Begin
    ASM
      mov   BX,Y
      mov   AX,80
      mul   BX
      mov   BX,X
      shr   BX,2
      add   AX,BX
      xchg  AX,BX            { BX = Offset = (Y*ZB4+(X AND 3)) }
      mov   DX,3CEh
      mov   AX,X
      xchg  AL,AH
      mov   AL,4
      and   AH,3
      out   DX,AX
      push  DS
      mov   DS,Bildadresse   { Bildschirmspeicheranfang ($A000) in DS }
      mov   AL,[BX]          { Punkt setzen }
      mov   Color,AL
      pop   DS
    End;
    GetPoint:=Color;
  End;

Begin
  For XB:=0 to Breite do
    Hor[XB]:=(79*XB) Div Breite;
  For YH:=0 to Hoehe do
    Ver[YH]:=(99*YH) Div Hoehe;
  For YH:=0 to Hoehe do
    For XB:=0 to Breite do
      SetPoint(XP+XB,YP+YH,GetPoint(XOffs+Hor[XB],YOffs+Ver[YH]));
End;

Procedure ClearPic;

Begin
  Port[$3C4]:=2; Port[$3C5]:=15;
  FillChar(Mem[$A000:0000],$FFFF,0);
End;

Procedure DieHard(Woran : Byte);

Const Kood : Array[0..7,0..1] of Word = ((000,000),(240,100),
                                         (000,100),(160,000),
                                         ( 80,100),(240,000),
                                         (160,100),( 80,000));

Var x,y : Word;
    ch  : Char;

Begin
  InitMode(R320x200);
  For x:=0 to 431 do
    BildStruk.Farben[x]:=0;
  SetPalette(BildStruk.Farben,255);
  ClearPic;
  Case Woran of
    0 : LoadPicture('DRAKE1C',16000);
    1 : LoadPicture('DRAKE4C',16000);
    2 : LoadPicture('DRAKE3C',16000);
    3 : LoadPicture('DRAKE5C',16000);
  End;
  SetPalette(BildStruk.Farben,160);
  For y:=0 to 7 do
    For X:=1 to 10 do Begin
      ZoomIn(Kood[y,0]+(40-(X*4)),Kood[y,1]+(50-(X*5)),
             (X*8-1),(X*10-1),Kood[y,0],Kood[y,1]+200);
      Delay(5);
    End;
  y:=0;
  Repeat
    Delay(1);
    Inc(y);
  Until ((y>3900) OR (KeyPressed));
  While KeyPressed do ch:=ReadKey;
  Port[$3C4]:=2; Port[$3C5]:=15;
  For y:=0 to 99 do Begin
    FillChar(Mem[$A000:(y*160)],80,0);
    FillChar(Mem[$A000:$3D90-(y*160)],80,0);
    Delay(8);
  End;
  For x:=0 to 431 do
    BildStruk.Farben[x]:=0;
  SetPalette(BildStruk.Farben,160);
  CloseMode
End;

End.
