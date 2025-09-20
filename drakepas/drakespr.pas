Program Hero;

Uses HeroSpiel,Crt,Dos;

Type Buffer = Array[0..810] of Byte;
     Stat   = Array[0..4500] of Byte;
     SpriteTyp = Array[0..800] of Byte;
     SpriteBum = Array[0..579] of Byte;
     Spin      = Array[0..472] of Byte;
     Scorp     = Array[0..350] of Byte;
     Fled      = Array[0..190] of Byte;
     Mauer     = Array[0..900] of Byte;
     KoordTyp  = Record
                    X,Y : Word;
                  End;

Var i,x1,y1,x,
    x2,y2,y,
    BitPl,res,
    SCnt,
    Energie,
    Kerosin,
    Schussmenge,
    AnzBomb,
    WelcherScorp
                : Word;
    WieWeit     : Array[0..10] of Word;
    ch          : Char;
    P,Steuer,
    v,tal,tar,
    tao,tau,
    EE,KE,SE,
    Zustand,
    Detonation : Byte;
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
    XS,YS      : Array[1..10,0..1] of Word;
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
      LevelLinks      : String[8];
      LevelRechts     : String[8];
      LevelOben       : String[8];
      LevelUnten      : String[8];
      LevelName       : String[8];
      Zahl            : String[2];
      Sprites         : Array[0..25] of ^SpriteTyp;
      SpinZeiger,
      FlederZeiger,
      FlaschenZeiger,
      SkorpionZeiger,
      MauerZeiger,
      KBuschZeiger,
      GBuschZeiger,
      XPeng,YPeng    : Word;
      SpinKoord,
      FlederKoord,
      FlaschenKoord,
      SkorpionKoord,
      MauerKoord      : Array[1..10] of KoordTyp;
      IstSpin,
      IstSkorpion,
      IstFMaus,
      IstFlasche      : Array[1..10] of Boolean;
      KBuschKoord,
      GBuschKoord     : Array[1..20] of KoordTyp;
      IstHERO,IstBomb : Boolean;
      f               : File;
      HeroKoord       : KoordTyp;
      Spider          : Array[0..79] of ^Spin;
      SkorpAnim       : Array[0..3,0..9] of ^Scorp;
      FlederAnim      : Array[0..12] of ^Fled;
{      SkorpGround     : Array[1..10,0..1] of ^Scorp;}
      Schuss,
      Poff            : Boolean;
      LiRe            : ShortInt;

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

Procedure LoadAllSprites;

