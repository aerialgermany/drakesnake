Unit PlayDrk2;

Interface

Uses Crt,SB_DAC,Dos;



Const SBAdress    : Word = 220;
      FreiesWord   = $F0;
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
Procedure InitAusgabe;
Procedure CloseAusgabe;


Implementation

Type KanonBuff  = Array[0..8057] of Byte;
     KaputtBuff = Array[0..5091] of Byte;
     BombBuff   = Array[0..9711] of Byte;
     FlugBuff   = Array[0..5790] of Byte;
     Zeiger     = Record
                    Segment,Ofset,Laenge : Word;
                  End;

Const LaengeS : Array[0..2] of Byte = (08,17,10);

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
    Spiele     : Boolean;
    SoundDat   : Array[0..2,0..40] of Word;

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
  If WasSpielt=Speaker then
    If Spiele then
      If Zaehler>LaengeS[PlaySample] then Begin
        Spiele:=False;
        Zaehler:=0;
        NoSound;
      End Else
      Begin
        Sound(SoundDat[PlaySample,Zaehler]);
        Inc(Zaehler);
      End;
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

Var f : Word;

Begin
  Case WasSpielt of
    SoundBlaster : Begin
                     StopVoiceProcess;
                     PSegment:=SampleDat[Welches].Segment;
                     POfset  :=SampleDat[Welches].Ofset;
                     OutputVoice(PSegment,POfset);
                   End;
    Speaker :      Begin
                     Spiele:=False;
                     NoSound;
                     Zaehler:=0;
                     PlaySample:=Welches;
                     Spiele:=True;
                   End;
  End;
End;

Procedure InitAusgabe;

Var f : File;

Begin
  If DACInit('')=0 then Begin
    WasSpielt:=SoundBlaster;
    OnOffSpeaker(1);
  End Else
  Begin
    WasSpielt:=Speaker;
    Assign(f,'SPEAKER.SND');
    Reset(f,1);
    BlockRead(f,SoundDat[0,0],20);
    BlockRead(f,SoundDat[1,0],40);
    BlockRead(f,SoundDat[2,0],10);
    Close(f);
  End;
  Spiele:=False;
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

End.