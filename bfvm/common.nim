import std/[
  endians # Used for helper procs
]

const
  MAGIC*: uint32 = 0x626E666B
  VERSION* = 1.byte

type
  Opcode* = enum
    IncCell = 1.byte # +
    DecCell          # -
    IncPtr           # >
    DecPtr           # <
    Label            # {No Mapping}
    GoToIfZ          # [
    GoToIfNZ         # ]
    PutChr           # .
    GetChr           # ,

  Instruction* = object
    op*: Opcode     # The opcode
    ub2Val*: uint16 # `Unsigned Byte 2 Value`

  Program* = object
    instrs*: seq[Instruction]

when cpuEndian == bigEndian:
  proc toBigEndian*(num: SomeNumber): SomeNumber = num
  proc fromBigEndian*(num: SomeNumber): SomeNumber = num

else:
  proc fromBigEndian*[T: uint8 | int8](num: T): T = num
  proc fromBigEndian*[T: uint16 | int16](num: T): T = swapEndian16(addr result, unsafeaddr num)
  proc fromBigEndian*[T: uint32 | int32](num: T): T = swapEndian32(addr result, unsafeaddr num)
  proc fromBigEndian*[T: uint64 | int64](num: T): T = swapEndian64(addr result, unsafeaddr num)

  proc toBigEndian*[T: uint8 | int8](num: T): T = num
  proc toBigEndian*[T: uint16 | int16](num: T): T = swapEndian16(addr result, unsafeaddr num)
  proc toBigEndian*[T: uint32 | int32](num: T): T = swapEndian32(addr result, unsafeaddr num)
  proc toBigEndian*[T: uint64 | int64](num: T): T = swapEndian64(addr result, unsafeaddr num)

#[
=====Instructions=====
LABEL <uint16>
  Labels a position that can be jumped to, marked by a <uint16>.

INCCELL <uint16>
  Increments a cell by <uint16>.

DECCELL <uint16>
  Decrements a cell by <uint16>.

INCPTR <uint16>
  Moves the pointer to the right by <uint16>.

DECPTR <uint16>
  Moves the pointer to the left by <uint16>.

LABEL <uint16>
  A label just specifies a tagged position in the bytecode that can
  be jumped to.

GOTOIFZ <uint16>
  Go to a label if the current cell is equal to 0.

GOTOIFNZ <uint16>
  Go to a label if the current cell is not 0.

PUTCHR
  Prints the current cell value in the cell to STDOUT.

GETCHR
  Fetches input from STDIN and sets the current cell value to it.
]#
