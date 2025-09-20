Unit PlanePic;

Interface

Uses Crt,GrafikOn,HeroSpiel;

Procedure AbsturzBild;

Implementation

Type  FuenfKB    = Array[0..5119] of Byte;
      SegBuffer = Array[0..2000] of Byte;

Var Name       : String[30];
    f          : File;
    a,x,y      : Word;
    Farbe,Pal2 : Paltyp;
    ch         : Char;

Procedure ErrorMessage(Message : String);

Begin
  TextMode(CO80);
  WriteLn(Message,#7);
  Halt;
End;

Procedure LoadAmiga(BildName : String; Var Palette : Paltyp);

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
    If Page>4 then
      Begin
        Inc(Zeile);
        Page:=Page Mod 5;
      End;
  End;

Begin
  WievielRAM:=0;
  Assign(FDest,BildName);
  Reset(FDest,1);
  BODYBig:=FileSize(FDest)-96;
  Noch:=BODYBig;
  If MemAvail<(Noch+96) then
    Begin
      Close(FDest);
      ErrorMessage('Zuwenig Speicher frei !');
    End;
  s:=(Noch Div 5119)+1;
  WievielRAM:=s;
  BlockRead(FDest,Palette,96,result);
  If result<>96 then Write(#7);
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

Procedure LoadPicture(Name : String);

Var f      : File;
    Farb   : PalTyp;

Begin
  LoadAmiga(Name+'.BLD',Farb);
  Move(Farb,Farbe,768);
End;

Procedure ClearPic;

Begin
  Port[$3C4]:=2; Port[$3C5]:=15;
  FillChar(Mem[$A000:0000],$FFFF,0);
End;

Procedure AbsturzBild;

Begin
  PutScreenOff;
  InitMode(R320x200);
  PutScreenOff;
  ClearPic;

  For x:=0 to 95 do Pal2[x]:=0;
  SetPalette(Pal2,33);

  Name:='CRASH&CR';
  LoadPicture(Name);
  PutScreenOn;

  For y:=0 to 64 do Begin
    For x:=0 to 95 do
      Pal2[x]:=(Farbe[x]*y) shr 6;
    SetPalette(Pal2,33);
  End;

  a:=0;
  Repeat
    Inc(a); Delay(1);
  Until ((KeyPressed) OR (a>3000));
  While KeyPressed do ch:=ReadKey;

  For y:=64 downto 0 do Begin
    For x:=0 to 95 do
      Pal2[x]:=(Farbe[x]*y) shr 6;
    SetPalette(Pal2,33);
  End;
  PutScreenOff;
  CloseMode;
  PutScreenOff;
End;

End.