Unit DS_Begin;

Interface

Uses Crt,FlyAfrik,Kart3Flg,PlanePic,GrafikOn;

Procedure Vorspann;

Implementation

Type  FarbHirestyp  = Array[0..47] of Byte;
      FarbLowrestyp = Array[0..767] of Byte;
      FuenfKB    = Array[0..5119] of Byte;
      SegBuffer = Array[0..2000] of Byte;

Const Transl : Array[34..154] of Byte = (62,59,59,59,59,62,59,59,59,59,
                                         61,74,59,63,73,64,65,66,67,68,
                                         69,70,71,72,60,60,59,59,59,59,
                                         59,00,01,02,03,04,05,06,07,08,
                                         09,10,11,12,13,14,15,16,17,18,
                                         19,20,21,22,23,24,25,59,64,59,
                                         63,59,63,26,27,28,29,30,31,32,
                                         33,34,35,36,37,38,39,40,41,42,
                                         43,44,45,46,47,48,49,50,51,59,
                                         60,59,59,59,59,57,59,59,55,59,
                                         59,59,59,59,59,59,59,59,52,59,
                                         59,59,59,59,56,59,59,59,59,53,54);
      Breiten : Array[0..74] of Byte = (3,3,3,3,3,3,3,3,2,3,3,3,3,3,3,
                                        3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
                                        3,2,3,3,2,3,3,2,3,3,3,3,3,3,3,
                                        2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
                                        3,3,3,3,3,3,3,3,3,3,3,3,3,3,3);
      Seiten = 9;
      SOFS   : Array[0..1] of Byte = (0,2);
                 {12345678901234567890123456}
      Story : Array[0..Seiten-1,0..8] of String =
               (('Wir schreiben den 1. April',
                 'des Jahres 1925.',
                 'Unser Held, Drake Snake, der',
                 'gerade in Phoenix/Kanada',
                 'Recherchen Åber einen',
                 'gewissen Dr.I.Jones anstellt,',
                 'erhÑlt unverhofft einen Brief',
                 'von dem Notar seines Vaters,',
                 'Jakob T. Ribber, in welchem'),
                ('Mr. Ribber ihm mitteilt, da· er',
                 'die wissenschaftlichen',
                 'Aufzeichnungen seines Vaters',
                 'geerbt hat.',
                 'Hierbei handelt es sich um',
                 'Nachforschungen Åber das',
                 'sagenhafte unterirdische',
                 'Reich der Pobo-Kata-Boppel',
                 'was soviel hei·t wie:'),
                ('Volk das nicht wei· warum es',
                 'sich so nennt. Dieses Reich',
                 'soll sich laut den Aufzeich-',
                 'nungen seines Vaters in der',
                 'NÑhe von dem Flu· Kotto/',
                 'Zentralafrika befinden.',
                 'Dort herrschte einmal ein',
                 'Kînig mit dem Namen Hechtel-',
                 'Zechteloboboppelkattel'),
                ('Er SOLL sagenhafte ReichtÅmer',
                 'in den Katakomben seines',
                 'Reiches versteckt haben.',
                 'Diese SchÑtze sind in',
                 'verwirrenden, gefÑhrlichen',
                 'Labyrinthen versteckt, aus',
                 'denen noch NIEMAND lebend',
                 'zurÅckgekehrt ist.',
                 ''),
                ('Nachdem Drake Snake sich das',
                 'Buch seines Vaters sorgfÑltig',
                 'durchgelesen hat, macht er',
                 'sich sogleich auf den Weg',
                 'zu dem geheimnisvollen Ort',
                 'um diesen sagenhaften Schatz',
                 'zu finden, damit er sich',
                 'endlich ein schîneres Leben',
                 'machen kann ...'),
                ('',
                 '',
                 '',
                 '@Drake hat nicht die',
                 '@geringste Ahnung auf was er',
                 '@sich da eingelassen hat',
                 '',
                 '',
                 ''),
                ('... Also nimmt er sich eine',
                 'regulÑre Linienmaschine nach',
                 'Zentralafrika und fliegt',
                 'dem Abenteuer entgegen.',
                 '',
                 '',
                 '',
                 '',
                 ''),
                ('@- PROGRAMMIERUNG -',
                 '',
                 '@Martin Keydel',
                 '',
                 '@- GRAFISCHE GESTALTUNG -',
                 '',
                 '@Markus Schrîder',
                 '@und',
                 '@Martin Keydel'),
                ('@- LEVELDESIGN -',
                 '',
                 '@Ralph Wiedemann',
                 '@und',
                 '@Martin Keydel',
                 '',
                 '',
                 '',
                 ''));
      Hires   = $12; Lores = $0D; MultiColour = $13; EndGraphic = $03;
      Spezial = 00;
      Screen = $A000;

