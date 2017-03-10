MODULE args;
(* this module is intended to be the wrapper for different argument parsing modules from different compilers*)
IMPORT (* for oo2c *)ProgramArgs, TextRider, Out, strnutils; 

CONST notfound* = "not found";

PROCEDURE argscount*() : LONGINT;
VAR r : TextRider.Reader;
l : LONGINT;
BEGIN
r := TextRider.ConnectReader(ProgramArgs.args);
IF r = NIL THEN  Out.String ("failed to connect reader to 'args'"); Out.Ln END;
l := ProgramArgs.args.ArgNumber();
RETURN(l);

END argscount;


PROCEDURE arg*(l : LONGINT) : strnutils.pstring;
VAR r : TextRider.Reader;
s : strnutils.string;
ps : strnutils.pstring;
i : LONGINT;
BEGIN
r := TextRider.ConnectReader(ProgramArgs.args);
IF r = NIL THEN Out.String ("failed to connect reader to 'args'"); Out.Ln; END;
i := argscount();
IF argscount() = 0 THEN Out.String ("no arguments given"); Out.Ln; NEW (ps); ps^
:= "not found"; RETURN (ps) END;
FOR i := 0 TO l DO
r.ReadLine(s);
END;
NEW(ps);
ps^ := s;
RETURN (ps)
END arg;

PROCEDURE argval*(o : strnutils.string) : strnutils.pstring;
VAR  i : LONGINT;
r : TextRider.Reader;
s : strnutils.string;
ps : strnutils.pstring;
BEGIN
r := TextRider.ConnectReader(ProgramArgs.args);
IF r = NIL THEN Out.String ("failed to connect reader to 'args'"); Out.Ln; END;
i := argscount();
IF argscount() = 1 THEN Out.String ("no arguments given"); Out.Ln; NEW (ps); ps^
:= "not found"; RETURN (ps) END;

FOR i := 0 TO argscount()-1 DO
r.ReadLine (s);
IF s = o THEN r.ReadLine(s); NEW(ps); ps^ := s; RETURN(ps) END;
END;
NEW(ps);
ps^ :=notfound;
RETURN(ps);
END argval;

BEGIN


END args.
