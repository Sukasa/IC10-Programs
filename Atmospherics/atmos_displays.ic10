section definitions
  define  O2Cooler        433306
  define  BACooler        433260
  define  N2Cooler        433268
  define  VlCooler        $69D4E
  define  CO2Outlet       $A020E
  define  BAMixer         $673CA
  define  FGMixer         $66E91
  define  CO2Filter       $657EC
  define  CO2Bypass       $677DC
  define  VlFilter        $657F5
  define  O2Filter        $657FC
  define  N2Filter        $6580A
  define  HeatPump        $6E9E3
  define  Crusher         $72C32
  define  DrainPort       $6AE1E
  define  DrainPump       $70F89
  define  IntakePump      $6D310
  define  Scavenger       $B4C98
  define  ExtHeater       $76F6A
  define  IntHeater1      $766A0
  define  IntHeater2      $766A4
  define  N2Tank          $5BC99
  define  O2Tank          $5BCAA
  define  VlTank          $5BCBD
  define  FGTank          $62542
  define  BATank          $5BA91
  define  BAPump          $6D3AC
  define  BAOutPres       $81FE5
  define  CO2Analyzer     $A020E
  define  WasteTank       $6E004
  define  Heatsink        $7E6DD
  define  O2Dump          $C2228
  define  N2Dump          $C2A3d
  define  VlDump          $C2235
  define  C2Dump          $C2241
  define  WasteDump       $C222E

  define  uio2pres        $BF7CD
  define  uio2temp        $BF7DC
  define  uio2filt1       $BF80D
  define  uio2filt2       $BF80B
  define  uio2dump        $C03B3

  define  uin2pres        $BF7D2
  define  uin2temp        $BF7D8
  define  uin2filt1       $BF815
  define  uin2filt2       $BF818
  define  uin2dump        $C03B9

  define  uivlpres        $BF7C8
  define  uivltemp        $BF7BA
  define  uivlfilt1       $BF7FA
  define  uivlfilt2       $BF7F6
  define  uivldump        $C03AF

  define  uico2pres       $BF7C3
  define  uico2temp       $BF7BF
  define  uico2filt1      $BF7FF
  define  uico2filt2      $BF803
  define  uico2bypass     $C0424
  define  uico2dump       $C03AA

  define  uiwgpres        $BF6A8
  define  uiwgintake      $BF82F
  define  uiwgscavenge    $C041D
  define  uiwgdump        $C03A3
  define  uiwgutil        $BF838

  define  uiport          $BF850
  define  uiice           $BF84B

  define  uibamixer       $BF730
  define  uibapres        $BF713
  define  uibatemp        $BF70F
  define  uibapump        $BF728
  define  uibaspress      $BF709
  
  define  uifgmixer       $BF736
  define  uifgpres        $BF702
  define  uifgtemp        $BF6FB

  define  Blue            0                       # Colours
  define  Gray            1
  define  Green           2
  define  Orange          3
  define  Red             4
  define  Yellow          5
  define  Black           7
  define  Pink            10
  define  Purple          11
  
  define  Pressure        5
  define  Temperature     6
  
  define  PURE_PRES_ZERO  0
  define  PURE_PRES_SPAN  60000
  define  PURE_PRES_LO    5000  
  define  PURE_PRES_HI    48000
  
  define  MIX_PRES_ZERO   0
  define  MIX_PRES_SPAN   20000
  define  MIX_PRES_LO     6500
  define  MIX_PRES_HI     16000
  
  define  BA_PRES_ZERO   0
  define  BA_PRES_SPAN   2000
  define  BA_PRES_LO     500
  define  BA_PRES_HI     1500
  
  define  TANK_TEMP_ZERO  273.15
  define  TANK_TEMP_SPAN  50
  
  define  TANK_TEMP_LO    18
  define  TANK_TEMP_HI    30

  define  table_size      188

