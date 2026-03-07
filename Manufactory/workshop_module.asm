section definitions
  define  SP_PRINTERID                  0
  define  SP_REAGENTS                   1
  define  SP_BUTTONS                    2
  define  SP_PRINTERTYPE                3

  define  SP_BUTTONS_TABLE              4

  define  SP_REAGENTS_TABLE             10
  define  SP_INGOTS_TABLE               30

  define  SP_SEC_TABLE                  80
  define  SP_MIN_TABLE                  140

  define  BTN_AUTO_BIT_IDX              Calc(SP_BUTTONS_TABLE)
  define  BTN_STOP_BIT_IDX              Calc(SP_BUTTONS_TABLE+1)
  define  BTN_ONE_BIT_IDX               Calc(SP_BUTTONS_TABLE+2)
  define  BTN_RUN_BIT_IDX               Calc(SP_BUTTONS_TABLE+3)

  define  BUTTON_AUTO                   0b00010000
  define  BUTTON_STARTS                 0b11000000 ; Bitflags to enable ONE and RUN buttons (maybe)
  define  BUTTON_ABORT                  0b00100000 ; Bitflags to enable ABORT button

  define  DISPLAYMODE_NUMERIC           0
  define  DISPLAYMODE_PERCENTAGE        1 ; Percentage Display Mode
  define  DISPLAYMODE_STRING            10

  define  QuantityKeypad                Hash("ModularDeviceNumpad")
  define  Stacker                       Hash("StructureStackerReverse")

  define  ButtonDiode                   Hash("ModularDeviceLabelDiode2")
  define  NeedsAttentionLight           Hash("ModularDeviceLabelDiode3")
  define  LEDDisplay2                   Hash("ModularDeviceLEDdisplay2")
  define  LEDDisplay3                   Hash("ModularDeviceLEDdisplay3")

  define  DigitalFlipFlop               Hash("StructureChuteDigitalFlipFlopSplitterRight")
  define  DigitalFlipFlopIntake         Hash("StructureChuteDigitalFlipFlopSplitterLeft")
  define  LogicMemory                   Hash("StructureLogicMemory")

  define  STR_DONE                      Str("FINISH")
  define  STR_FAIL                      Str("ABORT")
  define  STR_TIME                      0x6D000073 ;"m\x00\x00s"

  define  REAGENT_MODULUS_1             183829
  define  REAGENT_MODULUS_2             19

  define  REAGENT_MIN_QTY               500                                 ; Minimum desired quantity of each reagent
  define  REAGENT_BAD_QTY               200                                 ; Orange "oh shit" quantity threshold
  define  REAGENT_OK_QTY                400                                 ; Yellow "low" quantity threshold

  define  CMD_ACCEPT_INGOT              1

  alias   job_quantity                  r15                                 ; Also counts as "job active" if nonzero
  alias   auto_mode                     r14
  alias   post_print_timer              r13                                 ; Trigger timer for post-print functions
  alias   printer_refid                 r12                                 ; printer RefId
  alias   button_lights                 r11
  alias   button_lights_last            r10
  alias   printer_command               r9
  alias   print_batch_time              r8

  alias   scratch                       r0
  alias   scratch2                      r1
  alias   scratch3                      r2
  alias   scratch4                      r3

  alias   Mod_LowIngotHash              Channel0
  alias   Mod_LowIngotAmount            Channel1
  alias   Mod_AutomaticMode             Channel2

  alias   Mod_PrinterPrefabHash         Channel4
  alias   Mod_PrinterMetaCommand        Channel5
  alias   Mod_ReqItemHash               Channel6
  alias   Mod_ReqItemCount              Channel7

section common_init requires definitions
  clr db

macro reagent_map reagentCode ingotName
  poke Calc(reagentCode%REAGENT_MODULUS_1%REAGENT_MODULUS_2+SP_INGOTS_TABLE) ingotName
