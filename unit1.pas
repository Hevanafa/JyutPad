unit Unit1;

{$Mode ObjFPC}
{$H+}{$J+}

interface

uses
  Classes, SysUtils, Forms,
  Controls, Graphics, Dialogs, ComCtrls, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    OutputMemo: TMemo;
    SearchEdit: TEdit;
    ResultList: TListBox;
    StatusBar1: TStatusBar;
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

end.

