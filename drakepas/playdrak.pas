Unit PlayDrak;

Interface

Uses Crt,SB_DAC,Dos;



Const LPT      : Word = $0378; { LPT1=$378 / LPT2=$278 / LPTMono=$3BC }
      SBAdress : Word = 220;
      FreiesWord = $F0;
      NoTune       = 0;
      Speaker      = 1;
      Drucker      = 2;
      SoundBlaster = 3;
      Schiess         = 0;
      Getroffen       = 1;
      BombeExplodiert = 2;
      Fluggeraeusch   = 3;
      TWert           = 100;
      WasSpielt : Byte = 0;

Var PlaySample,
    TimerTick  : Byte;

Procedure Spiel(Welches : Byte);
Procedure InitAusgabe(Was : Byte);
Procedure CloseAusgabe;


Implementation

Type KanonBuff  = Array[0..8057] of Byte;
     KaputtBuff = Array[0..5091] of Byte;
     BombBuff   = Array[0..9711] of Byte;
     FlugBuff   = Array[0..5790] of Byte;
     Zeiger     = Record
                    Segment,Ofset,Laenge : Word;
                  End;

Var i,Zaehler,
    Oset,Laenge,
    PSegment,
    POfset     : Word;
    Wert       : ShortInt;
    b          : Byte;
    ch         : Char;
    Zeit       : LongInt;
    Alt_Int    : Pointer;                    { Sichern des alten Interrupts }
    res        : Word;
    SampleDat  : Array[0..3] of Zeiger;
    f          : File;
    Kanon      : ^KanonBuff;
    Kaputt     : ^KaputtBuff;
    Bomb       : ^BombBuff;
    Flug       : ^FlugBuff;

Procedure Play;
Interrupt;

Begin
  If PlaySample=1 then
    ASM
      cmp Laenge,0
      jz  @Nichts
      sub Laenge,4
      mov DX,LPT
      mov ES,PSegment
      mov SI,POfset
      mov AL,ES:[SI]
      out DX,AL
      add POfset,4
      jmp @Fertig
    @Nichts:
{      mov POfset,0
      mov AX,L2
      mov Laenge,AX}
      mov PlaySample,0
    @Fertig:
    End;
  Dec(TimerTick);
End;

Procedure IntRoutine;
Interrupt;

Begin
  ASM
    push  DS
    xor   AX,AX
    mov   ES,AX
    mov   BX,FreiesWord
    mov   AX,ES:[BX]
    mov   DS,AX
    xor   AL,AL
    mov   TimerTick,AL
    pop   DS
  End;
End;

Procedure SetSamplePlay;                  { Interruptroutine Initialisieren }

Begin
  PlaySample:=0;
  GetIntVec($1C,Alt_Int);
  SetIntVec($1C,@Play);
End;

Procedure SetTimerInt;                  { Interruptroutine Initialisieren }

Begin
  PlaySample:=0;
  Zaehler:=$9B4E;       { = 30 Hz }
  Port[$43]:=54;
  Port[$40]:=Lo(Zaehler);
  Port[$40]:=Hi(Zaehler);
  GetIntVec($1C,Alt_Int);
  SetIntVec($1C,@IntRoutine);
  MemW[$0000:FreiesWord]:=DSeg;
End;

Procedure ResetInt;                    { Alten Interrupt wiederherstellen }

Begin
  SetIntVec($1C,Alt_Int);
  Zaehler:=$FFFF;
  Port[$43]:=54;
  Port[$40]:=Lo(Zaehler);
  Port[$40]:=Hi(Zaehler);
End;

Procedure Spiel(Welches : Byte);

Begin
  Case WasSpielt of
    Drucker :      Begin
                     PlaySample:=0;
                     PSegment:=SampleDat[Welches].Segment;
                     POfset  :=SampleDat[Welches].Ofset;
                     Laenge  :=SampleDat[Welches].Laenge;
                     PlaySample:=1;
                   End;
    SoundBlaster : Begin
                     StopVoiceProcess;
                     PSegment:=SampleDat[Welches].Segment;
                     POfset  :=SampleDat[Welches].Ofset;
                     OutputVoice(PSegment,POfset);
                   End;
    Speaker :   Case Welches of
                  Schiess          : Begin
                                      Sound(500);
                                      Delay(500);
                                      NoSound;
                                    End;
                  Getroffen       : Begin
                                      Sound(300);
                                      Delay(500);
                                      NoSound;
                                    End;
                  BombeExplodiert : Begin
                                      Sound(300);
                                      Delay(1500);
                                      NoSound;
                                    End;
                  FlugGeraeusch   : Begin
                                      Sound(350);
                                      Delay(500);
                                      NoSound;
                                    End;
                End;
  End;
End;

Procedure InitAusgabe(Was : Byte);

Begin
  WasSpielt:=Was;
  Case WasSpielt of
    Drucker      : Begin
                     Zaehler:=$018D;       { Sample Rate = 3004 Hz }
                     Port[$43]:=54;
                     Port[$40]:=Lo(Zaehler);
                     Port[$40]:=Hi(Zaehler);
                     SetSamplePlay;
                   End;
    SoundBlaster : Begin
                     DACInit('');
                     OnOffSpeaker(1);
                   End;
  End;
  If WasSpielt>=Drucker then Begin
    New(Kanon);
    With SampleDat[Schiess] do Begin
      Segment:=Seg(Kanon^);
      Ofset  :=Ofs(Kanon^);
      LoadVoc('SHOOT3.VOC',Segment,Ofset);
    End;
    New(Kaputt);
    With SampleDat[Getroffen] do Begin
      Segment:=Seg(Kaputt^);
      Ofset  :=Ofs(Kaputt^);
      LoadVoc('EXPLODE.VOC',Segment,Ofset);
    End;
    New(Bomb);
    With SampleDat[BombeExplodiert] do Begin
      Segment:=Seg(Bomb^);
      Ofset  :=Ofs(Bomb^);
      LoadVoc('EXPLODE2.VOC',Segment,Ofset);
    End;
    New(Flug);
    With SampleDat[FlugGeraeusch] do Begin
      Segment:=Seg(Flug^);
      Ofset  :=Ofs(Flug^);
      LoadVoc('ABGAS1.VOC',Segment,Ofset);
    End;
    SampleDat[Schiess].Laenge         :=8000;
    SampleDat[Getroffen].Laenge      :=5036;
    SampleDat[BombeExplodiert].Laenge:=9656;
    SampleDat[FlugGeraeusch].Laenge  :=5732;
  End;
  If WasSpielt<>Drucker then SetTimerInt;
End;

Procedure CloseAusgabe;

Begin
  Case WasSpielt of
    Speaker      : NoSound;
    SoundBlaster : Begin
                     OnOffSpeaker(0);
                     DACClose;
                   End;
  End;
  ResetInt;
  If WasSpielt>Speaker then Begin
    Dispose(Kanon);
    Dispose(Kaputt);
    Dispose(Bomb);
    Dispose(Flug);
  End;
End;

{Begin
  InitAusgabe(Drucker);
    Spiel(Schiess);
    Repeat Until KeyPressed;
    While KeyPressed do ch:=ReadKey;
    Spiel(Treffer);
    Repeat Until KeyPressed;
    While KeyPressed do ch:=ReadKey;
    Spiel(BombeExplodiert);
    Repeat Until KeyPressed;
    While KeyPressed do ch:=ReadKey;
    Spiel(FlugGeraeusch);
    Repeat
      If PlaySample=0 then Spiel(FlugGeraeusch);
    Until KeyPressed;
    While KeyPressed do ch:=ReadKey;
  CloseAusgabe;}
End.