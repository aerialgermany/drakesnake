Program DS_Demo;

Uses DrakGame,DS_Begin,HeroSpiel,Crt,SB_DAC;

Type FuenfKB    = Array[0..5119] of Byte;
     SegBuffer = Array[0..2000] of Byte;
     Paltyp    = Array[0..767] of Byte;

Const Bildadresse : Word = $A000;

Var Weiter,
    Geschafft : Boolean;

Procedure SetPoint (X, Y : Word; Color : Byte);

Begin
  ASM
    mov   BX,Y
    mov   AX,80
    mul   BX
    mov   BX,X
    shr   BX,2
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

Procedure ClearVideoMem(Menge : Word;Was : Byte);

  Var Pl : Byte;

  Begin
    Pl:=Was AND 15;
    Port[$3C4]:=2;
    Port[$3C5]:=Pl;
    FillChar(Mem[$A000:0000],Menge,0);
  End;

{--------------------------------------------------------------------------}
{ InitBitMap - '™ffnet' eine Bitmap zum Lesen und beschreiben.             }
{              Bitmaps werden in den 256-Farb Modi simuliert.              }
{--------------------------------------------------------------------------}
Procedure InitBitMap(BitMap,Modus : Byte);

  Begin
    BitMap:=BitMap AND 7;
    If Modus=0 then
      Begin
        Port[$3C4]:=2;
        Port[$3C5]:=1 SHL (BitMap AND 3);
      End;
    If Modus=1 then
      Begin
          {*** Bit Mask Register beschreiben ***}
        Port[$3CE]:=8; Port[$3CF]:=1 shl (BitMap AND 7);
          {*** Schreibmodus 2 / Lesemodus 0 ***}
        Port[$3CE]:=5; Port[$3CF]:=2+64;
      End;
  End;

{--------------------------------------------------------------------------}
{ CloseBitMap - Schlieát die (simulierte) BitMap wieder                    }
{--------------------------------------------------------------------------}
Procedure CloseBitMap;

  Begin
    Port[$3C4]:=2;
    Port[$3C5] :=0;
      {*** alle Register in umgekehrter Reihenfolge zurcksetzen ***}
    Port[$3CE]:=5; Port[$3CF]:=64;
    Port[$3CE]:=8; Port[$3CF]:=$FF;
  End;

{--------------------------------------------------------------------------}
{ WriteToPlane - Schreibt ein Byte ("Wert") an die Offsetadresse "Ofset"   }
{                in die aktive BitMap. Haupts„chlich fr die simulierte    }
{                BitMap im 256-Farbmodus.                                  }
{--------------------------------------------------------------------------}
Procedure WriteToMap(Ofset : Word; Wert : Byte);

  Const Revers : Array[0..15] of Byte = (0,8,4,12,2,10,6,14,1,
                                         9,5,13,3,11,7,15);

  Var al,h,l : Byte;
      AdrOfs : Word;

  Begin
        AdrOfs:=Ofset*2;
        h:=Wert AND $F; l:=Wert shr 4;

          {*** Prozessor Latches "laden" ***}
        al:=Mem[$A000:AdrOfs];
          {*** "Farbe" zur Adresse schreiben ***}
        Mem[$A000:AdrOfs]:=Revers[l];

          {*** Prozessor Latches "laden" ***}
        al:=Mem[$A000:AdrOfs+1];
          {*** "Farbe" zur Adresse schreiben ***}
        Mem[$A000:AdrOfs+1]:=Revers[h];
  End;

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
  InitBitMap(Page,1);

  Repeat
    Mem[Seg(Z):Ofs(Z)]:=Mem[Start.S:Start.O];
    ADD_Pointer(Start,1);
    If Z>0 then
      Begin
        OfsScreen:=Zeile*40+Spalte;
        For Zaehl:=0 to Abs(Z) do
          Begin
            InitBitMap(Page,1);
            WriteToMap((OfsScreen+Zaehl),Mem[Start.S:Start.O]);
            CloseBitMap;
            ADD_Pointer(Start,1);
            ADD_BitPlanePointer(1);
          End;
      End
    Else
      Begin
        OfsScreen:=Zeile*40+Spalte;
        InitBitMap(Page,1);
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
    BildStruk : IFFStruct;
    Farb      : Paltyp;

