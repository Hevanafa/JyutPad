unit Unit1;

{$mode objfpc}
{$H+}
{$Codepage UTF8}

interface

uses
  Classes, SysUtils, Forms,
  Controls, Graphics, Dialogs, StdCtrls, LazUTF8;

type

  { TForm1 }

  TForm1 = class(TForm)
    Memo1: TMemo;
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormShow(Sender: TObject);
begin
  Memo1.lines.add('你好');
  memo1.lines.add(inttostr(utf8pos('#', '世界#')))
end;

end.

