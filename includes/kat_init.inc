Procedure MenueInitialisieren;

Var FMenu  : Text;
    FZeile : String[230];
    Zeich  : String;
    P,Zeil : Integer;

  Function LiesFarbe: Byte;

  Const Col : Array[0..16] of String =
                ('Black','Blue','Green','Cyan','Red','Magenta','Brown',
                 'LightGray','DarkGray','LightBlue','LightGreen',
                 'LightCyan','LightRed','LightMagenta','Yellow','White',
                 'Blink');

  Var i  : Byte;
      Da : Boolean;

  Begin      
    Da:=FALSE;
    i:=0;
    Repeat
      If Pos(Col[i],FZeile)>0 then
        Da:=TRUE
      Else
        Inc(i);
    Until Da OR (i>16);
    If NOT Da then
      Begin
        Close(FMenu);
        WriteLn(#7);
        WriteLn('Fehler in Zeile ',Zeil,' :');
        WriteLn(FZeile);
        Halt;
      End;
    If Pos(Col[16],FZeile)>0 then
      LiesFarbe:=i+128
    Else
      LiesFarbe:=i;
  End;

  Function LiesString: String;

  Var ZStr : String;

  Begin
    ZStr:=FZeile;
    If Pos(#39,ZStr)=0 then
      Begin
        Close(FMenu);
        WriteLn(#7);
        WriteLn('Fehler in Zeile ',Zeil,' :');
        WriteLn(FZeile);
        Halt;
      End;
    Delete(ZStr,1,Pos(#39,ZStr));
    If Pos(#39,ZStr)=0 then
      Begin
        Close(FMenu);
        WriteLn(#7);
        WriteLn('Fehler in Zeile ',Zeil,' :');
        WriteLn(FZeile);
        Halt;
      End;
    Delete(ZStr,Pos(#39,ZStr),(Length(ZStr)-Pos(#39,ZStr)+1));
    LiesString:=ZStr;
  End;

  Function AnzahlZeichen(ZeichenK : String; Zeich : Char): Byte;

  Var Zeil : String;
      i    : Byte;

  Begin
    Zeil:=ZeichenK;
    i:=0;
    While Pos(Zeich,Zeil)>0 do
      Begin
        Inc(i);
        Delete(Zeil,Pos(Zeich,Zeil),1);
      End;
    AnzahlZeichen:=i;
  End;

  Function SuchFarben(SuchStr : String): Byte;

  Begin
    While (Pos(SuchStr,FZeile)=0) AND (NOT Eof(FMenu)) do
      Begin
 	Inc(Zeil);
        ReadLn(FMenu,FZeile);
      End;
    SuchFarben:=LiesFarbe;
  End;

Begin
  Zeil:=0;
  If NOT CheckFile('SHAREKAT.INI') then
    Begin
      WriteLn(#7,'Initialisierungsfile (SHAREKAT.INI) nicht gefunden !');
      Halt;
    End;
  FZeile:='';
  Assign(FMenu,'SHAREKAT.INI');
  Reset(FMenu);
  AktivText    :=SuchFarben('AktivText=');
  AktivGrund   :=SuchFarben('AktivGrund=');
  NormalText   :=SuchFarben('NormalText=');
  NormalGrund  :=SuchFarben('NormalGrund=');
  Untergrund1  :=SuchFarben('Untergrund1=');
  Untergrund2  :=SuchFarben('Untergrund2=');
  SchattenText :=SuchFarben('SchattenText=');
  SchattenGrund:=SuchFarben('SchattenGrund=');
  WarnungText  :=SuchFarben('WarnungText=');
  WarnungGrund :=SuchFarben('WarnungGrund=');
  KopfText     :=SuchFarben('KopfText=');
  KopfGrund    :=SuchFarben('KopfGrund=');
  BestellText  :=SuchFarben('BestellText=');
  BestellGrund :=SuchFarben('BestellGrund=');

  MonoAktivText    :=SuchFarben('MonoAktivText=');
  MonoAktivGrund   :=SuchFarben('MonoAktivGrund=');
  MonoNormalText   :=SuchFarben('MonoNormalText=');
  MonoNormalGrund  :=SuchFarben('MonoNormalGrund=');
  MonoUntergrund1  :=SuchFarben('MonoUntergrund1=');
  MonoUntergrund2  :=SuchFarben('MonoUntergrund2=');
  MonoSchattenText :=SuchFarben('MonoSchattenText=');
  MonoSchattenGrund:=SuchFarben('MonoSchattenGrund=');
  MonoWarnungText  :=SuchFarben('MonoWarnungText=');
  MonoWarnungGrund :=SuchFarben('MonoWarnungGrund=');
  MonoKopfText     :=SuchFarben('MonoKopfText=');
  MonoKopfGrund    :=SuchFarben('MonoKopfGrund=');
  MonoBestellText  :=SuchFarben('MonoBestellText=');
  MonoBestellGrund :=SuchFarben('MonoBestellGrund=');

  While (Pos('GrundMuster=',FZeile)=0) AND (NOT Eof(FMenu)) do
    Begin
      Inc(Zeil);	
      ReadLn(FMenu,FZeile);
    End;
  Zeich:=LiesString;
  GrundMuster:=Zeich[1];

  While (Pos('Adresse=',FZeile)=0) AND (NOT Eof(FMenu)) do
    Begin
      Inc(Zeil);
      ReadLn(FMenu,FZeile);
    End;
  For P:=0 to 6 do
    Begin
      Inc(Zeil);	
      ReadLn(FMenu,FZeile);
      Adresse[P]:=LiesString;
    End;

  While (Pos('MenuLeiste=',FZeile)=0) AND (NOT Eof(FMenu)) do
    Begin 
      Inc(Zeil); 
      ReadLn(FMenu,FZeile);
    End;
  P:=0;
  Repeat
    Inc(Zeil); 
    ReadLn(FMenu,FZeile);
    If Length(FZeile)>0 then
      MenuLeiste[P]:=LiesString;
    Inc(P);
  Until (Length(FZeile)=0) OR (P>MaxMenuAnzahl);
  MenuAnzahl:=P-1;

  While (Pos('SubMenus=',FZeile)=0) AND (NOT Eof(FMenu)) do
    Begin
      Inc(Zeil);
      ReadLn(FMenu,FZeile);
    End;
  For P:=0 to MenuAnzahl-1 do
    Begin
      Inc(Zeil);
      ReadLn(FMenu,FZeile);
      SubMenus[P]:=LiesString;
      AnzSubMenus[P]:=AnzahlZeichen(SubMenus[P],'|')+1;
    End;

  While (Pos('Files=',FZeile)=0) AND (NOT Eof(FMenu)) do
    Begin
      Inc(Zeil);
      ReadLn(FMenu,FZeile);
    End;
  P:=0;
  Repeat 
    Inc(Zeil);
    ReadLn(FMenu,FZeile);
    If Length(FZeile)>0 then
      Files[P]:=LiesString;
    Inc(P);
  Until (Length(FZeile)=0) OR (P>MaxAnzFiles);

  While (Pos('Schlussmeldung=',FZeile)=0) AND (NOT Eof(FMenu)) do
    Begin
      Inc(Zeil);
      ReadLn(FMenu,FZeile);
    End;
  Schlussmeldung:=LiesString;
  While (Pos('File_Bestellung=',FZeile)=0) AND (NOT Eof(FMenu)) do
    Begin
      Inc(Zeil);
      ReadLn(FMenu,FZeile);
    End;
  File_Bestellung:=LiesString;
  While (Pos('BestellungTextFile=',FZeile)=0) AND (NOT Eof(FMenu)) do
    Begin
      Inc(Zeil);  
      ReadLn(FMenu,FZeile);
    End;
  BestellungTextFile:=LiesString;

  Close(FMenu);
End;
