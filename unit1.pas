unit Unit1;

{$Mode ObjFPC}
{$H+}{$J+}
{$Notes OFF}

interface

uses
  Classes, SysUtils, Forms,
  Controls, Graphics, Dialogs,
  ComCtrls, StdCtrls, LCLType, Buttons,
  FGL,
  StrUtils, LazUTF8;

type

  { TDictEntry }

  TDictEntry = class
  private
    fHanzi: UTF8String;
    fMandarin: UTF8String;
    fYue: UTF8String;
    { fDefinition: UTF8String; }
  public
    constructor Create(rawEntry: UTF8String);

    property Hanzi: UTF8String read fHanzi;
    property Mandarin: UTF8String read fMandarin;
    property Yue: UTF8String read fYue;
    { property Definition: string read fDefinition; }
  end;

  TEntryList = specialize TFPGObjectList<TDictEntry>;
  TReadingDict = specialize TFPGMap<string, TStringList>;

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
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure ResultListDblClick(Sender: TObject);
    procedure SearchEditChange(Sender: TObject);
    procedure SearchEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure appendSelectedEntry;
  private
    rawDict: TStringList;
    entries: TEntryList;
    readings: TReadingDict;

    function SearchText: UTF8String;
    procedure setReportLabel(txt: string);
    procedure loadDictionary;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TDictEntry }

constructor TDictEntry.Create(rawEntry: UTF8String);
var
  startIdx, endIdx: longint;
  pair: TStringArray;
begin
  { Substring and IndexOf use base 0 instead of the usual 1 }
  startIdx := UTF8Pos(rawEntry, '[');
  endIdx := utf8pos(rawEntry, ']');

  self.fMandarin := UTF8Copy(rawEntry, startIdx + 1, endIdx - startIdx - 1);

  pair := utf8copy(rawEntry, 1, endIdx - startIdx)
    .replace('，', '')
    .replace('…', '')
    .trim
    .split(' ');

  self.fHanzi := pair[0];

  startIdx := utf8pos(rawEntry, '{');
  endIdx := utf8pos(rawEntry, '}');

  self.fYue := utf8copy(rawEntry, startIdx + 1, endIdx - startIdx - 1)
    .replace('…', '')
end;

{ TForm1 }

procedure TForm1.loadDictionary;
var
  f: text;
  line: string;
  newEntry, entry: TDictEntry;
  entryIdx: word;  { for debugging }
  strList: TStringList;
  syllables: TStringArray;
  a: word;
  c: string;
begin
  AssignFile(f, 'cccanto-webdist.txt');
  reset(f);

  rawDict := TStringList.create;

  while not eof(f) do begin
    readln(f, line);
    if line.StartsWith('#') then continue;

    if line.Contains('#') then begin
      rawDict.add(line.Substring(1, line.IndexOf('#') - 1))
    end else
      rawDict.add(line);
  end;

  CloseFile(f);

  entries := TEntryList.create;

  for line in rawDict do
    entries.add(TDictEntry.Create(line));

  rawDict.clear;

  readings := TReadingDict.create;

  entryIdx := 0;

  for entry in entries do begin
    { syllables := entry.Yue.Split(' '); }
    syllables := SplitString(entry.Yue, ' ');

    for a := 1 to UTF8Length(entry.Hanzi) do begin
      c := UTF8Copy(entry.Hanzi, a, 1);

      if readings.IndexOf(c) >= 0 then begin
        strList := readings[c];

        if strList.IndexOf(syllables[a - 1]) < 0 then
          strList.Add(syllables[a - 1]);
      end else begin
        strList := TStringList.create;
        strList.Add(syllables[a - 1]);
        readings.add(c, strList);
      end;
    end;

    inc(entryIdx)
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  a: word;
begin
  loadDictionary;

  SearchEdit.clear;
  ResultList.clear;
  OutputMemo.clear;

  setReportLabel(format('Loaded %d entries', [entries.count]));

  { for a:=0 to 9 do
    OutputMemo.Lines.add(entries[a].yue); }

  { OutputMemo.Text := ; }
end;
    
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  rawDict.free;
  entries.free;
  readings.free;
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
const
  SearchLimit = 20;
var
  count: smallint;
  a: word;
begin
  count := 0;
  ResultList.clear;

  if entries.count = 0 then exit;

  if SearchText = '' then begin
    ResultList.clear;
    exit
  end;

  for a:=0 to entries.count - 1 do begin
    { if entries[a].fYue.StartsWith(SearchText) then begin }
    if UTF8Copy(entries[a].fYue, 1, UTF8Length(SearchText)) = SearchText then begin
      ResultList.Items.Add(entries[a].Hanzi);
      inc(count)
    end;

    if count >= SearchLimit then break;
  end;

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

