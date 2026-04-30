; Foundry Controller
; Takes input for "requested" ingot from Manufactory, checks if this ingot is in stock and vends.  Otherwise, checks if ingot is craftable
; If craftable, and smol-ter is idle, initiates a cycle on the smol-ter.


section definitions
  
  define  LogicMemory         Hash("StructureLogicMemory")
  define  VendingMachine      Hash("StructureVendingMachine")
  define  FoundryConnector    Hash("Foundry Data Link")
  define  SmolterConnector    Hash("Smol-Ter Interface")

  define  INGOT_MODULUS_1     199424
  define  INGOT_MODULUS_2     21

  define  SP_INGOT_TABLE      0
  define  SP_STOCK_TABLE      20                      # "Buckets" for storing ingot count
  define  SP_STOCK_TABLE_END  Calc(SP_STOCK_TABLE + INGOT_MODULUS_2)                  # End of the table

  alias   Scratch                       r0
  alias   Scratch2                      r1
  alias   Scratch3                      r2

section foundry_controller requires definitions

  poke Calc(SP_INGOT_TABLE) Hash("ItemWaspaloyIngot")
  poke Calc(SP_INGOT_TABLE+1) Hash("ItemHastelloyIngot")
  poke Calc(SP_INGOT_TABLE+2) Hash("ItemInconelIngot")
  poke Calc(SP_INGOT_TABLE+3) Hash("ItemAstroloyIngot")
  poke Calc(SP_INGOT_TABLE+4) Hash("ItemStelliteIngot")
  poke Calc(SP_INGOT_TABLE+5) Hash("ItemInvarIngot")
  poke Calc(SP_INGOT_TABLE+6) Hash("ItemLeadIngot")
  poke Calc(SP_INGOT_TABLE+7) Hash("ItemNickelIngot")
  poke Calc(SP_INGOT_TABLE+8) Hash("ItemSilverIngot")
  poke Calc(SP_INGOT_TABLE+9) Hash("ItemConstantanIngot")
  poke Calc(SP_INGOT_TABLE+10) Hash("ItemElectrumIngot")
  poke Calc(SP_INGOT_TABLE+11) Hash("ItemSolderIngot")
  poke Calc(SP_INGOT_TABLE+12) Hash("ItemSiliconIngot")
  poke Calc(SP_INGOT_TABLE+13) Hash("ItemGoldIngot")
  poke Calc(SP_INGOT_TABLE+14) Hash("ItemSteelIngot")
  poke Calc(SP_INGOT_TABLE+15) Hash("ItemCopperIngot")
  poke Calc(SP_INGOT_TABLE+16) Hash("ItemIronIngot")
  poke Calc(SP_INGOT_TABLE+17) Hash("ItemCoalOre")
  poke Calc(SP_INGOT_TABLE+18) Hash("ItemCobaltOre")

loop: ; Main application loop

  ; Now check stock levels in the vending machine
  move sp SP_STOCK_TABLE

clear_loop:
  push 0
  blt sp SP_STOCK_TABLE_END clear_loop

  move Scratch 102

stock_sum_loop:
  sub Scratch Scratch 1
  lbs Scratch2 VendingMachine Scratch PrefabHash Sum
  breqz Scratch2 _skip_sum_loop
  mod Scratch2 Scratch2 INGOT_MODULUS_1
  mod Scratch2 Scratch2 INGOT_MODULUS_2
  add Scratch2 Scratch2 SP_STOCK_TABLE
  get Scratch3 db Scratch2
  add Scratch3 Scratch3 1
  poke Scratch2 Scratch3
_skip_sum_loop:
  bgt Scratch 2 stock_sum_loop

  ; Showing stock levels is handled by another IC, so move on to checking if we need to provide an ingot

  lbn Scratch LogicMemory FoundryConnector Setting Sum
  beqz Scratch no_request

  ; Set Scratch2 = quantity available of requested ingot
  mod Scratch2 Scratch INGOT_MODULUS_1
  mod Scratch2 Scratch2 INGOT_MODULUS_2
  add Scratch2 Scratch2 SP_STOCK_TABLE
  get Scratch2 db Scratch2





  no_request:

  yield
  j loop

section stock_indicators requires definitions



stock_loop:
  move Scratch -1
  lb Scratch2 LEDDisplay3 PrefabHash Sum

_prefab_search_loop:
  add Scratch Scratch 1
  get devRefId db:0 Scratch
  l Scratch3 devRefId PrefabHash
  bne Scratch3 findPrefab _prefab_search_loop




  sub Scratch2 Scratch2 findPrefab
  bnez Scratch2 _prefab_search_loop
  j stock_loop
