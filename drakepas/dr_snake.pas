Program DrakeSnakeVorspann;

Uses Crt;

Type  Farbtyp = Array[0..47] of Byte;

Const Hires  = $12; Lores = $0D; MultiColour = $13; EndGraphic = $03;
      Screen = $A000;

Var Palette,
    Pal2    : Farbtyp;
    f       : File;
    p       : Byte;
    i,x,y   : Word;
    ch      : Char;

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

  Begin
    ASM
      xor    AH,AH      { Modus $12 }
      mov    AL,Modus
      int    10h
    End
  End;

Procedure SetHiresPalette(Farb : Farbtyp);

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

Procedure BildSpeicher(Posit : LongInt; Wert : Byte);

  Var Segment : Word;
      Plane   : Byte;

  Begin
    Segment:=(Posit Mod 80)+80*(Posit Div 320);
    Plane:=(Posit Div 80) Mod 4;
    WritePlane(Plane);
    Mem[Screen:Segment]:=Wert;
  End;

Procedure LoadHiresIFF(Name : String);

  Type Puffer = Array[0..3000] of Byte;

Var  i,X,Y,Z            : Word;
     ZeigerQ,ZeigerD    : LongInt;
     Bild,Bild2         : ^Puffer;
     Pic                : File;
     FORM,ILBM,BMHD,
     CMAP,BODY,UNDF     : Array[0..3] of Char;
     Lform,Lbmhd,Lcmap,
     Lbody,Lundf        : LongInt;
     result,
     HoeheG,BreiteG,XG,
     YG,TransC,BreiteQ,
     HoeheQ,Position    : Word;
     AnzBitPlanes,Mask,
     Kompress,None,XAsp,
     YAsp,Buf           : Byte;

Begin
  DirectVideo:=False;
  TextColor(White);
  New(Bild);
  Assign(Pic,Name);
  Reset(Pic,1);
  BlockRead(Pic,Bild^,48,result);
  FORM[0]:=Chr(Bild^[0]);  FORM[1]:=Chr(Bild^[1]);      { 'FORM' / Long }
  FORM[2]:=Chr(Bild^[2]);  FORM[3]:=Chr(Bild^[3]);
  If Pos('FORM',FORM)=0 then Begin
    WriteLn('Kein IFF-File !');
    Halt;
  End;
  Lform:=Bild^[6]; Lform:=Lform shl 8;
  Lform:=Lform+Bild^[7];
  ILBM[0]:=Chr(Bild^[8]);   ILBM[1]:=Chr(Bild^[9]);       { 'ILBM' / Long }
  ILBM[2]:=Chr(Bild^[10]);  ILBM[3]:=Chr(Bild^[11]);
  If Pos('ILBM',ILBM)=0 then Begin
    WriteLn('Keine Bilddatei !');
    Halt;
  End;
  BMHD[0]:=Chr(Bild^[12]);  BMHD[1]:=Chr(Bild^[13]);      { 'BMHD' / Long }
  BMHD[2]:=Chr(Bild^[14]);  BMHD[3]:=Chr(Bild^[15]);
  If Pos('BMHD',BMHD)=0 then Begin
    WriteLn('Kein Bit Map Header !');
    Halt;
  End;
  { DatenKompression (0 - nicht gepackt / 1 - gepackt) }
  Kompress:=Bild^[30];

  CMAP[0]:=Chr(Bild^[40]);  CMAP[1]:=Chr(Bild^[41]);          { 'CMAP' / Long }
  CMAP[2]:=Chr(Bild^[42]);  CMAP[3]:=Chr(Bild^[43]);
  If Pos('CMAP',CMAP)=0 then Begin
    WriteLn('Keine Colour Map !');
    Halt;
  End;
  { LÑnge der CMAP / Long }
  Lcmap:=Bild^[46]; Lcmap:=Lcmap shl 8; Lcmap:=Lcmap+Bild^[47];
  BlockRead(Pic,Palette,48);
  Repeat                                                  { 'BODY' / Long }
    BlockRead(Pic,Bild^,8);
    BODY[0]:=Chr(Bild^[0]);  BODY[1]:=Chr(Bild^[1]);
    BODY[2]:=Chr(Bild^[2]);  BODY[3]:=Chr(Bild^[3]);
    WriteLn(BODY);
    Lbody:=Bild^[5]; Lbody:=Lbody shl 8; Lbody:=Lbody+Bild^[6];
    Lbody:=Lbody shl 8; Lbody:=Lbody+Bild^[7];
    If Pos('BODY',BODY)=0 then
      BlockRead(Pic,Bild^,Lbody);
  Until Pos('BODY',BODY)<>0;

  ZeigerD:=0;
  If Kompress=1 then Begin
    Repeat
      BlockRead(Pic,Z,1);
      If Z<=128 then
        For X:=0 to Z do Begin
          BlockRead(Pic,Buf,1);
          BildSpeicher(ZeigerD,Buf);
          Inc(ZeigerD);
        End
      Else Begin
        BlockRead(Pic,Buf,1);
        For X:=0 to (256-Z) do Begin
          BildSpeicher(ZeigerD,Buf);
          Inc(ZeigerD);
        End;
      End;
    Until ZeigerD>=153600;
  End Else
    Repeat
      BlockRead(Pic,Buf,1);
      BildSpeicher(ZeigerD,Buf);
      Inc(ZeigerD);
    Until ZeigerD>=153600;
  Close(Pic);
  Dispose(Bild);
  DirectVideo:=True;
  End;

Begin
  InitMode(Hires);
  For p:=0 to 47 do Palette[p]:=0;
  SetHiresPalette(Palette);
  Assign(f,'DR_SNAKE.BLD');
  Reset(f,1);
  BlockRead(f,Palette,48);
  For p:=0 to 3 do Begin
    WritePlane(p);
    BlockRead(f,Mem[Screen:$0000],38400);
  End;
  Close(f);
  Sound(5000); Delay(50); NoSound;
  Repeat Until KeyPressed;
  While KeyPressed do ch:=ReadKey;
  For x:=0 to 256 do Begin
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 8;
    SetHiresPalette(Pal2);
  End;
  Repeat Until KeyPressed;
  While KeyPressed do ch:=ReadKey;
  For x:=256 downto 0 do Begin
    For y:=0 to 47 do
      Pal2[y]:=(Palette[y]*x) shr 8;
    SetHiresPalette(Pal2);
  End;
  InitMode(EndGraphic);
End.