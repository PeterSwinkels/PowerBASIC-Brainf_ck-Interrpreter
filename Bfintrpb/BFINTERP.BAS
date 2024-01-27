$CPU 80386
$DIM ALL
$ERROR ALL ON
$EVENT OFF
$FLOAT NPX
$OPTION CNTLBREAK OFF
$OPTION GOSUB OFF
$OPTIMIZE SPEED
$SOUND 16
$STACK 2048
$STRING 32
DEFINT A-Z

%MEMORY_SIZE = 32000

DECLARE FUNCTION Escape (BYVAL Text AS STRING) AS STRING
DECLARE FUNCTION GetLoopList (Code AS STRING) AS STRING
DECLARE FUNCTION LoadCode (Path AS STRING) AS STRING
DECLARE FUNCTION Loops (LoopList AS STRING, InstructionP AS INTEGER, Backwards AS INTEGER) AS INTEGER
DECLARE FUNCTION NextArgument (Arguments AS STRING) AS INTEGER
DECLARE FUNCTION PopArgument (Arguments AS STRING, Argument AS STRING) AS STRING
DECLARE FUNCTION Unescape (Text AS STRING) AS STRING
DECLARE SUB ExecuteProgram (Code AS STRING, InputLineBreak AS STRING, OutputLineBreak AS STRING)
DECLARE SUB Main ()

CALL Main

FUNCTION Escape (BYVAL Text AS STRING) AS STRING
DIM Character AS LOCAL STRING * 1
DIM Escaped AS LOCAL STRING
DIM Hexed AS LOCAL STRING
DIM Position AS LOCAL INTEGER

 Escaped = ""

 FOR Position = 1 TO LEN(Text)
  Character = MID$(Text, Position, 1)
  SELECT CASE Character
   CASE "/"
    Escaped = Escaped + "//"
   CASE " " TO "~"
    Escaped = Escaped + Character
   CASE ELSE
    Hexed = HEX$(ASC(Character))
    IF LEN(Hexed) = 1 THEN Hexed = "0" + Hexed
    Escaped = Escaped + "/" + Hexed
  END SELECT
 NEXT Position

 Escape = Escaped
END FUNCTION

SUB ExecuteProgram (Code AS STRING, InputLineBreak AS STRING, OutputLineBreak AS STRING)
DIM Character AS LOCAL STRING * 1
DIM InputBuffer AS LOCAL STRING
DIM InstructionP AS LOCAL INTEGER
DIM LoopList AS LOCAL STRING
DIM Memory(&H0 TO %MEMORY_SIZE) AS LOCAL BYTE
DIM MemoryP AS LOCAL INTEGER
DIM OutputBuffer AS LOCAL STRING
DIM UserInput AS LOCAL STRING

 FOR MemoryP = LBOUND(Memory) TO UBOUND(Memory)
  Memory(MemoryP) = &H0
 NEXT MemoryP

 InstructionP = &H0
 LoopList = GetLoopList(Code)
 MemoryP = &H0

 DO
  SELECT CASE MID$(Code, InstructionP + &H1, &H1)
   CASE ">"
    IF MemoryP = UBOUND(Memory) THEN MemoryP = LBOUND(Memory) ELSE INCR MemoryP
   CASE "<"
    IF MemoryP = LBOUND(Memory) THEN MemoryP = UBOUND(Memory) ELSE DECR MemoryP
   CASE "+"
    INCR Memory(MemoryP)
   CASE "-"
    DECR Memory(MemoryP)
   CASE "."
    Character = CHR$(Memory(MemoryP))

    IF OutputLineBreak = "" THEN
     PRINT Escape(Character);
    ELSE
     OutputBuffer = OutputBuffer + Character

     IF NOT LEFT$(OutputLineBreak, LEN(OutputBuffer)) = OutputBuffer THEN
      PRINT Escape(OutputBuffer);
      OutputBuffer = ""
     ELSEIF OutputBuffer = OutputLineBreak THEN
      PRINT
      OutputBuffer = ""
     END IF
    END IF
   CASE ","
    IF InputBuffer = "" THEN
     LINE INPUT UserInput
     InputBuffer = Unescape(UserInput) + InputBuffer + InputLineBreak
    END IF

    IF NOT InputBuffer = "" THEN
     Memory(MemoryP) = ASC(LEFT$(InputBuffer, 1))
     InputBuffer = MID$(InputBuffer, 2)
    END IF
   CASE "["
    IF Memory(MemoryP) = &H0 THEN
     InstructionP = Loops(LoopList, InstructionP, 0)
    END IF
   CASE "]"
    IF NOT Memory(MemoryP) = &H0 THEN
     InstructionP = Loops(LoopList, InstructionP, -1)
    END IF
  END SELECT

  INCR InstructionP
 LOOP WHILE InstructionP > &H0 AND InstructionP < LEN(Code)
END SUB

