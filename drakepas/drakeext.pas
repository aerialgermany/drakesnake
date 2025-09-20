Unit DrakeExt;

Interface

Uses HeroSpiel,Crt,Dos,GameCon,Joystick,DSAnfang;

Procedure Block(x1,y1,x2,y2 : Word; Colour : Byte);
Procedure VLine(x,y1,y2 : Word; Colour : Byte);
Procedure LoadSprite(Name : String;Wohin : Pointer);

Implementation

Procedure Block(x1,y1,x2,y2 : Word; Colour : Byte);

Var b,h : Word;

Begin
  For h:=y1 to y2 do
    For b:=x1 to x2 do
      SetPoint(b,h,Colour);
End;

Procedure VLine(x,y1,y2 : Word; Colour : Byte);

Var h : Word;

Begin
  For h:=y1 to y2 do
    SetPoint(x,h,Colour);
End;

Procedure LoadSprite(Name : String;Wohin : Pointer);

Var f      : File;
    result : Word;

Begin
  Assign(f,Name);
  Reset(f,1);
  BlockRead(f,Wohin^,50000,result);
  Close(f);
End;

End.

