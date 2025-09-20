Program LevelConstruct;

Uses GrafikWindow,Graph,Mouse,Crt;

Type  SpriteTyp = Array[0..454] of Byte;
      KoordTyp  = Record
                    X,Y : Word;
                  End;

Const FarbeW : Array[0..15,0..2] of Byte =
                ((0,0,0),(16,16,16),(20,20,20),(28,28,28),(28,20,13),
                 (34,24,16),(42,30,20),(56,40,26),(9,24,17),(13,32,22),
                 (16,42,30),(22,57,40),(55,27,19),(32,16,63),(59,45,39),
                 (40,40,40));
      GitterFarbe  = 2;
      AuswahlFarbe = 12;
      GitterAktiv  : Byte = 1;
      AktSpr       : Word = 0;
      LevelLinks   : String[8] = 'fine';
      LevelRechts  : String[8] = 'fine';
      LevelOben    : String[8] = 'fine';
      LevelUnten   : String[8] = 'fine';
      BildName     : String[8] = 'nothing';
      LFileName    : String[8] = 'First1';
      BildBreite   : Word = 2;
      BildHoehe    : Word = 2;
      BildX        : Word = 0;
      BildY        : Word = 0;
      LevelX = 20;
      LevelY = 28;

Var   Level           : Array[0..LevelY-1,0..LevelX-1] of Byte;
      x,y,i,xpos,ypos,
      Taste,Taste1    : Word;
      result          : Byte;
      res,AktB,AktH   : Word;
      Zahl            : String[2];
      Sprites         : Array[0..24] of ^SpriteTyp;
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
      KBuschKoord,
      GBuschKoord     : Array[1..20] of KoordTyp;
      IstHERO,IstBild,
      Aktion          : Boolean;
      f               : File;
      HeroKoord       : KoordTyp;


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

Procedure RahmenMove(Breite,Hoehe : Integer);

Var  XM,YM,Buttn : Word;
     X2,Y2       : Integer;

Begin
  SetColor(15);
  SetWriteMode(XORPut);
  Repeat
    GetMouse(XM,YM,Buttn);
    X2:=XM+Breite;
    Y2:=YM+Hoehe;
    Line(XM,YM,X2,YM);
    Line(X2,YM,X2,Y2);
    Line(X2,Y2,XM,Y2);
    Line(XM,Y2,XM,YM);
    WaitMouse;
    Line(XM,YM,X2,YM);
    Line(X2,YM,X2,Y2);
    Line(X2,Y2,XM,Y2);
    Line(XM,Y2,XM,YM);
  Until ButtonPressed;
{  Repeat Until ButtonPressed=False;}
  SetWriteMode(CopyPut);
End;

Procedure AktivAnzeige(Num,Farbe : Byte);

Var x,y : Word;

Begin
  x:=367+(Num Mod 5)*50;
  y:=47+(Num Div 5)*70;
  SetColor(Farbe);
  Line(x,y,x+44,y);
  Line(x+44,y,x+44,y+64);
  Line(x+44,y+64,x,y+64);
  Line(x,y+64,x,y);
End;

Procedure Update(MitGitter : Byte);

Var x,y : Word;

