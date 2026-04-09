unit UAppState;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses
  SysUtils, Classes, FGL, LazUTF8;

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
  TReadingDict = specialize TFPGMap<UTF8String, TStringList>;

implementation

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

end.

