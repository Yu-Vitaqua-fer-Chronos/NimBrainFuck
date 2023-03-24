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
  os        # Used for the command line
]

# The minimum amount of cells we provide by default
const CELL_COUNT {.intdefine.} = 30000

type CellType = byte

# The valid instructions, anything else is ignored
# This also could easily be removed if we wanted to
type Instruction = enum
  IncMemPtr # >
  DecMemPtr # <
  IncVal    # +
  DecVal    # -
  LoopStart # [
  LoopEnd   # ]
  GetChar   # ,
  PutChar   # .

# The interpreter state type just holds information that it can use
type BFInterpreterState = object
  cells: seq[CellType]
  program: seq[Instruction]
  loopPositions: seq[int]
  currentCell: int
  currentInstruction: int

# Simple initialisation function
proc init(_: typedesc[BFInterpreterState], maxCells=CELL_COUNT): BFInterpreterState =
  result = BFInterpreterState()
  result.cells = newSeqUninitialized[CellType](maxCells)
  result.currentCell = 0
  result.currentInstruction = 0


proc readBfString(state: var BFInterpreterState, code: string) =
  for inst in code:
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
    of ']':
      state.program.add LoopEnd
    of ',':
      state.program.add GetChar
    of '.':
      state.program.add PutChar
    else:
      discard

proc readBfFile(state: var BFInterpreterState, filename: string) =
  readBfString(state, readFile(filename))


proc evalBfInstruction(state: var BFInterpreterState) =
  case state.program[state.currentInstruction]
  of IncMemPtr:
    when defined(UNBOUNDED_CELLS):
      if state.currentCell < state.cells.len:
        state.cells.add 0

    state.currentCell += 1

    if state.currentCell > state.cells.len:
      quit("Program exited as the end of the tape was reached!", 1)

  of DecMemPtr:
    state.currentCell -= 1

    if state.currentCell < state.cells.len:
      quit("Program exited as the tape uses negative indexes!", 1)


  of IncVal:
    if state.cells[state.currentCell] == high(CellType):
      state.cells[state.currentCell] = low(CellType)

    else:
      state.cells[state.currentCell] += 1

  of DecVal:
    if state.cells[state.currentCell] == low(CellType):
      state.cells[state.currentCell] = high(CellType)

    else:
      state.cells[state.currentCell] -= 1

  of LoopStart:
    if state.cells[state.currentCell] == 0:
      # This ensures we don't exit prematurely
      var nestDepth = 0

      # Find the ending brace
      while (state.program[state.currentInstruction] != LoopEnd) and nestDepth == 0:
        state.currentInstruction += 1

        #echo "loop start: ", nestDepth

        # Find nested brackets
        if state.program[state.currentInstruction] == LoopStart:
          nestDepth += 1

        elif state.program[state.currentInstruction] == LoopEnd:
          nestDepth -= 1

  of LoopEnd:
    if state.cells[state.currentCell] != 0:
      # This ensures we don't exit prematurely
      var nestDepth = 0

      while (state.program[state.currentInstruction] != LoopStart) and nestDepth == 0:
        # We have to go backwards to find the opening bracket
        state.currentInstruction -= 1

        #echo "loop end: ", nestDepth

        # Find nested brackets
        if state.program[state.currentInstruction] == LoopEnd:
          nestDepth -= 1

        elif state.program[state.currentInstruction] == LoopStart:
          nestDepth += 1

  of GetChar:
    state.cells[state.currentCell] = getch().CellType

  of PutChar:
    stdout.write(state.cells[state.currentCell].char)
    stdout.flushFile()

  else:
    discard # Undefined behaviour should be ignored, it's though already
            # done implicitly

  state.currentInstruction += 1

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

