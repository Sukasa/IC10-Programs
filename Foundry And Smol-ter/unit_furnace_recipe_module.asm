include unit_furnace_definitions.asm

section recipe_initializer requires definitions

macro recipe index NameStr ResultHash TempSP PresSP
  define  TABLE_OFFSET Calc(index*RECIPE_STRIDE+MSTR_SP_RECIPE_TABLE)
  poke TABLE_OFFSET NameStr
  poke Calc(TABLE_OFFSET+RECIPE_OFFSET_RESULT) ResultHash
  poke Calc(TABLE_OFFSET+RECIPE_OFFSET_TEMP_SP) TempSP
  poke Calc(TABLE_OFFSET+RECIPE_OFFSET_PRES_SP) PresSP
  poke Calc(TABLE_OFFSET+RECIPE_OFFSET_TERMINATOR) 0
endmacro

macro recipe_reagent index reagentIdx ReagentHash RatioQty
  define  TABLE_OFFSET Calc(index*RECIPE_STRIDE+MSTR_SP_RECIPE_TABLE)
  poke Calc(reagentIdx*RECIPE_STRIDE_REAGENT+TABLE_OFFSET+RECIPE_OFFSET_REAGENT1) ReagentHash
  poke Calc(reagentIdx*RECIPE_STRIDE_REAGENT+TABLE_OFFSET+RECIPE_OFFSET_QUANTITY1) RatioQty
endmacro

macro simple_recipe index
  define  TABLE_OFFSET Calc(index*RECIPE_STRIDE+MSTR_SP_RECIPE_TABLE)
  poke Calc(2*RECIPE_STRIDE_REAGENT+TABLE_OFFSET+RECIPE_OFFSET_REAGENT1) 0
endmacro

  move sp RCP_SP_REAGENT_TABLE
  push ReagentCoal
  push ReagentSilver
  push ReagentSilicon
  push ReagentNickel
  push ReagentLead
  push ReagentIron
  push ReagentGold
  push ReagentCopper
  push ReagentCobalt
  push ReagentSteel
  push ReagentSolder
  push ReagentInvar
  push ReagentElectrum
  push ReagentConstantan
  push ReagentWaspaloy
  push ReagentStellite
  push ReagentInconel
  push ReagentHastelloy
  push ReagentAstroloy

  recipe 0 Str("Steel") Hash("ItemSteelIngot") 1000 1100
  recipe_reagent 0 0 ReagentCoal 0.25
  recipe_reagent 0 1 ReagentIron 0.75
  simple_recipe 0

  recipe 1 Str("Solder") Hash("ItemSolderIngot") 425 1100
  recipe_reagent 1 0 ReagentLead 0.5
  recipe_reagent 1 1 ReagentIron 0.5
  simple_recipe 1

  recipe 2 Str("Invar") Hash("ItemInvarIngot") 1250 19000
  recipe_reagent 2 0 ReagentNickel 0.5
  recipe_reagent 2 1 ReagentIron 0.5
  simple_recipe 2

  recipe 3 Str("Elctrm") Hash("ItemElectrumIngot") 700 1200
  recipe_reagent 3 0 ReagentSilver 0.5
  recipe_reagent 3 1 ReagentGold 0.5
  simple_recipe 3

  recipe 4 Str("Cstntn") Hash("ItemConstantanIngot") 1100 21000
  recipe_reagent 4 0 ReagentNickel 0.5
  recipe_reagent 4 1 ReagentCopper 0.5
  simple_recipe 4

  recipe 5 Str("Wspaly") Hash("ItemWaspaloyIngot") 600 51000
  recipe_reagent 5 0 ReagentSilver 0.25
  recipe_reagent 5 1 ReagentNickel 0.25
  recipe_reagent 5 2 ReagentLead 0.5

  recipe 6 Str("Stllte") Hash("ItemStelliteIngot") 1850 11000
  recipe_reagent 6 0 ReagentSilver 0.25
  recipe_reagent 6 1 ReagentSilicon 0.5
  recipe_reagent 6 2 ReagentCobalt 0.25

  recipe 7 Str("Incnl") Hash("ItemInconelIngot") 700 23750
  recipe_reagent 7 0 ReagentNickel 0.25
  recipe_reagent 7 1 ReagentGold 0.5
  recipe_reagent 7 2 ReagentSteel 0.25

  recipe 8 Str("Hstlly") Hash("ItemHastelloyIngot") 1050 27500
  recipe_reagent 8 0 ReagentSilver 0.5
  recipe_reagent 8 1 ReagentNickel 0.25
  recipe_reagent 8 2 ReagentCobalt 0.25

  recipe 9 Str("Astrly") Hash("ItemAstroloyIngot") 1100 35000
  recipe_reagent 9 0 ReagentCopper 0.25
  recipe_reagent 9 1 ReagentCobalt 0.25
  recipe_reagent 9 2 ReagentSteel 0.5

