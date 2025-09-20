Program Drake_Snake;

Uses HeroSpiel,Crt,Dos,GameCon,Joystick,DSAnfang,DrakeExt,PlayDrk2,Mouse;

Type Buffer = Array[0..810] of Byte;
     Stat   = Array[0..4500] of Byte;
     SpriteTyp = Array[0..800] of Byte;
     SpriteBum = Array[0..579] of Byte;
     Spin      = Array[0..472] of Byte;
     Scorp     = Array[0..350] of Byte;
     Fled      = Array[0..190] of Byte;
     Mauer     = Array[0..900] of Byte;
     BuffBild  = Array[0..65533] of Byte;
     KoordTyp  = Record
                    X,Y : Word;
                  End;

Const Page    : Array[0..1] of Word = (0,320);
      Lauf    : Array[0..63] of Byte = (00,01,02,03,04,05,06,07,08,09,
                                        10,11,12,13,14,15,16,17,18,19,
                                        20,21,22,23,24,25,26,27,28,29,
                                        30,31,
                                        32,31,30,29,28,27,26,25,24,23,
                                        22,21,20,19,18,17,16,15,14,13,
                                        12,11,10,09,08,07,06,05,04,03,
                                        02,01);
      Flug    : Array[0..63,0..1] of Byte = ((05,00),(06,00),(08,01),(09,02),
                                             (10,03),(11,04),(12,05),(12,06),
                                             (13,08),(13,09),(14,11),(14,12),
                                             (16,13),(17,14),(18,15),(19,15),
                                             (21,16),(22,16),(24,15),(25,14),
                                             (26,12),(26,11),(26,10),(26,09),
                                             (26,08),(26,07),(26,06),(26,05),
                                             (26,04),(25,03),(24,01),(23,01),
                                             (21,00),(20,00),(18,01),(17,02),
                                             (16,03),(15,04),(14,05),(14,06),
                                             (13,08),(13,09),(12,11),(11,12),
                                             (10,13),(09,14),(08,15),(07,15),
                                             (05,16),(04,16),(02,15),(01,13),
                                             (00,12),(00,11),(00,10),(00,09),
                                             (00,08),(00,07),(00,06),(00,05),
                                             (00,04),(01,03),(02,01),(03,01));
      Fahrend  = 1;
      Fliegend = 0;
      WieHelt  : Byte = 0;
      EnergieTeiler = 2;
      KerosinTeiler = 6;
      Schussteiler  = 1;
      IstBild  : Boolean = False;
      BildName : String[8] = 'nothing';
      SplitOff = 14;
      LevelX = 20;
      LevelY = 28;

Var i,x1,y1,x,
    x2,y2,y,
    BitPl,res,
    SCnt,FCnt,
    SkCnt,
    Energie,
    Kerosin,
    Schussmenge,
    AnzBomb,
    WelcherScorp,
    BildX,BildY,
    SoundOut    : Word;
    WieWeit,
    WieWeitF    : Array[0..10] of Word;
    ch          : Char;
    P,Steuer,
    v,tal,tar,
    tao,tau,
    EE,KE,SE,
    FE,
    Zustand,
    Detonation,
    BDetonation,
    Flag       : Byte;
    Sprite     : Array[0..3] of ^Buffer;
    Ground     : Array[0..1] of ^Buffer;
    Expeng     : Array[0..12] of ^SpriteBum;
    GxPeng     : Array[0..1] of ^SpriteBum;
    MauerSeq   : Array[0..11] of ^Mauer;
    BombGround : Array[0..1] of ^Spin;
    UZeile     : ^Stat;
    XG,YG,
    XP,YP,
    XD,YD      : Array[0..1] of Word;
    FP         : Array[0..1] of Byte;
    XS,YS,
    XF,YF      : Array[1..10,0..1] of Word;
    XSpr,YSpr,
    L1X,L1Y,
    L2X,L2Y,
    BX,BY,Gr,
    Grl,Grr,
    Gro,Gru,
    XBomb,
    YBomb,
    BombCount  : Word;
    YWin       : Integer;
    Regs       : Registers;
    XPos,YPos  : ShortInt;
    Grav       : ShortInt;
    Level      : Array[0..LevelY-1,0..LevelX-1] of Byte;
      LevelLinks      : String[8];
      LevelRechts     : String[8];
      LevelOben       : String[8];
      LevelUnten      : String[8];
      LevelName       : String[8];
      Zahl            : String[2];
      Sprites         : Array[0..25] of ^SpriteTyp;
      SpinZeiger,z,
      FlederZeiger,
      FlaschenZeiger,
      SkorpionZeiger,
      MauerZeiger,
      KBuschZeiger,
      GBuschZeiger,
      XPeng,YPeng,
      ScorpRot,
      ScorpOff        : Word;
      SpinKoord,
      FlederKoord,
      FlaschenKoord,
      SkorpionKoord,
      MauerKoord      : Array[1..10] of KoordTyp;
      IstSpin,
      IstSkorpion,
      IstFMaus,
      IstFlasche,
      IstMauer        : Array[1..10] of Boolean;
{      IstAlles        : Array[1..16,1..5,1..10] of Boolean;}
      KBuschKoord,
      GBuschKoord     : Array[1..20] of KoordTyp;
      IstHERO,IstBomb : Boolean;
      f               : File;
      HeroKoord       : KoordTyp;
      Spider          : Array[0..79] of ^Spin;
      SkorpAnim       : Array[0..3,0..10] of ^Scorp;
      FlederAnim      : Array[0..20] of ^Fled;
      SkorpGround     : Array[1..10,0..1] of ^Scorp;
      FlederGround    : Array[1..10,0..1] of ^Fled;
      Bild            : ^BuffBild;
      Schuss,
      Poff,KrachBum   : Boolean;
      LiRe            : ShortInt;

      Memorie         : LongInt;

Procedure Aufbau;

Var x,y,i,h : Word;
    f       : File;

