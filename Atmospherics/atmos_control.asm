# Atmospherics control code

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

  define  Heater1         $766A0
  define  Heater2         $766A4
  define  Heater3         $77F33
  
  alias   Scratch1        r0
  alias   Scratch2        r1
  alias   Scratch3        r2
  alias   BAFeedRate      r14
  alias   FiltersEnab     r15
  
  define  MAX_TANK_PRES   45000                   # 45MPa in kPa - Maximum pure (or waste) gas tank pressure
  define  CO2_TANK_TARG   20000
  define  CO2_TANK_STOP   21000
  define  MAX_MIX_PRES    10000                   # 10MPa in kPa - Maximum premix tank pressure
  define  MIN_TANK_PRES   5000                    # 5MPa in kPa  - Minimum pure gas tank pressure to enable mixers

  define  SCAV_WASTE_MAX  15000

  define  FILTSTARTPRES   15000
  define  FILTSTOPPRES    5000
  
  define  BA_PRES_SP      2100

loop:
  l Scratch1 N2Tank Pressure                      # Dump N2 tank contents if the pressure gets too high
  sge Scratch1 Scratch1 MAX_TANK_PRES
  s N2Dump On Scratch1
  
  l Scratch1 O2Tank Pressure                      # Dump O2 tank contents if the pressure gets too high
  sge Scratch1 Scratch1 MAX_TANK_PRES
  s O2Dump On Scratch1
  
  l Scratch1 VlTank Pressure                      # Dump Volatiles tank contents if the pressure gets too high
  sge Scratch1 Scratch1 MAX_TANK_PRES
  s VlDump On Scratch1
  
  l Scratch1 WasteTank Pressure                   # Dump waste tank contents if the pressure gets too high
  sge Scratch2 Scratch1 MAX_TANK_PRES
  s WasteDump On Scratch2
  
  sge Scratch2 Scratch1 FILTSTARTPRES
  or FiltersEnab FiltersEnab Scratch2
  sge Scratch2 Scratch1 FILTSTOPPRES
  and FiltersEnab FiltersEnab Scratch2
   
  l Scratch1 VlTank Pressure                      # Run fuel gas mixer if gas is available, to pressurize fuel gas system
  sgt Scratch2 Scratch1 MIN_TANK_PRES
  l Scratch1 O2Tank Pressure
  sgt Scratch1 Scratch1 MIN_TANK_PRES
  and Scratch2 Scratch1 Scratch2
  l Scratch1 FGTank Pressure
  sle Scratch1 Scratch1 MAX_MIX_PRES
  and Scratch2 Scratch1 Scratch2
  s FGMixer On Scratch2
  
  l Scratch1 N2Tank Pressure                      # Run breathing air mixer if gas is available, to pressurize base supply air
  sgt Scratch2 Scratch1 MIN_TANK_PRES
  l Scratch1 O2Tank Pressure
  sgt Scratch1 Scratch1 MIN_TANK_PRES
  and Scratch2 Scratch1 Scratch2
  l Scratch1 BATank Pressure
  sle Scratch1 Scratch1 MAX_MIX_PRES
  and Scratch2 Scratch1 Scratch2
  s BAMixer On Scratch2
  
  l Scratch1 CO2Outlet Pressure                   # Run CO2 filtration based on tank pressure
  l Scratch3 CO2Filter On
  sle Scratch2 Scratch1 CO2_TANK_TARG
  or Scratch3 Scratch3 Scratch2
  sle Scratch2 Scratch1 CO2_TANK_STOP
  and Scratch3 Scratch3 Scratch2
  and Scratch3 Scratch3 FiltersEnab
  s CO2Filter On Scratch3
  seqz Scratch3 Scratch3
  and Scratch3 Scratch3 FiltersEnab
  s CO2Bypass On Scratch3

  l Scratch1 HeatPump TemperatureInput            # HTF line temperature control
  l Scratch3 HeatPump Mode                        # Run heat pump to cool HTF line
  sgt Scratch2 Scratch1 303.15
  or Scratch3 Scratch2 Scratch3
  sgt Scratch2 Scratch1 298.15
  and Scratch3 Scratch2 Scratch3
  s HeatPump Mode Scratch3

  l Scratch1 HeatPump TemperatureOutput2          # HTF line temperature control
  l Scratch3 ExtHeater On  
  sle Scratch2 Scratch1 273.15
  or Scratch3 Scratch2 Scratch3
  sle Scratch2 Scratch1 283.15
  and Scratch3 Scratch2 Scratch3
  s ExtHeater On Scratch3
  
  
  l Scratch3 Heater1 On                           # Run heaters to heat HTF line without bursting the mars-side HTF lines
  slt Scratch2 Scratch1 288.15
  or Scratch3 Scratch2 Scratch3
  slt Scratch2 Scratch1 293.15
  and Scratch3 Scratch2 Scratch3
  s Heater1 On Scratch3
  
  l Scratch3 Heater2 On
  slt Scratch2 Scratch1 283.15
  or Scratch3 Scratch2 Scratch3
  slt Scratch2 Scratch1 293.15
  and Scratch3 Scratch2 Scratch3
  s Heater2 On Scratch3
  
  l Scratch3 Heater3 On
  slt Scratch2 Scratch1 278.15
  or Scratch3 Scratch2 Scratch3
  slt Scratch2 Scratch1 288.15
  and Scratch3 Scratch2 Scratch3
  s Heater3 On Scratch3
  
  l r0 BAOutPres Pressure
  l r1 BAPump Setting
  sub r0 r0 BA_PRES_SP
  div r0 r0 100
  sub r1 r1 r0
  s BAPump Setting r1
  s BAPump On 1
  
  l Scratch1 CO2Analyzer Pressure
  l Scratch3 Scavenger On
  slt Scratch2 Scratch1 CO2_TANK_TARG
  or Scratch3 Scratch2 Scratch3
  slt Scratch2 Scratch1 CO2_TANK_STOP
  and Scratch3 Scratch2 Scratch3
  l Scratch1 WasteTank Pressure
  slt Scratch2 Scratch1 SCAV_WASTE_MAX
  and Scratch3 Scratch2 Scratch3
  s Scavenger On Scratch3

  yield
  j loop
