Program Vollversion_Drake_Snake;

Uses GrafikOn,ScreenFX,Drake_FX,DrakGame,DS_Begin,Crt,DieSeq,
     C_Eingab,IntMusik,DS_Ende,DrakeSFX,DrakeVOC,WatSound,Crt2Unit;

Type LevelTyp = Record
                  Code        : String[11];
                  Filename    : String[8];
                  Anfangsbild : String[8];
                  Schwierigk  : Byte;
                  Energie     : Word;
                  Fuel        : Word;
                  AnzSchuss   : Word;
                  AnzBomben   : Word;
                  Zeitlimit   : Word;
                End;
     Buchstaben = Array[0..419] of Byte;

Const LastLevel             = 5;
      AktuellerLevel : Byte = 1;
      Levels : Array[1..LastLevel] of LevelTyp =
((Code:'DRAKELEVEL1';Filename:'LEVEL1';Anfangsbild:'LVL1DRSN';Schwierigk:117;
  Energie:136;Fuel:2432;AnzSchuss:54;AnzBomben:7;Zeitlimit:3600),

 (Code:'DRAKELEVEL2';Filename:'LEVEL2';Anfangsbild:'LVL1DRSN';Schwierigk:117;
  Energie:136;Fuel:2432;AnzSchuss:54;AnzBomben:7;Zeitlimit:3600),

 (Code:'DRAKELEVEL3';Filename:'LEVEL3';Anfangsbild:'LVL2DRSN';Schwierigk:117;
  Energie:136;Fuel:2432;AnzSchuss:54;AnzBomben:7;Zeitlimit:3600),

 (Code:'DRAKELEVEL4';Filename:'LEVEL4';Anfangsbild:'LVL2DRSN';Schwierigk:117;
  Energie:136;Fuel:2432;AnzSchuss:54;AnzBomben:7;Zeitlimit:3600),

 (Code:'DRAKELEVEL5';Filename:'LEVEL5';Anfangsbild:'LVL2DRSN';Schwierigk:117;
  Energie:136;Fuel:2432;AnzSchuss:54;AnzBomben:7;Zeitlimit:3600));


Var SpielSofort : Boolean;
    Geschafft   : Byte;
    MenuWert    : Byte;
    BildStruk   : Paltyp;
    ch          : Char;
    p           : Pointer;
    ParStr1     : String;
    Steuerung   : Byte;
    i           : Word;
    Kartentyp   : SoundKarte;
    Mon         : Text;
    CodeFont    : Array[0..35] of ^Buchstaben;
    BevorVorspann : Pointer;

Procedure ClearVideoMem(Menge : Word;Was : Byte);

  Var Pl : Byte;

  Begin
    Pl:=Was AND 15;
    Port[$3C4]:=2;
    Port[$3C5]:=Pl;
    FillChar(Mem[$A000:0000],Menge,0);
  End;

Procedure LoadCFont;

Var f : File;
    i : Byte;

Begin
  For i:=0 to 35 do
    New(CodeFont[i]);
  Assign(f,'CODEFONT.FNT');
  Reset(f,1);
  For i:=0 to 35 do
    BlockRead(f,CodeFont[i]^,418);
  Close(f);
End;

Procedure DisposeCFont;

Var i : Byte;

Begin
  For i:=0 to 35 do
    Dispose(CodeFont[i]);
End;

Procedure WriteCode(CodeStr : String);

Var i : Integer;

Begin
  For i:=1 to 11 do
    If CodeStr[i]>':' then
      PutImOut(8+i*19,8,CodeFont[(Ord(CodeStr[i])-65) MOD 36])
    Else
      PutImOut(8+i*19,8,CodeFont[(Ord(CodeStr[i])-22) MOD 36]);
End;

Procedure ErrorMessage(Message : String);

