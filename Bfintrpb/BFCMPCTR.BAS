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

DIM Buffer AS STRING * 32000
DIM BufferSize AS INTEGER
DIM Character AS STRING * 1
DIM InFileH AS INTEGER
DIM InPath AS STRING
dim Instructions AS STRING * 8
DIM OutFileH AS INTEGER
DIM OutPath AS STRING
DIM Position AS INTEGER

Instructions = "+,-.<>[]"

PRINT "Brainf*ck Compacter v1.01 - by: Peter Swinkels, ***2023***"

LINE INPUT "Input file: "; InPath
IF NOT InPath = "" THEN LINE INPUT "Output file: "; OutPath

IF NOT (InPath = "" OR OutPath = "") THEN
 IF DIR$(InPath) = "" THEN ERROR 53

 BufferSize = 32000
 InFileH = FREEFILE
 OPEN InPath FOR BINARY LOCK READ WRITE AS InFileH
  OutFileH = FREEFILE
  OPEN OutPath FOR OUTPUT LOCK READ WRITE AS OutFileH
   DO UNTIL LOC(InFileH) = LOF(InFileH)
    IF LOC(InFileH) + BufferSize > LOF(InFileH) THEN BufferSize = LOF(InFileH) - LOC(InFileH)
    GET #InFileH, , Buffer
    FOR Position = 1 TO BufferSize
     Character = MID$(Buffer, Position, 1)
     IF INSTR(Instructions, Character) > 0 THEN
      PRINT #OutFileH, Character;
     END IF
    NEXT Position
   LOOP
  CLOSE OutFileH
 CLOSE InFileH
END IF

