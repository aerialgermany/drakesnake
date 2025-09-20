Program FlugAnimation;

Uses FlugSpiel,Crt;

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

Procedure Aufbau;

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
End;

Procedure SavePicture;

Var OktOff : Word;
    f      : File;

Begin
  OktOff:=XOffs shr 2;
  Assign(f,'DrakeJgl.PIK');
  Rewrite(f,1);
  BlockWrite(f,BildStruk.Farben,768);
  For a:=0 to 3 do Begin
    Port[$3CE]:=4;
    Port[$3CF]:=a;
    For y:=0 to 239 do
      BlockWrite(f,Mem[$A000:(y*128+OktOff)],80);
  End;
  Close(f);
End;

Procedure LoadPicture;

Var OktOff : Word;
    f      : File;

Begin
  OktOff:=XOffs shr 2;
  Assign(f,'DrakeJgl.PIK');
  Reset(f,1);
  BlockRead(f,BildStruk.Farben,768);
  For a:=0 to 3 do Begin
    Port[$3C4]:=2; Port[$3C5]:=1 shl a;
    Port[$3CE]:=4; Port[$3CF]:=a;
    For y:=0 to 239 do Begin
      BlockRead(f,Mem[$A000:(y*128+OktOff)],80);
      Move(Mem[$A000:(y*128+OktOff)],Mem[$A000:((y+Page[1])*128+OktOff)],80);
    End;
  End;
  Close(f);
  SetPalette(BildStruk.Farben);
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

Procedure CalcAmigaPalette;

Var i     : Word;

Begin
  With BildStruk do Begin
    For i:=0 to 767 do
      Farben[i]:=Farben[i] shr 2;
    For i:=0 to 767 do
      Farben[i]:=Round(Farben[i]*4.2);
  End;
  SetPalette(BildStruk.Farben);
End;

Begin
  InitMode(R320x240);
  SetScreenWith(ScreenWith);
  ClearPic;
  New(Hgrund[0]);  New(Hgrund[1]);

  P:=0;
  KName:='flug.krd';
  XOffs:=96; YOffs:=0;

  SetWinPos(XOffs,Page[P]);

{  New(Bild);
  LoadIFF('c:\dpaint2\amiga\dsjungle.LBM',Bild,BildStruk);
  CalcAmigaPalette;
  Aufbau;
  SavePicture;
  Dispose(Bild);}
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

{  For i:=0 to Count-1 do Begin
    BPosition[i*2].X   :=APosition[i].X;
    BPosition[i*2].Y   :=APosition[i].Y;
    BPosition[i*2].Bild:=APosition[i].Bild;
    BPosition[i*2+1].X   :=(APosition[i].X+BPosition[i*2].X) shr 1;
    BPosition[i*2+1].Y   :=(APosition[i].Y+BPosition[i*2].Y) shr 1;
    BPosition[i*2+1].Bild:=APosition[i].Bild;
  End;

  Assign(f,'c:\tp60\flug.krd');
  Rewrite(f,1);
  For i:=0 to (Count*2)-1 do
    BlockWrite(f,BPosition[i],5);
  Close(f);}

  PicCount:=0;
  With APosition[PicCount] do Begin
    XSpr[P]:=X;         XSpr[1-P]:=X;
    YSpr[P]:=Y+Page[P]; YSpr[1-P]:=Y+Page[1-P];
  End;
  GetImage(XSpr[P],YSpr[P],AnimB,AnimH,HGrund[P]);
  P:=1-P;
  GetImage(XSpr[P],YSpr[P],AnimB,AnimH,HGrund[P]);
  Repeat
    If PicCount=0 then Begin
      SetWinPos(XOffs,Page[0]);
      GetImage(XOffs+39,80,240,43,TGround);
      Delay(1500);
      PutImOut(XOffs+39,80,TextPic);
      Delay(5000);
      PutImNor(XOffs+39,80,TGround);
      Delay(1000);
    End;
    PutImNor(XSpr[P],YSpr[P],HGrund[P]);
    With APosition[PicCount] do Begin
      XSpr[P]:=X; YSpr[P]:=Y+Page[P];
      GetImage(XSpr[P],YSpr[P],AnimB,AnimH,HGrund[P]);
      PutImOut(XSpr[P],YSpr[P],Anim[Bild]);
    End;
    P:=1-P;
    SetWinPos(XOffs,Page[1-P]);
    While KeyPressed do ch:=ReadKey;
    Inc(PicCount);
    If PicCount>=Count then Begin
      PicCount:=0;
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
    End;
  Until ch=#27;
{  Until ((ch=#27) OR (PicCount>=Count));}
  CloseMode;
  Dispose(TextPic); Dispose(TGround);
End.