{*****************************************************************************}
{* "Unit Spiel" ist zum Erstellen von Spielen im 256 Farb-Modus.             *}
{* Es werden Routinen fr eine zweite Bildschirmseite, Smooth Scrolling,     *}
{* Sprites und anderes mehr zur Verfgung gestellt.                          *}
{*****************************************************************************}
{* Erste Erstellung : 25.09.1991                                             *}
{* Letztes Update   : 15.04.1992                                             *}
{*****************************************************************************}
{* (c) 1992 bei Martin Keydel                                                *}
{*              Hochstraáe 11                                                *}
{*              7520 Bruchsal                                                *}
{*****************************************************************************}
Unit FlugSpiel;

Interface

Uses Dos,Crt;

Type Paltyp    = Array[0..767] of Byte;
     ResType   = (R320x200,R320x240,R320x400,R360x480);
     VideoAr   = Array[0..65534] of Byte;
     BigFeld   = Array[0..65534] of Byte;
     IFFStruct = Record
                   Breite,Hoehe : Word;
                   BitPlanes    : Byte;
                   Farben       : Paltyp;
                 End;

Const Kollision   : Byte = 0;
      BildAdresse : Word = $A000;
      FarbModus   : ResType = R320x200;

Var   pal        : Paltyp;
      ScreenWith : Word;

Procedure SetPalette(Pal : Paltyp);               {A Setzen der Farbpalette }
Procedure SetPoint (X, Y : Word; Color : Byte);   {A}
Function  GetPoint (X, Y : Word) : Byte;          {A}
Procedure InitMode(Res : ResType);             { Aktivieren des Grafikmodus }
Procedure CloseMode;                            { Schliesen des Grafikmodus }
Procedure SplitScreen(SplitLine : Word); {A Rasterposition fr zweites Bild }
Procedure ClearScreen(Color : Byte);         {A Bildschirm mit Farbe fllen }
Procedure PutImNor(X,Y : Word; Adresse : Pointer);     {A Bildteil ausgeben }
Procedure PutImOut(X,Y : Word; Adresse : Pointer);     {A Bildteil ausgeben }
Procedure GetImage(X,Y,Breite,Hoehe : Word; Adresse : Pointer);
Procedure PutImKol(X,Y : Word; Adresse : Pointer);     {A Bildteil ausgeben }
Procedure SetScreenWith(Breite : Word);   {A Virtuelle Bildbreite festlegen }
Procedure SetWinPos(X,Y : Word);            {A Virtuelle Bildpos. festlegen }
Procedure PutScreenOff;                       {A Schaltet Bildschirm dunkel }
Procedure PutScreenOn;                   {A Schaltet Bildschirm wieder hell }
Procedure Einblenden;
Procedure Ausblenden;
Procedure WritePlane(Plane : Byte;Offset : Word;Wert : Byte);
                                      { Verwaltet Modus 13h als 8 Bitplanes }
Procedure LoadIFF(BildName : String;Bildspeicher : Pointer;
                  Var Strukt : IFFStruct);
Function  ReadPlane(Plane : Byte;Offset : Word) : Byte;
                                      { Verwaltet Modus 13h als 8 Bitplanes }

Implementation

Const CRTCIndex   = $3D4;
      CRTCData    = $3D5;
      CRTCStat    = $3DA;
      Overflow    = $07;
      DispEN      = $01;
      VSync       = $08;
      LineCompare = $18;
      MaxScan     = $09;
      ZB4Const    = 128;
      Start       : Array[0..3] of Word =(0,16384,32768,49152);

Var i        : Integer;
    Med      : Byte;
    ZB4      : Word;
    VideoRAM : ^VideoAr;

Procedure PutScreenOff;

Begin
  ASM
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
  End;
End;

Procedure PutScreenOn;

Begin
  ASM
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
  End;
End;

Procedure WritePlane(Plane : Byte;Offset : Word;Wert : Byte);

Var Pack      : Array[0..7] of Byte;
    i,X,Y     : Word;
    Mask,RAM,
    Breite    : Byte;

Begin
  Mask:=255-(1 shl Plane);
  Pack[0]:=Wert shr 7;
  Pack[1]:=(Wert and 64) shr 6;
  Pack[2]:=(Wert and 32) shr 5;
  Pack[3]:=(Wert and 16) shr 4;
  Pack[4]:=(Wert and 8) shr 3;
  Pack[5]:=(Wert and 4) shr 2;
  Pack[6]:=(Wert and 2) shr 1;
  Pack[7]:=Wert and 1;
  Breite:=ZB4 shr 1;
  X:=(Offset Mod Breite) shl 3;
  Y:=Offset Div Breite;
  For i:=0 to 7 do Begin
    RAM:=GetPoint(X+i,Y);
    RAM:=RAM and Mask;
    RAM:=RAM or (Pack[i] shl Plane);
    SetPoint(X+i,Y,RAM);
  End;
End;

Function  ReadPlane(Plane : Byte;Offset : Word): Byte;

Var Pack      : Array[0..7] of Byte;
    i,X,Y     : Word;
    Breite,
    Wert      : Byte;

