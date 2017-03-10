MODULE UlmLibraryConverter;

IMPORT args, OBS, strnutils,Strings, Out, Files, TextRider, Msg;

TYPE record = RECORD
       name : strnutils.string;
       fields : strnutils.strings
       END;
     recs = POINTER TO ARRAY OF record;

VAR constants : strnutils.strings;
     types : strnutils.strings;
     variables : strnutils.strings;
     procedures : strnutils.strings;
     records : recs;
     
    modulename, s : strnutils.string;
    pmodulename: strnutils.pstring;

PROCEDURE parseargs() : strnutils.pstring;
VAR p : strnutils.pstring;
BEGIN
IF args.argscount() >= 1 THEN
   NEW(p);
   p := args.arg(1);
   RETURN(p)
ELSE
   HALT(0)
END;
END parseargs;

PROCEDURE SetLengthOfRecordsList*(list : recs; l : LONGINT) : recs;
VAR m : recs;
i : LONGINT;
BEGIN
NEW (m,l);
FOR i := 0 TO (LEN(list^)-1) DO
m[i] := list[i];
END (*FOR*);
RETURN (m);
END SetLengthOfRecordsList;


PROCEDURE ReadDefinition( name : strnutils.string);
   CONST ext = ".od";
   VAR s, s1 : strnutils.string;
   sym, symm : INTEGER;
   stop : BOOLEAN;
   stringlist : strnutils.strings;

   PROCEDURE expect (i : INTEGER);
      VAR s : INTEGER;
   BEGIN
      OBS.Get(s);
      IF s # i THEN Out.String ("unexpected symbol at "); Out.LongInt (OBS.R.Pos(), 0); Out.Ln; Out.String(" aborting"); Out.Ln; END;
   END expect;

