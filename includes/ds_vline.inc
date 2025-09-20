Procedure VLine(xVL,y1VL,y2VL : Word; ColourVL : Byte);

Var h : Word;

Begin
  For h:=y1VL to y2VL do
    SetPoint(xVL,h,ColourVL);
End;
