unit Unit1;

{$Mode ObjFPC}
{$H+}{$J+}
{$Notes OFF}

interface

uses
  Classes, SysUtils, Forms,
  Controls, Graphics, Dialogs,
  ComCtrls, StdCtrls, FGL;

type

  { TDictEntry }

  TDictEntry = class
  private
    fHanzi: string;
    fMandarin: string;
    fYue: string;
    fDefinition: string;
  public
    constructor Create(rawEntry: string);

    property Hanzi: string read fHanzi;
    property Mandarin: string read fMandarin;
    property Yue: string read fYue;
    property Definition: string read fDefinition;
  end;

  TEntryList = specialize TFPGObjectList<TDictEntry>;

  TForm1 = class(TForm)
    OutputMemo: TMemo;
    SearchEdit: TEdit;
    ResultList: TListBox;
    StatusBar1: TStatusBar;
    procedure FormShow(Sender: TObject);
  private
    rawDict: TStringList;
    entries: TEntryList;

    procedure loadDictionary;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TDictEntry }

constructor TDictEntry.Create(rawEntry: string);
var
  startIdx, endIdx: longint;
begin
  startIdx := rawEntry.IndexOf('[');
  endIdx := rawEntry.IndexOf(']');

  self.fHanzi := rawEntry.Substring(startIdx + 1, endIdx - startIdx - 1)

  { TODO: Load Hanzi }
  { TODO: Load Yue }
  { TODO: Load definition }
end;

{ TForm1 }

procedure TForm1.loadDictionary;
var
  f: text;
  line: string;
  newEntry: TDictEntry;
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

end;

procedure TForm1.FormShow(Sender: TObject);
var
  a: word;
begin
  loadDictionary;

  SearchEdit.clear;
  ResultList.clear;
  OutputMemo.clear;

  OutputMemo.Text := format('Loaded %d entries', [rawDict.count]);

  for a:=0 to 9 do
    OutputMemo.Lines.add(entries[a].Hanzi);
end;

end.