endmacro

  reagent_map Hash("Silver") Hash("ItemSilverIngot")          ; Write out a LUT for reagent -> ingot mapping
  reagent_map Hash("Silicon") Hash("ItemSiliconIngot")        ; We don't use rmap since that requires a d* device pin to be set
  reagent_map Hash("Nickel") Hash("ItemNickelIngot")          ; And any d* pin setup violates 'turnkey' self-provisioning design
  reagent_map Hash("Lead") Hash("ItemLeadIngot")
  reagent_map Hash("Iron") Hash("ItemIronIngot")
  reagent_map Hash("Gold") Hash("ItemGoldIngot")
  reagent_map Hash("Copper") Hash("ItemCopperIngot")
  reagent_map Hash("Steel") Hash("ItemSteelIngot")
  reagent_map Hash("Solder") Hash("ItemSolderIngot")
  reagent_map Hash("Invar") Hash("ItemInvarIngot")
  reagent_map Hash("Electrum") Hash("ItemElectrumIngot")
  reagent_map Hash("Constantan") Hash("ItemConstantanIngot")
  reagent_map Hash("Waspaloy") Hash("ItemWaspaloyIngot")
  reagent_map Hash("Stellite") Hash("ItemStelliteIngot")
  reagent_map Hash("Inconel") Hash("ItemInconelIngot")
  reagent_map Hash("Hastelloy") Hash("ItemHastelloyIngot")
  reagent_map Hash("Astroloy") Hash("ItemAstroloyIngot")


  sb DigitalFlipFlop On 1
  sb ButtonDiode On 0
  sb LEDDisplay2 Mode DISPLAYMODE_PERCENTAGE
  sb LEDDisplay2 Color Color.Yellow
  sb LEDDisplay3 Mode DISPLAYMODE_STRING

  move scratch -1

time_init_loop:                                               ; Construct lookup table for time-remaining strings
  add scratch scratch 1
  move scratch2 0x303000                                      ; Initialize scratch2 to "00 " where the space is a null byte

  mod scratch3 scratch 10                                     ; Add ones digit to second character in string
  sll scratch3 scratch3 8                                     ; ASCII in place is already '0' so we just have to increment it
  add scratch2 scratch2 scratch3

  div scratch3 scratch 10                                     ; Do the same for the tens digit
  trunc scratch3 scratch3
  sll scratch3 scratch3 16
  add scratch2 scratch2 scratch3

  bge scratch 60 no_write_seconds                             ; Write to seconds table only if 0 <= x <= 59
  add scratch3 scratch SP_SEC_TABLE
  poke scratch3 scratch2

  bgt scratch 9 no_write_seconds                              ; If x < 10, change the first byte from 0 to \x00 for tens digit of minutes table entry
  ins scratch2 Str(" ") 16 8

no_write_seconds:
  add scratch3 scratch SP_MIN_TABLE                           ; Write minutes table entry
  poke scratch3 scratch2
  blt scratch 99 time_init_loop                               ; Anything > 99m59s is beyond the ETA limit

  move r0 -1                                                  ; Find the printer on the network

search_loop:
  add r0 r0 1
  get printer_refid db:0 r0
  bdnvl printer_refid CompletionRatio search_loop

  lb r0 ButtonDiode PrefabHash Sum
  move r1 -1
  move sp SP_BUTTONS_TABLE

button_search_loop:
  add r1 r1 1
  get r2 db:0 r1
  l r3 r2 PrefabHash
  bne r3 ButtonDiode button_search_loop
  push r2
  sub r0 r0 ButtonDiode
  bnez r0 button_search_loop
  poke SP_BUTTONS sp

  move printer_command PrinterInstruction.ExecuteRecipe
  move button_lights_last -1
  move button_lights 0
  sb ButtonDiode On 1
  move post_print_timer 1

  move sp SP_REAGENTS_TABLE
  push Hash("Iron")
  push Hash("Silicon")
  push Hash("Copper")
  push Hash("Gold")
  push Hash("Steel")
  poke SP_REAGENTS sp

section toolmaker_init requires common_init
  push Hash("Invar")
  push Hash("Stellite")
  push Hash("Hastelloy")
  push Hash("Astroloy")
  push Hash("Waspaloy")
  push Hash("Constantan")
  push Hash("Solder")
  push Hash("Electrum")
  poke SP_REAGENTS sp

