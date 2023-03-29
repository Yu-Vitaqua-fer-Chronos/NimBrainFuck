import std/[
  terminal,  # Used for `getch`
  streams,   # Used for reading the program
  tables,    # Used for the jump map
  os         # Used for the command line arguments
]

import ./common

# Default amount of cells, changeable
const CELL_COUNT {.intdefine.} = 30000

type CellType = uint8

type BFVMState = object
  cells: seq[CellType]
  jumpTable: Table[uint16, uint16]
  program: Program
  currentCell: int
  currentInstruction: uint16

# Simple initialisation function
proc init(_: typedesc[BFVMState], maxCells=CELL_COUNT): BFVMState =
  result = BFVMState()
  result.cells = newSeqUninitialized[CellType](maxCells)
  result.currentCell = 0
  result.currentInstruction = 0

template jumpTo(vm: var BFVMState, label: uint16) =
  vm.currentInstruction = vm.jumpTable[label]

proc readProgram(vmState: var BFVMState, strm: Stream) =
  let magicNum = strm.readUint32().toBigEndian()

  if magicNum != MAGIC:
    quit("The magic number doesn't match the file's first 4 bytes!", 1)

  let ver = strm.readUint8().byte

  if ver != VERSION:
    quit("The brainfuck file is outdated! We're version {VERSION}, but the file was compiled with version {ver}!")

  var pos: uint16 = 0

  while not strm.atEnd:
    let op = strm.readUint8().Opcode
    var instr = Instruction(op: op)

    case op
      of Label:
        instr.ub2Val = strm.readUint16().fromBigEndian()
        vmState.jumpTable[instr.ub2Val] = pos

      of {IncCell, DecCell, IncPtr, DecPtr, GoToIfZ, GoToIfNZ}:
        instr.ub2Val = strm.readUint16().fromBigEndian()

        pos += 1

      else:
        pos += 1

    vmState.program.instrs.add instr


proc run*(filename: string) =
  var vmState = BFVMState.init()

  try:
    var strm = newFileStream(filename)
    vmState.readProgram(strm)
  except IOError:
    quit("Couldn't read from file!", 1)

  echo vmState.program

  while vmState.program.instrs.len.uint16 > vmState.currentInstruction:
    let instr = vmState.program.instrs[vmState.currentInstruction]

    case instr.op
      of IncCell:
        for i in uint16(1)..instr.ub2Val:
          vmState.cells[vmState.currentCell] += 1

        vmState.currentInstruction += 1

      of DecCell:
        for i in uint16(1)..instr.ub2Val:
          vmState.cells[vmState.currentCell] -= 1

        vmState.currentInstruction += 1

      of IncPtr:
        for i in uint16(1)..instr.ub2Val:
          when defined(UNBOUNDED_CELLS):
            if vmState.currentCell < vmState.cells.len:
              vmState.cells.add 0

          vmState.currentCell += 1

          if (vmState.currentCell >= CELL_COUNT) and (not defined(UNBOUNDED_CELLS)):
            quit("Program exited as the end of the tape was reached!", 1)

        vmState.currentInstruction += 1

      of DecPtr:
        for i in uint16(1)..instr.ub2Val:
          vmState.currentCell += 1

          if vmState.currentCell < 0:
            quit("Program exited as the start of the tape was reached!", 1)

        vmState.currentInstruction += 1

      of Label: # Already used so it's unneeded
        vmState.currentInstruction += 1

      of GoToIfZ:
        if vmState.cells[vmState.currentCell] == low(CellType):
          vmState.jumpTo(instr.ub2Val)

        else:
          vmState.currentInstruction += 1

      of GoToIfNZ:
        if vmState.cells[vmState.currentCell] != low(CellType):
          vmState.jumpTo(instr.ub2Val)

        else:
          vmState.currentInstruction += 1

      of PutChr:
        stdout.write(vmState.cells[vmState.currentCell].char)
        stdout.flushFile()

        vmState.currentInstruction += 1

      of GetChr:
        vmState.cells[vmState.currentCell] = getch().CellType

        vmState.currentInstruction += 1


if paramCount() != 1:
  quit("We only accept 1 argument to compile!", 1)

run(paramStr(1))
