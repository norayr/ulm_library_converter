MODULE strnutils;
IMPORT
(* oo2c*)
(************)
Strings;
(******)
(*XDS*)
(************
Strings := O2Strings;
**********)
TYPE string* = ARRAY 255 OF CHAR;
pstring* = POINTER TO string;
strings* = POINTER TO ARRAY OF string;
(*TYPE TSysCharset = POINTER TO ARRAY OF string;*)

PROCEDURE IsStringInStrings* (VAR s : string; VAR sn : strings )  : BOOLEAN;
VAR l : LONGINT;
BEGIN
FOR l := 0 TO LEN(sn^)-1 DO
IF sn^[l] = s THEN RETURN (TRUE) END;
END (*FOR*);
RETURN (FALSE)
END IsStringInStrings;

PROCEDURE SetLengthOfStringList*(list : strings; l : LONGINT) : strings;
VAR m : strings;
i : LONGINT;
BEGIN
NEW (m,l);
FOR i := 0 TO (LEN(list^)-1) DO
m[i] := list[i];
END (*FOR*);
RETURN (m);
END SetLengthOfStringList;

PROCEDURE Pos* (substr : CHAR ; s : string; n : INTEGER) : INTEGER;
VAR i : INTEGER;
BEGIN
FOR i := n TO Strings.Length(s) DO
IF s[i] = substr THEN RETURN(i) END;
END;
RETURN(0);
END Pos;

PROCEDURE RemoveLeftChars* (VAR s : string; ch : CHAR);
BEGIN
REPEAT
IF s[0] = ch THEN Strings.Delete (s, 0, 1) END;

UNTIL s[0] # ch;

END RemoveLeftChars;

PROCEDURE RemoveRightChars* (VAR s : string; ch : CHAR);
VAR l : INTEGER;
BEGIN
l := Strings.Length(s);
REPEAT

IF s[l] = ch THEN Strings.Delete (s, l, 1) END;
DEC(l);
UNTIL s[l] # ch;

END RemoveRightChars;


PROCEDURE WordCount* (s : string; ch : CHAR) : INTEGER;
VAR 
k,l : INTEGER;
BEGIN
RemoveLeftChars(s, ch);
RemoveRightChars (s, ch);
k := 0;
l := 0;
REPEAT 
IF s[l] = ch THEN 
   INC(k);
      REPEAT
      INC(l);
      UNTIL s[l] # ch;
        END;
INC(l);
UNTIL l = Strings.Length(s);
INC(k);
RETURN(k);


END WordCount;

PROCEDURE NumberOfChar* (s : string; ch : CHAR) : LONGINT;
VAR n, i : LONGINT;
BEGIN
n := 0;
FOR i := 0 TO Strings.Length(s) DO
IF s[i] = ch THEN INC(n) END;
END;
RETURN(n);
END NumberOfChar;

PROCEDURE Rpos* ( s : string ; ch : CHAR) : INTEGER;
VAR l : INTEGER;
BEGIN
l := Strings.Length (s);
IF s[l] = ch THEN RETURN(l) END;
REPEAT
DEC(l);
UNTIL s[l] = ch;
RETURN(l);
END Rpos;

PROCEDURE Lpos* ( s : string ; ch : CHAR) : INTEGER;
VAR l : INTEGER;
BEGIN
l := 0;
IF s[l] = ch THEN RETURN(l) END;
REPEAT
INC(l);
IF s[l] = ch THEN RETURN(l) END;
UNTIL l = Strings.Length(s);
RETURN(0);
END Lpos;


PROCEDURE ExtractWord* (n : INTEGER; s : string; ch : CHAR) : pstring;
VAR i,j, k, l : INTEGER;
str : string;
pstr : pstring;
BEGIN
RemoveLeftChars (s, ch);
RemoveRightChars (s, ch);
IF n = WordCount (s, ch) THEN
l := Rpos (s, ch);
Strings.Extract (s, l+1, Strings.Length(s)-l, str);
NEW(pstr);
pstr^ := str;
RETURN (pstr);
END;

IF n = 1 THEN
l := Lpos(s, ch);
Strings.Extract (s, 0, l, str);
NEW(pstr);
pstr^ := str;
RETURN (pstr);
END;

j := 0;
k := 0;
l := 0;
i := 0;

REPEAT
  IF s[i] = ch THEN INC(j) ;
            IF j = (n-1) THEN k := i  END;
         
           IF j = n THEN l := i END;
  END;
  INC(i);
UNTIL i = Strings.Length(s);

NEW (pstr);
Strings.Extract(s, k+1, l-k-1, str);
pstr^ := str;
RETURN (pstr);



END ExtractWord;

PROCEDURE tokenize*(s : string; ch : CHAR) : strings;
VAR strs : strings;
pstr : pstring;
l, n : INTEGER;
BEGIN
n := WordCount(s, ch);
NEW (strs, n);
IF n = 1 THEN
RemoveRightChars (s, ch);
RemoveLeftChars (s, ch);
strs^[0] := s;
RETURN (strs);
END;
l := 0;
REPEAT
pstr := ExtractWord ( l+1, s, ch);
strs^[l] := pstr^;
INC(l);
UNTIL l = n;
RETURN (strs); 
END tokenize;

PROCEDURE Assign* (VAR src : ARRAY OF CHAR ; VAR dst : ARRAY OF CHAR); 
VAR i, k : LONGINT;
BEGIN
IF LEN (src) < LEN(dst) THEN k := LEN(src) ELSE k := LEN(dst)  END;
FOR i := 0 TO k-2 DO
dst[i] := src[i];
END;
dst[k-1] := 0X;
END Assign;

BEGIN





END strnutils.