Begin
  Breite:=ZB4 shr 1;
  X:=(Offset Mod Breite) shl 3;
  Y:=Offset Div Breite;
  For i:=0 to 7 do Begin
    Pack[i]:=GetPoint(X+i,Y);
    Pack[i]:=Pack[i] shr Plane;
    Pack[i]:=Pack[i] AND 1;
  End;
  Wert:=Pack[0] shl 7;
  Wert:=Wert+Pack[1] shl 6;
  Wert:=Wert+Pack[2] shl 5;
  Wert:=Wert+Pack[3] shl 4;
  Wert:=Wert+Pack[4] shl 3;
  Wert:=Wert+Pack[5] shl 2;
  Wert:=Wert+Pack[6] shl 1;
  Wert:=Wert+Pack[7];
  ReadPlane:=Wert;
End;

Procedure SetScreenWith(Breite : Word);

Begin
  ScreenWith:=Breite;
  ZB4       :=ScreenWith shr 2;
  ASM
    mov  BX,Breite
    shr  BX,3
    mov  AL,19
    mov  AH,BL
    mov  DX,CRTCIndex
    out  DX,AX
  End;
End;

Procedure SetPalette(Pal : Paltyp);

Var Segment,
    Off         : Word;

Begin
  Segment:=Seg(Pal);
  Off:=Ofs(Pal);
  ASM                        { Warten auf Bildwechsel }
    mov  DX,3DAh
  @WaitVS:
    in    AL,DX
    test  AL,08h
    jz    @WaitVS