Begin
  TextMode(CO80);
  WriteLn(Message,#7);
  Halt;
End;

Procedure Zwischenbild(ZName,LevelCode : String);

Var z,i : Word;

Begin
  InitGraphicMode(S320x200_256);
  While KeyPressed do ch:=ReadKey;
  SetScreenWith(320);
  PutScreenOff;
  SetWinPos(0,200);
  ClearVideoMem($FFFF,15);
  If KeyPressed then
    If ReadKey=#27 then
      Begin
        SplitScreen(400);
        While KeyPressed do ch:=ReadKey;
        Exit;
      End;
  LoadMultiColour(ZName+'.BLD',BildStruk,0,0);
  LoadCFont;
  WriteCode(LevelCode);
  DisposeCFont;
  If KeyPressed then
    If ReadKey=#27 then
      Begin
        SplitScreen(400);
        While KeyPressed do ch:=ReadKey;
        Exit;
      End;
  SetPalette(BildStruk);
  PutScreenOn;
  For i:=0 to 200 do Begin
{    SetWinPos(0,i);}
    SplitScreen(400-(i*2));
    Delay(2);
    If KeyPressed then
      If ReadKey=#27 then
        Begin
          SplitScreen(400);
          While KeyPressed do ch:=ReadKey;
          Exit;
        End;
  End;
  z:=0;
  Repeat
    Delay(1);
    Inc(z);
  Until ((KeyPressed) OR (z>2500));
  While KeyPressed do ch:=ReadKey;
  For i:=200 downto 0 do Begin
{    SetWinPos(0,i);}
    SplitScreen(400-(i*2));
    Delay(2);
    If KeyPressed then
      If ReadKey=#27 then
        Begin
          SplitScreen(400);
          While KeyPressed do ch:=ReadKey;
          Exit;
        End;
  End;
{  CloseGraphicMode}
End;

Function LoadMenu: Byte;

Var ch    : Char;
    a,x,y : Word;
    Zeich : String;

Begin
  InitGraphicMode(S320x240_256);
  PutScreenOff;
  SetScreenWith(320);
  SetWinPos(0,0);
  ClearVideoMem($FFFF,15);
  LoadAmiga('DRAKEMEN.BLD',BildStruk,0,240);
  PutScreenOn;
  SetPalette(BildStruk);
  For y:=0 to 120 do Begin
    For x:=(120-y) to (199+y) do Begin
      SetPoint(x,120-y,GetPoint(x,360-y));
      SetPoint(x,119+y,GetPoint(x,y+359))
    End;
    For a:=(120-y) to (120+y) do Begin
      SetPoint((120-y),a,GetPoint((120-y),a+240));
      SetPoint((199+y),a,GetPoint((199+y),a+240))
    End
  End;
  Repeat
    Repeat Until KeyPressed;
    While KeyPressed do ch:=ReadKey;
  Until ch in ['1'..'3'];
  For y:=120 downto 0 do Begin
    For x:=(120-y) to (199+y) do Begin
      SetPoint(x,120-y,0);
      SetPoint(x,119+y,0)
    End;
    For a:=(120-y) to (120+y) do Begin
      SetPoint((120-y),a,0);
      SetPoint((199+y),a,0)
    End
  End;
  LoadMenu:=Ord(ch)-48;
End;

Procedure ProgrammBeenden;

Begin
{  ResetInt; {WarmBOOT;}
  With Kartentyp do
    Abspann(BasisAdresse,InterruptNr,Karte);
  CloseGraphicMode;
  TextMode(CO80);
  Halt(0);
End;

Procedure ProgrammAbbrechen;

Begin
  If Kartentyp.Karte>0 then
    CloseMusik;
  If Kartentyp.Karte>1 then
    CloseDrakeSFX;
  CloseGraphicMode;
  TextMode(CO80);
  WriteLn('Bis zum n„chsten mal !');
  Halt(0);
End;

Procedure SpieleLevel;

Begin
  If AktuellerLevel>LastLevel then
    Begin
      If Kartentyp.Karte>1 then
        CloseDrakeSFX;
      CloseMusik;
      ProgrammBeenden;
    End
  Else
    With Levels[AktuellerLevel] do
      Begin
        Zwischenbild(Anfangsbild,Code);
        If Kartentyp.Karte>0 then
          PlayMusik;
        Geschafft:=
          DrakeSnakeSpiel(Filename,'Drake',Steuerung,Schwierigk,Energie,Fuel,
                          AnzSchuss,AnzBomben,Zeitlimit);
        If Kartentyp.Karte>0 then
          PauseMusik(FALSE);
        If Geschafft>0 then
          Begin
            DieHard(Geschafft-1);
            SpielSofort:=FALSE;
          End
        Else
          Begin
            Inc(AktuellerLevel);
            SpielSofort:=TRUE;
          End;
      End;
End;

Procedure CodeEingabe;

Var CodeIndex : Integer;
    Eingabe   : String[12];

Begin
  Eingabe:=WelcherCode;
  CodeIndex:=1;
  While (CodeIndex<=LastLevel) AND (Levels[CodeIndex].Code<>Eingabe)do
    Inc(CodeIndex);
  If CodeIndex<=LastLevel then
    Begin
      AktuellerLevel:=CodeIndex;
      SpielSofort:=TRUE;
    End
  Else
    SpielSofort:=FALSE;
End;

Begin
  Steuerung:=1;
  WelcheSoundkarte(Kartentyp);
  If Kartentyp.Karte>1 then
    With KartenTyp do
      Soundkarten_Daten(BasisAdresse,InterruptNr,Karte-2);
  If ParamCount>0 then
    Begin
      ParStr1:=ParamStr(1);
      If ParStr1[1]='/' then
        Delete(ParStr1,1,1);
      For i:=1 to Length(ParStr1) do
        ParStr1[i]:=UpCase(ParStr1[i]);
      If ParStr1='?' then
        Begin
          WriteLn('Drake Snake & the secret Crypt - Version 1.5 '+
                  '(Registrierte Version)',#13,#10);
          WriteLn('M”gliche Parameter :');
          WriteLn(' /Maus     (Maussteuerung)');
          WriteLn(' /Joystick (Joysticksteuerung)');
          WriteLn(' /Tastatur (Tastatursteuerung'+
                  ' - Voreinstellung)');
          WriteLn(' /BIOS');
          Halt;
        End;
      If ParStr1='MAUS' then
        Begin
          Steuerung:=2;
        End;
      If ParStr1='JOYSTICK' then
        Begin
          Steuerung:=0;
        End;
      If ParStr1='TASTATUR' then
        Begin
          Steuerung:=1;
        End;
      If ParStr1='BIOS' then
        Begin
          DirectHardware:=FALSE;
        End;
      If ParamCount>1 then
        Begin
          ParStr1:=ParamStr(2);
          If ParStr1[1]='/' then
            Delete(ParStr1,1,1);
          If ParStr1='BIOS' then
            Begin
              DirectHardware:=FALSE;
            End;
        End;
    End;
  Mark(BevorVorspann);
  With Kartentyp do
    Vorspann(BasisAdresse,InterruptNr,Karte);
  Release(BevorVorspann);
  If Kartentyp.Karte>0 then
    InitMusik($388)
  Else
    InitMusik(0);
  If Kartentyp.Karte>0 then
    LoadMusik('DRAKE2');
  If Kartentyp.Karte>1 then
    InitDrakeSFX;
  MenuWert:=0; Geschafft:=100;
{  AssignCrt2(Mon);}
  SpielSofort:=FALSE;
  LoadCFont;
  Repeat
    If SpielSofort then
      MenuWert:=1
    Else
      MenuWert:=LoadMenu;
    Case MenuWert of
      1 : Repeat
            SpieleLevel;
          Until Geschafft>0;
      2 : CodeEingabe;

{            If WelcherCode=LevelCodes[1] then
              Geschafft:=0;}
      3 : ProgrammAbbrechen;
    End;
  Until 1=0;
End.
