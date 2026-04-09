program project;

{$Mode ObjFPC}
{$H+}{$J-}

uses
  Interfaces,
  Forms, Unit1, UAppState, ULogger;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='JyutPad';
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

