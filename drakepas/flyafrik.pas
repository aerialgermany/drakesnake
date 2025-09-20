Unit FlyAfrik;

Interface

Uses GrafikOn,FlugSpiel,Crt;

Procedure Fluganimation_ueber_Dschungel;

Implementation

Type Screen   = Array[0..64000] of Byte;
     TextBuf  = Array[0..10324] of Byte;

Const ScreenHigh = 240;
      ScreenWith = 512;
      AnimB      = 48;
      AnimH      = 48;
      AnzPics    = 25;
      Count      = 382;
      Page       : Array[0..1] of Word = (0,250);

Type  SpriteTyp = Array[0..(AnimB*AnimH+4)] of Byte;
      Koord = Record
                X,Y  : Word;
                Bild : Byte;
              End;
     FuenfKB    = Array[0..5119] of Byte;
     SegBuffer = Array[0..2000] of Byte;

Var Hgrund    : Array[0..1] of ^SpriteTyp;
    XSpr,YSpr : Array[0..1] of Word;
    Coulor    : IFFStruct;
    x,y,x2,y2,
    Taste,Big,
    Big2      : Word;
    Name,
    KName     : String[30];
    f         : File;
    v,BitPl,P : Byte;
    I,a,
    Breite,
    Hoehe     : Word;
    TextPic,
    TGround   : ^TextBuf;
    Pal       : Paltyp;
    Bild      : ^Screen;
    BildStruk : IFFStruct;
{    Farb      : Byte;}
    ch        : Char;
    Anim      : Array[0..Count-1] of ^SpriteTyp;
    APosition : Array[0..Count] of Koord;
    BPosition : Array[0..(Count*2)] of Koord;
    PicCount,
    XOffs,
    YOffs     : Word;

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
        OfsScreen:=Zeile*64+Spalte+12;
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
        OfsScreen:=Zeile*64+Spalte+12;
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


{Procedure Aufbau;

Var OktOff : Word;

Begin
  OktOff:=XOffs shr 3;
  With BildStruk do
    For y:=0 to 239 do
      For a:=0 to BitPlanes-1 do
        For x:=0 to 39 do Begin
          WritePlane(a,y*64+x+OktOff,Bild^[y*40*BitPlanes+a*40+x]);
          WritePlane(a,(y+Page[1])*64+x+OktOff,Bild^[y*40*BitPlanes+a*40+x]);
        End;
End;}

Procedure LoadPicture;

Var OktOff,x : Word;
    f        : File;
    Farb     : Paltyp;

Begin
{  OktOff:=XOffs shr 2;
  Assign(f,'DrakeJgl.PIK');
  Reset(f,1);
  BlockRead(f,BildStruk.Farben,768);}
  LoadAmiga('DRAKEJGL.PIK',Farb);
  Move(Farb,BildStruk.Farben,768);
  For a:=0 to 3 do Begin
    Port[$3C4]:=2; Port[$3C5]:=1 shl a;
    Port[$3CE]:=4; Port[$3CF]:=a;
    For y:=0 to 239 do Begin
{      BlockRead(f,Mem[$A000:(y*128+OktOff)],80);}
      Move(Mem[$A000:(y*128+OktOff)],Mem[$A000:((y+Page[1])*128+OktOff)],80);
    End;
  End;
{  Close(f);}
  For x:=0 to 95 do
    Pal[x]:=0;
  SetPalette(Pal);
End;

Procedure ClearPic;

Begin
  Port[$3C4]:=2; Port[$3C5]:=15;
  FillChar(Mem[$A000:0000],$FFFF,0);
End;

Procedure LadeKoordinaten;

Begin
  Assign(f,KName);
  Reset(f,1);
  For i:=0 to Count-1 do
    BlockRead(f,APosition[i],5);
  Close(f);
End;

Procedure Einblenden;

Var x,y : Word;

Begin
  For y:=0 to 64 do Begin
    For x:=0 to 95 do
      Pal[x]:=(BildStruk.Farben[x]*y) shr 6;
    SetPalette(Pal);
  End;
End;

Procedure Ausblenden;

Var x,y : Word;

Begin
  For y:=64 downto 0 do Begin
    For x:=0 to 95 do
      Pal[x]:=(BildStruk.Farben[x]*y) shr 6;
    SetPalette(Pal);
  End;
End;

Procedure Fluganimation_ueber_Dschungel;

Begin
  PutScreenOff;
  InitMode(R320x240);
  PutScreenOff;
  SetScreenWith(ScreenWith);
  ClearPic;
  New(Hgrund[0]);  New(Hgrund[1]);

  P:=0;
  KName:='flug.krd';
  XOffs:=96; YOffs:=0;

  SetWinPos(XOffs,Page[P]);

  ClearPic;
  LoadPicture;

  New(TextPic); New(TGround);
  Assign(f,'JTEXT.FLG'); Reset(f,1);
  BlockRead(f,TextPic^,10324); Close(f);

  For i:=0 to AnzPics-1 do New(Anim[i]);
  Assign(f,'plane2.anm');
  Reset(f,1);
  For i:=0 to AnzPics-1 do BlockRead(f,Anim[i]^,(AnimB*AnimH+4));
  Close(f);

  LadeKoordinaten;

  With APosition[0] do Begin
    XSpr[P]:=X;         XSpr[1-P]:=X;
    YSpr[P]:=Y+Page[P]; YSpr[1-P]:=Y+Page[1-P];
  End;
  GetImage(XSpr[P],YSpr[P],AnimB,AnimH,HGrund[P]);
  P:=1-P;
  GetImage(XSpr[P],YSpr[P],AnimB,AnimH,HGrund[P]);

  SetWinPos(XOffs,Page[0]);
  GetImage(XOffs+39,80,240,43,TGround);
  PutScreenOn;
  Einblenden;
  Delay(1500);
  PutImOut(XOffs+39,80,TextPic);
  Delay(5000);
  PutImNor(XOffs+39,80,TGround);
  Delay(1000);

  For PicCount:=0 to Count-1 do Begin

    PutImNor(XSpr[P],YSpr[P],HGrund[P]);
    With APosition[PicCount] do Begin
      XSpr[P]:=X; YSpr[P]:=Y+Page[P];
      GetImage(XSpr[P],YSpr[P],AnimB,AnimH,HGrund[P]);
      PutImOut(XSpr[P],YSpr[P],Anim[Bild]);
    End;
    SetWinPos(XOffs,Page[P]);
    P:=1-P;
{  While KeyPressed do ch:=ReadKey;}
  End;

  Delay(1000);
  For i:=0 to 5 do Begin
    SetWinPos(XOffs,1); Delay(3);
    SetWinPos(XOffs,2); Delay(4);
    SetWinPos(XOffs,3); Delay(3);
    SetWinPos(XOffs,4); Delay(3);
    SetWinPos(XOffs,5); Delay(5);
    SetWinPos(XOffs,4); Delay(3);
    SetWinPos(XOffs,3); Delay(2);
    SetWinPos(XOffs,2); Delay(3);
  End;
  SetWinPos(XOffs,Page[1-P]);
  Delay(3000);
  Ausblenden;
  PutScreenOff;
  CloseMode;
  PutScreenOff;
  Dispose(TextPic); Dispose(TGround);
End;

End.