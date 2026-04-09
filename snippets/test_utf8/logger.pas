unit Logger;

{$Mode ObjFPC}
{$H+}{$J-}

interface

uses
  Classes, SysUtils;

procedure initLogger;
procedure writeLog(line: string);
procedure closeLogger;


implementation

var
  logFile: text;

procedure initLogger;
begin
  AssignFile(logFile, 'log.txt');
  {$I-} rewrite(logFile) {$I+}
end;

procedure writeLog(line: string);
begin
  writeln(logfile, line);
  flush(logfile)
end;

procedure closeLogger;
begin
  CloseFile(logFile)
end;

end.

