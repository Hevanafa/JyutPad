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
    fRawDict: TStringList;
    fEntries: TEntryList;
    fReadings: TReadingDict;

  public
    procedure loadCharReadings;
    procedure loadDictionary;

    function SearchEntries(const searchTerm: string): TStringArray;
    function EntryCount: integer;

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

  fRawDict := TStringList.create;

  while not eof(f) do begin
    readln(f, line);

    if UTF8Pos('#', line) = 1 then continue;

    if UTF8Pos('#', line) > 0 then begin
      fRawDict.add(UTF8Copy(line, 1, utf8pos('#', line) - 1))
    end else
      fRawDict.add(line);
  end;

  CloseFile(f);

  { for a:=0 to 19 do
    OutputMemo.Lines.add(IntToStr(UTF8Pos('#', fRawDict[a]))); }

  fEntries := TEntryList.create;

  for line in fRawDict do
    fEntries.add(TDictEntry.Create(line));

  fRawDict.clear;
  fRawDict.free
end;

function TAppState.SearchEntries(const searchTerm: string): TStringArray;
const
  SearchLimit = 20;
var
  count: word;
  a: word;
  row, col: word;
begin
  count := 0;
  SetLength(SearchEntries, 0);

  if UTF8Pos(' ', searchTerm) = 0 then begin
    { Perform search per-character by reading }
    if fReadings.Count > 0 then
      for row:=0 to fReadings.count - 1 do begin
        for col:=0 to fReadings.data[row].count-1 do begin
          if UTF8StartsText(searchTerm, fReadings.data[row][col]) then begin
            SetLength(SearchEntries, length(SearchEntries) + 1);
            SearchEntries[high(SearchEntries)] := fReadings.keys[row];

            inc(count)
          end;

          if count >= SearchLimit then break;
        end;

        if count >= SearchLimit then break;
      end;
  end;

  for a:=0 to fEntries.count - 1 do begin
    if UTF8StartsText(searchTerm, fEntries[a].Yue) then begin
      SetLength(SearchEntries, length(SearchEntries) + 1);
      SearchEntries[high(SearchEntries)] := fEntries[a].Hanzi;

      inc(count)
    end;

    if count >= SearchLimit then break;
  end;
end;

function TAppState.EntryCount: integer;
begin
  EntryCount := fEntries.Count
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
  fReadings := TReadingDict.create(true);
  entryIdx := 0;

  try
    for entry in fEntries do begin
      syllables := SplitString(entry.Yue, ' ');

      for a := 1 to UTF8Length(entry.Hanzi) do begin
        c := UTF8Copy(entry.Hanzi, a, 1);

        if fReadings.IndexOf(c) >= 0 then begin
          strList := fReadings[c];

          if strList.IndexOf(syllables[a - 1]) < 0 then
            strList.Add(syllables[a - 1]);
        end else begin
          strList := TStringList.create;
          strList.Add(syllables[a - 1]);
          fReadings.add(c, strList);
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
  { loadDictionary;
  loadCharReadings }
end;

destructor TAppState.Destroy;
begin
  { fRawDict.free; }
  fEntries.free;

  { Optional with TFPGMapObject }
  { if fReadings.count > 0 then
    for a:=0 to fReadings.count-1 do
      fReadings.data[a].free;

  fReadings.clear; }

  fReadings.free;

  inherited Destroy
end;

end.