Begin
  SetFillStyle(1,Hintergrund);
  Bar(0,0,LevelX*16,LevelY*14);
  If MitGitter=1 then Begin
    SetColor(GitterFarbe);
    For y:=0 to LevelY-1 do
      For x:=0 to LevelX-1 do Begin
        Line(x*16,y*14,x*16+15,y*14);
        Line(x*16,y*14,x*16,y*14+13);
        Line(x*16,y*14+13,x*16+15,y*14+13);
        Line(x*16+15,y*14,x*16+15,y*14+13);
      End;
  End;
  For y:=0 to LevelY-1 do
    For x:=0 to LevelX-1 do
      Case Level[y,x] of
        5      : PutImage(x*16,y*14-2,Sprites[4]^,NormalPut);
        6..9   : PutImage(x*16,y*14,Sprites[Level[y,x]-1]^,NormalPut);
        14     : PutImage(x*16,y*14,Sprites[13]^,NormalPut);
        15     : PutImage(x*16-13,y*14,Sprites[14]^,NormalPut);
        16..18 : PutImage(x*16,y*14-1,Sprites[Level[y,x]-1]^,NormalPut);
        19..23 : PutImage(x*16,y*14,Sprites[Level[y,x]-1]^,NormalPut);
        24     : PutImage(x*16,y*14-1,Sprites[23]^,NormalPut);
        25     : PutImage(x*16,y*14-2,Sprites[24]^,NormalPut);
        30     : Begin
                   SetColor(7);
                   Line(x*16,y*14,x*16+15,y*14);
                   Line(x*16+15,y*14,x*16+15,y*14+13);
                   Line(x*16+15,y*14+13,x*16,y*14+13);
                   Line(x*16,y*14+13,x*16,y*14);
                 End;
      End;
  If IstBild then Begin
    SetColor(Red);
    Line(BildX,BildY,BildX+BildBreite-1,BildY);
    Line(BildX+BildBreite-1,BildY,BildX+BildBreite-1,BildY+BildHoehe-1);
    Line(BildX+BildBreite-1,BildY+BildHoehe-1,BildX,BildY+BildHoehe-1);
    Line(BildX,BildY+BildHoehe-1,BildX,BildY);
  End;
  If SpinZeiger>0 then
    For x:=1 to SpinZeiger do
      PutImage(SpinKoord[x].X,SpinKoord[x].Y,Sprites[0]^,NormalPut);
  If FlederZeiger>0 then
    For x:=1 to FlederZeiger do
      PutImage(FlederKoord[x].X,FlederKoord[x].Y,Sprites[1]^,NormalPut);
  If FlaschenZeiger>0 then
    For x:=1 to FlaschenZeiger do
      PutImage(FlaschenKoord[x].X,FlaschenKoord[x].Y,Sprites[3]^,NormalPut);
  If SkorpionZeiger>0 then
    For x:=1 to SkorpionZeiger do
      PutImage(SkorpionKoord[x].X,SkorpionKoord[x].Y,Sprites[10]^,NormalPut);
  If MauerZeiger>0 then
    For x:=1 to MauerZeiger do
      PutImage(MauerKoord[x].X,MauerKoord[x].Y,Sprites[9]^,NormalPut);
  If KBuschZeiger>0 then
    For x:=1 to KBuschZeiger do
      PutImage(KBuschKoord[x].X,KBuschKoord[x].Y,Sprites[12]^,NormalPut);
  If GBuschZeiger>0 then
    For x:=1 to GBuschZeiger do
      PutImage(GBuschKoord[x].X,GBuschKoord[x].Y,Sprites[11]^,NormalPut);
  If IstHERO=True then
    PutImage(HeroKoord.X,HeroKoord.Y,Sprites[2]^,NormalPut);
End;

Procedure Save;

Var f      : File;
    Name   : String[8];
    i      : Word;
    beit   : Byte;

