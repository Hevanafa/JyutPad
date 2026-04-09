unit UAppState;

{$Mode ObjFPC}
{$H+}{$J-}
{$Notes OFF}

interface

uses
  SysUtils, Classes, StrUtils, FGL, LazUTF8;

type
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
  TReadingDict = specialize TFPGMapObject<UTF8String, TStringList>;

  { TAppState }

  TAppState = class
  private
    procedure loadCharReadings;
    procedure loadDictionary;
  public
    rawDict: TStringList;
    entries: TEntryList;
    readings: TReadingDict;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses ULogger;

{ TDictEntry }

constructor TDictEntry.Create(rawEntry: UTF8String);
var
  startIdx, endIdx: longint;
  pair: TStringArray;
begin
  { Substring and IndexOf use base 0 instead of the usual 1 }
  startIdx := UTF8Pos('[', rawEntry);
  endIdx := utf8pos(']', rawEntry);

  self.fMandarin := UTF8Copy(rawEntry, startIdx + 1, endIdx - startIdx - 1);

  pair := utf8copy(rawEntry, 1, endIdx - startIdx)
    .replace('，', '')
    .replace('…', '')
    .trim
    .split(' ');

  self.fHanzi := pair[0];

  startIdx := utf8pos('{', rawEntry);
  endIdx := utf8pos('}', rawEntry);

  self.fYue := utf8copy(rawEntry, startIdx + 1, endIdx - startIdx - 1)
    .replace('，', '')
    .replace('…', '')
    .replace(',', '')
end;

procedure TAppState.loadDictionary;
var
  f: text;
  line: utf8string;
begin
  AssignFile(f, 'cccanto-webdist.txt');
  reset(f);

  rawDict := TStringList.create;

  while not eof(f) do begin
    readln(f, line);

    if UTF8Pos('#', line) = 1 then continue;

    if UTF8Pos('#', line) > 0 then begin
      rawDict.add(UTF8Copy(line, 1, utf8pos('#', line) - 1))
    end else
      rawDict.add(line);
  end;

  CloseFile(f);

  { for a:=0 to 19 do
    OutputMemo.Lines.add(IntToStr(UTF8Pos('#', rawDict[a]))); }

  entries := TEntryList.create;

  for line in rawDict do
    entries.add(TDictEntry.Create(line));

  rawDict.clear;
  rawDict.free
end;

procedure TAppState.loadCharReadings;
var
  entryIdx: word;  { for debugging }
  entry: TDictEntry;
  strList: TStringList;
  syllables: TStringArray;
  a: word;
  c: utf8string;
  s: string;
begin
  readings := TReadingDict.create(true);
  entryIdx := 0;

  try
    for entry in entries do begin
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

  except
    on E: Exception do begin
      s := format('Error on entry number %d: %s, when checking this hanzi: %s', [entryIdx, e.Message, entry.hanzi]);

      if strList <> nil then strList.free;

      writeLog(s)
    end;
  end;
end;

constructor TAppState.Create;
begin
  loadDictionary;
  loadCharReadings
end;

destructor TAppState.Destroy;
begin
  { rawDict.free; }
  entries.free;

  { Optional with TFPGMapObject }
  { if readings.count > 0 then
    for a:=0 to readings.count-1 do
      readings.data[a].free;

  readings.clear; }

  readings.free;

  inherited Destroy
end;

end.

