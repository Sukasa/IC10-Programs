# SPSM PROJECT - ASC ALARM STATE CONTROL
# Revision: 2025-10-04
# Variant: Stack-Driven w/ Aggregate, Shared ACK
# Timing: 10 AS/tick, 3 ticks/cycle.  Ticks per step: 126, 121, 123
# Format: n: RAM Address (13)
# Reads a configurable set of in-alarm flags from a connected STACK UNIT, pushing back NORMAL/UNACK/ACKED state values to the same stack addresses
# Reads the Alarm Reset signal from the STACK UNIT and clears it after resetting.  Updates its own `Setting` with alarm statistics every full cycle through its alarm list
# Scans up to 30 alarms at a fixed 0.67 Hz update rate.  Uses ACK handler that allows for multiple ASCs to share one ACK flag without contention
# Provides an AAC-compatible value store in Stack 1-30 to match AAC chip.  Zone RAM addresses at 32..61

  alias StackUnit d0
  define ACKADDR  0
 
  # ALARM STATE Look-Up Table
  alias LUT0       r0
  alias LUT1       r1
  alias LUT2       r2
  alias LUT3       r3
  alias LUT4       r4
  alias LUT5       r5
  alias LUT6       r6
  alias LUT7       r7
  
  # Statistics Bin Table
  alias StatsInAkd r8	# Inactive Acknowledged ("Normal") Alarms
  alias StatsInUnA r9	# Inactive Unacknowledged ("Previous") Alarms
  alias StatsAcAkd r10	# Active Acknowledged ("Acknowledged") Alarms
  alias StatsAcUnA r11	# Active Unacknowleged ("Current") Alarms
  
  # Working Registers
  alias RamAddr    r12	# RAM Address of ALARM STATE value in STACK UNIT
  alias Step       r13	# Tick Step of ASC iteraction
  alias Acknldg    r14	# Acknowledge State Flag
  alias Scratch    r15	# Scratch Register
  alias ScratchPtr rr15	# Indirect Scratch Lookup

  poke 31 -1    # Init safety sentinel value
  move LUT0 0
  move LUT1 3
  move LUT2 2
  move LUT3 3
  move LUT4 0
  move LUT5 5
  move LUT6 6
  move LUT7 7

zone_ack:
  move sp 62
  beqz Acknldg no_clear
  put d0 ACKADDR 0
  
no_clear:
  get Acknldg d0 ACKADDR		# Process alarm acknowledgement signal, in a way that won't clobber other ASCs using the same address
  move Step 2
  
tick:
  bltz Step zone_ack
  yield
  beqz Step ack_apply
  beq Step 1 stats
  
ret_point:
  sub Step Step 1
  
next:
  pop RamAddr					# Get the next Zone RAM address for ALARM STATE
  bltz RamAddr check_tick       # If it's invalid, skip this entry
  get Scratch d0 RamAddr        # Read Zone RAM state (which may have been altered with an INS x 0 1 AlarmActiveBit for the alarm)
  sub ra sp 31                  # Offset for AAC memory location
  poke ra ScratchPtr            # Write new ALARM STATE to self RAM for AAC
  put d0 RamAddr ScratchPtr     # Also write ALARM STATE to Zone RAM
  ins Scratch 2 2 2             # Mask + Offset to stats bin table
  add ScratchPtr ScratchPtr 1   # Stats aggregate
  
check_tick:
  mod Scratch sp 10				# Keep track of how many ALARM STATE values we have processed this tick
  bne Scratch 2 next            # Check anti-race-condition limiter
  j tick						# Next tick
  
stats:
  ins StatsInAkd 13 13 StatsInUnA   # Allow up to 8192 alarms per bin (way more than we'll ever need)
  ins StatsInAkd 26 13 StatsAcAkd
  ins StatsInAkd 39 13 StatsAcUnA
  s db Setting StatsInAkd
  move StatsInAkd 0
  move StatsInUnA 0
  move StatsAcAkd 0
  move StatsAcUnA 0
  j ret_point
  
ack_apply: 						# Apply state diagram changes based on acknowledge flag
  select LUT2 Acknldg 0 2
  select LUT3 Acknldg 5 3
  select LUT6 Acknldg 0 6
  select LUT7 Acknldg 5 7
  j ret_point