Procedure LoadSprite(Name : String;Wohin : Pointer);

Var f      : File;
    result : Word;

Begin
  Assign(f,Name);
  Reset(f,1);
  BlockRead(f,Wohin^,50000,result);
  Close(f);
End;