Begin
  LoadMultiColour(Name+'.BLD',Farb,(Offset Div 80));
  Move(Farb,BildStruk.Farben,768);
{  Assign(f,Name+'.BLD');
  Reset(f,1);
  BlockRead(f,BildStruk.Farben,768);
  For a:=0 to 3 do Begin
    Port[$3C4]:=2; Port[$3C5]:=1 shl a;
    Port[$3CE]:=4; Port[$3CF]:=a;
    BlockRead(f,Mem[$A000:Offset],16000);
  End;
  Close(f);}
  SetPalette(BildStruk.Farben,160);
End;

Procedure LoadMenu;

Var ch    : Char;
    a,x,y : Word;

Begin
  InitMode(R320X200);
  PutScreenOff;
  ClearVideoMem($FFFF,15);
  LoadPicture('DRAKEMEN',16000);
  PutScreenOn;
  For y:=0 to 100 do Begin
    For x:=(100-y) to (219+y) do Begin
      SetPoint(x,100-y,GetPoint(x,300-y));
      SetPoint(x,99+y,GetPoint(x,y+299))
    End;
    For a:=(100-y) to (100+y) do Begin
      SetPoint((100-y),a,GetPoint((100-y),a+200));
      SetPoint((219+y),a,GetPoint((219+y),a+200))
    End
  End;
  Repeat Until KeyPressed;
  While KeyPressed do ch:=ReadKey;
  For y:=100 downto 0 do Begin
    For x:=(100-y) to (219+y) do Begin
      SetPoint(x,100-y,0);
      SetPoint(x,99+y,0)
    End;
    For a:=(100-y) to (100+y) do Begin
      SetPoint((100-y),a,0);
      SetPoint((219+y),a,0)
    End
  End;
  If ch='3' then Begin
    CloseMode;
    WriteLn('Hasta la vista Baby');
    Halt;
  End;
  PutScreenOff;
  CloseMode
End;

Procedure Zwischenbild(ZName : String);

Var z,i : Word;

Begin
  InitMode(R320X200);
  PutScreenOff;
  ClearVideoMem($FFFF,15);
  SetScreenWith(320);
  LoadPicture(ZName,16000);
  SetWinPos(0,0);
  PutScreenOn;
  For i:=0 to 200 do Begin
    SetWinPos(0,i);
    Delay(2);
  End;
  z:=0;
  Repeat
    Delay(1);
    Inc(z);
  Until ((KeyPressed) OR (z>2500));
  For i:=200 downto 0 do Begin
    SetWinPos(0,i);
    Delay(2);
  End;
  PutScreenOff;
  CloseMode
End;

Begin
  Vorspann;             { Steuer Stfe Eng Kero Schuss Bomb}
  Basis:=$220;
  IntNum:=5;
  Repeat
    LoadMenu;
    Zwischenbild('LVL1DRSN');
    Geschafft:=DrakeSnakeSpiel('Level1','Drake',1,117,136,2432,54,7);
  Until Geschafft;
  Repeat
    Zwischenbild('LVL2DRSN');
    Geschafft:=DrakeSnakeSpiel('Level2','Drake',1,128,136,2432,34,7);
    If Geschafft=False then LoadMenu;
  Until Geschafft;
  CloseMode;
  WriteLn('Drake Snake (& the secret Crypt) >Demoversion< - [Beta Released]');
{  Zwischenbild;
  Geschafft:=DrakeSnakeSpiel('Level3',1,117,136,2432,54,7);
  Zwischenbild;
  Geschafft:=DrakeSnakeSpiel('Level4',1,117,136,2432,54,7);}
End.