Var Palette,
    Pal2,
    VFarb   : FarbHirestyp;
    LPalette,
    LPal2   : FarbLowrestyp;
    f       : File;
    p,SNr   : Byte;
    i,x,y,
    YPos    : Word;
    Multi   : Real;
    ch      : Char;
    Sinus   : Array[1..30] of Word;
    Ausgabe : String[40];
    ExitVar : Boolean;

Procedure WritePlane(Nr : Byte);

  Begin
    Nr:=Nr AND 3;
    Port[$3C4]:=2;
    Port[$3C5]:=1 shl Nr;
  End;

Procedure ReadPlane(Nr : Byte);

  Begin
    Nr:=Nr AND 3;
    Port[$3CE]:=4;
    Port[$3CF]:=Nr;
  End;

Procedure InitMode(Modus : Byte);

  Type  CRTCAr = Array[0..23] of Byte;

  Const CRTC320x240 : CRTCAr =
        ($5F,$4F,$50,$82,$54,$80,$0D,$3E,$00,$41,$00,$00,
         $00,$00,$00,$00,$EA,$AC,$DF,$28,$00,$E7,$06,$E3);

  Var   I : Byte;


  Begin
    If Modus>0 then Begin
      ASM
        xor    AH,AH      { Modus $12 }
        mov    AL,Modus
        int    10h
      End
    End Else
    Begin
      ASM
        xor    AH,AH
        mov    AL,13h
        int    10h
      End;
      Port[$3C4]:=4;      { Sequenzer-Controller : Memory Mode }
      Port[$3C5]:=6;
                            { Extended Memory ein, Odd/Even aus  }
      Port[$3D4] := $11;                { CRTC: Register $11     }
      Port[$3D5] := Port[$3D5] and $7F; { Schreibschutz aufheben }

      Port[$3C4]:=0;        { Seq.Controller: Reset Register }
      Port[$3C5]:=1;        { Synchroner Reset, Seq. aus     }
      Port[$3C2]:=$E3;      { 480 Scan-Zeilen }
      Port[$3C4]:=0;        { Synchroner Reset, Seq. ein     }
      Port[$3C5]:=3;
      For I := 0 to 23 do Begin  { CRTC-Registerwerte setzen }
        Port[$3D4]:=I;
        Port[$3D5]:=CRTC320x240[I];
      End;
    End;
  End;

Procedure Programmende;

Begin
  InitMode(EndGraphic);                     { Ende des Vorspanns }
  ExitVar:=True;
End;