Begin
  For i:=0 to 10 do
    WieWeit[i]:=0;
  For i:=0 to 10 do
    WieWeitF[i]:=0;
  ClearScreen(0);
  If IstBild then Begin
    New(Bild);
    Assign(f,BildName+'.BLD');
    Reset(f,1);
    BlockRead(f,Bild^,65533,i);
    Close(f);
    PutImNor(BildX+Page[0],BildY+SplitOff,Bild);
    PutImNor(BildX+Page[1],BildY+SplitOff,Bild);
    Dispose(Bild);
  End;
  For i:=0 to 1 do Begin
  For y:=0 to LevelY-1 do
    For x:=0 to LevelX-1 do
      Case Level[y,x] of
        5      : PutImNor(x*16+Page[i],y*14-2+SplitOff,
                           Sprites[4]);
        6..9   : PutImNor(x*16+Page[i],y*14+SplitOff,
                           Sprites[Level[y,x]-1]);
        14     : PutImNor(x*16+Page[i],y*14+SplitOff,
                           Sprites[13]);
        15     : PutImNor(x*16+Page[i]-13,y*14+SplitOff,
                           Sprites[14]);
        16..18 : PutImNor(x*16+Page[i],y*14-1+SplitOff,
                           Sprites[Level[y,x]-1]);
        19..23 : PutImNor(x*16+Page[i],y*14+SplitOff,
                           Sprites[Level[y,x]-1]);
        24     : PutImNor(x*16+Page[i],y*14-2+SplitOff,
                           Sprites[23]);
        25     : PutImNor(x*16+Page[i],y*14-2+SplitOff,
                           Sprites[24]);
      End;
  If SpinZeiger>0 then
    For x:=1 to SpinZeiger do
      PutImNor(SpinKoord[x].X+Page[i],SpinKoord[x].Y+SplitOff,
                 Sprites[0]);
{  If FlederZeiger>0 then
    For x:=1 to FlederZeiger do
      PutImNor(FlederKoord[x].X+Page[i],FlederKoord[x].Y+SplitOff,
                 Sprites[1]);}
  If FlaschenZeiger>0 then
    For x:=1 to FlaschenZeiger do
      PutImNor(FlaschenKoord[x].X+Page[i],FlaschenKoord[x].Y+SplitOff,
                 Sprites[3]);
{  If SkorpionZeiger>0 then
    For x:=1 to SkorpionZeiger do
      PutImNor(SkorpionKoord[x].X+Page[i],SkorpionKoord[x].Y+SplitOff,
                 Sprites[10]);}
  If MauerZeiger>0 then
    For x:=1 to MauerZeiger do Begin
      PutImNor(MauerKoord[x].X+Page[i],MauerKoord[x].Y+SplitOff,
                 Sprites[9]);
      For h:=0 to 3 do Begin
        Level[(MauerKoord[x].Y Div 14)+h,((MauerKoord[x].X-2) Div 16)]:=30;
      End;
    End;
  If KBuschZeiger>0 then
    For x:=1 to KBuschZeiger do
      PutImNor(KBuschKoord[x].X+Page[i],KBuschKoord[x].Y+SplitOff,
                 Sprites[12]);
  If GBuschZeiger>0 then
    For x:=1 to GBuschZeiger do
      PutImNor(GBuschKoord[x].X+Page[i],GBuschKoord[x].Y+SplitOff,
                 Sprites[11]);
  End;
  PutImNor(Page[0],0,UZeile);
  Block(105,5,105+EE,9,253); Block(105+EE,5,139,9,0);
  Block(26,5,26+KE,9,252); Block(26+KE,5,64,9,0);
  Block(171,5,171+SE,9,250); Block(171+SE,5,198,9,0);
  Block(210,3,210+8*(7-AnzBomb),12,0);
  For i:=1 to SpinZeiger do
    IstSpin[i]:=TRUE;
  For i:=1 to SkorpionZeiger do
    IstSkorpion[i]:=TRUE;
  For i:=1 to FlederZeiger do
    IstFMaus[i]:=TRUE;
  For i:=1 to FlaschenZeiger do
    IstFlasche[i]:=TRUE;
  For i:=1 to MauerZeiger do
    IstMauer[i]:=TRUE;
  For i:=1 to SkorpionZeiger do Begin
    XS[i,0]:=SkorpionKoord[i].X+Page[0];
    YS[i,0]:=SkorpionKoord[i].Y+SplitOff;
    XS[i,1]:=SkorpionKoord[i].X+Page[1];
    YS[i,1]:=SkorpionKoord[i].Y+SplitOff;
    GetImage(XS[i,0],YS[i,0],26,13,SkorpGround[i,0]);
    GetImage(XS[i,1],YS[i,1],26,13,SkorpGround[i,1]);
  End;
  WelcherScorp:=0;
  For i:=1 to FlederZeiger do Begin
    XF[i,0]:=FlederKoord[i].X+Page[0]+Flug[0,0];
    YF[i,0]:=FlederKoord[i].Y+SplitOff+Flug[0,1];
    XF[i,1]:=FlederKoord[i].X+Page[1]+Flug[0,0];
    YF[i,1]:=FlederKoord[i].Y+SplitOff+Flug[0,1];
    GetImage(XF[i,0],YF[i,0],18,10,FlederGround[i,0]);
    GetImage(XF[i,1],YF[i,1],18,10,FlederGround[i,1]);
  End;
  ScorpRot:=0;
  ScorpOff:=0;
End;

Function CheckFile(Name : String): Boolean;  { Ergibt TRUE, wenn es dieses }
                                             { File gibt, ansonsten FALSE  }
Var f      : File;
    Fehler : Word;

Begin
  {$I-}
  Assign(f,Name);
  Reset(f);
  Close(f);
  Fehler:=IOResult;
  If Fehler=0 then
    CheckFile:=True
  Else
    CheckFile:=False;
  {$I+}
End;

Procedure LodeAllSprites;

