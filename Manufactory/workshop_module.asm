section definitions
  define  SP_PRINTERID                  0
  define  SP_REAGENTS                   1
  define  SP_BUTTONS                    2
  define  SP_PRINTERTYPE                3

  define  SP_BUTTONS_TABLE              4

  define  SP_REAGENTS_TABLE             10
  define  SP_INGOTS_TABLE               30

  define  BTN_AUTO_BIT_IDX              Calc(SP_BUTTONS_TABLE)
  define  BTN_STOP_BIT_IDX              Calc(SP_BUTTONS_TABLE+1)
  define  BTN_RUN_BIT_IDX               Calc(SP_BUTTONS_TABLE+2)
  define  BTN_ONE_BIT_IDX               Calc(SP_BUTTONS_TABLE+3)

  define  BUTTON_AUTO                   0b00010000
  define  BUTTON_STARTS                 0b11000000 ; Bitflags to enable ONE and RUN buttons (maybe)
  define  BUTTON_ABORT                  0b00100000 ; Bitflags to enable ABORT button

  define  DISPLAYMODE_NUMERIC           0
  define  DISPLAYMODE_PERCENTAGE        1 ; Percentage Display Mode
  define  DISPLAYMODE_STRING            10

  define  QuantityKeypad                Hash("ModularDeviceNumpad")
  define  Stacker                       Hash("StructureStackerReverse")
  define  ProgressBar                   Hash("ModularDeviceSliderDiode2")

  define  ButtonDiode                   Hash("ModularDeviceLabelDiode2")
  define  NeedsAttentionLight           Hash("ModularDeviceLabelDiode3")
  define  LEDDisplay2                   Hash("ModularDeviceLEDdisplay2")
  define  LEDDisplay3                   Hash("ModularDeviceLEDdisplay3")

  define  DigitalFlipFlop               Hash("StructureChuteDigitalFlipFlopSplitterRight")
  define  DigitalFlipFlopIntake         Hash("StructureChuteDigitalFlipFlopSplitterLeft")
  define  LogicMemory                   Hash("StructureLogicMemory")

  define  STR_DONE                      Str("FINISH")
  define  STR_TIME                      Str("00m00s")

  define  REAGENT_MODULUS_1             183829
  define  REAGENT_MODULUS_2             19

  define  REAGENT_MIN_QTY               500                                 ; Minimum desired quantity of each reagent
  define  REAGENT_BAD_QTY               200                                 ; Orange "oh shit" quantity threshold
  define  REAGENT_OK_QTY                400                                 ; Yellow "low" quantity threshold

  define  CMD_ACCEPT_INGOT              1

  alias   job_quantity                  r15                                 ; Also counts as "job active" if nonzero
  alias   auto_mode                     r14
  alias   stacker_delay                 r13                                 ; trigger delay before stacker is fired at end of job
  alias   color_delay                   r12                                 ; trigger delay before colours are reset on job finished
  alias   printer_refid                 r11                                 ; printer RefId
  alias   button_codes                  r10
  alias   button_lights                 r9
  alias   button_masks                  r8

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

macro reagent_map reagentCode ingotName
  poke Calc(reagentCode%REAGENT_MODULUS_1%REAGENT_MODULUS_2+SP_INGOTS_TABLE) ingotName
endmacro

  ; LUT for ingots
  reagent_map Hash("Silver") Hash("ItemSilverIngot")
  reagent_map Hash("Silicon") Hash("ItemSiliconIngot")
  reagent_map Hash("Nickel") Hash("ItemNickelIngot")
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
  sb ButtonDiode On 1
  sb LEDDisplay2 Mode DISPLAYMODE_PERCENTAGE
  move r0 -1                                                      ; Find the printer on the network

search_loop:
  add r0 r0 1
  get printer_refid db:0 r0
  bdnvl printer_refid CompletionRatio search_loop
  poke SP_PRINTERID printer_refid

  lb r0 ButtonDiode PrefabHash Sum
  move r1 -1
button_search_loop:
  add r1 r1 1
  get r2 db:0 r1
  l r3 r2 PrefabHash
  bne r3 ButtonDiode button_search_loop
  push r2
  sub r1 r1 ButtonDiode
  bnez r1 button_search_loop

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

  move color_delay 1
  move stacker_delay 1
  move job_quantity 0
  get printer_refid db SP_PRINTERID

loop:
  yield
  l scratch printer_refid PrefabHash
  s db:0 Mod_PrinterPrefabHash scratch                       ; Write printer type to network (Every tick in case network reworked; stops NaN printer hash)

  ; Keep the splitter in the right mode and keep some network vars persistent
  seqz r0 auto_mode
  sb DigitalFlipFlop Mode r0

  ; If we get command = 1 from the master, we need to divert an incoming ingot
  l scratch db:0 Mod_PrinterMetaCommand
  bne scratch CMD_ACCEPT_INGOT no_intake
  sb DigitalFlipFlopIntake Mode 1