section autolathe_init requires common_init
  push Hash("Solder")
  push Hash("Electrum")
  push Hash("Constantan")
  push Hash("Astroloy")
  push Hash("Stellite")
  poke SP_REAGENTS sp

section bender_init requires common_init
  push Hash("Silver")
  push Hash("Electrum")
  push Hash("Constantan")
  push Hash("Invar")
  push Hash("Stellite")
  poke SP_REAGENTS sp

section electro_init requires common_init
  push Hash("Electrum")
  push Hash("Constantan")
  push Hash("Solder")
  push Hash("Inconel")
  push Hash("Astroloy")
  push Hash("Stellite")
  push Hash("Hastelloy")
  push Hash("Silver")
  poke SP_REAGENTS sp


section application requires definitions

loop_clear_jq:
  move job_quantity 0                                         ; Clear job_quantity on initial application boot or if getting NaN quantity from auto mode channel data

loop:
  l scratch printer_refid PrefabHash
  s db:0 Mod_PrinterPrefabHash scratch                        ; Write printer type to network (Every tick in case network reworked; stops NaN printer hash)
  seqz r0 auto_mode                                           ; Keep the splitter in the right mode
  sb DigitalFlipFlop Mode r0
  l scratch db:0 Mod_PrinterMetaCommand                       ; If we get command = 1 from the master, we need to divert an incoming ingot
  bne scratch CMD_ACCEPT_INGOT no_intake
  sb DigitalFlipFlopIntake Mode 1

no_intake:
  s db:0 Mod_PrinterMetaCommand 0                             ; Clear command from manufactory control
  get scratch db BTN_AUTO_BIT_IDX                             ; Then read in automatic status from indicator light / switch
  l auto_mode scratch On
  s db:0 Mod_AutomaticMode auto_mode                          ; Update automatic mode state to manufactory
  select scratch job_quantity 1 auto_mode                     ; Lock the printer if in auto mode or running a batch
  s printer_refid Lock scratch
  select button_lights job_quantity BUTTON_ABORT BUTTON_STARTS
  select button_lights auto_mode BUTTON_AUTO button_lights    ; Select which lights we should display based on current state
  beq button_lights_last button_lights start_qty_loop         ; If we haven't asked for a button state change, don't force new values
  get sp db SP_BUTTONS

button_loop:                                                  ; Iterate through the buttons, pulling control bits from button_lights
  pop scratch2                                                ; and pushing to On logic type
  ext scratch button_lights sp 1                              ; Yes, using SP as both table iterator and bit index.  No, the table is not 0-aligned.
  s scratch2 On scratch                                       ; We just lose four bits out of a 53-bit word, I think we can afford that
  bgt sp SP_BUTTONS_TABLE button_loop
  move button_lights_last button_lights

start_qty_loop:
  get sp db SP_REAGENTS                                       ; Now scan reagent store to see what we need to request from the manufactory master controller
  move scratch2 REAGENT_MIN_QTY                               ; Find anything with less than REAGENT_MIN_QTY units in the printer
  move scratch4 0                                             ; Whichever reagent type we have LEAST of, we ask for from the manufactory

qty_loop:
  pop scratch3                                                ; Read reagent type from stack
  lr scratch printer_refid Contents scratch3                  ; Get reagent contents from printer
  bgt scratch scratch2 end_qty_loop                           ; And check if this reagent type is less than our previous "lowest" quantity
  move scratch2 scratch                                       ; If so, store the new lowest reagent quantity and hash
  move scratch4 scratch3