section recipe_controller requires definitions

  ; TODO: If the reagents are scanned in a known order, then as long as the recipe uses that order we
  ; can simplify a lot of the search/check code

  alias   RecipeReagentsAddr        r11
  alias   ReagentHash               r10
  alias   ReagentQuantity           r9
  alias   MixArrayIndex             r8
  alias   ExpectedReagentCount      r7
  alias   RecipeArrayIndex          r6

  lbn MasterDevice ICHousingCompact MasterChip ReferenceId Sum
  lb FurnaceRefId AdvancedFurnace ReferenceId Sum

start_idle:
  put MasterDevice MSTR_SP_LOAD_STATE LOAD_INCOMPLETE

idle_loop: ; Wait for the chamber to leave the CHAMBER_IDLE state
  yield
  jal read_furnace_contents

  get CurrentMode MasterDevice MSTR_SP_CHAMBER_STATE
  beq CurrentMode CHAMBER_IDLE idle_loop

  ; Move into active mode: note current recipe reagent state
  get RecipeReagentsAddr MasterDevice MSTR_SP_CURRENT_RECIPE
  add ExpectedReagentCount RecipeReagentsAddr RECIPE_OFFSET_REAGENT3 ; Initialize to Reagent 3
  add RecipeReagentsAddr RecipeReagentsAddr RECIPE_OFFSET_REAGENT1 ; And update reagents addr for later

  get ExpectedReagentCount MasterDevice ExpectedReagentCount ; And check if there is a third reagent
  select ExpectedReagentCount ExpectedReagentCount RECIPE_OFFSET_TERMINATOR RECIPE_OFFSET_REAGENT3 ; Then select the appropriate offset for the end of the reagent list
  add ExpectedReagentCount ExpectedReagentCount RecipeReagentsAddr ; Add to base address and store for later
  ; Main continuous recipe-validation loop
active_loop:
  yield

  ; Check for process cancellation or abort
  get CurrentMode MasterDevice MSTR_SP_CHAMBER_STATE
  beq CurrentMode CHAMBER_IDLE start_idle ; These could be optimized into an `sna` call if I found the math again
  beq CurrentMode CHAMBER_ABORT start_idle
  beq CurrentMode CHAMBER_DUMP wait_inactive_loop ; If we're dumping, then we can stop monitoring the chamber reagents

  jal read_furnace_contents ; Read in the contents of the furnace

  jal check_valid_reagent ; Now validate the reagents are valid (i.e. match the recipe)

  ; We made it through the list of reagents, and passed the valid reagent check each time.
  ; Now set state based on load / balancing

  blt MixArrayIndex ExpectedReagentCount active_loop ; If not enough reagents, we're still LOAD_INCOMPLETE

  ; Get match ratio from recipe reagent 1
  move MixArrayIndex RecipeReagentsAddr
  get ReagentHash MasterDevice MixArrayIndex
  lr ReagentQuantity FurnaceRefId Contents ReagentHash
  jal get_reagent_ratio
  move Scratch3 Scratch

  ; Check the recipe ratio against reagent ingredient 2
  add MixArrayIndex RecipeReagentsAddr 2
  get ReagentHash MasterDevice MixArrayIndex
  lr ReagentQuantity FurnaceRefId Contents ReagentHash
  jal get_reagent_ratio
  bne Scratch Scratch3 ratio_mismatch

  ; Check the recipe ratio against reagent ingredient 3 (if there is one)
  add MixArrayIndex RecipeReagentsAddr 4
  get ReagentHash MasterDevice MixArrayIndex
  beqz ReagentHash ratio_good
  lr ReagentQuantity FurnaceRefId Contents ReagentHash
  jal get_reagent_ratio
  bne Scratch Scratch3 ratio_mismatch