{    mov   DX,3C4h             Bildschirm abschalten
    mov   AL,1
    out   DX,AL
    inc   DX
    in    AL,DX
    or    AL,20h
    xchg  AL,AH
    dec   DX
    mov   AL,1
    out   DX,AX}

    push  DS
    mov   DS,Segment
    mov   BX,Off
    mov   CX,32                   { 32 Farbeintr„ge }
    mov   DX,3C8h
    mov   AL,0
    cli
    out   DX,AL
    inc   DX
  @PalZaehler:
    mov   AX,[BX]                 { Lade Rot und Grnanteil }
    out   DX,AL                   { Rot ausgeben }
    xchg  AL,AH
    out   DX,AL                   { Grn ausgeben }
    inc   BX                      { Zeiger erh”hen }
    inc   BX
    mov   AL,[BX]                 { Lade Blauanteil }
    out   DX,AL                   { Blau ausgeben }
    inc   BX                      { Zeiger erh”hen }
    loop  @PalZaehler
    sti
    pop   DS
{    mov   DX,3C4h                 { Bildschirm wieder anschalten
    mov   AL,1
    out   DX,AL
    inc   DX
    in    AL,DX
    and   AL,223
    xchg  AL,AH
    dec   DX
    mov   AL,1
    out   DX,AX}
  End;
End;

Procedure Einblenden;

Var i,j   : Word;
    Pal2  : Paltyp;

Begin
  For i:=0 to 32 do Begin
    For j:=0 to 767 do
      Pal2[j]:=(Pal[j]*i) shr 5;
    SetPalette(Pal2);
    Delay(1);
  End;
End;

Procedure Ausblenden;

Var i,j   : Word;
    Pal2  : Paltyp;

Begin
  For i:=32 downto 0 do Begin
    For j:=0 to 767 do
      Pal2[j]:=(Pal[j]*i) shr 5;
    SetPalette(Pal2);
    Delay(1);
  End;
End;

Procedure CloseMode;

Begin
  SplitScreen(0);
  ASM
    xor    AH,AH
    mov    AL,03h
    int    10h
  End;
End;

Procedure SplitScreen(SplitLine : Word);

Begin
  ASM
    mov   DX,3DAh
  @WaitVS:
    in    AL,DX
    test  AL,08h
    jz    @WaitVS
    mov   DX,3D4h                      { CRTC-Index-Register }
    mov   AL,18h                       { Index fr Line Compare }
    out   DX,AL                        { Register selektieren }
    inc   DX
    { Split-Zeilen Bit 0-7 }
    mov   AL,Byte Ptr SplitLine
    out   DX,AL                        { ins Line Compare Reg. }
    dec   DX
    mov   AL,7                         { Index fr Overflow }
    out   DX,AL
    inc   DX
    in    AL,DX                        { Overflow-Wert einlesen }
    { Bit 8 von Split separieren }
    mov   BL,Byte Ptr SplitLine+1
    and   BL,1
    mov   CL,4
    shl   BL,CL
    and   AL,NOT 10h                   { Bit 4 rcksetzen }
    or    AL,BL                        { Split-Bit 8 einfgen }
    out   DX,AL                        { und in Overflow ablegen }
    dec   DX
    mov   AL,9                         { Max Scan Line Reg. lesen }
    out   DX,AL
    inc   DX
    in    AL,DX
    and   AL,NOT 40h                   { Bit 6 rcksetzen }
    out   DX,AL                        { und zurckschreiben }
  End;
End;

Procedure GetImage(X,Y,Breite,Hoehe : Word; Adresse : Pointer);

Var AdrHi,AdrLo,
    B1,B2,B3,B4 : Word;

Begin
  AdrHi:=Seg(Adresse^);
  AdrLo:=Ofs(Adresse^);
  ASM
    push  DS               { Breite B1..B4 ausrechnen }
    cld
    mov   CX,Breite
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B1,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B2,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B3,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B4,BX

    mov   ES,AdrHi         { Kopiervorgang vorbereiten }
    mov   DI,AdrLo
    mov   AX,Breite        { Breite & H”he im Spriteblock ablegen }
    stosw
    mov   AX,Hoehe
    stosw

    mov   BX,Y             { Offset ermitteln }
    mov   AX,ZB4
    mul   BX
    mov   BX,X
    shr   BX,2
    add   AX,BX
    mov   SI,AX            { SI = Offset = (Y*ZB4+(X AND 3)) }
    mov   BX,AX
    mov   DX,3CEh

    mov   AX,X             { Page (0..3) festlegen }
    xchg  AL,AH
    mov   AL,4
    and   AH,3
    out   DX,AX

    mov   CX,Hoehe         { "Spalte 0" kopieren }
    push  BX
    mov   BX,B1
    mov   DS,BildAdresse
  @ZeileI:
    mov   AX,BX
    xchg  CX,AX
    rep
    movsb
    add   SI,ZB4Const       { 320 = 40; 360 = 50 (ZB4) }
    sub   SI,BX
    xchg  CX,AX
    loop  @ZeileI
    pop   BX

    mov   AX,X             { Page (0..3) festlegen }
    and   AX,3
    inc   AX
    push  AX
    xchg  AL,AH
    mov   AL,4
    and   AH,3
    out   DX,AX
    pop   AX
    shr   AX,2
    mov   SI,BX
    add   SI,AX

    pop   DS
    push  DS
    mov   CX,Hoehe         { "Spalte 1" kopieren }
    push  BX
    mov   BX,B2
    mov   DS,BildAdresse
  @ZeileII:
    mov   AX,BX
    xchg  CX,AX
    rep
    movsb
    add   SI,ZB4Const      { 320 = 40; 360 = 50 (ZB4) }
    sub   SI,BX
    xchg  CX,AX
    loop  @ZeileII
    pop   BX

    mov   AX,X             { Page (0..3) festlegen }
    and   AX,3
    add   AX,2
    push  AX
    xchg  AL,AH
    mov   AL,4
    and   AH,3
    out   DX,AX
    pop   AX
    shr   AX,2
    mov   SI,BX
    add   SI,AX

    pop   DS
    mov   CX,Hoehe         { "Spalte 2" kopieren }
    push  DS
    push  BX
    mov   BX,B3
    mov   DS,BildAdresse
  @ZeileIII:
    mov   AX,BX
    xchg  CX,AX
    rep
    movsb
    add   SI,ZB4Const         { 320 = 40; 360 = 50 (ZB4) }
    sub   SI,BX
    xchg  CX,AX
    loop  @ZeileIII
    pop   BX

    mov   AX,X             { Page (0..3) festlegen }
    and   AX,3
    add   AX,3
    push  AX
    xchg  AL,AH
    mov   AL,4
    and   AH,3
    out   DX,AX
    pop   AX
    shr   AX,2
    mov   SI,BX
    add   SI,AX

    pop   DS
    mov   CX,Hoehe         { "Spalte 2" kopieren }
    push  DS
    push  BX
    mov   BX,B4
    mov   DS,BildAdresse
  @ZeileIV:
    mov   AX,BX
    xchg  CX,AX
    rep
    movsb
    add   SI,ZB4Const     { 320 = 40; 360 = 50 (ZB4) }
    sub   SI,BX
    xchg  CX,AX
    loop  @ZeileIV
    pop   BX

    pop   DS
  End;
End;

Procedure PutImNor(X,Y : Word; Adresse : Pointer);

Var AdrHi,AdrLo,
    B1,B2,B3,B4 : Word;

Begin
  AdrHi:=Seg(Adresse^);
  AdrLo:=Ofs(Adresse^);
  ASM
    push  DS
    cld
    mov   DS,AdrHi
    mov   SI,AdrLo
    lodsw                  { Breite => CX }
    mov   CX,AX
    dec   CX               { Breite B1..B4 ausrechnen }
    mov   BX,CX
    shr   BX,2
    inc   BX
    pop   DS
    mov   B1,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B2,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B3,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B4,BX

    mov   BX,Y             { Offset ermitteln }
    mov   AX,ZB4
    mul   BX
    mov   BX,X
    shr   BX,2
    add   AX,BX
    xchg  AX,BX            { BX = Offset = (Y*ZB4+(X shr 2)) }

    mov   DX,3C4h          { Page (0..3) festlegen }
    mov   AL,2
    mov   AH,1
    mov   CX,X          
    and   CL,3
    shl   AH,CL
    out   DX,AX

    mov   ES,BildAdresse
    mov   DI,BX
    push  DS
    mov   DS,AdrHi
    lodsw
    mov   CX,AX            { "Spalte 0" kopieren }
    pop   DS
    push  AX
    push  DS
    push  BX
    push  DX
    mov   BX,B1
    mov   DX,ZB4
    mov   DS,AdrHi
  @FirstI:
    mov   AX,BX
    xchg  CX,AX
    rep
    movsb
    add   DI,DX
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstI
    pop   DX
    pop   BX

    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CX,3
    inc   CX
    push  CX
    and   CL,3
    shl   AH,CL
    out   DX,AX
    mov   DI,BX
    pop   CX
    shr   CX,2
    add   DI,CX

    pop   DS
    pop   AX
    mov   CX,AX            { "Spalte 1" kopieren }
    push  AX
    push  DS
    push  BX
    push  DX
    mov   BX,B2
    mov   DX,ZB4
    mov   DS,AdrHi
  @FirstII:
    mov   AX,BX
    xchg  CX,AX
    rep
    movsb
    add   DI,DX
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstII
    pop   DX
    pop   BX

    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CX,3
    add   CX,2
    push  CX
    and   CL,3
    shl   AH,CL
    out   DX,AX
    mov   DI,BX
    pop   CX
    shr   CX,2
    add   DI,CX

    pop   DS
    pop   AX
    mov   CX,AX            { "Spalte 2" kopieren }
    push  AX
    push  DS
    push  BX
    push  DX
    mov   BX,B3
    mov   DX,ZB4
    mov   DS,AdrHi
  @FirstIII:
    mov   AX,BX
    xchg  CX,AX
    rep
    movsb
    add   DI,DX
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstIII
    pop   DX
    pop   BX

    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CX,3
    add   CX,3
    push  CX
    and   CL,3
    shl   AH,CL
    out   DX,AX
    mov   DI,BX
    pop   CX
    shr   CX,2
    add   DI,CX

    pop   DS
    pop   AX
    mov   CX,AX            { "Spalte 3" kopieren }
    push  DS
    push  BX
    push  DX
    mov   BX,B4
    mov   DX,ZB4
    mov   DS,AdrHi
  @FirstIV:
    mov   AX,BX
    xchg  CX,AX
    rep
    movsb
    add   DI,DX
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstIV
    pop   DX
    pop   BX

    pop   DS
  End;
End;

Procedure PutImOut(X,Y : Word; Adresse : Pointer);

Var AdrHi,AdrLo,
    B1,B2,B3,B4 : Word;

Begin
  AdrHi:=Seg(Adresse^);
  AdrLo:=Ofs(Adresse^);
  ASM
    push  DS
    cld
    mov   DS,AdrHi
    mov   SI,AdrLo
    lodsw                  { Breite => CX }
    mov   CX,AX
    dec   CX               { Breite B1..B4 ausrechnen }
    mov   BX,CX
    shr   BX,2
    inc   BX
    pop   DS
    mov   B1,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B2,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B3,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B4,BX

    mov   BX,Y             { Offset ermitteln }
    mov   AX,ZB4
    mul   BX
    mov   BX,X
    shr   BX,2
    add   AX,BX
    xchg  AX,BX            { BX = Offset = (Y*ZB4+(X shr 2)) }

    mov   DX,3C4h          { Page (0..3) festlegen }
    mov   AL,2
    mov   AH,1
    mov   CX,X          
    and   CL,3
    shl   AH,CL
    out   DX,AX

    mov   ES,BildAdresse
    mov   DI,BX
    push  DS
    mov   DS,AdrHi
    lodsw
    mov   CX,AX            { "Spalte 0" kopieren }
    pop   DS
    push  AX
    push  DS
    push  BX
    push  DX
    mov   BX,B1
    mov   DS,AdrHi
  @FirstI:
    mov   AX,BX
    xchg  CX,AX

    push  AX                  { ersetzt rep/movsb }
  @Copy1:
    mov   AL,[SI]
    cmp   AL,0
    jz    @Weiter1
    movsb
    dec   SI
    dec   DI
  @Weiter1:
    inc   SI
    inc   DI
    loop  @Copy1
    pop   AX

    add   DI,ZB4Const          { 320 = 40; 360 = 50 (ZB4) }
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstI
    pop   DX
    pop   BX

    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CX,3
    inc   CX
    push  CX
    and   CL,3
    shl   AH,CL
    out   DX,AX
    mov   DI,BX
    pop   CX
    shr   CX,2
    add   DI,CX

    pop   DS
    pop   AX
    mov   CX,AX            { "Spalte 1" kopieren }
    push  AX
    push  DS
    push  BX
    push  DX
    mov   BX,B2
    mov   DS,AdrHi
  @FirstII:
    mov   AX,BX
    xchg  CX,AX

    push  AX                  { ersetzt rep/movsb }
  @Copy2:
    mov   AL,[SI]
    cmp   AL,0
    jz    @Weiter2
    movsb
    dec   SI
    dec   DI
  @Weiter2:
    inc   SI
    inc   DI
    loop  @Copy2
    pop   AX

    add   DI,ZB4Const         { 320 = 40; 360 = 50 (ZB4) }
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstII
    pop   DX
    pop   BX

    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CX,3
    add   CX,2
    push  CX
    and   CL,3
    shl   AH,CL
    out   DX,AX
    mov   DI,BX
    pop   CX
    shr   CX,2
    add   DI,CX

    pop   DS
    pop   AX
    mov   CX,AX            { "Spalte 2" kopieren }
    push  AX
    push  DS
    push  BX
    push  DX
    mov   BX,B3
    mov   DS,AdrHi
  @FirstIII:
    mov   AX,BX
    xchg  CX,AX

    push  AX                  { ersetzt rep/movsb }
  @Copy3:
    mov   AL,[SI]
    cmp   AL,0
    jz    @Weiter3
    movsb
    dec   SI
    dec   DI
  @Weiter3:
    inc   SI
    inc   DI
    loop  @Copy3
    pop   AX

    add   DI,ZB4Const         { 320 = 40; 360 = 50 (ZB4) }
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstIII
    pop   DX
    pop   BX

    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CX,3
    add   CX,3
    push  CX
    and   CL,3
    shl   AH,CL
    out   DX,AX
    mov   DI,BX
    pop   CX
    shr   CX,2
    add   DI,CX

    pop   DS
    pop   AX
    mov   CX,AX            { "Spalte 3" kopieren }
    push  DS
    push  BX
    push  DX
    mov   BX,B4
    mov   DS,AdrHi
  @FirstIV:
    mov   AX,BX
    xchg  CX,AX

    push  AX                  { ersetzt rep/movsb }
  @Copy4:
    mov   AL,[SI]
    cmp   AL,0
    jz    @Weiter4
    movsb
    dec   SI
    dec   DI
  @Weiter4:
    inc   SI
    inc   DI
    loop  @Copy4
    pop   AX

    add   DI,ZB4Const         { 320 = 40; 360 = 50 (ZB4) }
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstIV
    pop   DX
    pop   BX

    pop   DS
  End;
End;

Procedure PutImKol(X,Y : Word; Adresse : Pointer);

Var AdrHi,AdrLo,
    B1,B2,B3,B4 : Word;

Begin
  AdrHi:=Seg(Adresse^);
  AdrLo:=Ofs(Adresse^);
  ASM
    push  DS
    cld
    mov   DS,AdrHi
    mov   SI,AdrLo
    lodsw                  { Breite => CX }
    mov   CX,AX
    dec   CX               { Breite B1..B4 ausrechnen }
    mov   BX,CX
    shr   BX,2
    inc   BX
    pop   DS
    mov   B1,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B2,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B3,BX
    dec   CX
    mov   BX,CX
    shr   BX,2
    inc   BX
    mov   B4,BX

    mov   BX,Y             { Offset ermitteln }
    mov   AX,ZB4
    mul   BX
    mov   BX,X
    shr   BX,2
    add   AX,BX
    xchg  AX,BX            { BX = Offset = (Y*ZB4+(X shr 2)) }

    mov   DX,3C4h          { Page (0..3) festlegen }
    mov   AL,2
    mov   AH,1
    mov   CX,X          
    and   CL,3
    shl   AH,CL
    out   DX,AX

    mov   ES,BildAdresse
    mov   DI,BX
    push  DS
    mov   DS,AdrHi
    lodsw
    mov   CX,AX            { "Spalte 0" kopieren }
    pop   DS
    push  AX
    push  DS
    push  BX
    mov   DL,Kollision
    mov   BX,B1
    mov   DS,AdrHi
  @FirstI:
    mov   AX,BX
    xchg  CX,AX

    push  AX                  { ersetzt rep/movsb }
  @Copy1:
    mov   AL,[SI]
    cmp   AL,0
    jz    @Weiter1
    mov   AL,ES:[DI]
    or    DL,AL
    movsb
    dec   SI
    dec   DI
  @Weiter1:
    inc   SI
    inc   DI
    loop  @Copy1
    pop   AX

    add   DI,ZB4Const         { 320 = 40; 360 = 50 (ZB4) }
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstI
    pop   BX
    pop   DS
    mov   Kollision,DL

    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CX,3
    inc   CX
    push  CX
    and   CL,3
    shl   AH,CL
    mov   DX,3C4h
    out   DX,AX
    mov   DI,BX
    pop   CX
    shr   CX,2
    add   DI,CX

    pop   AX
    mov   CX,AX            { "Spalte 1" kopieren }
    push  AX
    push  DS
    push  BX
    mov   DL,Kollision
    mov   BX,B2
    mov   DS,AdrHi
  @FirstII:
    mov   AX,BX
    xchg  CX,AX

    push  AX                  { ersetzt rep/movsb }
  @Copy2:
    mov   AL,[SI]
    cmp   AL,0
    jz    @Weiter2
    mov   AL,ES:[DI]
    or    DL,AL
    movsb
    dec   SI
    dec   DI
  @Weiter2:
    inc   SI
    inc   DI
    loop  @Copy2
    pop   AX

    add   DI,ZB4Const        { 320 = 40; 360 = 50 (ZB4) }
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstII
    pop   BX
    pop   DS
    mov   Kollision,DL

    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CX,3
    add   CX,2
    push  CX
    and   CL,3
    shl   AH,CL
    mov   DX,3C4h
    out   DX,AX
    mov   DI,BX
    pop   CX
    shr   CX,2
    add   DI,CX

    pop   AX
    mov   CX,AX            { "Spalte 2" kopieren }
    push  AX
    push  DS
    push  BX
    mov   DL,Kollision
    mov   BX,B3
    mov   DS,AdrHi
  @FirstIII:
    mov   AX,BX
    xchg  CX,AX

    push  AX                  { ersetzt rep/movsb }
  @Copy3:
    mov   AL,[SI]
    cmp   AL,0
    jz    @Weiter3
    mov   AL,ES:[DI]
    or    DL,AL
    movsb
    dec   SI
    dec   DI
  @Weiter3:
    inc   SI
    inc   DI
    loop  @Copy3
    pop   AX

    add   DI,ZB4Const         { 320 = 40; 360 = 50 (ZB4) }
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstIII
    pop   BX
    pop   DS
    mov   Kollision,DL

    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CX,3
    add   CX,3
    push  CX
    and   CL,3
    shl   AH,CL
    mov   DX,3C4h
    out   DX,AX
    mov   DI,BX
    pop   CX
    shr   CX,2
    add   DI,CX

    pop   AX
    mov   CX,AX            { "Spalte 3" kopieren }
    push  DS
    push  BX
    mov   DL,Kollision
    mov   BX,B4
    mov   DS,AdrHi
  @FirstIV:
    mov   AX,BX
    xchg  CX,AX

    push  AX                  { ersetzt rep/movsb }
  @Copy4:
    mov   AL,[SI]
    cmp   AL,0
    jz    @Weiter4
    mov   AL,ES:[DI]
    or    DL,AL
    movsb
    dec   SI
    dec   DI
  @Weiter4:
    inc   SI
    inc   DI
    loop  @Copy4
    pop   AX

    add   DI,ZB4Const       { 320 = 40; 360 = 50 (ZB4) }
    sub   DI,BX
    xchg  CX,AX
    loop  @FirstIV
    pop   BX
    pop   DS
    mov   Kollision,DL

  End;
End;

Procedure SetWinPos(X,Y : Word);

Begin
  ASM
    mov   AX,ScreenWith          { Adresse des Bildschirmspeicherposition }
    shr   AX,2                   { errechnen ((ScreenWith/4)*Y+(X/4))     }
    mov   BX,Y
    mul   BX
    mov   BX,X
    shr   BX,2
    add   AX,BX
    xchg  AX,BX                  { Adresse => BX }
    mov   DX,3DAh                { Warten bis Rasterstrahl im v. rcklauf }
  @WaitDE:                       { Display enable }
    in    AL,DX
    test  AL,01h
    jz    @WaitDE
  @WaitVS:                       { Vertical sync. }
    in    AL,DX
    test  AL,08h
    jz    @WaitVS
    cli
    mov   DX,CRTCIndex
    mov   AH,BH                  { Hi-Wert der Adresse (BH) dem CRTC }
    mov   AL,12                  { bergeben                         }
    out   DX,AX
    inc   AL
    mov   AH,BL                  { Lo-Wert der Adresse (BL) dem CRTC }
    out   DX,AX                  { bergeben                         }
    xor   AH,AH
    mov   BX,X                   { (X Modulo 4) => BX                }
    and   BX,3
    mov   DL,0C0h                { Wert von BX ins Attribute-        }
    mov   AL,33h                 { Controller-Register ( Hor. PEL    }
    out   DX,AL                  { Panning )                         }
    mov   AL,BL
    out   DX,AL
    sti
  End;
End;

Procedure InitMode(Res : ResType);

  Type  CRTCAr = Array[0..23] of Byte;

  Const CRTC320x240 : CRTCAr =
        ($5F,$4F,$50,$82,$54,$80,$0D,$3E,$00,$41,$00,$00,
         $00,$00,$00,$00,$EA,$AC,$DF,$28,$00,$E7,$06,$E3);
        CRTC320x400 : CRTCAr =
        ($5F,$4F,$50,$82,$54,$80,$BF,$1F,$00,$40,$00,$00,
         $00,$00,$00,$00,$9C,$8E,$8F,$28,$00,$96,$B9,$E3);
        CRTC360x480 : CRTCAr =
        ($6B,$59,$5A,$8E,$5E,$8A,$0D,$3E,$00,$40,$00,$00,
         $00,$00,$00,$00,$EA,$AC,$DF,$2D,$00,$E7,$06,$E3);

  Var   I : Byte;

  Begin
    FarbModus:=Res;
    ASM
      xor    AH,AH      { Bildschirml”schen durch Modus $12 }
      mov    AL,12h
      int    10h
      mov    AL,13h
      int    10h
    End;
    Port[$3C4]:=4;      { Sequenzer-Controller : Memory Mode }
    Port[$3C5]:=6;
                          { Extended Memory ein, Odd/Even aus  }
    Port[$3D4] := $11;                { CRTC: Register $11     }
    Port[$3D5] := Port[$3D5] and $7F; { Schreibschutz aufheben }
    Med:=0;
    Case Res of
      R320x200 : Begin
                   ZB4:=80;
                   Port[$3C4]:=0;
                   Port[$3C5]:=1;
                   Port[$3C2]:=Port[$3CC] or 2;
                   Port[$3C4]:=0;
                   Port[$3C5]:=3;{}
                 End;
      R320x240 : Begin
                   Port[$3C4]:=0;        { Seq.Controller: Reset Register }
                   Port[$3C5]:=1;        { Synchroner Reset, Seq. aus     }
                   Port[$3C2]:=$E3;      { 480 Scan-Zeilen }
                   Port[$3C4]:=0;        { Synchroner Reset, Seq. ein     }
                   Port[$3C5]:=3;
                   For I := 0 to 23 do Begin  { CRTC-Registerwerte setzen }
                     Port[$3D4]:=I;
                     Port[$3D5]:=CRTC320x240[I];
                   End;
                   ZB4 := 80;
                 End;
      R320x400 : Begin
                   For I := 0 to 23 do Begin  { CRTC-Registerwerte setzen }
                     Port[$3D4]:=I;
                     Port[$3D5]:=CRTC320x400[I];
                   End;
                   ZB4 := 80;
                 End;
      R360x480 : Begin
                   Port[$3C4]:=0;        { Seq.Controller: Reset Register }
                   Port[$3C5]:=1;        { Synchroner Reset, Seq. aus     }
                   Port[$3C2] := $E7;    { 480 Scan-Zeilen, Clock=28MHz   }
                   Port[$3C4]:=0;        { Synchroner Reset, Seq. ein     }
                   Port[$3C5]:=3;
                   For I := 0 to 23 do Begin { CRTC-Registerwerte setzen  }
                     Port[$3D4]:=I;
                     Port[$3D5]:=CRTC360x480[I];
                   End;
                   ZB4 := 90;
                 End;
    End;
    ScreenWith:=ZB4 shl 2;
    VideoRAM := Ptr($A000,0);
End;

Procedure SetPoint (X, Y : Word; Color : Byte);

Begin
  ASM
    mov   BX,Y
    mov   AX,ZB4
    mul   BX
    mov   BX,X
    shr   BX,2
    add   AX,BX
    xchg  AX,BX            { BX = Offset = (Y*ZB4+(X shr 2)) }
    mov   DX,3C4h
    mov   AL,2
    mov   AH,1
    mov   CX,X
    and   CL,3
    shl   AH,CL
    out   DX,AX
    push  DS
    mov   DS,Bildadresse   { Bildschirmspeicheranfang ($A000) in DS }
    mov   AL,Color
    mov   [BX],AL          { Punkt setzen }
    pop   DS
  End;
End;

Function GetPoint (X, Y : Word) : Byte;

Var Color : Byte;

Begin
  ASM
    mov   BX,Y
    mov   AX,ZB4
    mul   BX
    mov   BX,X
    shr   BX,2
    add   AX,BX
    xchg  AX,BX            { BX = Offset = (Y*ZB4+(X AND 3)) }
    mov   DX,3CEh
    mov   AX,X
    xchg  AL,AH
    mov   AL,4
    and   AH,3
    out   DX,AX
    push  DS
    mov   DS,Bildadresse   { Bildschirmspeicheranfang ($A000) in DS }
    mov   AL,[BX]          { Punkt setzen }
    mov   Color,AL
    pop   DS
  End;
  GetPoint:=Color;
End;

Procedure ClearScreen(Color : Byte);

Begin
  ASM
    mov   DX,3C4h             { Alle 4 Grafikseiten gleichzeitig }
    mov   AL,2
    mov   AH,15
    out   DX,AX
    mov   AL,Color            { Mit dem Wert "Color" beschreiben }
    mov   AH,AL
    mov   CX,32768            { 32768 Words = 64 kByte }
    mov   DI,0000             { Ab Adresse $A000:0000 }
    mov   ES,BildAdresse
    cld                       { Richtung = Aufsteigend }
    rep
    stosw
  End;
End;

Procedure LoadIFF(BildName : String;Bildspeicher : Pointer;
                  Var Strukt : IFFStruct);

Type Puffer     = Array[0..65534] of Byte;

Var  i,X,Y,Z,ZeigerQ,
     ZeigerD            : Word;
     Bild,Bild2         : ^Puffer;
     Pic                : File;
     FORM,ILBM,BMHD,
     CMAP,BODY,UNDF     : Array[0..3] of Char;
     Lform,Lbmhd,Lcmap,
     Lbody,Lundf,result,
     HoeheG,BreiteG,XG,
     YG,TransC,BreiteQ,
     HoeheQ,Position    : Word;
     AnzBitPlanes,Mask,
     Kompress,None,XAsp,
     YAsp               : Byte;

Begin
  New(Bild);
  Bild2:=Bildspeicher;
  Assign(Pic,BildName);
  Reset(Pic);
  BlockRead(Pic,Bild^,65534,result);
  Close(Pic);
  Position:=0;

  FORM[0]:=Chr(Bild^[0]);  FORM[1]:=Chr(Bild^[1]);            { 'FORM' / Long }
  FORM[2]:=Chr(Bild^[2]);  FORM[3]:=Chr(Bild^[3]);
  If Pos('FORM',FORM)=0 then Begin
    WriteLn('Kein IFF-File !');
    Halt;
  End;

  If Bild^[5]>0 then Begin                    { Gesamtl„nge des Bildes / Long }
    WriteLn('File > 64 KByte !');
    Halt;
  End;
  Lform:=Bild^[6]; Lform:=Lform shl 8;
  Lform:=Lform+Bild^[7];

  ILBM[0]:=Chr(Bild^[8]);   ILBM[1]:=Chr(Bild^[9]);           { 'ILBM' / Long }
  ILBM[2]:=Chr(Bild^[10]);  ILBM[3]:=Chr(Bild^[11]);
  If Pos('ILBM',ILBM)=0 then Begin
    WriteLn('Keine Bilddatei !');
    Halt;
  End;

  BMHD[0]:=Chr(Bild^[12]);  BMHD[1]:=Chr(Bild^[13]);          { 'BMHD' / Long }
  BMHD[2]:=Chr(Bild^[14]);  BMHD[3]:=Chr(Bild^[15]);
  If Pos('BMHD',BMHD)=0 then Begin
    WriteLn('Kein Bit Map Header !');
    Halt;
  End;

  { L„nge der BMHD / Long }
  Lbmhd:=Bild^[18]; Lbmhd:=Lbmhd shl 8; Lbmhd:=Lbmhd+Bild^[19];
  { Breite der Grafik / Word }
  BreiteG:=Bild^[20]; BreiteG:=BreiteG shl 8; BreiteG:=BreiteG+Bild^[21];
  { H”he der Grafik / Word }
  HoeheG:=Bild^[22]; HoeheG:=HoeheG shl 8; HoeheG:=HoeheG+Bild^[23];
  { X-Position der Grafik / Word }
  XG:=Bild^[24]; XG:=XG shl 8; XG:=XG+Bild^[25];
  { Y-Position der Grafik / Word }
  YG:=Bild^[26]; YG:=YG shl 8; YG:=YG+Bild^[27];
  { Anzahl der Bitplanes }
  Strukt.BitPlanes:=Bild^[28];
  { Masking (0 - Kein Masking / 1 - Masking / 2 - Transparent / 3 - Lasso) }
  Mask:=Bild^[29];
  { DatenKompression (0 - nicht gepackt / 1 - gepackt) }
  Kompress:=Bild^[30];
  { unbenutzt }
  None:=Bild^[31];
  { Transparentfarbe / Word }
  TransC:=Bild^[32]; TransC:=TransC shl 8; TransC:=TransC+Bild^[33];
  { X-Aspekt }
  XAsp:=Bild^[34];
  { Y-Aspekt }
  YAsp:=Bild^[35];
  { Breite der Quellseite }
  BreiteQ:=Bild^[36]; BreiteQ:=BreiteQ shl 8; BreiteQ:=BreiteQ+Bild^[37];
  { H”he der Quellseite }
  HoeheQ:=Bild^[38]; HoeheQ:=HoeheQ shl 8; HoeheQ:=HoeheQ+Bild^[39];

  CMAP[0]:=Chr(Bild^[40]);  CMAP[1]:=Chr(Bild^[41]);          { 'CMAP' / Long }
  CMAP[2]:=Chr(Bild^[42]);  CMAP[3]:=Chr(Bild^[43]);
  If Pos('CMAP',CMAP)=0 then Begin
    WriteLn('Keine Colour Map !');
    Halt;
  End;

  { L„nge der CMAP / Long }
  Lcmap:=Bild^[46]; Lcmap:=Lcmap shl 8; Lcmap:=Lcmap+Bild^[47];
  For i:=0 to (Lcmap-1) Div 3 do Begin
    For x:=0 to 2 do
      Strukt.Farben[i*3+x]:=(Bild^[((i*3+x)+48)]) shr 2;
  End;
  Position:=48+Lcmap;

                                                              { 'BODY' / Long }
  Repeat
    BODY[0]:=Chr(Bild^[Position]);  BODY[1]:=Chr(Bild^[Position+1]);
    BODY[2]:=Chr(Bild^[Position+2]);  BODY[3]:=Chr(Bild^[Position+3]);
    Inc(Position,6);
    Lbody:=Bild^[Position]; Lbody:=Lbody shl 8; Lbody:=Lbody+Bild^[Position+1];
    Inc(Position,2);
    If Position>Lform then Begin
      CloseMode;
      WriteLn('Keine Bilddaten gefunden !');
      Halt;
    End;
    If Pos('BODY',BODY)=0 then
      Inc(Position,Lbody);
  Until Pos('BODY',BODY)<>0;

  ZeigerQ:=Position;
  i:=ZeigerQ;
  ZeigerD:=0;
  If Kompress=1 then Begin
    Repeat
      Z:=Bild^[ZeigerQ];
      Inc(ZeigerQ);
      If Z<=128 then
        For X:=0 to Z do Begin
          Bild2^[ZeigerD]:=Bild^[ZeigerQ];
          Inc(ZeigerD);
          Inc(ZeigerQ);
        End
      Else Begin
        For X:=0 to (256-Z) do Begin
          Bild2^[ZeigerD]:=Bild^[ZeigerQ];
          Inc(ZeigerD);
        End;
        Inc(ZeigerQ);
      End;
    Until ((ZeigerQ-i)>=Lbody-1);
  End Else
    Repeat
      Bild2^[ZeigerD]:=Bild^[ZeigerQ];
      Inc(ZeigerD);
      Inc(ZeigerQ);
    Until ((ZeigerQ-i)>=Lbody-1);
    Strukt.Breite:=BreiteG;
    Strukt.Hoehe:=HoeheG;

  Dispose(Bild);
End;

End.