Begin
  If CheckFile('DRAKE.SPR')=FALSE then
    Begin
      CloseMode;
      WriteLn('Spritefile existiert nicht !');
      HALT;
    End;
  Assign(f,'DRAKE.SPR');
  Reset(f,1);
  BlockRead(f,Addr(Pal)^,768);     { Palette - 256*3 Werte }

  BlockRead(f,UZeile^,4500);       { Statuszeile }

  BlockRead(f,Sprite[0]^,810);      { Spritefigur Rechts mit Antrieb }
  BlockRead(f,Sprite[1]^,810);      { Spritefigur Links mit Antrieb }
  BlockRead(f,Sprite[2]^,810);      { Spritefigur Rechts }
  BlockRead(f,Sprite[3]^,810);      { Spritefigur Links }

  For i:=0 to 79 do                  { Spinnenanimation 80 Pic's }
    BlockRead(f,Spider[i]^,472);

  For i:=0 to 12 do                  { Explosionsanimation 13 Pic's }
    BlockRead(f,Expeng[i]^,579);

  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (rechts) }
    BlockRead(f,SkorpAnim[0,i]^,342);
  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (links) }
    BlockRead(f,SkorpAnim[1,i]^,342);
  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (drehung) }
    BlockRead(f,SkorpAnim[2,i]^,342);
  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (drehung) }
    BlockRead(f,SkorpAnim[3,i]^,342);

  For i:=0 to 12 do                  { Fledermausanimation 13 Pic's }
    BlockRead(f,FlederAnim[i]^,184);

  For i:=0 to 11 do
    BlockRead(f,MauerSeq[i]^,900);   { Maueranimation 12 Pic's }

  For i:=0 to 25 do                  { Levelsprites 26 StÅck }
    BlockRead(f,Sprites[i]^,800);

  Close(f);
End;

Procedure Ende;

Begin
  CloseAusgabe;
  Ausblenden;
  For i:=0 to 3 do
    Dispose(Sprite[i]);
  Dispose(Ground[0]); Dispose(Ground[1]);
  For i:=0 to 79 do Dispose(Spider[i]);
  Dispose(UZeile);
  CloseMode;
{  If Steuer=1 then}
  DeInstallGameKey;
  Halt;
End;

Procedure Load(Name : String);

Var f      : File;
    i      : Word;
    beit   : Byte;

Begin
  IstBild:=False;
  If CheckFile((Name+'.LVL'))=False then Begin
    Write(#7); Write(#7);
    PutScreenOn;
    Ende
  End Else
  Begin
  Assign(f,(Name+'.LVL'));
  Reset(f,1);
  BlockRead(f,Mem[Seg(Level):Ofs(Level)],(LevelX*LevelY));
  BlockRead(f,SpinZeiger,2);
  If SpinZeiger<>0 then
    For i:=1 to SpinZeiger do Begin
      BlockRead(f,SpinKoord[i].X,2);
      BlockRead(f,SpinKoord[i].Y,2)
    End;
  BlockRead(f,FlederZeiger,2);
  If FlederZeiger<>0 then
    For i:=1 to FlederZeiger do Begin
      BlockRead(f,FlederKoord[i].X,2);
      BlockRead(f,FlederKoord[i].Y,2)
    End;
  BlockRead(f,FlaschenZeiger,2);
  If FlaschenZeiger<>0 then
    For i:=1 to FlaschenZeiger do Begin
      BlockRead(f,FlaschenKoord[i].X,2);
      BlockRead(f,FlaschenKoord[i].Y,2)
    End;
  BlockRead(f,MauerZeiger,2);
  If MauerZeiger<>0 then
    For i:=1 to MauerZeiger do Begin
      BlockRead(f,MauerKoord[i].X,2);
      BlockRead(f,MauerKoord[i].Y,2)
    End;
  BlockRead(f,SkorpionZeiger,2);
  If SkorpionZeiger<>0 then
    For i:=1 to SkorpionZeiger do Begin
      BlockRead(f,SkorpionKoord[i].X,2);
      BlockRead(f,SkorpionKoord[i].Y,2)
    End;
  BlockRead(f,GBuschZeiger,2);
  If GBuschZeiger<>0 then
    For i:=1 to GBuschZeiger do Begin
      BlockRead(f,GBuschKoord[i].X,2);
      BlockRead(f,GBuschKoord[i].Y,2)
    End;
  BlockRead(f,KBuschZeiger,2);
  If KBuschZeiger<>0 then
    For i:=1 to KBuschZeiger do Begin
      BlockRead(f,KBuschKoord[i].X,2);
      BlockRead(f,KBuschKoord[i].Y,2)
    End;
  BlockRead(f,beit,1);
  If beit>0 then Begin
    BlockRead(f,BildX,2);
    BlockRead(f,BildY,2);
    BlockRead(f,BildName,9);
    IstBild:=True;
  End Else
    IstBild:=False;
  BlockRead(f,HeroKoord.X,2);
  BlockRead(f,HeroKoord.Y,2);
  BlockRead(f,LevelLinks,9);
  BlockRead(f,LevelRechts,9);
  BlockRead(f,LevelOben,9);
  BlockRead(f,LevelUnten,9);
  Close(f);
  End;
  For i:=1 to SkorpionZeiger do Begin
    New(SkorpGround[i,0]);
    New(SkorpGround[i,1]);
  End;
  For i:=1 to FlederZeiger do Begin
    New(FlederGround[i,0]);
    New(FlederGround[i,1]);
  End;
End;

Function IstInNaehe(x1,y1,x2,y2: Word;RangeX,RangeY : Byte): Boolean;

Var x,y : Integer;
    JN  : Boolean;
    h,v : Word;


Begin
  JN:=FALSE;
  x:=x2-x1;
  y:=y2-y1;
  h:=Abs(x);
  v:=Abs(y);
  If h in [0..RangeX] then
    If v in [0..RangeY] then
      JN:=TRUE;
  IstInNaehe:=JN;
End;

Procedure SchauFlasche;

Var x1,y1 : Integer;
    i     : Word;

Begin
  For i:=1 to FlaschenZeiger do
    If IstFlasche[i] then
      If IstInNaehe(FlaschenKoord[i].X,
                    (FlaschenKoord[i].Y+SplitOff),
                    (XSpr+8),(YSpr+25),10,10) then Begin
          IstFlasche[i]:=FALSE;
          Inc(Energie,20);
          If Energie>136 then Energie:=136;
          EE:=Energie shr EnergieTeiler;
          Inc(Kerosin,400);
          If Kerosin>2432 then Kerosin:=2432;
          KE:=Kerosin shr KerosinTeiler;
          Block(105,5,105+EE,9,253); Block(105+EE,5,139,9,0);
          Block(26,5,26+KE,9,252); Block(26+KE,5,64,9,0);

          PutImNor(XG[0],YG[0],Ground[0]);
          PutImNor(XG[1],YG[1],Ground[1]);
          Block(FlaschenKoord[i].X+Page[0],FlaschenKoord[i].Y+SplitOff,
                FlaschenKoord[i].X+Page[0]+4,FlaschenKoord[i].Y+SplitOff+7,
                0);
          Block(FlaschenKoord[i].X+Page[1],FlaschenKoord[i].Y+SplitOff,
                FlaschenKoord[i].X+Page[1]+4,FlaschenKoord[i].Y+SplitOff+7,
                0);
          GetImage(XG[0],YG[0],22,34,Ground[0]);
          PutImKol(XG[0],YG[0],Sprite[WieHelt]);
          GetImage(XG[1],YG[1],22,34,Ground[1]);
          PutImKol(XG[1],YG[1],Sprite[WieHelt]);
      End;
End;

Procedure Eingabe(Was : Byte);

Var ch       : Char;
    ScanCode : Byte;
    XMotion,
    YMotion  : Integer;

Begin
  Case Was of
    0 : Case Digi_Joy of
          0 : Begin XPos:=-1; YPos:=-1; End;
          1 : Begin XPos:=0;  YPos:=-1; End;
          2 : Begin XPos:=1;  YPos:=-1; End;
          3 : Begin XPos:=-1; YPos:=0;  End;
          4 : Begin XPos:=0;  YPos:=0;  End;
          5 : Begin XPos:=1;  YPos:=0;  End;
          6 : Begin XPos:=-1; SchauFlasche;  End;
          7 : SchauFlasche;
          8 : Begin XPos:=1;  SchauFlasche;  End;
        End;
    1 : Begin
          XPos:=0; YPos:=0;
          If Tasfeld[75] then XPos:=-1;
          If Tasfeld[77] then XPos:=1;
          If Tasfeld[80] then SchauFlasche;
          If Tasfeld[72] then YPos:=-1;
        End;
    2 : Begin
         { XPos:=0; YPos:=0;}
          GetMouseMotion(XMotion,YMotion);
          If XMotion>3  then
            If XPos=-1 then XPos:=0 Else XPos:=1;
          If XMotion<-3 then
            If XPos=1 then XPos:=0 Else XPos:=-1;
          If YMotion>3  then Begin
            SchauFlasche;
            YPos:=0;
          End;
          If YMotion<-3 then YPos:=-1;
        End;
  End;
  If YPos=-1 then Begin
{     Spiel(FlugGeraeusch);}
     If Kerosin=0 then
       YPos:=0
     Else
       Dec(Kerosin);
    KE:=Kerosin shr KerosinTeiler;
    VLine(26+KE,5,9,0);
  End;
  If YPos<0 then
    Case XPos of
       1 : WieHelt:=0;
       0 : WieHelt:=WieHelt Mod 2;
      -1 : WieHelt:=1;
    End
  Else
    Case XPos of
       1 : WieHelt:=2;
       0 : WieHelt:=(WieHelt Mod 2)+2;
      -1 : WieHelt:=3;
    End;
End;

Procedure PutBomb;

Var RasterPos : Word;

Begin
  RasterPos:=(YSpr-SplitOff+34) Div 14;
  If Level[RasterPos,(XSpr+3) Div 16]=17 then Exit;
  New(BombGround[0]); New(BombGround[1]);
  PutImNor(XG[0],YG[0],Ground[0]);
  PutImNor(XG[1],YG[1],Ground[1]);
  IstBomb:=TRUE;
  BombCount:=80;
  Block(210+8*(7-AnzBomb),3,217+8*(7-AnzBomb),12,0);
  Dec(AnzBomb);
  XBomb:=XSpr+3;
  YBomb:=RasterPos*14-11;

  GetImage(XBomb+Page[0],YBomb+SplitOff,7,10,BombGround[0]);
  GetImage(XBomb+Page[1],YBomb+SplitOff,7,10,BombGround[1]);
  PutImOut(XBomb+Page[0],YBomb+SplitOff,Sprites[25]);
  PutImOut(XBomb+Page[1],YBomb+SplitOff,Sprites[25]);

  GetImage(XG[0],YG[0],22,34,Ground[0]);
  PutImKol(XG[0],YG[0],Sprite[WieHelt]);
  GetImage(XG[1],YG[1],22,34,Ground[1]);
  PutImKol(XG[1],YG[1],Sprite[WieHelt]);
End;

Procedure SetHero(XHPos,YHPos : Word);

Begin
  P:=0;
  XG[P]:=Page[P]+XHPos;
  YG[P]:=SplitOff+YHPos;
  GetImage(XG[P],YG[P],22,34,Ground[P]);
  P:=1;
  XG[P]:=Page[P]+XHPos;
  YG[P]:=SplitOff+YHPos;
  GetImage(XG[P],YG[P],22,34,Ground[P]);
  P:=0;
  XSpr:=XHPos;
  YSpr:=SplitOff+YHPos;
End;


Procedure Stirb(Woran : Word);

Var i : Word;

Begin
  CloseAusgabe;
  Ausblenden;
  For i:=0 to 3 do
    Dispose(Sprite[i]);
  Dispose(Ground[0]); Dispose(Ground[1]);
  For i:=0 to 79 do Dispose(Spider[i]);
  Dispose(UZeile);
  CloseMode;
  Case Woran of
    0 : WriteLn('Ich habe keine Kraft mehrrr....');
    1 : WriteLn('Spinnen sind tîtlich');
    2 : WriteLn('Skorpione - mehr sag ich nicht');
    3 : WriteLn('Schei· FledermÑuse');
    4 : WriteLn('Igitt - Fleischfressende Pflanzen');
    5 : WriteLn('Schei· Bombeahhhhhhhhrrrggg !');
  End;
{  If Steuer=1 then}
  DeInstallGameKey;
  Halt;
End;

Procedure RechtsRaus;

Begin
  For i:=1 to SkorpionZeiger do Begin
    Dispose(SkorpGround[i,0]);
    Dispose(SkorpGround[i,1]);
  End;
  For i:=1 to FlederZeiger do Begin
    Dispose(FlederGround[i,0]);
    Dispose(FlederGround[i,1]);
  End;
  Schuss  :=False;
  Poff    :=False;
  KrachBum:=False;
  IstBomb :=False;
  If Pos('fine',LevelRechts)=1 then Ende;
  If ((LevelRechts<>'none') AND (LevelRechts<>'fine')) then Begin
    Ausblenden;
    Load(LevelRechts);
    Aufbau;
    SetHero(3,(YSpr-SplitOff));
    Einblenden
  End
End;

Procedure LinksRaus;

Begin
  For i:=1 to SkorpionZeiger do Begin
    Dispose(SkorpGround[i,0]);
    Dispose(SkorpGround[i,1]);
  End;
  For i:=1 to FlederZeiger do Begin
    Dispose(FlederGround[i,0]);
    Dispose(FlederGround[i,1]);
  End;
  Schuss  :=False;
  Poff    :=False;
  KrachBum:=False;
  IstBomb :=False;
  If Pos('fine',LevelLinks)=1 then Ende;
  If ((LevelLinks<>'none') AND (LevelLinks<>'fine')) then Begin
    Ausblenden;
    Load(LevelLinks);
    Aufbau;
    SetHero(293,(YSpr-SplitOff));
    Einblenden;
  End;
End;

Procedure ObenRaus;

Begin
  For i:=1 to SkorpionZeiger do Begin
    Dispose(SkorpGround[i,0]);
    Dispose(SkorpGround[i,1]);
  End;
  For i:=1 to FlederZeiger do Begin
    Dispose(FlederGround[i,0]);
    Dispose(FlederGround[i,1]);
  End;
  Schuss  :=False;
  Poff    :=False;
  KrachBum:=False;
  IstBomb :=False;
  If Pos('fine',LevelOben)=1 then Ende;
  If ((LevelOben<>'none') AND (LevelOben<>'fine')) then Begin
    Ausblenden;
    Load(LevelOben);
    Aufbau;
    SetHero(XSpr,346);
    SetWinPos(Page[P],((199+SplitOff) Div 2));
    Einblenden;
  End;
End;

Procedure UntenRaus;

Begin
  For i:=1 to SkorpionZeiger do Begin
    Dispose(SkorpGround[i,0]);
    Dispose(SkorpGround[i,1]);
  End;
  For i:=1 to FlederZeiger do Begin
    Dispose(FlederGround[i,0]);
    Dispose(FlederGround[i,1]);
  End;
  Schuss  :=False;
  Poff    :=False;
  KrachBum:=False;
  IstBomb :=False;
  If Pos('fine',LevelUnten)=1 then Ende;
  If ((LevelUnten<>'none') AND (LevelUnten<>'fine')) then Begin
    Ausblenden;
    Load(LevelUnten);
    Aufbau;
    SetHero(XSpr,3);
    SetWinPos(Page[P],(SplitOff Div 2));
    Einblenden;
  End;
End;

Procedure AnimateSpider;

Var zlr,y    : Word;

Begin
  Inc(Scnt);
  SCnt:=SCnt Mod 80;
  For zlr:=1 to SpinZeiger do
    If IstSpin[zlr]=TRUE then Begin
      y:=SpinKoord[zlr].Y+SplitOff;
      If (((y+40)>YWin) AND (y<(YWin+190))) then
        PutImNor(SpinKoord[zlr].X+Page[P],SpinKoord[zlr].Y+SplitOff,
                   Spider[(Scnt+(zlr shl 4)) Mod 80]);
    End;
End;

Procedure AnimateExplosion;

Var i : Word;

Begin
  If Detonation>1 then PutImNor(XD[P],YD[P],GxPeng[P]);
  If Detonation>12 then
    PutImNor(XD[P],YD[P],GxPeng[P])
  Else Begin
    GetImage(XD[P],YD[P],25,23,GxPeng[P]);
    PutImOut(XD[P],YD[P],Expeng[Detonation]);
  End;
  Inc(Detonation);
  If Detonation>14 then Begin
    Poff:=False;
    For i:=0 to 1 do Dispose(GxPeng[i]);
  End;
End;

Procedure AnimateMauer;

Begin
  If BDetonation<12 then
    PutImNor(MauerKoord[Flag].X+Page[P]-2,
             MauerKoord[Flag].Y+SplitOff,MauerSeq[BDetonation])
  Else
    Block(MauerKoord[Flag].X+Page[P]-2,MauerKoord[Flag].Y+SplitOff,
        MauerKoord[Flag].X+12+Page[P],MauerKoord[Flag].Y+55+SplitOff,0);

  Inc(BDetonation);
  If BDetonation>14 then
    KrachBum:=False;
End;

Procedure AnimateSkorpion;

Var  i,x,y,sr  : Word;

Begin
  Inc(SkCnt);
  SkCnt:=SkCnt Mod 10;
  For i:=1 to SkorpionZeiger do Begin
   y:=SkorpionKoord[i].Y+SplitOff;
      If (((y+20)>YWin) AND (y<(YWin+190))) then
        If IstSkorpion[i]=TRUE then Begin
          PutImNor(XS[i,P],YS[i,P],SkorpGround[i,P]);
          If WieWeit[i] in [63,31] then Begin
            Inc(ScorpRot);
            ScorpRot:=ScorpRot Mod 10;
            SkCnt:=ScorpRot;
            ScorpOff:=2;
            sr:=ScorpRot Div 9;
            WieWeit[i]:=WieWeit[i]+sr;
            ScorpOff:=ScorpOff-sr-sr;
          End Else
          Begin
            Inc(WieWeit[i]);
            ScorpOff:=0;
            WieWeit[i]:=WieWeit[i] AND 63;
            XS[i,P]:=SkorpionKoord[i].X+Page[P]+Lauf[WieWeit[i]];
            YS[i,P]:=SkorpionKoord[i].Y+SplitOff;
          End;
          WieWeit[i]:=WieWeit[i] AND 63;
          GetImage(XS[i,P],YS[i,P],26,13,SkorpGround[i,P]);
          PutImOut(XS[i,P],YS[i,P],
                   SkorpAnim[(WieWeit[i] shr 5)+ScorpOff,SkCnt]);
        End;
  End;
End;

Procedure AnimateFledermaus;

Var  i,x,y  : Word;

Begin
  Inc(FCnt);
  FCnt:=FCnt Mod 13;
  For i:=1 to FlederZeiger do Begin
   y:=FlederKoord[i].Y+SplitOff;
      If (((y+20)>YWin) AND (y<(YWin+190))) then
        If IstFMaus[i]=TRUE then Begin
          PutImNor(XF[i,P],YF[i,P],FlederGround[i,P]);
          Inc(WieWeitF[i]);
          WieWeitF[i]:=WieWeitF[i] AND 63;
          XF[i,P]:=FlederKoord[i].X+Page[P]+Flug[WieWeitF[i],0];
          YF[i,P]:=FlederKoord[i].Y+SplitOff+Flug[WieWeitF[i],1];
          GetImage(XF[i,P],YF[i,P],18,10,FlederGround[i,P]);
          PutImOut(XF[i,P],YF[i,P],FlederAnim[FCnt]);
        End;
  End;
End;

Procedure MoveHero(x,y : Word);

Begin
  PutImNor(XG[P],YG[P],Ground[P]);
  If Schuss then
    SetPoint(XP[P],YP[P],FP[P]);
  AnimateSpider;
  AnimateSkorpion;
  AnimateFledermaus;
  If Poff then AnimateExplosion;
  If (KrachBum  AND (Not Poff)) then AnimateMauer;
  XG[P]:=Page[P]+x;
  YG[P]:=y;
  GetImage(XG[P],YG[P],22,34,Ground[P]);
  PutImKol(XG[P],YG[P],Sprite[WieHelt]);
End;

Procedure Explosion(XDetonation,YDetonation : Word);

Var i,a,h,v : Word;
    x1,y1   : Integer;
    Treffer : Boolean;

Begin
  If Poff=False then Begin
    h:=XDetonation; v:=YDetonation;
    Treffer:=FALSE;
    For i:=0 to 1 do New(GxPeng[i]);
    Poff:=TRUE;
    Detonation:=0;
    XD[0]:=h+Page[0]-13; XD[1]:=h+Page[1]-13;
    YD[0]:=v-12;         YD[1]:=v-12;
    PutImNor(XG[0],YG[0],Ground[0]);
    PutImNor(XG[1],YG[1],Ground[1]);
    Spiel(Getroffen);
    For i:=1 to SpinZeiger do
      If IstInNaehe(SpinKoord[i].X,(SpinKoord[i].Y+SplitOff),
                      (h-7),(v-19),20,30) then Begin
          IstSpin[i]:=FALSE;
          Treffer:=TRUE;
          Block(SpinKoord[i].X+Page[0],SpinKoord[i].Y+SplitOff,
                SpinKoord[i].X+Page[0]+15,SpinKoord[i].Y+SplitOff+37,0);
          Block(SpinKoord[i].X+Page[1],SpinKoord[i].Y+SplitOff,
                SpinKoord[i].X+Page[1]+15,SpinKoord[i].Y+SplitOff+37,0);
      End;

    For i:=1 to SkorpionZeiger do
      If IstInNaehe(SkorpionKoord[i].X+Lauf[WieWeit[i]],
                    (SkorpionKoord[i].Y+SplitOff),
                    (h-13),(v-7),30,20) then Begin
          IstSkorpion[i]:=FALSE;
          Treffer:=TRUE;
          PutImNor(XS[i,P],YS[i,P],SkorpGround[i,P]);
          PutImNor(XS[i,1-P],YS[i,1-P],SkorpGround[i,1-P]);
      End;

    For i:=1 to FlederZeiger do
      If IstInNaehe(FlederKoord[i].X+Flug[WieWeitF[i],0],
                      (FlederKoord[i].Y+SplitOff+Flug[WieWeitF[i],1]),
                      (h-9),(v-3),15,10) then Begin
          IstFMaus[i]:=FALSE;
          Treffer:=TRUE;
          PutImNor(XF[i,P],YF[i,P],FlederGround[i,P]);
          PutImNor(XF[i,1-P],YF[i,1-P],FlederGround[i,1-P]);
      End;

    x1:=h Div 16;
    y1:=(v-SplitOff) Div 14;
    If Level[y1,x1+1]=15 then Begin
      Treffer:=TRUE;
      Level[y1,x1+1]:=30;
      PutImNor(Succ(x1)*16+Page[0]-13,y1*14+SplitOff,Sprites[2]);
      PutImNor(Succ(x1)*16+Page[1]-13,y1*14+SplitOff,Sprites[2]);
    End;

    If Level[y1,x1-1]=14 then Begin
      Treffer:=TRUE;
      Level[y1,x1-1]:=28;
      PutImNor(Pred(x1)*16+Page[0],y1*14+SplitOff,Sprites[1]);
      PutImNor(Pred(x1)*16+Page[1],y1*14+SplitOff,Sprites[1]);
    End;
    GetImage(XG[0],YG[0],22,34,Ground[0]);
    PutImKol(XG[0],YG[0],Sprite[WieHelt]);
    GetImage(XG[1],YG[1],22,34,Ground[1]);
    PutImKol(XG[1],YG[1],Sprite[WieHelt]);
  End;
End;

Function Beruehrt(X,Y : Word): Word;

Var i,a,h,v,
    Touch   : Word;
    x1,y1   : Integer;
    Treffer : Boolean;

Begin
  h:=X+11; v:=Y+17-SplitOff;
  Touch:=0;
  For i:=1 to SpinZeiger do
    If IstSpin[i] then
      If IstInNaehe(SpinKoord[i].X,(SpinKoord[i].Y),
                      (h-7),(v-19),18,35) then
        Touch:=1;

  For i:=1 to SkorpionZeiger do
    If IstSkorpion[i] then
      If IstInNaehe(SkorpionKoord[i].X+Lauf[WieWeit[i]],
                    (SkorpionKoord[i].Y),
                  (h-13),(v-7),23,23) then
        Touch:=2;

  For i:=1 to FlederZeiger do
    If IstFmaus[i] then
      If IstInNaehe(FlederKoord[i].X+Flug[WieWeitF[i],0],
                      (FlederKoord[i].Y+Flug[WieWeitF[i],1]),
                      (h-9),(v-3),19,20) then
        Touch:=3;

  x1:=(X+21) Div 16;
  y1:=(Y-17-SplitOff) Div 14;
  For i:=1 to 4 do
    If Level[(y1+i),x1+1]=15 then
      Touch:=4;

  x1:=X Div 16;
  For i:=1 to 4 do
    If Level[(y1+i),x1-1]=14 then
      Touch:=4;

  Beruehrt:=Touch;
End;

Procedure Wusch(x,y : Word);

Var groud : Byte;

Begin
{  SetPoint(XP[P],YP[P],FP[P]);}
  XP[p]:=x+Page[P];
  YP[p]:=y;
  groud:=GetPoint(XP[P],YP[P]);
  FP[P]:=groud;
  groud:=groud OR GetPoint(XP[P]+1,YP[P]);
  If ((groud in [110..128,230..255]) OR (XPeng>316) OR (XPeng<4)) then Begin
    Schuss:=False;
    SetPoint(XP[P],YP[P],FP[P]); SetPoint(XP[1-P],YP[1-P],FP[1-P]);
    If groud in [230..255] then Explosion(XP[0],YP[0]);
  End
  Else
    SetPoint(XP[P],YP[P],126);
End;

Procedure Peng;

Var i : Word;
    b : Byte;

Begin
  Schuss:=True;
  SE:=Schussmenge shr SchussTeiler;
  VLine(171+SE,5,9,0);
  Dec(Schussmenge);
  Spiel(Schiess);
  b:=WieHelt AND 1;
  If b=1 then
    LiRe:=-1 Else LiRe:=1;
  If LiRe=1 then
    XPeng:=XSpr+23
  Else
    XPeng:=XSpr-3;
  YPeng:=YSpr+14;
  XP[P]:=XPeng+Page[P]; XP[1-P]:=XPeng+Page[1-P];;
  YP[P]:=YPeng; YP[1-P]:=YPeng;
  FP[P]:=GetPoint(XP[P],YP[P]);
  FP[1-P]:=GetPoint(XP[1-P],YP[1-P]);
End;

Procedure ShowWand;

Var i,x,x1,y1,
    x2,y2      : Word;
    xa,ya      : Integer;

Begin
  Flag:=0;
  If MauerZeiger>0 then
    For x:=1 to MauerZeiger do Begin
      y1:=(MauerKoord[x].Y+42) Div 14;
      y2:=YBomb Div 14;
      x1:=(MauerKoord[x].X+8) Div 16;
      x2:=(XBomb+3) Div 16;
      ya:=y2-y1; ya:=Abs(ya);
      xa:=x2-x1; xa:=Abs(xa);
      If ya in [0..1] then
        If xa in [0..1] then Flag:=x
    End;
  IstBomb:=FALSE;
  Explosion(XBomb+3,YBomb+5+SplitOff);

  PutImNor(XBomb+Page[0],YBomb+SplitOff,BombGround[0]);
  PutImNor(XBomb+Page[1],YBomb+SplitOff,BombGround[1]);
  Dispose(BombGround[0]); Dispose(BombGround[1]);

  ya:=SplitOff+YBomb-YSpr-12;
  ya:=Abs(ya);
  If ya in [0..25] then Begin
    xa:=XSpr+7-XBomb;
    xa:=Abs(xa);
    If xa in [0..40] then Stirb(5);
  End;
  If ((Flag>0) AND (IstMauer[Flag]=True)) then Begin
      Spiel(BombeExplodiert);
    For i:=0 to 3 do
      Level[(MauerKoord[Flag].Y Div 14)+i,(MauerKoord[Flag].X Div 16)]:=0;
    IstMauer[Flag]:=False;
    KrachBum:=TRUE;
    BDetonation:=0;
  End
End;

Procedure FlugSteuerung;

Begin
    L1X:=XSpr Div 16;
    L1Y:=(YSpr-SplitOff) Div 14;
    L2X:=(XSpr+21) Div 16;
    L2Y:=((YSpr-SplitOff)+33) Div 14;
    Gr:=0; Gro:=0; Gru:=0; Grl:=0; Grr:=0;

    Inc(Gru,Level[L2Y,L1X]);
    Inc(Gru,Level[L2Y,Succ(L1X)]);
    Inc(Gru,Level[L2Y,L2X]);
    If Level[L2Y,(XSpr+11) Div 16]>0 then Zustand:=Fahrend;
    Inc(Gro,Level[L1Y,L1X]);
    Inc(Gro,Level[L1Y,Succ(L1X)]);
    Inc(Gro,Level[L1Y,L2X]);
    For BY:=L1Y to L2Y do Begin
      Inc(Grl,Level[BY,L1X]);
      Inc(Grr,Level[BY,L2X]);
    End;
    Gr:=Grl OR Gro OR Grr OR Gru;

    If Gr>0 then Begin
      If ((Gro>0) AND (Grav=-1)) then Inc(YSpr);
      If ((Gru>0) AND (Grav=1))  then Dec(YSpr);
      If ((Grl>0) AND (XPos=-1)) then Inc(XSpr);
      If ((Grr>0) AND (XPos=1))  then Dec(XSpr);
    End;
End;

Procedure FahrSteuerung;

Begin
    L1X:=XSpr Div 16;
    L1Y:=(YSpr-SplitOff) Div 14;
    L2X:=(XSpr+21) Div 16;
    L2Y:=((YSpr-SplitOff)+33) Div 14;
    Gr:=0; Gru:=0; Grl:=0; Grr:=0;

    Inc(Gru,Level[L2Y,L1X]);
    Inc(Gru,Level[L2Y,Succ(L1X)]);
    Inc(Gru,Level[L2Y,L2X]);
    If Gru=0 then Zustand:=Fliegend;

    Inc(Grl,Level[L2Y-1,L1X]);
    Inc(Grl,Level[L2Y-2,L1X]);
    Inc(Grr,Level[L2Y-1,L2X]);
    Inc(Grr,Level[L2Y-2,L2X]);

    Gr:=Grl OR Grr OR Gru;

    If Gr>0 then Begin
      If ((Gru>0) AND (Grav=1))  then Dec(YSpr);
      If ((Grl>0) AND (XPos=-1)) then Inc(XSpr);
      If ((Grr>0) AND (XPos=1))  then Dec(XSpr);
    End;
End;

Begin
{  Vorspann;{}
  InitAusgabe;
  Steuer:=1;
{  Write('Levelname : ');
  ReadLn(LevelName);{}
{  Write('Steuerung (0=Joystick/1=Tastatur/2=Maus) : ');
  ReadLn(Steuer);
  ClrScr;{}
{  If Steuer=1 then}
  InstallGameKey;
  If Steuer=2 then
    If InitMouse=0 then Halt Else HideMouse;
  InitMode(R320x200);
  PutScreenOff;
  SetScreenWith(640);
{  SetPalette(Pal);
  Ausblenden;}
  SplitScreen((400-SplitOff*2));
  YWin:=SplitOff;
  New(UZeile);
  For i:=0 to 3 do New(Sprite[i]);
  For i:=0 to 79 do New(Spider[i]);
  For i:=0 to 12 do New(Expeng[i]);
  New(Ground[0]); New(Ground[1]);
  For i:=0 to 25 do New(Sprites[i]);  {****************}
  For i:=0 to 9 do New(SkorpAnim[0,i]);
  For i:=0 to 9 do New(SkorpAnim[1,i]);
  For i:=0 to 9 do New(SkorpAnim[2,i]);
  For i:=0 to 9 do New(SkorpAnim[3,i]);
  For i:=0 to 12 do New(FlederAnim[i]);
  For i:=0 to 11 do New(MauerSeq[i]);
  LodeAllSprites;                     { Palette und Sprites laden }
  SpinZeiger:=0;
  FlederZeiger:=0;
  IstHERO:=False;
  FlaschenZeiger:=0;
  SkorpionZeiger:=0;
  MauerZeiger:=0;
  KBuschZeiger:=0;
  GBuschZeiger:=0;
{  Load('C:\HEROCONS\TEST1');{}
  Load('First1');{}
{  Load(LevelName);{}
  Energie:=76;           { >=136 Energie = vielfaches von 34 }
  EE:=Energie shr EnergieTeiler;
  Kerosin:=2032;         { >=2432 }
  KE:=Kerosin shr KerosinTeiler;
  Schussmenge:=54;       { >=54   }
  SE:=Schussmenge shr SchussTeiler;
  AnzBomb:=7;
  Aufbau;
  i:=0; SCnt:=0;
  SetHero(HeroKoord.X,HeroKoord.Y);
  SetWinPos(Page[P],SplitOff);{}
  Einblenden;
  Schuss:=FALSE;
  IstBomb:=FALSE;
  Poff:=FALSE;
  KrachBum:=FALSE;
  Zustand:=Fahrend;
  XPos:=0; YPos:=0;
  z:=0;

  YWin:=YSpr-100;
  If YWin<SplitOff then YWin:=SplitOff;
  If YWin>(199+SplitOff) then YWin:=199+SplitOff;
  SetWinPos(Page[P],YWin);
  PutScreenOn;

  Repeat
    Eingabe(Steuer);
    XSpr:=XSpr+XPos;
    Grav:=YPos+YPos+1;
    If YPos=-1 then Zustand:=Fliegend;
    YSpr:=YSpr+Grav;

    If Zustand=Fliegend then FlugSteuerung
    Else FahrSteuerung;

    MoveHero(XSpr,YSpr);

    If Schuss then Begin
      XPeng:=XPeng+LiRe+LiRe;
      Wusch(XPeng,YPeng);
    End;

    If IstBomb then Dec(BombCount);

    If Kollision in [130..255] then Begin
      Dec(Energie);
      i:=Beruehrt(XSpr,YSpr);
      If (i>0) AND (i<>3) then Stirb(i);
      If Energie=0 then Stirb(0);
      EE:=Energie shr EnergieTeiler;
      VLine(105+EE,5,9,0);
    End;
    Kollision:=0;

    YWin:=YSpr-100;
    If YWin<SplitOff then YWin:=SplitOff;
    If YWin>(199+SplitOff) then YWin:=199+SplitOff;
    SetWinPos(Page[P],YWin);

    P:=1-P;
    If XSpr<2 then LinksRaus;
    If (IstBomb AND (BombCount=0)) then ShowWand;
    If Steuer=0 then Begin
      If (Fire(2) AND (Zustand=Fahrend) AND (IstBomb=FALSE)
                  AND (AnzBomb>0)) then PutBomb;
      If Fire(1) then
        If ((Not Schuss) AND (Schussmenge>0) AND (Poff=FALSE)) then Peng;
    End;
    If Steuer=1 then Begin
      If (TasFeld[48] AND (Zustand=Fahrend) AND (IstBomb=FALSE)
                  AND (AnzBomb>0)) then PutBomb;
      If TasFeld[57] then
        If ((Not Schuss) AND (Schussmenge>0) AND (Poff=FALSE)) then Peng;
    End;
    If Steuer=2 then Begin
      If ((WhichButton=2) AND (Zustand=Fahrend) AND (IstBomb=FALSE)
                  AND (AnzBomb>0)) then PutBomb;
      If WhichButton=1 then
        If ((Not Schuss) AND (Schussmenge>0) AND (Poff=FALSE)) then Peng;
    End;
    If Kerosin=0 then
      If P=1 then Begin
        Inc(z);
        z:=z AND 7;
        If z=7 then Begin
          Dec(Energie);
          If Energie=0 then Stirb(0);
          EE:=Energie shr EnergieTeiler;
          VLine(105+EE,5,9,0);
        End;
      End;
    If (Tasfeld[29] AND Tasfeld[56] AND Tasfeld[83]) then Begin
      Ausblenden;
      Einblenden;
    End;
    If Tasfeld[59] then Begin
      Delay(100);
      If Tasfeld[59]=False then
        If WasSpielt<>NoTune then Begin
          SoundOut:=WasSpielt;
          WasSpielt:=NoTune;
        End Else
        Begin
          WasSpielt:=SoundOut;
        End;
    End;
    If Tasfeld[25] then Begin
      Delay(100);
      Repeat Until Tasfeld[25];
      Delay(100);
    End;
    If (TasFeld[1] AND TasFeld[29]) then Begin
      If Tasfeld[61] then Begin
        Energie:=136;          { >=136 Energie = vielfaches von 34 }
        EE:=Energie shr EnergieTeiler;
        Block(105,5,105+EE,9,253); Block(105+EE,5,139,9,0);
      End;
      If Tasfeld[60] then Begin
        Kerosin:=2432;         { >=2432 }
        KE:=Kerosin shr KerosinTeiler;
        Block(26,5,26+KE,9,252); Block(26+KE,5,64,9,0);
      End;
      If Tasfeld[62] then Begin
        Schussmenge:=54;       { >=54   }
        SE:=Schussmenge shr SchussTeiler;
        Block(171,5,171+SE,9,250); Block(171+SE,5,198,9,0);
      End;
      If Tasfeld[63] then Begin
        For AnzBomb:=0 to 6 do
          PutImNor(211+8*AnzBomb,3,Sprites[25]);
        AnzBomb:=7;
      End;
    End;
    If XSpr>294 then RechtsRaus;
    If YSpr<(2+SplitOff) then ObenRaus;
    If YSpr>(346+SplitOff) then UntenRaus;
    Repeat Until TimerTick<10;
    TimerTick:=TWert;
  Until XSpr<-2;
  CloseMode
End.