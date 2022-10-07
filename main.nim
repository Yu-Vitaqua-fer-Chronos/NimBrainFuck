# > = increases memory pointer, or moves the pointer to the right 1 block.
# < = decreases memory pointer, or moves the pointer to the left 1 block.
# + = increases value stored at the block pointed to by the memory pointer
# - = decreases value stored at the block pointed to by the memory pointer
# [ = like c while(cur_block_value != 0) loop.
# ] = if block currently pointed to's value is not zero, jump back to [
# , = like c getchar(). input 1 character.
# . = like c putchar(). print 1 character to the console

# Imports
import std/os

# The maximum cells we can have at once, as defined by the spec
const CELL_COUNT = 30000

# The valid instructions, anything else is ignored
# This also could easily be removed
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
  cells: seq[ptr int]
  program: seq[Instruction]
  loopPositions: seq[int]
  currentCell: int
  currentInstruction: int

# Simple initialisation function
proc init(_: typedesc[BFInterpreterState], maxCells=CELL_COUNT): BFInterpreterState =
  result = BFInterpreterState()
  for _ in 0..maxCells:
    result.cells.add create(int)
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
    state.currentCell += 1

  of DecMemPtr:
    state.currentCell -= 1

  of IncVal:
    cast[ptr int](state.cells[state.currentCell])[] += 1

  of DecVal:
    cast[ptr int](state.cells[state.currentCell])[] -= 1

  of LoopStart:
    state.loopPositions.add state.currentInstruction

  of LoopEnd:
    if cast[ptr int](state.cells[state.currentCell])[] == 0:
      state.loopPositions.del(state.loopPositions.len-1)
    else:
      state.currentInstruction = state.loopPositions[^1]

  of GetChar:
    discard # Not implemented yet

  of PutChar:
    stdout.write(cast[ptr int](state.cells[state.currentCell])[].char)
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

