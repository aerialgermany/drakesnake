Program BitplanesIFF_to_RawBLD;

Uses HeroSpiel,Crt;

Type Screen   = Array[0..64000] of Byte;
     Buffer   = Array[0..64000] of Byte;

Const ScreenHigh = 200;
      ScreenWith = 320;

Var Coulor     : IFFStruct;
    x,y,x2,y2,
    Taste,Big,
    Big2       : Word;
    Name,
    KName      : String[30];
    f          : File;
    v,BitPl,P  : Byte;
    I,a,
    Breite,
    Hoehe      : Word;
    Pal        : Paltyp;
    Bild       : ^Screen;
    Bildschirm : ^Buffer;
    BildStruk  : IFFStruct;
{    Farb      : Byte;}
    ch         : Char;
    PicCount,
    XOffs,
    YOffs      : Word;

Procedure InitBitPlane(BitPlane : Byte);

Begin
    {*** Bit Mask Register beschreiben ***}
  Port[$3CE]:=8; Port[$3CF]:=1 shl (BitPlane AND 7);
    {*** Schreibmodus 2 / Lesemodus 0 ***}
  Port[$3CE]:=5; Port[$3CF]:=2+64;
End;

Procedure CloseBitPlane;

Begin
      {*** alle Register in umgekehrter Reihenfolge zurÅcksetzen ***}
    Port[$3CE]:=5; Port[$3CF]:=64;
    Port[$3CE]:=8; Port[$3CF]:=$FF;
End;

Procedure WriteToPlane(Ofset : Word; Wert : Byte);

Const Revers : Array[0..15] of Byte = (0,8,4,12,2,10,6,14,1,9,5,13,3,11,7,15);

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

Procedure WritePlane(Plane : Byte;Ofset : Word;Wert : Byte);

Const Revers : Array[0..15] of Byte = (0,8,4,12,2,10,6,14,1,9,5,13,3,11,7,15);

Var al,h,l : Byte;
    AdrOfs : Word;

Begin
    AdrOfs:=Ofset*2;
    h:=Wert AND $F; l:=Wert shr 4;
      {*** Bit Mask Register beschreiben ***}
    Port[$3CE]:=8; Port[$3CF]:=1 shl (Plane AND 7);
      {*** Schreibmodus 2 / Lesemodus 0 ***}
    Port[$3CE]:=5; Port[$3CF]:=2+64;

      {*** Prozessor Latches "laden" ***}
    al:=Mem[$A000:AdrOfs];
      {*** "Farbe" zur Adresse schreiben ***}
    Mem[$A000:AdrOfs]:=Revers[l];

      {*** Prozessor Latches "laden" ***}
    al:=Mem[$A000:AdrOfs+1];
      {*** "Farbe" zur Adresse schreiben ***}
    Mem[$A000:AdrOfs+1]:=Revers[h];

      {*** alle Register in umgekehrter Reihenfolge zurÅcksetzen ***}
    Port[$3CE]:=5; Port[$3CF]:=64;
    Port[$3CE]:=8; Port[$3CF]:=$FF;
End;

Procedure Aufbau;

Var OktOff : Word;

Begin
  With BildStruk do
    For y:=0 to Hoehe-1 do
      For a:=0 to BitPlanes-1 do
        Begin
          InitBitPlane(a);
          For x:=0 to 39 do
            WriteToPlane(y*40+x,Bild^[y*40*BitPlanes+a*40+x]);
{            WritePlane(a,y*40+x,Bild^[y*40*BitPlanes+a*40+x]);}
          CloseBitPlane;
        End;
End;

Procedure SavePicture(Name : String);

Var f      : File;

Begin
  Assign(f,Name+'.BLD');
  Rewrite(f,1);
  BlockWrite(f,BildStruk.Farben,768);
  For a:=0 to 3 do Begin
    Port[$3CE]:=4;
    Port[$3CF]:=a;
    For y:=0 to 199 do
      BlockWrite(f,Mem[$A000:(y*80)],80);
  End;
  Close(f);
End;

Procedure LoadPicture(Name : String);

Var f      : File;

Begin
  Assign(f,Name+'.BLD');
  Reset(f,1);
  BlockRead(f,BildStruk.Farben,768);
  For a:=0 to 3 do Begin
    Port[$3C4]:=2; Port[$3C5]:=1 shl a;
    Port[$3CE]:=4; Port[$3CF]:=a;
    For y:=0 to 199 do
      BlockRead(f,Mem[$A000:(y*80)],80);
  End;
  Close(f);
  SetPalette(BildStruk.Farben,256);
End;

Procedure ClearPic;

Begin
  Port[$3C4]:=2; Port[$3C5]:=15;
  FillChar(Mem[$A000:0000],$FFFF,0);
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
  SetPalette(BildStruk.Farben,256);
End;

Begin
  InitMode(R320x240);
  SetScreenWith(ScreenWith);
  ClearPic;

  New(Bild); New(Bildschirm);
  Name:='DSJUNGLE';
  LoadIFF(Name+'.LBM',Bild,BildStruk);
  If BildStruk.BitPlanes=5 then
    CalcAmigaPalette
  Else
    SetPalette(BildStruk.Farben,256);
  Aufbau;
{  SavePicture(Name);
  ClearPic;
  LoadPicture(Name);{}

  Dispose(Bild); Dispose(Bildschirm);

  Repeat Until KeyPressed;
  While KeyPressed do ch:=ReadKey;
  CloseMode;
End.