Program Flug_auf_Karte;

Uses Graph,Mouse,Crt;

Type  Daten = Array[0..160] of Byte;
      FarbHirestyp  = Array[0..47] of Byte;
      Koord = Record
                X,Y : Integer;
              End;

Const Driver : Integer = VGA;
      Mode   : Integer = VGAHi;
      Menge  = 7862;

Var dr        : Integer;
    Sprite,
    Grund     : ^Daten;
    x,y,B,Z,i : Word;
    Palette   : FarbHiresTyp;
    Pos       : Array[0..10000] of Koord;
    f         : File;

Procedure WritePlane(Nr : Byte);

  Begin
    Nr:=Nr AND 3;
    Port[$3C4]:=2;
    Port[$3C5]:=1 shl Nr;
  End;

Procedure LoadHiresPic(Name : String;Var Farben : FarbHirestyp);

  Var f : File;
      p : Byte;

  Begin
    Assign(f,Name);
    Reset(f,1);
    BlockRead(f,Farben,48);
    For p:=0 to 3 do Begin
      WritePlane(p);
      BlockRead(f,Mem[$A000:$0000],38400);
    End;
    Close(f);
  End;

Procedure VGADriver; External;
  {$L VGA.OBJ }

Begin
  dr:=RegisterBGIDriver(@VGADriver);
  InitGraph(Driver,Mode,'');
{  dr:=InitMouse;
  HideMouse;}
  New(Sprite); New(Grund);
  SetColor(2);
  For dr:=0 to 4 do
    Circle(8,8,dr);
  GetImage(4,4,12,12,Sprite^);

  LoadHiresPic('C:\TP6\PICSHERO\MAP2.BLD',Palette);
  Assign(f,'FlugKord.map');
  Reset(f,1);
  BlockRead(f,Pos,(Menge*4));
  Close(f);

{  Z:=0;
  Repeat
    GetMouse(x,y,B);
    GetImage(x,y,x+9,y+9,Grund^);
    PutImage(x,y,Sprite^,NotPut);
    WaitMouse;
    If Not ButtonPressed then PutImage(x,y,Grund^,NormalPut)
    Else
    Begin
      Pos[Z].X:=x;
      Pos[Z].Y:=y;
      Inc(Z);
      If Z>10000 then Z:=10000;
    End;
  Until B=RightButton;
  LoadHiresPic('C:\TP6\PICSHERO\MAP2.BLD',Palette);}
    For i:=0 to Menge Div 16 do Begin
      PutImage(Pos[i*16].X,Pos[i*16].Y,Sprite^,ORPut);
      Delay(10);
    End;
{  Repeat
  Until ButtonPressed;
  GetMouse(x,y,B);
  If B=RightButton then Begin
    Assign(f,'FlugKord.map');
    Rewrite(f,1);
    BlockWrite(f,Pos,(Z*4));
    Close(f);
  End;}
  Repeat Until KeyPressed;
  CloseGraph;
End.