Begin
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
  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (drehen) }
    BlockRead(f,SkorpAnim[2,i]^,342);
  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (drehen) }
    BlockRead(f,SkorpAnim[3,i]^,342);

  For i:=0 to 12 do                  { Fledermausanimation 13 Pic's }
    BlockRead(f,FlederAnim[i]^,184);

  For i:=0 to 11 do
    BlockRead(f,MauerSeq[i]^,900);   { Maueranimation 12 Pic's }

  For i:=0 to 25 do                  { Levelsprites 26 StÅck }
    BlockRead(f,Sprites[i]^,800);

  Close(f);
End;

Procedure SpeicherSprites;

Begin
  Assign(f,'DRAKE.SPR');
  Rewrite(f,1);
  BlockWrite(f,Addr(Pal)^,768);     { Palette - 256*3 Werte }

  BlockWrite(f,UZeile^,4500);       { Statuszeile }

  BlockWrite(f,Sprite[0]^,810);      { Spritefigur Rechts mit Antrieb }
  BlockWrite(f,Sprite[1]^,810);      { Spritefigur Links mit Antrieb }
  BlockWrite(f,Sprite[2]^,810);      { Spritefigur Rechts }
  BlockWrite(f,Sprite[3]^,810);      { Spritefigur Links }

  For i:=0 to 79 do                  { Spinnenanimation 80 Pic's }
    BlockWrite(f,Spider[i]^,472);

  For i:=0 to 12 do                  { Explosionsanimation 13 Pic's }
    BlockWrite(f,Expeng[i]^,579);

  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (rechts) }
    BlockWrite(f,SkorpAnim[0,i]^,342);
  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (links) }
    BlockWrite(f,SkorpAnim[1,i]^,342);
  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (drehen) }
    BlockWrite(f,SkorpAnim[2,i]^,342);
  For i:=0 to 9 do                   { Skorpionanimation 10 Pic's (drehen) }
    BlockWrite(f,SkorpAnim[3,i]^,342);

  For i:=0 to 12 do                  { Fledermausanimation 13 Pic's }
    BlockWrite(f,FlederAnim[i]^,184);

  For i:=0 to 11 do
    BlockWrite(f,MauerSeq[i]^,900);   { Maueranimation 12 Pic's }

  For i:=0 to 25 do                  { Levelsprites 26 StÅck }
    BlockWrite(f,Sprites[i]^,800);

  Close(f);
End;

Begin
  Assign(f,'HERO256.PAL');
  Reset(f,1); BlockRead(f,Addr(Pal)^,768); Close(f);
  New(UZeile);
  For i:=0 to 3 do New(Sprite[i]);
  For i:=0 to 79 do New(Spider[i]);
  Assign(f,'SPIDER.ANM'); Reset(f,1);
  For i:=0 to 79 do BlockRead(f,Spider[i]^,472);  {472}
  Close(f);
  For i:=0 to 12 do New(Expeng[i]);
   Assign(f,'KABUMM.ANM'); Reset(f,1);
  For i:=0 to 12 do BlockRead(f,Expeng[i]^,579,res);
  if res<579 then Halt;
  Close(f);
  For i:=0 to 9 do New(SkorpAnim[0,i]);
  Assign(f,'SCORP_R.ANM'); Reset(f,1);
  For i:=0 to 9 do BlockRead(f,SkorpAnim[0,i]^,342);
  Close(f);
  For i:=0 to 9 do New(SkorpAnim[1,i]);
  Assign(f,'SCORP_L.ANM'); Reset(f,1);
  For i:=0 to 9 do BlockRead(f,SkorpAnim[1,i]^,342);
  Close(f);
  For i:=0 to 9 do New(SkorpAnim[2,i]);
  Assign(f,'SCORP_RL.ANM'); Reset(f,1);
  For i:=0 to 9 do BlockRead(f,SkorpAnim[2,i]^,342);
  Close(f);
  For i:=0 to 9 do New(SkorpAnim[3,i]);
  Assign(f,'SCORP_LR.ANM'); Reset(f,1);
  For i:=0 to 9 do BlockRead(f,SkorpAnim[3,i]^,342);
  Close(f);
  For i:=0 to 12 do New(FlederAnim[i]);
  Assign(f,'FLEDER.ANM'); Reset(f,1);
  For i:=0 to 12 do BlockRead(f,FlederAnim[i]^,184);
  Close(f);
  For i:=0 to 11 do New(MauerSeq[i]);
  Assign(f,'MAUER.ANM'); Reset(f,1);
  For i:=0 to 11 do BlockRead(f,MauerSeq[i]^,900);
  Close(f);

{  New(Ground[0]); New(Ground[1]);}
  Assign(f,'STATUSL.SPR'); Reset(f,1);
  BlockRead(f,UZeile^,4500,res); Close(f);
  Assign(f,'HERORVA.SPR'); Reset(f,1);
  BlockRead(f,Sprite[0]^,810,res); Close(f);
  Assign(f,'HEROLVA.SPR'); Reset(f,1);
  BlockRead(f,Sprite[1]^,810,res); Close(f);
  Assign(f,'HERORVO.SPR'); Reset(f,1);
  BlockRead(f,Sprite[2]^,810,res); Close(f);
  Assign(f,'HEROLVO.SPR'); Reset(f,1);
  BlockRead(f,Sprite[3]^,810,res); Close(f);
  For i:=0 to 25 do New(Sprites[i]);  {****************}
  For i:=1 to 26 do Begin
    Str(i,Zahl);
    Assign(f,'SPR'+Zahl+'.DAT');
    Reset(f,1);
    BlockRead(f,Sprites[i-1]^,800,res);
    Close(f);
  End;
  SpeicherSprites;
End.