section provisioning requires definitions
  move sp 0
  push table_size
  push app_start
  
  # Waste Tank
  push uiwgintake
  push IntakePump
  push func_indicate_on
  
  push uiwgscavenge
  push Scavenger
  push func_indicate_on
  
  push uiwgdump
  push WasteDump
  push func_indicate_on
  
  push PURE_PRES_SPAN
  push uiwgpres
  push PURE_PRES_HI
  push PURE_PRES_LO
  push PURE_PRES_ZERO
  push Pressure
  push WasteTank
  push func_meter
  
  # Waste Utilities
  push uiwgutil
  push DrainPump
  push func_indicate_on
  
  push uiport
  push DrainPort
  push func_occupied
  
  push uiice
  push Crusher
  push func_occupied
  
  # Filtration
  
  # CO2
  push uico2bypass
  push CO2Bypass
  push func_indicate_on
  
  push uico2dump
  push C2Dump
  push func_indicate_on
  
  push PURE_PRES_SPAN
  push uico2pres
  push PURE_PRES_HI
  push PURE_PRES_LO
  push PURE_PRES_ZERO
  push Pressure
  push CO2Analyzer
  push func_meter
  
  push TANK_TEMP_SPAN
  push uico2temp
  push TANK_TEMP_HI
  push TANK_TEMP_LO
  push TANK_TEMP_ZERO
  push Temperature
  push CO2Analyzer
  push func_meter
  
  push uico2filt1
  push 0 
  push CO2Filter
  push func_filter
  
  push uico2filt2
  push 1 
  push CO2Filter
  push func_filter
  
  # O2
  push uio2dump
  push O2Dump
  push func_indicate_on
  
  push PURE_PRES_SPAN
  push uio2pres
  push PURE_PRES_HI
  push PURE_PRES_LO
  push PURE_PRES_ZERO
  push Pressure
  push O2Tank
  push func_meter
  
  push TANK_TEMP_SPAN
  push uio2temp
  push TANK_TEMP_HI
  push TANK_TEMP_LO
  push TANK_TEMP_ZERO
  push Temperature
  push O2Tank
  push func_meter
  
  push uio2filt1
  push 0 
  push O2Filter
  push func_filter
  
  push uio2filt2
  push 1 
  push O2Filter
  push func_filter
  
  # N2
  push uin2dump
  push N2Dump
  push func_indicate_on
  
  push PURE_PRES_SPAN
  push uin2pres
  push PURE_PRES_HI
  push PURE_PRES_LO
  push PURE_PRES_ZERO
  push Pressure
  push N2Tank
  push func_meter
  
  push TANK_TEMP_SPAN
  push uin2temp
  push TANK_TEMP_HI
  push TANK_TEMP_LO
  push TANK_TEMP_ZERO
  push Temperature
  push N2Tank
  push func_meter
  
  push uin2filt1
  push 0 
  push N2Filter
  push func_filter
  
  push uin2filt2
  push 1 
  push N2Filter
  push func_filter

