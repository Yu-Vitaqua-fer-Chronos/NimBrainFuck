# > = increases memory pointer, or moves the pointer to the right 1 block.
# < = decreases memory pointer, or moves the pointer to the left 1 block.
# + = increases value stored at the block pointed to by the memory pointer
# - = decreases value stored at the block pointed to by the memory pointer
# [ = like c while(cur_block_value != 0) loop.
# ] = if block currently pointed to's value is not zero, jump back to [
# , = like c getchar(). input 1 character.
# . = like c putchar(). print 1 character to the console

# Imports
import std/[
  terminal, # Used for `getch`
  sequtils, # Used for `filterIt`
  tables,   # Used for storing jump positions
  os        # Used for the command line
]

# The minimum amount of cells we provide by default
const CELL_COUNT {.intdefine.} = 30000

type CellType = byte

# The valid instructions, anything else is ignored
# This also could easily be removed if we wanted to
type Instruction = enum
  IncMemPtr  # >
  DecMemPtr  # <
  IncVal     # +
  DecVal     # -
  LoopStart  # [
  LoopEnd    # ]
  GetChar    # ,
  PutChar    # .

proc `$`*(i: Instruction): string =
  return case i
    of IncMemPtr: ">"
    of DecMemPtr: "<"
    of IncVal:    "+"
    of DecVal:    "-"
    of LoopStart: "["
    of LoopEnd:   "]"
    of GetChar:   ","
    of PutChar:   "."

proc `$`*(p: seq[Instruction]): string =
  result &= "("

  for i in p:
    result &= $i

  result &= ")"

# The interpreter state type just holds information that it can use
type BFInterpreterState = object
  cells: seq[CellType]
  program: seq[Instruction]
  jumpTable: Table[int, int]
  currentCell: int
  currentInstruction: int

# Simple initialisation function
proc init(_: typedesc[BFInterpreterState], maxCells=CELL_COUNT): BFInterpreterState =
  result = BFInterpreterState()
  result.cells = newSeqUninitialized[CellType](maxCells)
  result.currentCell = 0
  result.currentInstruction = 0


proc findMatchingEndBracket(position: int, code: string | seq[char]): int =
  var pos = position + 1
  var nest = 0

  while true:
    if code[pos] == '[':
      nest += 1

    if code[pos] == ']':
      if nest == 0:
        return pos

      nest -= 1

    pos += 1


proc findMatchingStartBracket(position: int, code: string | seq[char]): int =
  var pos = position - 1
  var nest = 0

  while true:
    if code[pos] == '[':
      if nest == 0:
        return pos

      nest -= 1

    if code[pos] == ']':
      nest += 1

    pos -= 1


proc readBfString(state: var BFInterpreterState, rawCode: string) =
  let code = rawCode.filterIt(it in ".,-+<>[]")
  var pos = 0

  while pos < code.len:
    let inst = code[pos]

    case inst
    of '>':
      state.program.add IncMemPtr
    of '<':
      state.program.add DecMemPtr
    of '+':
      state.program.add IncVal
    of '-':
      state.program.add DecVal
    of '[':
      state.program.add LoopStart
      state.jumpTable[pos] = findMatchingEndBracket(pos, code)
    of ']':
      state.program.add LoopEnd
      state.jumpTable[pos] = findMatchingStartBracket(pos, code)
    of ',':
      state.program.add GetChar
    of '.':
      state.program.add PutChar
    else:
      discard

    pos += 1

proc readBfFile(state: var BFInterpreterState, filename: string) =
  readBfString(state, readFile(filename))


proc evalBfInstruction(state: var BFInterpreterState) =
  case state.program[state.currentInstruction]
  of IncMemPtr:
    when defined(UNBOUNDED_CELLS):
      if state.currentCell < state.cells.len:
        state.cells.add 0

    state.currentCell += 1

    if (state.currentCell > CELL_COUNT) and (not defined(UNBOUNDED_CELLS)):
      quit("Program exited as the end of the tape was reached!", 1)

    state.currentInstruction += 1

  of DecMemPtr:
    state.currentCell -= 1

    if state.currentCell < 0:
      quit("Program exited as the tape uses negative indexes!", 1)

    state.currentInstruction += 1

  of IncVal:
    if state.cells[state.currentCell] == high(CellType):
      state.cells[state.currentCell] = low(CellType)

    else:
      state.cells[state.currentCell] += 1

    state.currentInstruction += 1

  of DecVal:
    if state.cells[state.currentCell] == low(CellType):
      state.cells[state.currentCell] = high(CellType)

    else:
      state.cells[state.currentCell] -= 1

    state.currentInstruction += 1

  of LoopStart:
    if state.cells[state.currentCell] == low(CellType):
      state.currentInstruction = state.jumpTable[state.currentInstruction]

    state.currentInstruction += 1


  of LoopEnd:
    if state.cells[state.currentCell] != low(CellType):
      state.currentInstruction = state.jumpTable[state.currentInstruction]

    state.currentInstruction += 1


  of GetChar:
    state.cells[state.currentCell] = getch().CellType
    state.currentInstruction += 1

  of PutChar:
    stdout.write(state.cells[state.currentCell].char)
    stdout.flushFile()
    state.currentInstruction += 1

  else:
    discard # Undefined behaviour should be ignored, though it's already
            # done implicitly

proc runBf(state: var BFInterpreterState) =
  while state.currentInstruction < state.program.len:
    evalBfInstruction(state)

proc run(state: var BFInterpreterState, filename: string) =
  state.readBfFile(filename)

  state.runBf()

# Create the initial state
var interpreterState = BFInterpreterState.init()

# Run the brainfuck file
if paramCount() != 1:
  quit("We only accept 1 argument to execute!", 1)

interpreterState.run(paramStr(1))

