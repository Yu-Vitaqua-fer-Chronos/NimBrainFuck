
import std/endians

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


var
  a = 255u8
  b = 654319i64
assert a.toBigEndian().fromBigEndian() == a
assert b.toBigEndian().fromBigEndian() == b