section provisioning2 requires definitions
  
  # Volatiles
  push uivldump
  push VlDump
  push func_indicate_on
  
  push PURE_PRES_SPAN
  push uivlpres
  push PURE_PRES_HI
  push PURE_PRES_LO
  push PURE_PRES_ZERO
  push Pressure
  push VlTank
  push func_meter
  
  push TANK_TEMP_SPAN
  push uivltemp
  push TANK_TEMP_HI
  push TANK_TEMP_LO
  push TANK_TEMP_ZERO
  push Temperature
  push VlTank
  push func_meter
  
  push uivlfilt1
  push 0 
  push VlFilter
  push func_filter
  
  push uivlfilt2
  push 1 
  push VlFilter
  push func_filter
  
  # Breathing Air
  push uibamixer
  push BAMixer
  push func_indicate_on
  
  push uibapump
  push BAPump
  push func_indicate_on
  
  push MIX_PRES_SPAN
  push uibapres
  push MIX_PRES_HI
  push MIX_PRES_LO
  push MIX_PRES_ZERO
  push Pressure
  push BATank
  push func_meter
  
  push TANK_TEMP_SPAN
  push uibatemp
  push TANK_TEMP_HI
  push TANK_TEMP_LO
  push TANK_TEMP_ZERO
  push Temperature
  push BATank
  push func_meter
  
  push BA_PRES_SPAN
  push uibaspress
  push BA_PRES_HI
  push BA_PRES_LO
  push BA_PRES_ZERO
  push Pressure
  push BAOutPres
  push func_meter
  
  # Fuel Gas
  push uifgmixer
  push FGMixer
  push func_indicate_on
  
  push MIX_PRES_SPAN
  push uifgpres
  push MIX_PRES_HI
  push MIX_PRES_LO
  push MIX_PRES_ZERO
  push Pressure
  push FGTank
  push func_meter
  
  push TANK_TEMP_SPAN
  push uifgtemp
  push TANK_TEMP_HI
  push TANK_TEMP_LO
  push TANK_TEMP_ZERO
  push Temperature
  push FGTank
  push func_meter

section application requires definitions

app_start:
  yield
  get sp db 0
  
next_ins:
  pop r0
  j r0
  
func_indicate_on:                                 # func_indicate_on(RefId Machine, RefId Indicator)
  pop r0
  pop r1
  l r0 r0 On
  s r1 On r0
  j next_ins
  
func_indicate_color:                              # func_indicate_color(RefId Machine, RefId Indicator)
  pop r0
  pop r1
  l r0 r0 On
  select r0 r0 Green Red
  s r1 Color r0
  j next_ins

func_meter:                                       # func_meter(RefId Tank, LogicType Property, float Zero, float LowSP, float HighSP, RefId Meter, float MeterSpan)
  pop r0
  pop r1
  l r0 r0 r1
  pop r1
  sub r0 r0 r1
  pop r1
  sle r1 r0 r1
  select r2 r1 Yellow Green
  pop r1
  sle r1 r0 r1
  select r1 r1 r2 Red
  pop r2
  s r2 Color r1
  pop r1
  div r0 r0 r1
  s r2 Setting r0
  j next_ins
  
func_filter:                                      # func_filter(RefId Filtration, int Slot, RefId Meter)
  pop r0
  pop r1
  ls r0 r0 r1 Quantity
  div r0 r0 100
  pop r1
  s r1 Setting r0
  j next_ins
  
func_occupied:                                    # func_occupied(RefId Storage, RefId Indicator)
  pop r0
  ls r0 r0 0 Occupied
  pop r1
  s r1 On r0
  j next_ins
  
func_switch:                                      # func_switch(RefId Switch)
  peek r0
  l r0 r0 Setting
  select r1 r0 Green Red
  pop r0
  s r0 Color r1
  j next_ins
  
func_spdial:                                      # func_spdial(RefId Dial, RefId Display, int DisplayMode)
  pop r0
  l r1 r0 Setting
  s r0 Setting 5
  sub r1 r1 5
  pop r0
  l r2 r0 Setting
  add r2 r1 r2
  s r0 Setting r2
  pop r1
  s r0 Mode r1
  j next_ins
  
func_xfer:                                        # func_xfer(RefId from, LogicType Type, RefId To)
  pop r0
  pop r1
  l r2 r0 r1
  pop r0
  s r0 r1 r2
  j next_ins

func_xfer2:                                        # func_xfer(RefId from, LogicType FromType, RefId To, Logictype ToType)
  pop r0
  pop r1
  l r2 r0 r1
  pop r0
  pop r1
  s r0 r1 r2
  j next_ins

func_lcd:                                           # func_lcd(RefId From, LogicType FromType, RefId LCD, int Mode)
  pop r0
  pop r1
  l r2 r0 r1
  pop r0
  pop r1
  s r0 Mode r1
  s r0 Setting r2
  j next_ins