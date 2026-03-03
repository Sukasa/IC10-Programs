section definitions

  define  OreVender         $?                      # Ore/Ice stacker + vending machine
  define  IngotVender       $?                      # Ingot vending machine
  define  ArcFurnace        $?                      # Arc Furnace for converting ingots
  define  Centrifuge        $?                      # Centrifuge for degassing coal
  define  AlloyFurnace      $?                      # Advanced Furnace, for alloying
  define  IceDiverter       $?                      # Digital flip/flop to divert ice to crusher
  define  CoalDiverter      $?                      # Digital flip/flop to divert coal to degassing
  define  AlloyDiverter     $?                      # Digital flip/flop to divert ingots to alloying
  
  
  define  OreBucketSize     41                      # Size of bucketing range (modulus amount) for ores/ices
  define  IngotBucketSize   20                      # Size of bucketing range (moulus amount) for degassed ingots / coal
  
  define  LogicMemory                   Hash("StructureLogicMemory")
  define  FoundryConnector              Hash("Foundry Data Link")

section intake requires definitions

  define  IngotBucketStart  0                       # "Buckets" for storing quantities of ingots
  define  OreBucketStart    20                      # "Buckets" for storing quantities of ore

  alias   slotIdx           r0
  alias   itemInfo          r1
  alias   bucketIdx         r2
  alias   stackPtr          r3
  alias   lastOreCount      r4                      # Last ore vender import/export count
  alias   lastIngotCount    r5                      # Last ingot vendor import/export count
  
  alias   ImportCountOres   r9
  alias   ImportCountIngots r10
  alias   canVendOres       r11
  alias   canVendIngots     r12
  alias   canVendFlags      r13                     # Flags for if an item can be vended (cleared on vend, set on target not empty)
  alias   Scratch2          r14
  alias   Scratch1          r15

  define  FLAG_IDX_COAL    0
  define  FLAG_IDX_ICE     1
  define  FLAG_IDX_ORE     2

  # Intake controller.  Receives everything from the unloader, shuttles ices to the crusher (when it's empty), and sends off ores for degassing if there's room in the destination vending machine
main:
  jal func_scan_ores

  yield
  j main
  
  
func_scan_ores:
  move canVendOres 0                              # Clear "can vend" bit array
  move slotIdx 1                                  # Indexes 0/1 are the import/export slots.  We start from index 2 and run through index 101
scan_loop:
  add slotIdx slotIdx 1
  bgt slotIdx 101 ra
  ls itemInfo OreVender slotIdx PrefabHash
  beqz itemInfo scan_loop
  mod bucketIdx itemInfo OreBucketSize
  add stackPtr bucketIdx OreBucketStart
  ls itemInfo OreVender slotIdx Quantity
  get Scratch1 db stackPtr
  add Scratch1 Scratch1 itemInfo
  poke stackPtr Scratch1
  sge Scratch1 Scratch1 500
  ins canVendOres bucketIdx 1 Scratch1
  j scan_loop

func_scan_ingots:
  move canVendIngots 0                            # Clear "can vend" bit array
  move slotIdx 1                                  # Indexes 0/1 are the import/export slots.  We start from index 2 and run through index 101
ingot_loop:
  add slotIdx slotIdx 1
  bgt slotIdx 101 ra
  ls itemInfo IngotVender slotIdx PrefabHash
  beqz itemInfo ingot_loop
  mod bucketIdx itemInfo IngotBucketSize
  ls itemInfo IngotVender slotIdx Quantity
  get Scratch1 db bucketIdx
  add Scratch1 Scratch1 itemInfo
  poke bucketIdx Scratch1
  sge Scratch1 Scratch1 500
  ins canVendIngots bucketIdx 1 Scratch1
  j ingot_loop

func_send_ice:                                    # Check if we can send any ice (we have >500 of any stack).  If we can, and the bit is set, and the slot is empty, vend
  ls Scratch1 Crusher 0 Occupied
  ext Scratch2 canVendFlags 1 1

func_send_ore:
  