ratio_good: ; Reagents are good and we have a balanced ratio
  put MasterDevice MSTR_SP_LOAD_STATE LOAD_BALANCED
  j active_loop

ratio_mismatch: ; Reagents are good, but the ratio is off (maybe we're still loading?)
  put MasterDevice MSTR_SP_LOAD_STATE LOAD_IMBALANCE
  j active_loop

monitor_reagent_loop_fail: ; Tell the master controller the recipe load is an unusable mix and to abort to IDLE.
  put MasterDevice MSTR_SP_LOAD_STATE LOAD_IMPROPER

wait_inactive_loop: ; Wait for the chamber to enter the CHAMBER_IDLE state (i.e. done dump)
  yield
  get CurrentMode MasterDevice MSTR_SP_CHAMBER_STATE
  bne CurrentMode CHAMBER_IDLE wait_inactive_loop
  j start_idle


  ; ******
  ; Validate the mix contents (not ratios)
  ; ******
check_valid_reagent: ; Returns if the reagent is valid; breaks out to fail state if not

  move MixArrayIndex MSTR_SP_MIX_TABLE
  add RecipeArrayIndex RecipeArrayIndex RECIPE_OFFSET_REAGENT1

check_next_reagent:
  get Scratch2 MasterDevice MixArrayIndex ; Check the next mix entry
  beqz Scratch2 ra ; If the mix ends early, we consider that a 'pass' (partial load)

  ; Validated we have a mix entry.  Now check that it's in the recipe.
  move RecipeArrayIndex RecipeReagentsAddr


  get Scratch db RecipeArrayIndex ; Get the recipe reagent that should be in this slot otherwise

  bne Scratch Scratch2 monitor_reagent_loop_fail ; If so, it's valid; do nothing and return

  add Scratch Scratch 2 ; Otherwise it MAY be valid, check the next index in the reagent table
  bnez Scratch2 check_next_reagent ; Repeat check loop as long as we didn't hit the null terminator in the recipe
  j monitor_reagent_loop_fail ; We failed to match, so this recipe is now IMPROPER

get_reagent_ratio: ; Get reagent ratio for ReagentHash, result in Scratch
  move Scratch RecipeReagentsAddr
find_reagent:
  get Scratch2 MasterDevice Scratch
  add Scratch Scratch 2
  bne Scratch2 ReagentHash find_reagent
  sub Scratch Scratch 1
  get Scratch2 MasterDevice Scratch
  div Scratch ReagentQuantity Scratch2
  j ra


  ; ******
  ; Read the contents of the furnace out into the "Mix Table" for display
  ; ******
read_furnace_contents:
  move sp RCP_SP_REAGENT_TABLE_END
  move MixArrayIndex MSTR_SP_MIX_TABLE

monitor_reagent_loop:
  ble sp RCP_SP_REAGENT_TABLE clear_table  ; If we reached the end of the reagent table, check contents next
  pop ReagentHash ; Otherwise we pop a reagent hash, and get the quantity
  lr ReagentQuantity FurnaceRefId Contents ReagentHash
  beqz ReagentQuantity monitor_reagent_loop ; If none of that in the furnace, continue the loop
  bge MixArrayIndex MSTR_SP_MIX_TABLE_END too_many_reagents ; Don't write past end of table

  put MasterDevice MixArrayIndex ReagentHash ; Store hash to mix table
  add MixArrayIndex MixArrayIndex 1
  put MasterDevice MixArrayIndex ReagentQuantity ; Store quantity to mix table
  add MixArrayIndex MixArrayIndex 1
  j monitor_reagent_loop  ; and continue looping through the reagents to check in the furnace

clear_table:
  move Scratch MixArrayIndex

clear_contents_loop:
  put MasterDevice Scratch 0 ; Clear complete mix table
  add Scratch Scratch 1
  blt Scratch MSTR_SP_MIX_TABLE_END clear_contents_loop

too_many_reagents:
  put MasterDevice MSTR_SP_LOAD_STATE LOAD_IMPROPER
  j ra