FUNCTION GetLoopList (Code AS STRING) AS STRING
DIM Character AS LOCAL STRING * 1
DIM LoopList AS LOCAL STRING
DIM LoopStack AS LOCAL STRING
DIM Position AS LOCAL INTEGER
DIM StartOfLoop AS LOCAL INTEGER

 LoopList = ""
 LoopStack = ""
 FOR Position = 1 TO LEN(Code)
  Character = MID$(Code, Position, 1)
  SELECT CASE Character
   CASE "["
    LoopStack = LoopStack + MKI$(Position - 1)
   CASE "]"
    IF LoopStack = "" THEN
     PRINT "End of loop without start."
     EXIT FOR
    ELSE
     StartOfLoop = CVI(MID$(LoopStack, LEN(LoopStack) - 1, 2))
     LoopStack = LEFT$(LoopStack, LEN(LoopStack) - 2)
     LoopList = LoopList + MKI$(StartOfLoop) + MKI$(Position - 1)
    END IF
  END SELECT
 NEXT Position

 IF NOT LoopStack = "" THEN
  PRINT "Loop without end."
 END IF

 GetLoopList = LoopList
END FUNCTION

FUNCTION LoadCode (Path AS STRING) AS STRING
DIM Code AS LOCAL STRING
DIM FileH AS LOCAL INTEGER

 IF DIR$(Path) = "" THEN ERROR 53

 FileH = FREEFILE
 OPEN Path FOR BINARY LOCK READ WRITE AS FileH
  Code = STRING$(LOF(FileH), &H0)
  GET FileH, , Code
 CLOSE FileH

 LoadCode = Code
END FUNCTION

FUNCTION Loops (LoopList AS STRING, InstructionP AS INTEGER, Backwards AS INTEGER) AS INTEGER
DIM NewInstructionP AS LOCAL INTEGER
DIM Position AS LOCAL INTEGER

 FOR Position = 1 TO LEN(LoopList) STEP 4
  SELECT CASE Backwards
   CASE 0
    IF InstructionP = CVI(MID$(LoopList, Position, 2)) THEN
     NewInstructionP = CVI(MID$(LoopList, Position + 2, 2))
     EXIT FOR
    END IF
   CASE -1
    IF InstructionP = CVI(MID$(LoopList, Position + 2, 2)) THEN
     NewInstructionP = CVI(MID$(LoopList, Position, 2))
     EXIT FOR
    END IF
  END SELECT
 NEXT Position

 Loops = NewInstructionP
END FUNCTION

SUB Main ()
DIM Arguments AS LOCAL STRING
DIM InputLineBreak AS LOCAL STRING
DIM OutputLineBreak AS LOCAL STRING
DIM Path AS LOCAL STRING

 Arguments = LTRIM$(RTRIM$(COMMAND$))
 InputLineBreak = CHR$(13)
 OutputLineBreak = CHR$(13)

 IF NOT Arguments = "" THEN
  Arguments = PopArgument(Arguments, Path)
  IF NOT Arguments = "" THEN
   Arguments = PopArgument(Arguments, InputLineBreak)
   IF NOT Arguments = "" THEN
    Arguments = PopArgument(Arguments, OutputLineBreak)
   END IF
  END IF
 END IF

 IF Path = "" THEN
  PRINT "Brainf*ck Interpreter v1.00, by: Peter Swinkels, ***2023***"
  PRINT
  PRINT "Usage:"
  PRINT "BFInterp.exe PATH LINE_BREAK_IN LINE_BREAK_OUT"
 ELSE
  ExecuteProgram LoadCode(Path), Unescape(InputLineBreak), Unescape(OutputLineBreak)
 END IF
END SUB

FUNCTION NextArgument (Arguments AS STRING)
DIM Position AS INTEGER

 Position = INSTR(1, Arguments, " ")
 IF Position = 0 THEN Position = LEN(Arguments) + 1
 IF Position = 1 THEN Position = 0

 NextArgument = Position
END FUNCTION

FUNCTION PopArgument (Arguments AS STRING, Argument AS STRING) AS STRING
DIM NextPosition AS LOCAL INTEGER

 Arguments = LTRIM$(RTRIM$(Arguments))
 NextPosition = NextArgument(Arguments)
 IF NextPosition > 0 THEN
  Argument = LEFT$(Arguments, NextPosition - 1)
  Arguments = MID$(Arguments, NextPosition + 1)
 END IF

 PopArgument = Arguments
END FUNCTION

FUNCTION Unescape (Text AS STRING) AS STRING
DIM Character AS LOCAL STRING * 1
DIM Position AS LOCAL INTEGER
DIM Unescaped AS LOCAL STRING

 Position = 1
 Unescaped = ""
 DO UNTIL Position > LEN(Text)
  Character = MID$(Text, Position, 1)
  IF Character = "/" THEN
   IF MID$(Text, Position + 1, 1) = "/" THEN
    Unescaped = Unescaped + Character
    Position = Position + 2
   ELSE
    Unescaped = Unescaped + CHR$(VAL("&H" + MID$(Text, Position + 1, 2) + "%"))
    Position = Position + 3
   END IF
  ELSE
   Unescaped = Unescaped + Character
   INCR Position
  END IF
 LOOP

 Unescape = Unescaped
END FUNCTION

