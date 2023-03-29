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
  sequtils, # Used for `filterIt`
  streams,  # Used for writing bytes to a stream
  os        # Used for the command line and to get the correct ext
]

import ./common # Used so we can have more code reuse


proc findMatchingEndBracket(position: uint16, code: seq[char]): uint16 =
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


proc findMatchingStartBracket(position: uint16, code: seq[char]): uint16 =
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


proc incOrDecOp(chr: char, op: Opcode, pos: var uint16, code: seq[char]): Instruction =
  var count: uint16 = 0

  while code[pos] == chr:
    count += 1
    pos += 1

    if pos.int >= code.len:
      break

  Instruction(op: op, ub2Val: count)


proc compileBf(strm: Stream, rawCode: string) =
  var program = Program()

  let code = rawCode.filterIt(it in ".,-+<>[]")
  var pos: uint16 = 0

  while pos.int < code.len:
    let inst = code[pos]

    case inst
      of '+':
        program.instrs.add incOrDecOp('+', Opcode.IncCell, pos, code)

      of '-':
        program.instrs.add incOrDecOp('-', Opcode.DecCell, pos, code)

      of '>':
        program.instrs.add incOrDecOp('>', Opcode.IncPtr, pos, code)

      of '<':
        program.instrs.add incOrDecOp('<', Opcode.DecPtr, pos, code)

      of '[':
        let endB = findMatchingEndBracket(pos, code)
        program.instrs.add Instruction(op: Opcode.Label, ub2Val: pos)
        program.instrs.add Instruction(op: Opcode.GoToIfZ, ub2Val: endB)

        pos += 1

      of ']':
        let startB = findMatchingStartBracket(pos, code)
        program.instrs.add Instruction(op: Opcode.Label, ub2Val: pos)
        program.instrs.add Instruction(op: Opcode.GoToIfNZ, ub2Val: startB)

        pos += 1

      of '.':
        program.instrs.add Instruction(op: Opcode.PutChr, ub2Val: 0)

        pos += 1

      of ',':
        program.instrs.add Instruction(op: Opcode.GetChr, ub2Val: 0)

        pos += 1

      else:
        pos += 1

  strm.write(MAGIC.toBigEndian)
  strm.write(VERSION.toBigEndian)

  for instr in program.instrs:
    strm.write(instr.op)

    case instr.op
      of {IncCell, DecCell, IncPtr, DecPtr, Label, GoToIfZ, GoToIfNZ}:
        strm.write(instr.ub2Val.toBigEndian)

      else:
        discard


proc compile(filename: string) =
  var strm = newStringStream()
  compileBf(strm, readFile(filename))

  strm.setPosition(0)
  writeFile(filename.changeFileExt("nbf"), strm.readAll())


# Compile the brainfuck file
if paramCount() != 1:
  quit("We only accept 1 argument to compile!", 1)

compile(paramStr(1))