BEGIN
   Strings.Assign (name, s);
   Strings.Append (ext, s);

   NEW (constants, 0);
   NEW (variables, 0);
   NEW (procedures, 0);
   NEW (types, 0);
   NEW (records, 0);

   OBS.Init (s, 0);
   stop := FALSE;

   OBS.Get(sym);
   REPEAT
      IF (
         (sym # 58) &
         (sym # 59) &
         (sym # 60) &
         (sym # 61)
         ) THEN
         OBS.Get(sym) 
      END;

      IF sym = 58 (* CONST *) THEN 
         (*Out.String ("found CONST definition"); Out.Ln;*)
         REPEAT
            OBS.Get(sym);
            IF sym = 37 (* ident *) THEN
               constants := strnutils.SetLengthOfStringList (constants, LEN(constants^)+1);
               strnutils.Assign (OBS.name, constants[LEN(constants^)-1]);
               expect (9); (* = *)
               REPEAT  
	          OBS.Get(symm)
	       UNTIL symm = 38; (* ; *)
            END;
         UNTIL sym # 37;
      END;

      IF sym = 59 (* TYPE *) THEN
         REPEAT
            OBS.Get(sym);
            IF sym = 37 (* ident *) THEN
               strnutils.Assign ( OBS.name, s1);
               expect (9); (* = *)
               OBS.Get(symm);
               IF symm # 55 (* ~ RECORD *) THEN
                  types := strnutils.SetLengthOfStringList (types, LEN(types^)+1);
                  strnutils.Assign (s1, types[LEN(types^)-1]);
                  REPEAT 
		     OBS.Get(symm);
	             IF symm = 29 THEN
	                REPEAT	    
	                   OBS.Get(symm);
	                UNTIL symm = 22
	             END;	  
	          UNTIL symm = 38; (* ; *)
	       END;
	       IF symm = 55 THEN
                  (*Out.String ('found "record" definition'); Out.Ln;*)
	          records := SetLengthOfRecordsList (records, LEN(records^)+1);
	          strnutils.Assign (s1, records[LEN(records^)-1].name);
	          (*Out.String ('record type "'); Out.String (records^[LEN(records^)-1].name); Out.String ('" added to the list'); Out.Ln;*)
	          OBS.Get(symm);
	          IF symm = 29 (* ( *) THEN
	             (*Out.String ('record is extention of "');*)
	             REPEAT
		        OBS.Get(symm); 
	                IF symm = 37 THEN 
	                   (*Out.String (OBS.name) *)
	                ELSE 
	                   IF symm # 22 THEN  (*Out.Char(".")*) END;
		        END
		     UNTIL symm = 22; (* ) *)
	             (*Out.Char('"'); Out.Ln;*)
	             OBS.Get(symm);
	          END;
	          IF symm # 40 (* END *) THEN
	             NEW (stringlist, 0);
	             REPEAT
		        stringlist := strnutils.SetLengthOfStringList (stringlist, LEN(stringlist^)+1);
		        strnutils.Assign (OBS.name, stringlist[LEN(stringlist^)-1]) ;
		        (*Out.String ('found field "'); Out.String (stringlist[LEN(stringlist^)-1]); Out.String ('"'); Out.Ln;*)
		        records^[(LEN(records^)-1)].fields := stringlist;
		        OBS.Get(symm); 
		        IF symm = 20 THEN
		        (* in ulm's oberon library the last record field always ends with semicolon *)
		           REPEAT
			      OBS.Get(symm); 
			      IF symm = 29 THEN 
			         REPEAT 
				    OBS.Get(sym) 
				 UNTIL symm = 22 
			      END    
			   UNTIL symm = 38; (* ; *)
		           OBS.Get(symm);
		        END;
		        IF symm = 19 THEN OBS.Get(sym) END;
		     UNTIL symm = 40; (* END *)
	          ELSE
	             IF symm = 40 THEN NEW(stringlist, 0); records^[(LEN(records^)-1)].fields := stringlist END;
	          END;
	          REPEAT  OBS.Get(symm); UNTIL symm = 38; (* ; *) (* ; *)
               END;       
            END;
         UNTIL (sym # 37);
      END;

      IF sym = 60 (* VAR *) THEN
         (*Out.String ('found "var" keyword'); Out.Ln;*)
         REPEAT
            OBS.Get(sym);
            IF sym = 37 (* ident *) THEN
               variables := strnutils.SetLengthOfStringList (variables, LEN(variables^)+1);
               strnutils.Assign (OBS.name, variables[LEN(variables^)-1]);
               (*Out.String ('variable "'); Out.String (variables[LEN(variables^)-1]); Out.String ('" added to the list'); Out.Ln;*)
               OBS.Get(symm);
               IF symm = 20 THEN 
                  REPEAT  OBS.Get(symm) UNTIL symm = 38; (* ; *)
               END
            END;
         UNTIL sym # 37;
      END;

      IF sym = 61 (* PROCEDURE  *) THEN
         (*Out.String ('found "procedure" keyword'); Out.Ln;*)
         OBS.Get(sym);
         IF sym = 37 (* ident *) THEN
            procedures := strnutils.SetLengthOfStringList (procedures, LEN(procedures^)+1);
            strnutils.Assign (OBS.name, procedures[LEN(procedures^)-1]);
            (*Out.String ('procedure "'); Out.String (procedures[LEN(procedures^)-1]); Out.String ('" added to the list'); Out.Ln;*)
            REPEAT
	       OBS.Get(sym); 
	       IF sym = 29 THEN REPEAT OBS.Get(sym) UNTIL sym = 22  END      
	    UNTIL sym = 38; (* ; *)
         END;
      END;


      IF sym = 40 (* END *) THEN
         OBS.Get(sym);
         IF sym = 37 (* ident *) THEN
            IF OBS.name = name THEN stop := TRUE END;
         END;
      END;
   UNTIL stop = TRUE;

END ReadDefinition;

PROCEDURE Insert (name : strnutils.string; pos : LONGINT);
CONST ext = ".om";
(*ext2 = ".mod";*)
VAR f : Files.File; r : TextRider.Reader; w : TextRider.Writer; res : Msg.Msg;
VAR text : POINTER TO ARRAY OF CHAR;
avail, i : LONGINT;
ch : CHAR;
s : strnutils.string;
BEGIN
Strings.Assign (name, s);
Strings.Append (ext, s); (*Out.String ('opening '); Out.String (s); Out.Ln;*)
f := Files.Old (s, {Files.read}, res);
IF (res # Files.done) THEN
Out.String ("failed to open ");
Out.String (s);
Out.String (" file"); Out.Ln;
HALT(0);
END;

r := TextRider.ConnectReader (f);
IF r = NIL THEN Out.String ("error connecting reader"); Out.Ln; f.Close; HALT(0) END;
r.SetPos(0);
avail := r.Available();
NEW (text, avail + 1);
i := 0;
REPEAT
(*FOR i := 0 TO pos DO*)
r.ReadChar(ch);
text^[i] := ch;
INC(i)
UNTIL i = pos;
(*END;*)

(*INC(i);*)
text[i] := "*";

REPEAT
r.ReadChar(ch);
INC(i);
text^[i] := ch;
UNTIL r.Available() <= 0;

f.Close;
f := Files.New (s, {Files.write}, res);
IF (res # Files.done) THEN
Out.String ("failed to open ");
Out.String (s);
Out.String (" file"); Out.Ln;
HALT(0)
END;
w := TextRider.ConnectWriter(f); IF w = NIL THEN Out.String ("error connecting writer"); HALT(0) END;
FOR i := 0 TO LEN(text^)-1 DO w.WriteChar (text^[i]) END; f.Close;
END Insert;

PROCEDURE exported (s : strnutils.string; VAR n : LONGINT) : BOOLEAN;
VAR l : LONGINT;

BEGIN

l := -1;
REPEAT
INC(l);
IF records^[l].name = s THEN n := l; RETURN (TRUE) END;
UNTIL l >= LEN(records^)-1; 
RETURN (FALSE)
END exported;

PROCEDURE fieldexported (n : LONGINT; s : strnutils.string) : BOOLEAN;
BEGIN
IF strnutils.IsStringInStrings (s, records^[n].fields) THEN RETURN TRUE ELSE RETURN FALSE END;
END fieldexported;

PROCEDURE WriteDefinition(name : strnutils.string);
CONST ext = ".om";

VAR position : LONGINT;
s, s2, s3 : strnutils.string;
stop : BOOLEAN;
sym : INTEGER;
l : LONGINT;
n : LONGINT;
recnames : strnutils.strings;
BEGIN
Strings.Assign (name, s);
Strings.Append (ext, s);

IF LEN(records^)=0 THEN NEW(records, 1); records[0].name := ""; NEW(records[0].fields, 1) END;

	 (*recnames := records.name[0]-records.name[LEN-1]*)
	 (*NEW(recnames, LEN(records^));
	 FOR l := 0 TO LEN(records^)-1 DO recnames^[l] := records^[l].name END;*)

OBS.Init (s, 0);
OBS.Get(sym);
stop := FALSE;
REPEAT
IF (
    (sym # 58) &
    (sym # 59) &
    (sym # 60) &
    (sym # 61)
    ) THEN
OBS.Get(sym);
END;

IF sym = 58 (* CONST *) THEN
    (*Out.String ('found "const" keyword'); Out.Ln;*)
    OBS.Get(sym);
    REPEAT
       IF sym = 37 (* ident *) THEN
         strnutils.Assign (OBS.name, s2);
         IF (strnutils.IsStringInStrings (s2, constants)) THEN 
              position := OBS.R.Pos()-1; 
	      OBS.Get(sym); 
	      IF (sym # 1) THEN 
	      OBS.Finish;
	      Insert(name, position);
	      OBS.Init(s, 0);
              END;
	      IF sym = 1 THEN END;
         END;
       END;
              REPEAT  OBS.Get(sym)                UNTIL sym = 38; (* ; *)
              OBS.Get(sym);

    UNTIL sym # 37;
END;

IF sym = 59 (* TYPE *) THEN
    (*Out.String ('found "type" keyword'); Out.Ln;*)
    OBS.Get(sym);
    REPEAT
       IF sym = 37 (* ident *) THEN (*Out.String (OBS.name); Out.Ln;*)
         strnutils.Assign (OBS.name, s2); (* type name *)
         IF (strnutils.IsStringInStrings (s2, types)) THEN (*Out.String ("exported"); Out.Ln;*)
              position := OBS.R.Pos()-1; (*Out.LongInt (position, 2); Out.Ln;*)
	      OBS.Get(sym); (*Out.Int(sym, 0); Out.Ln;*)
	      IF (sym # 1) THEN 
              (*Out.String ('type "'); Out.String (s2); Out.String ('" marked'); Out.Ln;       *)
	      OBS.Finish;
	      Insert(name, position);
	      OBS.Init(s, 0)
              END;
	      IF sym = 1 THEN (*Out.String ("already has an asterisk"); Out.Ln;*) END
         END;
         
       END;
              OBS.Get(sym); (*Out.LongInt(sym, 0); Out.Ln; OBS.Get(sym); Out.LongInt (sym, 0); Out.Ln;*)
	      IF sym = 55 THEN REPEAT OBS.Get(sym); (*Out.LongInt(sym, 0); Out.Ln;*) UNTIL sym = 40 END; 
              REPEAT  OBS.Get(sym); IF sym = 29 THEN REPEAT OBS.Get(sym) UNTIL sym = 22 END                UNTIL sym = 38; (* ; *)
              OBS.Get(sym);

    UNTIL sym # 37; (*Out.String ("sym # 37");Out.Ln*)
END;


IF sym = 60 (* VAR *) THEN
    (*Out.String ('found "var" keyword'); Out.Ln;*)
    OBS.Get(sym);
    REPEAT
       IF sym = 37 (* ident *) THEN (*Out.String ("variable"); Out.Ln;*)
         strnutils.Assign (OBS.name, s2);
         IF (strnutils.IsStringInStrings (s2, variables)) THEN (*Out.String ("found!");*)
              position := OBS.R.Pos()-1; (*Out.LongInt (position, 2); Out.Ln;*)
	      OBS.Get(sym); (*Out.Int(sym, 0); Out.Ln;*)
	      IF (sym # 1) THEN 
              (*Out.String ('constant "'); Out.String (OBS.name); Out.String ('" marked'); Out.Ln;       *)
	      OBS.Finish;
	      Insert(name, position);
	      OBS.Init(s, 0);
              END;
	      IF sym = 1 THEN (*Out.String ("already has an asterisk"); Out.Ln;*) END;
         END;
       END;
              REPEAT  OBS.Get(sym); IF sym = 29 THEN REPEAT OBS.Get(sym) UNTIL sym = 22 END               UNTIL sym = 38; (* ; *)
              OBS.Get(sym);

    UNTIL sym # 37;
END;

IF sym = 61 (* PROCEDURE *) THEN
    (*Out.String ('found "procedure" keyword'); Out.Ln; *)OBS.Get(sym);
       IF sym = 37 (* ident *) THEN (*Out.String ("procedure"); Out.Ln;*)
       position := OBS.R.Pos()-1;
       OBS.Get(sym);
        IF sym # 1 THEN
         strnutils.Assign (OBS.name, s2);
         IF (strnutils.IsStringInStrings (s2, procedures)) THEN (*Out.String ("found!");*)
              (*position := OBS.R.Pos()-1;*) (*Out.LongInt (position, 2); Out.Ln;*)
	      OBS.Finish;
	      Insert(name, position);
	      OBS.Init(s, 0);
         END;
	END 
       END;
              REPEAT  OBS.Get(sym); IF sym = 29 THEN REPEAT  OBS.Get(sym) UNTIL sym = 22 END             UNTIL sym = 38; (* ; *)
              OBS.Get(sym);
END;


IF sym = 40 (* END *) THEN
   OBS.Get(sym);
   IF sym = 37 (* ident *) THEN 
      IF OBS.name = name THEN stop := TRUE END;
   END;
END;
UNTIL (stop = TRUE);

stop := FALSE;
OBS.Init (s, 0);
REPEAT
   OBS.Get(sym);
      IF sym = 37 THEN 
         n := 0;
         strnutils.Assign (OBS.name, s3);
            IF exported(s3, n) THEN
             (*Out.String ("record "); Out.String (s3); Out.String (" number "); Out.LongInt(n, 0); Out.String (" exported "); Out.Ln;*)
               position := OBS.R.Pos() - 1;
	       (*Out.String ("position "); Out.LongInt (position, 0); Out.Ln;*)
               OBS.Get(sym);
                 IF sym = 9 THEN
                   OBS.Get(sym);
                     IF sym = 55 THEN
                        OBS.Finish; (*Out.String ("inserting asterisk at position "); Out.LongInt(position, 0); Out.Ln;*)
                        Insert(name, position);
                        OBS.Init (s, position+1);
                     END;
                     REPEAT 
		        OBS.Get(sym);
		        IF sym = 29 THEN 
			   REPEAT 
			      OBS.Get(sym);
			   UNTIL sym = 22
			END;
	              UNTIL ((sym = 37) OR (sym = 40));
                      IF sym = 37 THEN
		         REPEAT
                            strnutils.Assign (OBS.name, s3);
	                 IF fieldexported (n, s3) THEN
                            position := OBS.R.Pos() - 1;
                            OBS.Finish;
                            Insert (name, position);
                            OBS.Init (s, position+1);
	                      REPEAT
				OBS.Get(sym);
				   IF sym = 29 THEN
				     REPEAT
				 	OBS.Get(sym)
				     UNTIL sym = 22
				   END;
				UNTIL sym = 38;
                             END;
                          OBS.Get(sym)
                        UNTIL sym = 40;
			END;
                 END;
            END;
      END;
IF sym = 40 (* END *) THEN
   OBS.Get(sym);
   IF sym = 37 (* ident *) THEN
      IF OBS.name = name THEN stop := TRUE END;
   END;
END;

UNTIL (stop = TRUE);

END WriteDefinition;


PROCEDURE ShowRecords;
VAR l, n : LONGINT;
BEGIN
FOR l := 0 TO LEN(records^)-1 DO
Out.String ("record "); Out.String (records^[l].name); Out. String ("has following exported fields"); Out.Ln;
   FOR n := 0 TO LEN (records^[l].fields^) -1 DO
   Out.String (records^[l].fields^[n]); Out.Ln
   END;
END;
END ShowRecords;

PROCEDURE HideExt (s : strnutils.string; VAR ss : strnutils.string);
VAR k, j : INTEGER;
a : BOOLEAN;
BEGIN
k := -1;
REPEAT INC(k); UNTIL ((s[k] = ".") OR (k > LEN(s)));
IF k > LEN(s) THEN HALT(0); END;
FOR j := 0 TO k-1 DO ss[j] := s[j] END;
ss[k] := 0X
END HideExt;

BEGIN
NEW(pmodulename);
pmodulename := parseargs();
modulename := pmodulename^;
HideExt(modulename, s);
Out.String(s);Out.Ln;
ReadDefinition (s);
(*ShowRecords;*)
WriteDefinition (s);
END UlmLibraryConverter.