Begin
  If IstHero then Begin
    HideMouse;
    Name:=Eingabe(290,100,33,'Filename dieses'+
                           ' Levels (8 Char.)',LFileName);
    LFileName:=Name;
    If CheckFile((Name+'.LVL'))=True then Begin
      Write(#7);
      If JaNeinWindow('File existiert bereits - File Åberschreiben ?')<>1
        then Begin
          ShowMouse;
          Exit
        End;
      End;
      Assign(f,(Name+'.LVL'));
      Rewrite(f,1);
      BlockWrite(f,Mem[Seg(Level):Ofs(Level)],(LevelX*LevelY));
      BlockWrite(f,SpinZeiger,2);
      If SpinZeiger>0 then
        For i:=1 to SpinZeiger do Begin
          BlockWrite(f,SpinKoord[i].X,2);
          BlockWrite(f,SpinKoord[i].Y,2)
        End;
      BlockWrite(f,FlederZeiger,2);
      If FlederZeiger>0 then
        For i:=1 to FlederZeiger do Begin
          BlockWrite(f,FlederKoord[i].X,2);
          BlockWrite(f,FlederKoord[i].Y,2)
        End;
      BlockWrite(f,FlaschenZeiger,2);
      If FlaschenZeiger>0 then
        For i:=1 to FlaschenZeiger do Begin
          BlockWrite(f,FlaschenKoord[i].X,2);
          BlockWrite(f,FlaschenKoord[i].Y,2)
        End;
      BlockWrite(f,MauerZeiger,2);
      If MauerZeiger>0 then
        For i:=1 to MauerZeiger do Begin
          BlockWrite(f,MauerKoord[i].X,2);
          BlockWrite(f,MauerKoord[i].Y,2)
        End;
      BlockWrite(f,SkorpionZeiger,2);
      If SkorpionZeiger>0 then
        For i:=1 to SkorpionZeiger do Begin
          BlockWrite(f,SkorpionKoord[i].X,2);
          BlockWrite(f,SkorpionKoord[i].Y,2)
        End;
      BlockWrite(f,GBuschZeiger,2);
      If GBuschZeiger>0 then
        For i:=1 to GBuschZeiger do Begin
          BlockWrite(f,GBuschKoord[i].X,2);
          BlockWrite(f,GBuschKoord[i].Y,2)
        End;
      BlockWrite(f,KBuschZeiger,2);
      If KBuschZeiger>0 then
        For i:=1 to KBuschZeiger do Begin
          BlockWrite(f,KBuschKoord[i].X,2);
          BlockWrite(f,KBuschKoord[i].Y,2)
        End;
      If IstBild then Begin
        beit:=1;
        BlockWrite(f,beit,1);
        BlockWrite(f,BildX,2);
        BlockWrite(f,BildY,2);
        BlockWrite(f,BildName,9);
      End Else
      Begin
        beit:=0;
        BlockWrite(f,beit,1);
      End;
      BlockWrite(f,HeroKoord.X,2);
      BlockWrite(f,HeroKoord.Y,2);
      BlockWrite(f,LevelLinks,9);
      BlockWrite(f,LevelRechts,9);
      BlockWrite(f,LevelOben,9);
      BlockWrite(f,LevelUnten,9);
      Close(f);
      ShowMouse;
  End;
End;

Procedure Load;

Var f      : File;
    Name   : String[8];
    i      : Word;
    beit   : Byte;

Begin
  HideMouse;
  Name:=Eingabe(290,100,33,'Filename des'+
                         ' Levels (8 Char.)',LFileName);
  LFileName:=Name;
  If CheckFile((Name+'.LVL'))=False then Begin
    Write(#7);
    ShowMouse;
    Meldung('File existiert nicht');
    Exit
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
  End Else {}
    IstBild:=False;
  BlockRead(f,HeroKoord.X,2);
  BlockRead(f,HeroKoord.Y,2);
  BlockRead(f,LevelLinks,9);
  BlockRead(f,LevelRechts,9);
  BlockRead(f,LevelOben,9);
  BlockRead(f,LevelUnten,9);
  Close(f);
  If IstBild then Begin
    Assign(f,BildName+'.BLD');
    Reset(f,1);
    BlockRead(f,BildBreite,2);
    BlockRead(f,BildHoehe,2);
    Close(f);
  End;
  IstHERO:=True;
  Update(GitterAktiv);
  ShowMouse;
  End;
End;

Function LoadBild : Boolean;

Var f      : File;
    Name   : String[8];
    i      : Word;

Begin
  HideMouse;
  If CheckFile((BildName+'.BLD'))=False then Begin
    Write(#7);
    ShowMouse;
    Meldung('File existiert nicht');
    LoadBild:=False;
    Exit
  End Else
  Begin
  Assign(f,(BildName+'.BLD'));
  Reset(f,1);
  BlockRead(f,BildBreite,2);
  BlockRead(f,BildHoehe,2);
  Close(f);
  ShowMouse;
  LoadBild:=True;
  End;
End;


Begin
  LFileName:=LFileName+'1';
  For i:=0 to 24 do New(Sprites[i]);
  For y:=0 to 15 do
    For x:=0 to 3 do
      Farben[y,x]:=FarbeW[y,x];
  Init(True);
  For i:=1 to 25 do Begin
    Str(i,Zahl);
    Assign(f,'spr'+Zahl+'.dat');
    Reset(f,1);
    BlockRead(f,Sprites[i-1]^,455,res);
    Close(f);
  End;
  SpinZeiger:=0;
  FlederZeiger:=0;
  IstHERO:=False;
  IstBild:=False;
  FlaschenZeiger:=0;
  SkorpionZeiger:=0;
  MauerZeiger:=0;
  KBuschZeiger:=0;
  GBuschZeiger:=0;
  HideMouse;
  Hintergrund:= 0;
  HellerRand := 11;
  Vordergrund:= 10;
  DunklerRand:= 9;
  TextFarbe  := 0;
  For y:=0 to LevelY-1 do
    For x:=0 to LevelX-1 do
      Level[y,x]:=0;
  Update(GitterAktiv);
  For i:=0 to 24 do
    PutImage(370+(i Mod 5)*50,50+(i Div 5)*70,Sprites[i]^,NormalPut);
  RoomBlock(0,460,639,479);
  PutText(120,467,TextFarbe,'Levelkonstruktion fuer'+
                           ' "HERO"  V 1.6 / 1992 by M.K.');
  RoomBlock(360,0,440,15);
  PutText(370,4,TextFarbe,'M E N U');
  AktivAnzeige(AktSpr,AuswahlFarbe);
  ShowMouse;
  Repeat
    Repeat
      GetMouse(xpos,ypos,Taste);
    Until ButtonPressed=True;
    GetMouse(xpos,ypos,Taste1);
    Repeat Until ButtonPressed=False;
    Aktion:=False;
    If MouseInXY(360,0,440,15) then Begin         { MenÅbalken anwÑhlen }
      MenuBox(360,16,'Level laden|Level speichern|Undo|Neuaufbau'+
           '|Level Links|Level Rechts|Level Oben|Level Unten|'+
           'Gitter an/aus|Program beenden|Neu|Bild einbinden',result);
      If result in [0..4,9,11] then Begin
        HideMouse;
        CloseWindow;
        ShowMouse;
      End;
      Case result of
        1 : Load;
        2 : Save;
        3 : Begin
              Case AktSpr of
                0  : If SpinZeiger>0 then Dec(SpinZeiger);
                1  : If FlederZeiger>0 then Dec(FlederZeiger);
                3  : If FlaschenZeiger>0 then Dec(FlaschenZeiger);
                9  : If MauerZeiger>0 then Dec(MauerZeiger);
                10 : If SkorpionZeiger>0 then Dec(SkorpionZeiger);
                11 : If GBuschZeiger>0 then Dec(GBuschZeiger);
                12 : If KBuschZeiger>0 then Dec(KBuschZeiger);
                2  : IstHERO:=False;
              End;
              HideMouse;
              Update(GitterAktiv);
              ShowMouse;
            End;
        4 : Begin
              HideMouse;
              Update(GitterAktiv);
              ShowMouse;
            End;
        5 : Begin
              LevelLinks:=Eingabe(290,100,33,'Name des Linken'+
                                   ' Level (8 Char.)',LevelLinks);
              HideMouse;
              CloseWindow;
              ShowMouse;
            End;
        6 : Begin
              LevelRechts:=Eingabe(290,100,33,'Name des Rechten'+
                                   ' Level (8 Char.)',LevelRechts);
              HideMouse;
              CloseWindow;
              ShowMouse;
            End;
        7 : Begin
              LevelOben:=Eingabe(290,100,33,'Name des Oberen'+
                                   ' Level (8 Char.)',LevelOben);
              HideMouse;
              CloseWindow;
              ShowMouse;
            End;
        8 : Begin
              LevelUnten:=Eingabe(290,100,33,'Name des Unteren'+
                                   ' Level (8 Char.)',LevelUnten);
              HideMouse;
              CloseWindow;
              ShowMouse;
            End;
        9 : Begin
              GitterAktiv:=1-GitterAktiv;
              HideMouse;
              Update(GitterAktiv);
              ShowMouse;
            End;
        10 : Begin
              If JaNeinWindow('Programm wirklich beenden ?')=1 then Begin
                CloseGraph;
                For i:=0 to 24 do Dispose(Sprites[i]);
                Halt;
              End;
              HideMouse;
              CloseWindow;
              ShowMouse;
            End;
        11 : Begin
              HideMouse;
              For y:=0 to LevelY-1 do
                For x:=0 to LevelX-1 do
                  Level[y,x]:=0;
              IstHero:=False;
              SpinZeiger:=0;
              FlederZeiger:=0;
              FlaschenZeiger:=0;
              SkorpionZeiger:=0;
              MauerZeiger:=0;
              KBuschZeiger:=0;
              GBuschZeiger:=0;
              Update(GitterAktiv);
              ShowMouse;
            End;
        12 : Begin
               BildName:=Eingabe(290,100,33,'Name des Bildes'
                                    ,BildName);
               HideMouse;
               CloseWindow;
               If LoadBild then Begin
                 HideMouse;
                 RahmenMove(BildBreite,BildHoehe);
                 GetMouse(x,y,Taste);
                 If (BildBreite+x)<=320 then
                   If (BildHoehe+y)<=392 then Begin
                     BildX:=x;
                     BildY:=y;
                     IstBild:=True;
                     Repeat Until ButtonPressed=False;
                     Aktion:=True;
                     SetColor(Red);
                     Line(BildX,BildY,BildX+BildBreite-1,BildY);
                     Line(BildX+BildBreite-1,BildY,BildX+BildBreite-1,
                       BildY+BildHoehe-1);
                     Line(BildX+BildBreite-1,BildY+BildHoehe-1,BildX,
                       BildY+BildHoehe-1);
                     Line(BildX,BildY+BildHoehe-1,BildX,BildY);
                     AktSpr:=29;
                   End Else
                     IstBild:=False
                 Else
                   IstBild:=False;
               End;
               ShowMouse;
             End;
      End;
    End Else
{    If Aktion=False then}
    Begin
    If MouseInXY(0,0,(LevelX-1)*16+15,(LevelY-1)*14+13) then Begin
      HideMouse;
      GetMouse(x,y,Taste);
      If Taste1=LeftButton then
      Case AktSpr of
        0   : Begin
                Inc(SpinZeiger);
                If SpinZeiger>10 then SpinZeiger:=10;
                SpinKoord[SpinZeiger].X:=x;
                SpinKoord[SpinZeiger].Y:=y;
                PutImage(x,y,Sprites[0]^,NormalPut);
              End;
        1   : Begin
                Inc(FlederZeiger);
                If FlederZeiger>10 then FlederZeiger:=10;
                FlederKoord[FlederZeiger].X:=x;
                FlederKoord[FlederZeiger].Y:=y;
                PutImage(x,y,Sprites[1]^,NormalPut);
              End;
        2   : Begin
                IstHERO:=True;
                HeroKoord.X:=x;
                HeroKoord.Y:=y;
                PutImage(x,y,Sprites[2]^,NormalPut);
              End;
        3   : Begin
                Inc(FlaschenZeiger);
                If FlaschenZeiger>10 then FlaschenZeiger:=10;
                FlaschenKoord[FlaschenZeiger].X:=x;
                FlaschenKoord[FlaschenZeiger].Y:=y;
                PutImage(x,y,Sprites[3]^,NormalPut);
              End;
        4..8 : Begin
                 Level[(y Div 14),(x Div 16)]:=AktSpr+1;
                 Case AktSpr of
                   4    : PutImage((x Div 16)*16,(y Div 14)*14-2,
                                    Sprites[AktSpr]^,NormalPut);
                   5..8 : PutImage((x Div 16)*16,(y Div 14)*14,
                                    Sprites[AktSpr]^,NormalPut);
                 End;
               End;
        9   : Begin
                Inc(MauerZeiger);
                If MauerZeiger>10 then MauerZeiger:=10;
                MauerKoord[MauerZeiger].X:=(x Div 16)*16+2;
                MauerKoord[MauerZeiger].Y:=(y Div 14)*14;
                PutImage((x Div 16)*16+2,(y Div 14)*14,
                           Sprites[9]^,NormalPut);
              End;
        10  : Begin
                Inc(SkorpionZeiger);
                If SkorpionZeiger>10 then SkorpionZeiger:=10;
                SkorpionKoord[SkorpionZeiger].X:=x;
                SkorpionKoord[SkorpionZeiger].Y:=y;
                PutImage(x,y,Sprites[10]^,NormalPut);
              End;
        11  : Begin
                Inc(GBuschZeiger);
                If GBuschZeiger>20 then GBuschZeiger:=20;
                GBuschKoord[GBuschZeiger].X:=x;
                GBuschKoord[GBuschZeiger].Y:=y;
                PutImage(x,y,Sprites[11]^,NormalPut);
              End;
        12  : Begin
                Inc(KBuschZeiger);
                If KBuschZeiger>20 then KBuschZeiger:=20;
                KBuschKoord[KBuschZeiger].X:=x;
                KBuschKoord[KBuschZeiger].Y:=y;
                PutImage(x,y,Sprites[12]^,NormalPut);
              End;
        13..29 : Begin
                 Level[(y Div 14),(x Div 16)]:=AktSpr+1;
                 Case AktSpr of
                   13 : PutImage((x Div 16)*16,(y Div 14)*14,
                                  Sprites[AktSpr]^,NormalPut);
                   14 : PutImage((x Div 16)*16-13,(y Div 14)*14,
                                  Sprites[AktSpr]^,NormalPut);
                   15..17 : PutImage((x Div 16)*16,(y Div 14)*14-1,
                                  Sprites[AktSpr]^,NormalPut);
                   18..22 : PutImage((x Div 16)*16,(y Div 14)*14,
                                  Sprites[AktSpr]^,NormalPut);
                   23     : PutImage((x Div 16)*16,(y Div 14)*14-1,
                                  Sprites[AktSpr]^,NormalPut);
                   24     : PutImage((x Div 16)*16,(y Div 14)*14-2,
                                  Sprites[AktSpr]^,NormalPut);
                   29     : Begin
                              SetColor(7);
                              Line((x Div 16)*16,(y Div 14)*14,
                                   (x Div 16)*16+15,(y Div 14)*14);
                              Line((x Div 16)*16+15,(y Div 14)*14,
                                   (x Div 16)*16+15,(y Div 14)*14+13);
                              Line((x Div 16)*16+15,(y Div 14)*14+13,
                                   (x Div 16)*16,(y Div 14)*14+13);
                              Line((x Div 16)*16,(y Div 14)*14+13,
                                   (x Div 16)*16,(y Div 14)*14);
                            End;
                 End;
               End;
      End Else
      Begin
        Level[(y Div 14),(x Div 16)]:=0;
        SetFillStyle(1,Hintergrund);
        Bar((x Div 16)*16,(y Div 14)*14,
          (x Div 16)*16+15,(y Div 14)*14+13);
      End;
      ShowMouse;
    End;
    If MouseInXY(367,47,611,391) then Begin
      GetMouse(x,y,Taste);
      HideMouse;
      AktivAnzeige(AktSpr,Hintergrund);
      x:=(x-367) Div 50;
      y:=(y-47) Div 70;
      AktSpr:=y*5+x;
      AktivAnzeige(AktSpr,AuswahlFarbe);
      If AktSpr in [0..3,9..12] then Begin
        AktB:=Sprites[AktSpr]^[1] shl 8 +Sprites[AktSpr]^[0];
        AktH:=Sprites[AktSpr]^[3] shl 8 +Sprites[AktSpr]^[2];
        If AktSpr=1  then Begin Inc(AktB,26); Inc(AktH,16); End;
        If AktSpr=10 then Inc(AktB,32);
        RahmenMove(AktB,AktH)
      End Else
        ShowMouse;
    End
    End;
  Until DunklerRand=217;
End.