end_qty_loop:
  bgt sp SP_REAGENTS_TABLE qty_loop

  mod scratch4 scratch4 REAGENT_MODULUS_1                     ; Report this up to the master, but first look up the ingot hash from the reagent hash
  mod scratch4 scratch4 REAGENT_MODULUS_2                     ; Use this over rmap because rmap requires a d* pin ref
  add scratch4 scratch4 SP_INGOTS_TABLE                       ; Double-modulus technique lets me map 17 reagent hashes into a 19-entry table w/ 17 ingots
  get scratch4 db scratch4                                    ; Single-modulus approach requires a 78-word table instead, so big space savings for one LoC.

  s db:0 Mod_LowIngotHash scratch4                            ; Write these to network channels for the manufactory controller to read
  s db:0 Mod_LowIngotAmount scratch2                          ; Each workshop module has a dedicated network split by a logic memory.

  sgt scratch scratch2 REAGENT_BAD_QTY                        ; Set the colour of the "stock status light bar" based on if all reagents have at least
  sgt scratch2 scratch2 REAGENT_OK_QTY                        ; REAGENT_BAD_QTY / REAGENT_OK_QTY quantity or not.
  select scratch scratch Color.Yellow Color.Orange            ;                    Qty <= REAGENT_BAD_QTY => Orange
  select scratch scratch2 Color.Green scratch                 ; REAGENT_BAD_QTY <  Qty <= REAGENT_OK_QTY  => Yellow
  sb NeedsAttentionLight Color scratch                        ; REAGENT_OK_QTY  <  Qty                    => Green
  sb NeedsAttentionLight On 1

test_idle:
  yield                                                       ; Yield AFTER setting buttons so that the changes have time to implement
  sb LEDDisplay2 On job_quantity                              ; before we start reading button states
  beqz job_quantity idle                                      ; Then turn on the progress % indicator if we're printing.  Otherwise jump to idle handler

active_job:                                                   ; Handler for when the printer is expected to be active
  add print_batch_time print_batch_time 0.5                   ; Keep track of how many seconds this print job has been running for
  l scratch printer_refid ExportCount                         ; Start by showing the current print progress
  l scratch2 printer_refid CompletionRatio                    ; Take ExportCount (integer) + CompletionRatio ([0..1) ratio)
  add scratch3 scratch scratch2                               ; Add those together and divide by total job quantity
  div scratch3 scratch3 job_quantity
  sb LEDDisplay2 Setting scratch3                             ; Set that to the progress % display
  beqz scratch3 no_time_update                                ; If we've made exactly 0% progress, we can't do a time estimation yet.

  sub scratch4 1 scratch3                                     ; If we've made progress, we can do a time-remaining estimation.  Start by getting the remaining progress
  div scratch3 scratch3 print_batch_time                      ; Then divide our 'made' progress by how long that took, to get a progress/time rate
  div scratch3 scratch4 scratch3                              ; Then divide the remaining progress by that rate to get estimated # of seconds to finish the print job
  blt scratch3 CALC(99*60+59) normal_time                     ; If ETA is over 99m59s, show "long" instead of trying to read out of bounds in stack
  move scratch2 Str(">1h40m")                                 ; Technically inaccurate at exactly 1h40m00s
  j write_time

normal_time:
  mod scratch4 scratch3 60                                    ; Then assemble the time string using lookup tables
  add scratch2 scratch4 SP_SEC_TABLE                          ; We look up the "seconds" and "minutes" number groups separately.
  get scratch2 db scratch2                                    ; Load seconds display to scratch

  sub scratch3 scratch3 scratch4                              ; Get minutes string from lookup table too (this table omits the leading 0, seconds does not)
  div scratch3 scratch3 60                                    ; Subtract seconds from total then divide by 60 to get integer minutes remaining
  add scratch3 scratch3 SP_MIN_TABLE                          ; Load from data table
  get scratch3 db scratch3                                    ; and insert into the minutes section.
  ins scratch2 scratch3 24 24                                 ; NOTE: Both number groups are *3* characters long, rightmost chars are \00 and replaced below.

  or scratch2 scratch2 STR_TIME                               ; Bitwise-OR the "m  s" text into the display overtop of the \00 characters from M/S strings

write_time:
  sb LEDDisplay3 Setting scratch2                             ; and write to large LCD

no_time_update:
  bnez auto_mode no_abort                                     ; Don't allow checking the abort button in auto mode
  get scratch3 db BTN_STOP_BIT_IDX                            ; Pull the abort button's RefID and check if it's on
  l scratch3 scratch3 On
  bnez scratch3 no_abort                                      ; If the light is on, we have NOT pressed the abort button, so don't abort
  clrd printer_refid                                          ; Otherwise, clear command memory and stop the printer
  s printer_refid Activate 0