Procedure SetHiresPalette(Farb : FarbHirestyp);

  Var Segment,
      Off         : Word;

  Begin
    Segment:=Seg(Farb);
    Off:=Ofs(Farb);
    ASM                        { Warten auf Bildwechsel }
      mov  DX,3DAh
    @WaitVS:
      in    AL,DX
      test  AL,08h
      jz    @WaitVS
      mov   DX,3C4h            { Bildschirm abschalten }
      mov   AL,1
      out   DX,AL
      inc   DX
      in    AL,DX
      or    AL,20h
      xchg  AL,AH
      dec   DX
      mov   AL,1
      out   DX,AX
      push  DS
      mov   DS,Segment
      mov   BX,Off
      cli

      mov   CX,6                    { 0,1,2,3,4,5 }
      mov   DX,3C8h
      mov   AL,0
      out   DX,AL
      inc   DX
    @PalZaehler:
      mov   AX,[BX]                 { Lade Rot und GrÅnanteil }
      out   DX,AL                   { Rot ausgeben }
      xchg  AL,AH
      out   DX,AL                   { GrÅn ausgeben }
      inc   BX                      { Zeiger erhîhen }
      inc   BX
      mov   AL,[BX]                 { Lade Blauanteil }
      out   DX,AL                   { Blau ausgeben }
      inc   BX                      { Zeiger erhîhen }
      loop  @PalZaehler

      mov   DX,3C8h                 { 20 }
      mov   AL,20
      out   DX,AL
      inc   DX
      mov   AX,[BX]                 { Lade Rot und GrÅnanteil }
      out   DX,AL                   { Rot ausgeben }
      xchg  AL,AH
      out   DX,AL                   { GrÅn ausgeben }
      inc   BX                      { Zeiger erhîhen }
      inc   BX
      mov   AL,[BX]                 { Lade Blauanteil }
      out   DX,AL                   { Blau ausgeben }
      inc   BX                      { Zeiger erhîhen }

      mov   DX,3C8h                 { 7 }
      mov   AL,7
      out   DX,AL
      inc   DX
      mov   AX,[BX]                 { Lade Rot und GrÅnanteil }
      out   DX,AL                   { Rot ausgeben }
      xchg  AL,AH
      out   DX,AL                   { GrÅn ausgeben }
      inc   BX                      { Zeiger erhîhen }
      inc   BX
      mov   AL,[BX]                 { Lade Blauanteil }
      out   DX,AL                   { Blau ausgeben }
      inc   BX                      { Zeiger erhîhen }

      mov   CX,8                    { 56,57,58,59,60,61,62,63 }
      mov   DX,3C8h
      mov   AL,56
      out   DX,AL
      inc   DX
    @PalZaehler1:
      mov   AX,[BX]                 { Lade Rot und GrÅnanteil }
      out   DX,AL                   { Rot ausgeben }
      xchg  AL,AH
      out   DX,AL                   { GrÅn ausgeben }
      inc   BX                      { Zeiger erhîhen }
      inc   BX
      mov   AL,[BX]                 { Lade Blauanteil }
      out   DX,AL                   { Blau ausgeben }
      inc   BX                      { Zeiger erhîhen }
      loop  @PalZaehler1

      sti
      pop   DS
      mov   DX,3C4h                 { Bildschirm wieder anschalten }
      mov   AL,1
      out   DX,AL
      inc   DX
      in    AL,DX
      and   AL,223
      xchg  AL,AH
      dec   DX
      mov   AL,1
      out   DX,AX
    End;
  End;

Procedure SetLowresPalette(Farb : FarbLowrestyp);

Var Segment,
    Off         : Word;

Begin
  Segment:=Seg(Farb);
  Off:=Ofs(Farb);
  ASM                        { Warten auf Bildwechsel }
    mov  DX,3DAh
  @WaitVS:
    in    AL,DX
    test  AL,08h
    jz    @WaitVS
    mov   DX,3C4h            { Bildschirm abschalten }
    mov   AL,1
    out   DX,AL
    inc   DX
    in    AL,DX
    or    AL,20h
    xchg  AL,AH
    dec   DX
    mov   AL,1
    out   DX,AX
    push  DS
    mov   DS,Segment
    mov   BX,Off
    mov   CX,32                   { 32 FarbeintrÑge }
    mov   DX,3C8h
    mov   AL,0
    cli
    out   DX,AL
    inc   DX
  @PalZaehler:
    mov   AX,[BX]                 { Lade Rot und GrÅnanteil }
    out   DX,AL                   { Rot ausgeben }
    xchg  AL,AH
    out   DX,AL                   { GrÅn ausgeben }
    inc   BX                      { Zeiger erhîhen }
    inc   BX
    mov   AL,[BX]                 { Lade Blauanteil }
    out   DX,AL                   { Blau ausgeben }
    inc   BX                      { Zeiger erhîhen }
    loop  @PalZaehler
    sti
    pop   DS
    mov   DX,3C4h                 { Bildschirm wieder anschalten }
    mov   AL,1
    out   DX,AL
    inc   DX
    in    AL,DX
    and   AL,223
    xchg  AL,AH
    dec   DX
    mov   AL,1
    out   DX,AX
  End;
End;

