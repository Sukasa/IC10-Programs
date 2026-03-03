# SPSM PROJECT - AAC ALARM ANNUCIATOR CHIP
# Revision: 2025-10-04
# Variant: Stack-Driven
# Timing: 8 init + 8/loop + 4/alarm
# Format: n: RefrenceId (53)
# Annunciates ALARM STATE values from an ASC to up to 30 DISPLAY UNITS, by setting their `On` LogicType values
# Stores ReferenceId values of DISPLAY UNITS in stack memory starting from Stack addresses 30..1

  alias ASC d0
  move r0 0
  move r1 0
  move r2 0
  move r3 0
  move r4 0
  move r5 1
  move r6 0
  move r7 0
 
start:
  yield
  
  # Update AAC LUT
  seqz r3 r3
  xor r2 r2 r3
  move r7 r3
  move r6 r2
  
  # Enter loop
  move sp 31
  pop r15
  
loop:
  get r13 d0 sp
  s r15 On rr13
  pop r15
  bgtz r15 loop
  j start