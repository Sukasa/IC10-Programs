section definitions
alias opcode  r15
alias blinker r10

alias bucket_outvalue r14
alias bucket_boundary r13

;  55544444444443333333333222222222211111111110000000000 Bit Index (10s)
;  21098765432109876543210987654321098765432109876543210 Bit Index ( 1s)
;0b0000000KKKKJJJJJJJJJIIIIHGGGFFFFEEEDDCCCCCCCCCBBBBAAA Bit Assignment


section application requires definitions

init:
  move sp 1                                       # Do this instead of `get sp db 0` in order to maintain compatibility with atmospherics device sockets
  pop sp
  seqz blinker blinker

next_ins:
  pop opcode
  beqz opcode init                                # An all-zero opcode is treated as a "j 0" equivalent
  
  ext r14 opcode 0 3                              # AAA       - Input Type
  ext r13 opcode 3 4                              # BBBB      - Slot # or Register #
  ext r12 opcode 7 9                              # CCCCCCCCC - LogicType
  pop r8
  jr r14
  
_read_property:
  l r8 r8 r12
  
_read_constant:
  j modification
  
_read_slot_property:
  ls r8 r8 r13 r12
  j modification
  
_read_register:
  push r8                                         # We should not have popped r11 in this sole case, so put it back
  bgt r12 3 _read_stack                           # If read type > 3, it's actually a stack read to an address >= 4
  beqz r12 _read_stack                            # If read type == 0, that's an invalid read type so map it to stack read too (address 0 + index register)
  jr r12                                          # Read type is 1-3, mapping to (indirect, direct, no-op) register read type
  move r13 rr13
  move r8 rr13
  j modification
  
_read_stack:
  beqz r13 _read_stack_actual
  add r12 r12 rr13                                # Read stack address (Address >= 4 or == 0)
  
_read_stack_actual:
  get r8 d0 r12
  
modification:
  ext r14 opcode 16 2                             # DD
  jr r14
  
_modify_bucket:
  j do_bucket_sort
  
_modify_passthrough:
  j mutation                                    # Restore SP to instruction pointer
  
_modify_scale:
  pop r14
  sub r8 r8 r14
  pop r14
  mul r8 r8 r14

mutation:
  ext r14 opcode 18 3                             # EEE  - Mutation Select
  ext r11 opcode 28 1                             # H - Invert Flag
  jr r14

_mutation_storeif:
  ext r12 opcode 25 3                             # GGG  - Register Select
  snez r12 rr12
  xor r11 r11 r12
  
_mutation_none:
  j storage
  
_mutation_math:
  ext r12 opcode 25 3                             # GGG  - Register Select
  move r12 rr12
  ext r13 opcode 21 4                             # FFFF - Math Select
  jr r13
  
_math_add:
  add r8 r8 r12
  j end_math

_math_mult:
  mul r8 r8 r12
  j end_math

_math_BAND:
  and r8 r8 r12
  j end_math

_math_BOR:
  or r8 r8 r12
  j end_math

_math_BXOR:
  xor r8 r8 r12
  j end_math

_math_LT:
  slt r8 r8 r12
  j end_math

_math_LE:
  sle r8 r8 r12
  j end_math

_math_EQ:
  seq r8 r8 r12
  
end_math:
  xor r8 r8 r11
  move r11 1

storage:
  ext r14 opcode 29 3                             # IIII       - Store Type
  ext r13 opcode 33 9                             # JJJJJJJJJ - (Slot)LogicType or Register
  jr r14
  
_write_property:
  pop r12
  beqz r11 next_ins
  s r12 r13 r8
  j next_ins
  
_write_slot:
  pop r12
  beqz r11 next_ins
  ext r14 opcode 42 4                             # KKKK      - Slot #
  ss r12 r14 r13 r8
  j next_ins 
  
_write_register:
  beqz r11 next_ins
  and r13 r13 7
  move rr13 r8
  j next_ins
  
_write_stack:
  beqz r11 next_ins
  ext r14 opcode 42 4                             # KKKK      - Register # for indexing
  beqz r14 _write_stack_actual
  add r13 r13 rr14
  
_write_stack_actual:
  put d0 r13 r8
  j next_ins

do_bucket_sort:
  sub r11 sp 1                                    # Back up instruction pointer and set SP to the bucket data location in stack
  move r9 r8
  pop sp
  
next_bucket:
  pop bucket_boundary
  beqz bucket_boundary end_bucket
  pop bucket_outvalue
  blt r8 bucket_boundary next_bucket
  move r9 bucket_outvalue
  j next_bucket
  
end_bucket:
  move r8 r9
  move sp r11
  j modification