Procedure ClearVideoMem(Menge : Word;Was : Byte);

  Var Pl : Byte;

  Begin
    Pl:=Was AND 15;
    Port[$3C4]:=2;
    Port[$3C5]:=Pl;
    FillChar(Mem[$A000:0000],Menge,0);
  End;

Procedure ErrorMessage(Message : String);

Begin
  TextMode(CO80);
  WriteLn(Message,#7);
  Halt;
End;

Procedure LoadHires(BildName : String; Var Palette : Paltyp);

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
    SmallBuf   : Array[0..320] of Byte;
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
    If Spalte>79 then
      Begin
        Inc(Page);
        Spalte:=Spalte Mod 80;
      End;
    If Page>3 then
      Begin
        Inc(Zeile);
        Page:=Page Mod 4;
      End;
    InitBitMap(Page);
  End;

Begin
  WievielRAM:=0;
  Assign(FDest,BildName);
  Reset(FDest,1);
  BODYBig:=FileSize(FDest)-48;
  Noch:=BODYBig;
  If MemAvail<(Noch+48) then
    Begin
      Close(FDest);
      ErrorMessage('Zuwenig Speicher frei !');
    End;
  s:=(Noch Div 5119)+1;
  WievielRAM:=s;
  BlockRead(FDest,Palette,48,result);
  If result<>768 then Write(#7);
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
        Move(Mem[Start.S:Start.O],Mem[$A000:(Zeile*80)+Spalte],(Z+1));
        ADD_Pointer(Start,(Z+1));
        ADD_BitPlanePointer(Z+1);
      End
    Else
      Begin
        FillChar(Mem[$A000:(Zeile*80)+Spalte],Abs(Z)+1,Mem[Start.S:Start.O]);
        ADD_BitPlanePointer(Abs(Z)+1);
        ADD_Pointer(Start,1);
      End;
  Until Start.Zaehler>=BODYBig;
  For i:=1 to WievielRAM do
    Dispose(GrossesRAM[i]);

End;


Procedure LoadAmiga(BildName : String; Var Palette : Paltyp; Plus : Word);

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

  Spalte:=0; Page:=0; Zeile:=Plus;
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


Procedure LoadMultiColour(BildName : String; Var Palette : Paltyp);

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
    If Page>7 then
      Begin
        Inc(Zeile);
        Page:=Page Mod 8;
      End;
  End;

Begin
  WievielRAM:=0;
  Assign(FDest,BildName);
  Reset(FDest,1);
  BODYBig:=FileSize(FDest)-768;
  Noch:=BODYBig;
  If MemAvail<(Noch+768) then
    Begin
      Close(FDest);
      ErrorMessage('Zuwenig Speicher frei !');
    End;
  s:=(Noch Div 5119)+1;
  WievielRAM:=s;
  BlockRead(FDest,Palette,768,result);
  If result<>768 then Write(#7);
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


Procedure LoadHiresPic(Name : String;Var Farben : FarbHirestyp);

  Var f    : File;
      p    : Byte;
      Farb : PalTyp;

  Begin
    LoadHires(Name+'.BLD',Farb);
    Move(Farb,Farben,48)
  End;

Procedure LoadLowresPic(Name : String;Var Farben : FarbLowrestyp;
                        Ofset,Menge : Word);

  Var f    : File;
      p    : Byte;
      Farb : Paltyp;

  Begin
    If Menge=16000 then
      Begin
        LoadMultiColour(Name+'.BLD',Farb);
        Move(Farb,Farben,96);
      End
    Else
      Begin
        LoadAmiga(Name+'.BLD',Farb,(Ofset Div 80));
        Move(Farb,Farben,96);
      End;
  End;

Procedure LoadMiddlePicture(Name : String;Var Farben : FarbLowrestyp);

  Var f         : File;
      a         : Byte;
      Farb      : Paltyp;

  Begin
    LoadMultiColour(Name+'.BLD',Farb);
    Move(Farb,Farben,768);
  End;

Procedure SetPoint (X, Y : Word; Color : Byte);

  Var Offset : Word;

  Begin
    Offset := Y*80 + (X shr 2);
    Port[$3C4]:=2;
    Port[$3C5]:=1 shl (X and 3);
    Mem[$A000:Offset] := Color
  End;

Procedure WaitKey(BisWann : Word);

  Var i  : Word;

  Begin
    i:=0;
    Repeat
      Inc(i);
      Delay(1);
    Until ((KeyPressed) OR (i>BisWann)); { Warte bis Tastendruck }
    While KeyPressed do ch:=ReadKey;
    If ch=#27 then Programmende;
  End;

Procedure WaitBuch(BisWann : Word);

  Var i,y,a  : Word;

  Begin
    i:=0;
    Repeat
      Inc(i);
      Delay(1);
      Randomize;
      a:=120+Random(8);
      For y:=0 to 47 do
        Pal2[y]:=(Palette[y]*a) shr 7;
      SetHiresPalette(Pal2);
    Until ((KeyPressed) OR (i>BisWann)); { Warte bis Tastendruck }
    While KeyPressed do ch:=ReadKey;
    If ch=#27 then Programmende;
  End;

Procedure SetMode(r,w : Byte); ASSEMBLER;

  ASM
    mov  AH,r
    and  AH,1h
    shl  AH,1
    shl  AH,1
    shl  AH,1
    mov  AL,w
    and  AL,3h
    add  AH,AL
    or   AH,40h
    mov  DX,03CEh
    mov  AL,5h
    out  DX,AX
  End;

Procedure VgaCopy(vx,vy,w,h,nx,ny : Word);

  Var i,a,b,c,d,e : Word;

  Begin
    Port[$3C4]:=2;
    Port[$3C5]:=$F;
    SetMode(0,1);
    a:=(vx shr 2)+vy*80; b:=(nx shr 2)+ny*80; c:=w shr 2;
    PortW[$3CE]:=$1803;
    For i:=0 to h do Begin
      Move(Mem[$A000:a],
           Mem[$A000:b],c);
      Inc(a,80); Inc(b,80);
    End;
    SetMode(0,0);
  End;

Procedure LoadHiresFont;

  Var f : File;

  Begin
    Assign(f,'DRAKESNK.FNT');
    Reset(f,1);
    BlockRead(f,VFarb,12);
    WritePlane(0);
    BlockRead(f,Mem[$A000:$97E0],(162*75));
    WritePlane(1);
    BlockRead(f,Mem[$A000:$97E0],(162*75));
{    SetHiresPalette(VFarb);}
  End;

Procedure WriteHires(X,Y : Word; Etwas : String);

  Var l,i,ZAdr,
      QAdr,h,u,
      Ofset,
      LGes,ZOff : Word;

  Begin
{    Port[$3C4]:=2;
    Port[$3C5]:=$F;
    SetMode(0,1);
    PortW[$3CE]:=$1803;}
    l:=Length(Etwas);
    LGes:=0;
    For i:=1 to l do
      If Etwas[i]='·' then
        Inc(LGes,3)
      Else
        If Etwas[i]=' ' then
          Inc(LGes,2)
        Else
          Inc(LGes,Breiten[Transl[Ord(Etwas[i])]]);
    Ofset:=(80-LGes) shr 1;
    If x>79 then
      ZAdr:=y*54*80+Ofset
    Else
      ZAdr:=y*54*80+x*3;
    For i:=1 to l do Begin
      If Ord(Etwas[i])>33 then Begin
        QAdr:=Transl[Ord(Etwas[i])]*3+$97E0;
        If Etwas[i]='·' then
          QAdr:=58*3+$97E0;
        For h:=0 to 53 do
          For u:=0 to 1 do Begin
            ReadPlane(u); WritePlane(u+(SOFS[p]));
            Move(Mem[$A000:QAdr+h*225],Mem[$A000:ZAdr+h*80],3);
          End;
      End;
      If Etwas[i]='·' then
        Inc(ZAdr,3)
      Else
        If Etwas[i]=' ' then
          Inc(ZAdr,2)
        Else
          Inc(ZAdr,Breiten[Transl[Ord(Etwas[i])]]);
    End;
{    SetMode(0,0);}
  End;

Procedure Umblenden;

  Var u,a,b : Byte;

  Begin
    Case p of
      0 : For u:=16 downto 0 do Begin
            For a:=0 to 3 do
              For b:=0 to 3 do Begin
                Pal2[(b shl 2+a)*3]  :=(VFarb[a*3]  *(16-u)+
                                         VFarb[b*3]  *u) shr 4;
                Pal2[(b shl 2+a)*3+1]:=(VFarb[a*3+1]*(16-u)+
                                         VFarb[b*3+1]*u) shr 4;
                Pal2[(b shl 2+a)*3+2]:=(VFarb[a*3+2]*(16-u)+
                                         VFarb[b*3+2]*u) shr 4;
              End;
            SetHiresPalette(Pal2);
            Delay(30);
          End;
      1 : For u:=0 to 16 do Begin
            For a:=0 to 3 do
              For b:=0 to 3 do Begin
                Pal2[(b shl 2+a)*3]  :=(VFarb[a*3]  *(16-u)+
                                         VFarb[b*3]  *u) shr 4;
                Pal2[(b shl 2+a)*3+1]:=(VFarb[a*3+1]*(16-u)+
                                         VFarb[b*3+1]*u) shr 4;
                Pal2[(b shl 2+a)*3+2]:=(VFarb[a*3+2]*(16-u)+
                                         VFarb[b*3+2]*u) shr 4;
              End;
            SetHiresPalette(Pal2);
            Delay(30);
          End;
    End;
  End;

Procedure SchreibStory(von,bis : Byte);

Var WarteZeit,
    SNr,i       : Word;
    VolleZeilen : Byte;

Begin
  ClearVideoMem($9600,15);
  SetHiresPalette(Pal2);
  For SNr:=von to bis do Begin
    ClearVideoMem($9600,(3 shl SOFS[p]));
    VolleZeilen:=0;
    For i:=0 to 8 do Begin
      If Length(Story[SNr,i])>0 then Inc(VolleZeilen);
      If Story[SNr,i][1]='@' then Begin
        Ausgabe:=Copy(Story[SNr,i],2,Length(Story[SNr,i])-1);
        Ausgabe[0]:=Chr(Length(Story[SNr,i])-1);
        WriteHires(90,i,Ausgabe)
      End
      Else
        WriteHires(0,i,Story[SNr,i]);
    End;
    Umblenden;
    WarteZeit:=VolleZeilen*1500;
    WaitKey(WarteZeit);
    p:=1-p;
  End;
  ClearVideoMem($9600,(3 shl SOFS[p]));
  Umblenden;
End;

Procedure PutScreenOff;

Begin
  ASM
    push DS
    mov  DX,3DAh             { Auf Bildwechsel warten }
  @WaitVS:
    in    AL,DX
    test  AL,08h
    jz    @WaitVS
  @WaitDE:
    in   AL,DX
    test AL,01h
    jz   @WaitDE
    mov   DX,3C4h            { Bildschirm abschalten }
    mov   AL,1
    out   DX,AL
    inc   DX
    in    AL,DX
    or    AL,20h
    xchg  AL,AH
    dec   DX
    mov   AL,1
    out   DX,AX
    pop   DS
  End;
End;

Procedure PutScreenOn;

Begin
  ASM
    push DS
    mov  DX,3DAh                  { Bildwechsel abwarten }
  @WaitVS:
    in    AL,DX
    test  AL,08h
    jz    @WaitVS
  @WaitDE:
    in   AL,DX
    test AL,01h
    jz   @WaitDE
    mov   DX,3C4h                 { Bildschirm anschalten }
    mov   AL,1
    out   DX,AL
    inc   DX
    in    AL,DX
    and   AL,223
    xchg  AL,AH
    dec   DX
    mov   AL,1
    out   DX,AX
    pop   DS
  End;
End;


Procedure Vorspann;

Begin
  ExitVar:=False;
  InitMode(Hires);
  ClearVideoMem(38400,15);
  InitMode(Spezial);                        { 320 x 240 x 256 Einschalten }
  LoadLowresPic('COD',LPalette,19200,19200);  { COD-Logo laden }
  LPal2[0]:=0; LPal2[1]:=0; LPal2[2]:=0;
  LPal2[3]:=20; LPal2[4]:=20; LPal2[5]:=20;
  SetPoint(160,120,2);                      { 'Brennpunkt' setzen }
  SetPoint(161,120,1);
  SetPoint(159,120,1);
  SetPoint(160,119,1);
  SetPoint(160,121,1);
  For x:=20 to 63 do Begin                  { 'aufglÅhen' lassen }
    LPal2[6]:=x; LPal2[7]:=x; LPal2[8]:=x;
    SetLowresPalette(LPal2);
    Delay(1);
  End;
  For x:=0 to 158 do Begin                  { Punkt dehnt sich aus }
    SetPoint(158-x,120,1);
    SetPoint(161+x,120,1);
    Delay(1);
  End;
  For x:=20 to 63 do Begin
    LPal2[3]:=x; LPal2[4]:=x; LPal2[5]:=x;
    SetLowresPalette(LPal2);
    Delay(1);
  End;
  SetLowresPalette(LPalette);

  For y:=1 to 30 do
    Sinus[y]:=Round(239*Sin(Pi/60*y));
  For y:=1 to 30 do Begin                   { Bild COD wird aufgebaut }
    YPos:=120-(Sinus[y] shr 1);
    Multi:=240/Sinus[y];
    For x:=0 to Sinus[y] do Begin
      VgaCopy(0,240+Round(x*Multi),320,0,0,YPos+x);
    End;
    Delay(1);
  End;
  VgaCopy(0,241,320,239,0,0);

  WaitKey(4000);                            { ca. 4 sekunden warten }
  If ExitVar then Exit;
  For x:=128 downto 0 do Begin              { ausblenden }
    For y:=0 to 95 do
      LPal2[y]:=(LPalette[y]*x) shr 7;
    SetLowresPalette(LPal2);
  End;

  ClearVideoMem($FFFF,15);
  For y:=0 to 95 do
    LPal2[y]:=0;
  SetLowresPalette(LPal2);
  LoadLowresPic('PRESENT1',LPalette,0,16000);  { PRESENT laden }
  For x:=0 to 128 do Begin                  { einblenden }
    For y:=0 to 95 do
      LPal2[y]:=(LPalette[y]*x) shr 7;
    SetLowresPalette(LPal2);
  End;
  WaitKey(2500);
  If ExitVar then Exit;
  For x:=128 downto 0 do Begin              { ausblenden }
    For y:=0 to 95 do
      LPal2[y]:=(LPalette[y]*x) shr 7;
    SetLowresPalette(LPal2);
  End;

  PutScreenOff;
  InitMode(Hires);
  For p:=0 to 47 do Palette[p]:=0;
  SetHiresPalette(Palette);
  LoadHiresPic('DR_SNAKE',Palette);     { Drake Snake Titelbild laden }
  PutScreenOn;
  For x:=0 to 128 do Begin                  { und einblenden }
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 7;
    SetHiresPalette(Pal2);
  End;
  WaitKey(7000);                            { ca. 7 sekunden warten }
  If ExitVar then Exit;
  For x:=128 downto 0 do Begin              { und wieder ausblenden }
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 7;
    SetHiresPalette(Pal2);
  End;

  p:=0;
  LoadHiresFont;
  SchreibStory(0,3);
  If ExitVar then Exit;

  For p:=0 to 47 do Palette[p]:=0;
  SetHiresPalette(Palette);
  LoadHiresPic('BUCH',Palette);         { Bild des Alten Buches laden }
  For x:=0 to 128 do Begin                  { und einblenden }
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 7;
    SetHiresPalette(Pal2);
  End;
  WaitBuch(550);                            { ca. 9 sekunden warten }
  If ExitVar then Exit;
  For x:=128 downto 0 do Begin              { und wieder ausblenden }
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 7;
    SetHiresPalette(Pal2);
  End;

  p:=0;
  SchreibStory(4,Seiten-3);
  If ExitVar then Exit;

  Flug_ueber_Weltkarte;
  Fluganimation_ueber_Dschungel;

  AbsturzBild;

  PutScreenOff;
  InitMode(Hires);
  LoadHiresFont;
  For y:=0 to 47 do
    Pal2[y]:=0;
  SetHiresPalette(Pal2);
  PutScreenOn;

  SchreibStory(Seiten-2,Seiten-1);
  If ExitVar then Exit;

  PutScreenOff;
  InitMode(EndGraphic);                     { Ende des Vorspanns }
End;

End.