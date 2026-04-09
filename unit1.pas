unit Unit1;

{$Mode ObjFPC}
{$H+}{$J+}
{$Notes OFF}

interface

uses
  Classes, SysUtils, Forms,
  Controls, Graphics, Dialogs,
  ComCtrls, StdCtrls, LCLType,
  Buttons, FGL, StrUtils, LazUTF8,
  UAppState, ULogger;

type
  { TForm1 }

  TForm1 = class(TForm)
    CopyButton: TBitBtn;
    ClearButton: TBitBtn;
    OutputMemo: TMemo;
    SearchEdit: TEdit;
    ResultList: TListBox;
    StatusBar1: TStatusBar;

    procedure ClearButtonClick(Sender: TObject);
    procedure CopyButtonClick(Sender: TObject);

    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    procedure ResultListDblClick(Sender: TObject);
    procedure SearchEditChange(Sender: TObject);
    procedure SearchEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure appendSelectedEntry;
  private
    state: TAppState;

    function SearchText: UTF8String;
    procedure setReportLabel(txt: string);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}


{ TForm1 }

procedure TForm1.FormShow(Sender: TObject);
var
  a: word;
  list: TStringList;
begin
  initLogger;
  { writelog('Test logger!'); }

  state := TAppState.create;

  SearchEdit.clear;
  ResultList.clear;
  OutputMemo.clear;

  setReportLabel(format('Loaded %d entries', [state.entries.count]));

  { Begin debug }
  { for a:=0 to 9 do
    OutputMemo.Lines.add(entries[a].yue); }

  { Show the possible readings }

  if state.readings.count > 0 then
    for a:=0 to state.readings.count-1 do begin
      list := state.readings.data[a];

      if list.count = 1 then continue;

      list.Delimiter := ',';
      list.StrictDelimiter := true;

      OutputMemo.lines.add(
        format('%s: %s', [state.readings.keys[a], list.DelimitedText]));
    end;
end;
    
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  a: word;
begin
  state.free;

  closeLogger
end;

procedure TForm1.CopyButtonClick(Sender: TObject);
begin
  OutputMemo.SelectAll;
  OutputMemo.CopyToClipboard;

  OutputMemo.SelLength := 0;

  setReportLabel('Copied to the clipboard!')
end;

procedure TForm1.ClearButtonClick(Sender: TObject);
begin
  OutputMemo.clear;
  setReportLabel('Cleared the output')
end;

procedure TForm1.appendSelectedEntry;
begin
  if ResultList.SelCount = 0 then exit;

  OutputMemo.text := OutputMemo.text + ResultList.items[ResultList.ItemIndex]
end;

function TForm1.SearchText: UTF8String;
begin
  SearchText := trim(SearchEdit.Text)
end;

procedure TForm1.ResultListDblClick(Sender: TObject);
begin
  appendSelectedEntry
end;

procedure TForm1.SearchEditChange(Sender: TObject);
begin
  ResultList.clear;

  if state.entries.count = 0 then exit;

  if SearchText = '' then begin
    ResultList.clear;
    exit
  end;

  ResultList.Items.AddStrings(state.SearchEntries(SearchText));

  if ResultList.Count > 0 then
    ResultList.ItemIndex := 0;
end;

procedure TForm1.SearchEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case key of
  VK_RETURN:
    appendSelectedEntry;

  VK_UP:
    if ResultList.ItemIndex - 1 >= 0 then
      ResultList.ItemIndex := ResultList.ItemIndex - 1;
  vk_down:
    if ResultList.ItemIndex + 1 < ResultList.count then
      ResultList.ItemIndex := ResultList.ItemIndex + 1;
  end;
end;

procedure TForm1.setReportLabel(txt: string);
begin
  StatusBar1.Panels[0].Text := txt
end;

end.

