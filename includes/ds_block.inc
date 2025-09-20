Procedure Block(x1,y1,x2,y2 : Word; Colour : Byte);

Var b,h : Word;

Begin
  For h:=y1 to y2 do
    For b:=x1 to x2 do
      SetPoint(b,h,Colour);
End;
