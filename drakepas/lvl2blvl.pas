Program LevelToBiglevel;

Uses Crt;

Type Buffer = Array[0..810] of Byte;
     BuffBild  = Array[0..65533] of Byte;
     KoordTyp  = Record
                    X,Y : Word;
                  End;

Const IstBild  : Boolean = False;
      BildName : String[8] = 'nothing';
      LevelX = 20;
      LevelY = 28;

Var i,x,y,BildX,
    BildY           : Word;
    ch              : Char;
    Level           : Array[0..LevelY-1,0..LevelX-1] of Byte;
    LevelLinks      : String[8];
    LevelRechts     : String[8];
    LevelOben       : String[8];
    LevelUnten      : String[8];
    LevelName       : String[8];
    SpinZeiger,
    FlederZeiger,
    FlaschenZeiger,
    SkorpionZeiger,
    MauerZeiger,
    KBuschZeiger,
    GBuschZeiger    : Word;
    SpinKoord,
    FlederKoord,
    FlaschenKoord,
    SkorpionKoord,
    MauerKoord      : Array[1..10] of KoordTyp;
    IstAlles        : Array[1..16,1..5,1..10] of Boolean;
    KBuschKoord,
    GBuschKoord     : Array[1..20] of KoordTyp;
    f,S,D           : File;
    HeroKoord,
    DrakeKoord      : KoordTyp;
    Bild            : ^BuffBild;

    AnzLevels       : Array[1..25] of String[8];
    Anschluss       : Array[1..25,1..4] of Byte;
    FilePosition    : Array[1..25] of LongInt;
    Positionen,
    FileGroesse     : LongInt;
    ZaehlerL,
    AnzSubLevels,qs : Byte;
    Schlussbild     : String[8];
    CompleteLevel   : ^BuffBild;

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

Procedure LoadPic(Name : String);

Begin
  New(Bild);
  Assign(f,BildName+'.BLD');
  Reset(f,1);
  BlockRead(f,Bild^,65533,i);
  Close(f);
  Dispose(Bild);
End;

Procedure Load(Name : String);

Var f      : File;
    i      : Word;
    beit   : Byte;

Begin
  IstBild:=False;
  If CheckFile((Name+'.LVL'))=False then Begin
    Write(#7);
    WriteLn('File existiert nicht');
    Halt
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
End;

Begin
  WriteLn('Levelkonverter !');
  Write('Name des zu erstellenden Levels : '); ReadLn(LevelName);
  Write('Anzahl der Sub-Levels (max. 25): '); ReadLn(AnzSubLevels);
  For i:=1 to AnzSubLevels do Begin
    Repeat
      Write(i:2,'. Levelname : '); ReadLn(AnzLevels[i]);
      If CheckFile((AnzLevels[i]+'.LVL'))=False then
        WriteLn('Level nicht vorhanden !');
    Until CheckFile((AnzLevels[i]+'.LVL'))=True;
  End;

  For i:=1 to AnzSubLevels do Begin
    Load(AnzLevels[i]);
    If i=1 then Begin
      DrakeKoord.X:=HeroKoord.X;
      DrakeKoord.Y:=HeroKoord.Y;
    End;
    qs:=0;
    Repeat
      Inc(qs);
    Until ((Pos(AnzLevels[qs],LevelLinks)=1) OR (qs=AnzSubLevels));
    If Pos('fin',LevelLinks)=1 then qs:=0;
    Anschluss[i,1]:=qs;

    qs:=0;
    Repeat
      Inc(qs);
    Until ((Pos(AnzLevels[qs],LevelRechts)=1) OR (qs=AnzSubLevels));
    If Pos('fin',LevelRechts)=1 then qs:=0;
    Anschluss[i,2]:=qs;

    qs:=0;
    Repeat
      Inc(qs);
    Until ((Pos(AnzLevels[qs],LevelOben)=1) OR (qs=AnzSubLevels));
    If Pos('fin',LevelOben)=1 then qs:=0;
    Anschluss[i,3]:=qs;

    qs:=0;
    Repeat
      Inc(qs);
    Until ((Pos(AnzLevels[qs],LevelUnten)=1) OR (qs=AnzSubLevels));
    If Pos('fin',LevelUnten)=1 then qs:=0;
    Anschluss[i,4]:=qs;
  End;

  Positionen:=5+AnzSubLevels*8;
  FilePosition[1]:=Positionen;
  For i:=1 to AnzSubLevels-1 do Begin
   Assign(f,(AnzLevels[i]+'.LVL')); Reset(f,1);
   FileGroesse:=FileSize(f);
   Close(f);
   Positionen:=Positionen+FileGroesse-40;
   FilePosition[i+1]:=Positionen;
  End;

  New(CompleteLevel);
  Assign(D,LevelName+'.LVL');
  Rewrite(D,1);
  BlockWrite(D,AnzSubLevels,1);
  BlockWrite(D,DrakeKoord.X,2);
  BlockWrite(D,DrakeKoord.Y,2);
  BlockWrite(D,Anschluss[1,1],(AnzSubLevels*4));
  BlockWrite(D,FilePosition[1],(AnzSubLevels*4));
  For i:=1 to AnzSubLevels do Begin
    Assign(S,(AnzLevels[i]+'.LVL'));
    Reset(S,1);
    FileGroesse:=(FileSize(S)-40);
    BlockRead(S,CompleteLevel^,FileGroesse);
    BlockWrite(D,CompleteLevel^,FileGroesse);
    Close(S);
  End;
  Close(D);
  Dispose(CompleteLevel);
End.
