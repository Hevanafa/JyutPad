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
    procedure FormShow(Sender: TObject);
  private
    dict: TStringList;

    procedure loadDictionary;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.loadDictionary;
var
  f: text;
  line: string;
begin
  AssignFile(f, 'cccanto-webdist.txt');
  reset(f);

  dict := TStringList.create;

  while not eof(f) do begin
    readln(f, line);
    if line.StartsWith('#') then continue;

    if line.Contains('#') then begin
      dict.add(line.Substring(1, line.IndexOf('#') - 1))
    end else
      dict.add(line);
  end;

  CloseFile(f)
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  loadDictionary;

  SearchEdit.clear;
  ResultList.clear;
  OutputMemo.clear;

  OutputMemo.Text := format('Loaded %d entries', [dict.count]);
end;

end.

