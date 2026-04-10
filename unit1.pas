unit Unit1;

{$Mode ObjFPC}
{$H+}{$J+}
{$Notes OFF}

interface

uses
  Classes, SysUtils, Forms,
  Controls, Graphics, Dialogs,
  ComCtrls, StdCtrls, LCLType,
  Buttons, ExtCtrls, FGL, StrUtils,
  LazUTF8, IniFiles,
  UAppState, ULogger;

type
  { TForm1 }

  TForm1 = class(TForm)
    CopyButton: TBitBtn;
    ClearButton: TBitBtn;
    OutputMemo: TMemo;
    SearchEdit: TEdit;
    ResultList: TListBox;
    PlaceholderText: TStaticText;
    StatusBar1: TStatusBar;
    OneShotTimer: TTimer;

    procedure CopyButtonClick(Sender: TObject);

    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    procedure OneShotTimerTimer(Sender: TObject);
    procedure PlaceholderTextClick(Sender: TObject);

    procedure ResultListDblClick(Sender: TObject);
    procedure SearchEditChange(Sender: TObject);
    procedure SearchEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ClearButtonClick(Sender: TObject);

  private
    state: TAppState;
    lastSearchText: string;

    procedure loadSavedOutput;
    procedure loadSavedQuery;
    procedure saveLastOutput;
    procedure saveLastQuery;

    procedure saveWindowPosSize;
    procedure loadWindowPosSize;

    procedure setReportLabel(txt: string);
    function SearchText: UTF8String;
    procedure appendSelectedEntry;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}


{ TForm1 }

procedure TForm1.FormShow(Sender: TObject);
begin
  initLogger;
  loadWindowPosSize
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  saveLastQuery;
  saveLastOutput;
  saveWindowPosSize;

  CanClose := true;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  a: word;
begin
  state.free;
  closeLogger
end;

procedure TForm1.OneShotTimerTimer(Sender: TObject);
begin
  OneShotTimer.Enabled := false;

  SearchEdit.ReadOnly := true;

  { writelog('Test logger!'); }

  state := TAppState.create;

  setReportLabel('Loading dictionary...');
  Application.ProcessMessages;
  state.loadDictionary;

  setReportLabel('Loading Jyutping readings...');
  Application.ProcessMessages;
  state.loadCharReadings;

  setReportLabel(format('Loaded %d entries', [state.EntryCount]));

  SearchEdit.ReadOnly := false;
  SearchEdit.clear;
  ResultList.clear;
  OutputMemo.clear;

  loadSavedOutput;
  loadSavedQuery

  { Begin debug }

  { for a:=0 to 9 do
    OutputMemo.Lines.add(entries[a].yue); }

  { Show the possible readings }

  {
  if state.readings.count > 0 then
    for a:=0 to state.readings.count-1 do begin
      list := state.readings.data[a];

      if list.count = 1 then continue;

      list.Delimiter := ',';
      list.StrictDelimiter := true;

      OutputMemo.lines.add(
        format('%s: %s', [state.readings.keys[a], list.DelimitedText]));
    end;
  }
end;

procedure TForm1.PlaceholderTextClick(Sender: TObject);
begin
  SearchEdit.SetFocus
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

procedure TForm1.saveLastQuery;
var
  f: text;
begin
  AssignFile(f, 'last_query.txt');
  rewrite(f);
  writeln(f, SearchText);
  CloseFile(f)
end;

procedure TForm1.loadSavedQuery;
var
  f: text;
  line: string;
begin
  if not FileExists('last_query.txt') then exit;

  assignfile(f, 'last_query.txt');
  reset(f);
  readln(f, line);
  SearchEdit.Text := line;
  closefile(f)
end;

procedure TForm1.loadSavedOutput;
var
  sl: TStringListUTF8Fast;
begin
  if not FileExists('last_output.txt') then exit;

  sl := TStringListUTF8Fast.create;
  sl.LoadFromFile('last_output.txt');
  OutputMemo.Text := sl.text;
  sl.free
end;

procedure TForm1.saveLastOutput;
var
  f: text;
begin
  { Save the last output }
  AssignFile(f, 'last_output.txt');
  rewrite(f);
  write(f, OutputMemo.Text);
  CloseFile(f);
end;

procedure TForm1.saveWindowPosSize;
var
  f: TIniFile;
begin
  f := TIniFile.create(Application.Location + 'jyutpad.ini');

  f.WriteInteger('window', 'x', left);
  f.WriteInteger('window', 'y', top);
  f.WriteInteger('window', 'width', width);
  f.WriteInteger('window', 'height', height);

  f.free
end;

procedure TForm1.loadWindowPosSize;
var
  f: TIniFile;
begin
  if not FileExists('jyutpad.ini') then exit;

  f := TIniFile.create(Application.Location + 'jyutpad.ini');

  self.left := f.ReadInteger('window', 'x', (Screen.width - self.width) div 2);
  self.top := f.ReadInteger('window', 'y', (screen.height - self.height) div 2);
  self.width := f.ReadInteger('window', 'width', self.width);
  self.height := f.ReadInteger('window', 'height', self.height);

  f.free
end;

function TForm1.SearchText: UTF8String;
var
  query: string;
begin
  query := trim(SearchEdit.Text);

  while UTF8Pos('  ', query) > 0 do
    query := ReplaceStr(query, '  ', ' ');

  SearchText := query
end;

procedure TForm1.ResultListDblClick(Sender: TObject);
begin
  appendSelectedEntry;
  SearchEdit.SetFocus
end;

procedure TForm1.SearchEditChange(Sender: TObject);
begin
  if state.EntryCount = 0 then exit;

  if lastSearchText <> SearchText then begin
    lastSearchText := SearchText;

    ResultList.clear;

    if SearchText = '' then begin
      setReportLabel('Empty input');
      PlaceholderText.Visible := true;
    end else
      PlaceholderText.Visible := false;

    ResultList.Items.AddStrings(state.SearchEntries(SearchText));

    if ResultList.Count > 0 then
      setReportLabel(format('Found %d results in ? seconds', [ResultList.items]))
    else
      setReportLabel('No results');

    if ResultList.Count > 0 then
      ResultList.ItemIndex := 0;
  end;
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