no_intake:
  s db:0 Mod_PrinterMetaCommand 0

  ; Check what ingot we have the least of from the list
  get sp db SP_REAGENTS
  move scratch2 REAGENT_MIN_QTY                                                ; Find anything with less than 500 units in the printer
  move scratch4 0

qty_loop:
  pop scratch3
  lr scratch printer_refid Contents scratch3
  bgt scratch scratch2 end_qty_loop
  move scratch2 scratch
  move scratch4 scratch3

end_qty_loop:
  bgt sp SP_REAGENTS_TABLE qty_loop

  ; Report this up to the master
  ; but first look up the ingot hash from the reagent hash
  ; use this over rmap because rmap requires a d* pin ref
  mod scratch4 scratch4 REAGENT_MODULUS_1
  mod scratch4 scratch4 REAGENT_MODULUS_2
  add scratch4 scratch4 SP_INGOTS_TABLE
  get scratch4 db scratch4

  s db:0 Mod_LowIngotHash scratch4
  s db:0 Mod_LowIngotAmount scratch2

  sgt scratch scratch2 REAGENT_BAD_QTY
  sgt scratch2 scratch2 REAGENT_OK_QTY
  select scratch scratch Color.Yellow Color.Orange
  select scratch scratch2 Color.Green scratch
  sb NeedsAttentionLight Color scratch
  sb NeedsAttentionLight On 1

  select scratch job_quantity auto_mode 0
  s printer_refid Lock scratch

  ; Handle button control.  Light up available buttons
  ; Read buttons where lit up OR man/auto in IDLE
  ; Button reads as pressed if light OFF (user interacted)

  or button_masks button_lights BUTTON_AUTO
  ins button_lights auto_mode BTN_AUTO_BIT_IDX 1
  get sp db SP_BUTTONS
  move button_codes 0
  button_loop:
  pop scratch2
  l scratch2 scratch2 On
  seqz scratch scratch2
  ins button_codes scratch sp 1
  ext scratch button_lights sp 1
  s scratch2 On scratch
  bgt sp SP_BUTTONS_TABLE button_loop
  and button_codes button_codes button_masks
  move button_masks button_lights

  beqz job_quantity idle

active_job:
  l scratch printer_refid ExportCount                                  ; Start by showing the current print progress
  l scratch2 printer_refid CompletionRatio
  add scratch scratch scratch2
  div scratch scratch job_quantity
  sb LEDDisplay2 Setting scratch
  sb LEDDisplay2 On 1

  ; Check if printer has idled.  If so, check the export count if we succeeded.  Then unlock the printer.
  l scratch printer_refid ExportCount
  bge scratch job_quantity job_complete

  j loop

job_complete:
  move stacker_delay 2
  move color_delay 12
  yield
  yield
  l r0 printer_refid ExportCount
  seq r0 r0 job_quantity
  move job_quantity 0
  select r0 r0 Color.Green Color.Red

  sb QuantityKeypad Color r0
  sb LogicMemory Setting 0

  j loop

idle:
  move button_lights BUTTON_STARTS
  ext auto_mode button_codes BTN_AUTO_BIT_IDX 1
  s db:0 Mod_AutomaticMode auto_mode
  clrd printer_refid

  blez stacker_delay no_stacker_trig
  sub stacker_delay stacker_delay 1
  bgtz stacker_delay no_stacker_trig
  sb Stacker Activate 1
no_stacker_trig:

  blez color_delay no_color_trig
  sub color_delay color_delay 1
  bgtz color_delay no_color_trig
  sb QuantityKeypad Color Color.White
  sb LEDDisplay2 On 0
no_color_trig:

check_manual_start:
  ext job_quantity button_codes BTN_ONE_BIT_IDX 1
  ext scratch button_codes BTN_RUN_BIT_IDX 1
  lb scratch2 QuantityKeypad Setting Sum
  select job_quantity scratch scratch2 job_quantity
  beqz job_quantity loop
  l r0 printer_refid RecipeHash
  j start_job

check_auto_start:
  l job_quantity db:0 Mod_ReqItemCount                            ; Check for a quantity command from the master
  beqz job_quantity loop                                          ; 0? No job - Otherwise we store the job quantity and start to dispatch a job
  bnan job_quantity loop                                          ; NaN check just to be sure
  s db:0 Mod_ReqItemCount 0                                       ; Zero out quantity command after reading it
  l r0 db:0 Mod_ReqItemHash                                       ; Load recipe hash from Channel6

start_job:
  s printer_refid ClearMemory 1                                   ; Reset printer export counts before starting job
  sb LogicMemory Setting r0
  ins r0 r0 16 32                                                 ; Hash to correct bitfield
  ins r0 PrinterInstruction.ExecuteRecipe 0 8                     ; Load instruction
  ins r0 job_quantity 8 8                                         ; Insert quantity field
  put printer_refid 0 r0                                          ; Dispatch instruction to printer

  sb QuantityKeypad Color Color.Yellow
  sb ProgressBar Color Color.Yellow
  j loop