no_abort:
  get scratch3 printer_refid 0                                ; Printer clears command memory on finish.  So cleared memory == finished OR aborted
  bnez scratch3 loop                                          ; If memory is not clear, printer still running so return to loop start

job_complete:
  yield                                                       ; If the job is finished, we need to wait a second to let the printer finish updating internal logic
  yield                                                       ; Otherwise we will always flag a failed print (even if it succeeded)
  l scratch printer_refid ExportCount                         ; Pull the export count (resets every job start)
  seq scratch scratch job_quantity                            ; and compare to the expected quantity
  move job_quantity 0                                         ; Clear expected job quantity
  select scratch2 scratch STR_DONE STR_FAIL                   ; And choose between green FINISh and red ABORT text based on quantity match
  select scratch scratch Color.Green Color.Red

  sb QuantityKeypad Color scratch                             ; Set keypad/display colours and text based on result
  sb LEDDisplay3 Color scratch
  sb LEDDisplay3 Setting scratch2
  sb LogicMemory Setting 0                                    ; Clear "current job" indication for console screen

  move post_print_timer 0                                     ; And trigger timer to reset colours + fire stacker
  j loop                                                      ; Then return to main loop

idle:
  sub post_print_timer post_print_timer 1                     ; "Idle" handler.  Resets display colours and runs stacker if needed
  bne post_print_timer -2 no_stacker_trig                     ; If a second job starts too fast, this won't run those functions.
  sb Stacker Activate 1                                       ; But that's okay - colour shouldn't be reset if not idle, and stacker
                                                              ; will be triggered when the first item of the next print spits out
no_stacker_trig:
  bne post_print_timer -6 no_color_trig                       ; Fire stacker at 2 ticks after complete, and clear colours at 6 ticks after complete
  sb QuantityKeypad Color Color.White
  sb LEDDisplay3 Color Color.White
  sb LEDDisplay3 Setting Str("Idle")

no_color_trig:
  bnez auto_mode check_auto_start                             ; Otherwise, depending on auto/manual mode, look for job start trigger

check_manual_start:                                           ; In manual mode, ONE or RUN buttons start with 1 or (keypad) job_quantity
  get scratch db BTN_ONE_BIT_IDX
  l job_quantity scratch On
  seqz job_quantity job_quantity                              ; So we can load the ONE button directly into job_quantity with a logical not

  get scratch db BTN_RUN_BIT_IDX                              ; Load RUN button and use to select between Keypad QTY (if OFF) or job_quantity from ONE button
  l scratch scratch On
  lb scratch2 QuantityKeypad Setting Sum
  select job_quantity scratch job_quantity scratch2
  l scratch printer_refid RecipeHash
  j start_job                                                 ; Always try to start the job.  job_quantity == 0 is checked in common start_job handler

check_auto_start:
  l job_quantity db:0 Mod_ReqItemCount                        ; Check for a quantity command from the master
  bnan job_quantity loop_clear_jq                             ; NaN check just to be sure
  s db:0 Mod_ReqItemCount 0                                   ; Zero out quantity command after reading it
  l scratch db:0 Mod_ReqItemHash                              ; Load recipe hash from Channel6

start_job:
  beqz job_quantity loop                                      ; 0? No job - Otherwise we store the job quantity and start to dispatch a job
  s printer_refid ClearMemory 1                               ; Reset printer export counts before starting job
  sb LogicMemory Setting scratch                              ; Update logic memory (and thus console hash display) with active job
  ins printer_command scratch 16 32                           ; Hash to correct bitfield
  ins printer_command job_quantity 8 8                        ; Insert quantity field
  put printer_refid 0 printer_command                         ; Dispatch instruction to printer

  sb QuantityKeypad Color Color.Yellow                        ; Change display colours to "in progress" code
  sb LEDDisplay3 Color Color.Yellow
  move print_batch_time 0                                     ; Reset the print timer
  j loop                                                      ; And return to main loop
