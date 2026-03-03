section definitions
  define  PressureRegulator         Hash("StructurePressureRegulator")
  define  VolumePump                Hash("StructureVolumePump")
  define  ActiveVent                Hash("StructureActiveVent")
  define  Combustor                 Hash("H2Combustor")
  define  Tank                      Hash("StructureTankSmallInsulated")
  define  GasAnalyzer               Hash("StructurePipeAnalysizer")
  define  PipeHeater                Hash("StructurePipeHeater")

  define  FlipCoverSwitch           Hash("ModularDeviceFlipCoverSwitch")
  define  FlipSwitch                Hash("ModularDeviceFlipSwitch")
  define  Gauge                     Hash("ModularDeviceGauge2x2")
  define  Dial                      Hash("ModularDeviceDialSmall")
  define  LEDDisplay2               Hash("ModularDeviceLEDdisplay2")
  define  LabelDiode2               Hash("ModularDeviceLabelDiode2")

  define  GasProdUnitVent           Hash("Gas Production Unit Vent")
  define  FuelRegulator             Hash("Fuel Regulator")
  define  FuelPump                  Hash("Fuel Pump")
  define  AirPump                   Hash("Cold Air Compressor Pump")
  define  ColdTank                  Hash("Cold Gas Tank")
  define  HotTank                   Hash("Hot Gas Tank")
  define  HGPres                    Hash("Hot Gas Pressure")
  define  HGPresSP                  Hash("Hot Gas Pressure SP")
  define  HGTemp                    Hash("Hot Gas Temperature")
  define  CGPres                    Hash("Cold Gas Pressure")
  define  CGPresSP                  Hash("Cold Gas Pressure SP")
  define  CGTemp                    Hash("Cold Gas Temperature")
  define  CGEnab                    Hash("Cold Gas Compression Enable")
  define  HGEnab                    Hash("Hot Gas Production Enable")
  define  Production                Hash("PRODUCTION")
  define  Compression               Hash("COMPRESSION")
  define  Heat                      Hash("HEAT")
  define  FuelRegEnable             Hash("Fuel Regulator Enable")
  define  VentEnable                Hash("Production Unit Ventilation")
  define  FuelReg                   Hash("Fuel Regulation")
  define  FPres                     Hash("Fuel Pressure")
  define  FuelRegSP                 Hash("Fuel Regulation SP")
  define  FuelLine                  Hash("Fuel Line")
  define  HGTempSP                  Hash("Hot Gas Temperature SP")
  define  RHEnab                    Hash("Gas Reheat Enable")

  alias   Scratch                   r0
  alias   Scratch2                  r1
  alias   Scratch3                  r2
  alias   Scratch4                  r3

  define  SP_COLD_PRES              20
  define  SP_COLD_TEMP              40
  define  SP_HOT_PRES               60
  define  SP_HOT_TEMP               80
  define  SP_FUEL_PRES              100

section initializer requires definitions

  ; Cold gas pressure
  poke Calc(SP_COLD_PRES-1) 2000
  poke Calc(SP_COLD_PRES-2) 0.75
  poke Calc(SP_COLD_PRES-3) Color.Red
  poke Calc(SP_COLD_PRES-4) 0.55
  poke Calc(SP_COLD_PRES-5) Color.Orange
  poke Calc(SP_COLD_PRES-6) 0.45
  poke Calc(SP_COLD_PRES-7) Color.Green
  poke Calc(SP_COLD_PRES-8) 0.25
  poke Calc(SP_COLD_PRES-9) Color.Orange
  poke Calc(SP_COLD_PRES-10) 0
  poke Calc(SP_COLD_PRES-11) Color.Red

  ; Cold Gas Temperature
  poke Calc(SP_COLD_TEMP-1) 500
  poke Calc(SP_COLD_TEMP-2) Calc(423.15/500)
  poke Calc(SP_COLD_TEMP-3) Color.Red
  poke Calc(SP_COLD_TEMP-4) Calc(373.15/500)
  poke Calc(SP_COLD_TEMP-5) Color.Yellow
  poke Calc(SP_COLD_TEMP-6) Calc(273.15/500)
  poke Calc(SP_COLD_TEMP-7) Color.Green
  poke Calc(SP_COLD_TEMP-8) Calc(253.15/500)
  poke Calc(SP_COLD_TEMP-9) Color.Yellow
  poke Calc(SP_COLD_TEMP-10) 0
  poke Calc(SP_COLD_TEMP-11) Color.Blue

  ; Hot gas pressure
  poke Calc(SP_HOT_PRES-1) 2000
  poke Calc(SP_HOT_PRES-2) 0.75
  poke Calc(SP_HOT_PRES-3) Color.Red
  poke Calc(SP_HOT_PRES-4) 0.55
  poke Calc(SP_HOT_PRES-5) Color.Orange
  poke Calc(SP_HOT_PRES-6) 0.45
  poke Calc(SP_HOT_PRES-7) Color.Green
  poke Calc(SP_HOT_PRES-8) 0.25
  poke Calc(SP_HOT_PRES-9) Color.Orange
  poke Calc(SP_HOT_PRES-10) 0
  poke Calc(SP_HOT_PRES-11) Color.Red

  ; Hot Gas Temperature
  poke Calc(SP_HOT_TEMP-1) 3100
  poke Calc(SP_HOT_TEMP-2) Calc(2900/3100)
  poke Calc(SP_HOT_TEMP-3) Color.Red
  poke Calc(SP_HOT_TEMP-4) Calc(2700/3100)
  poke Calc(SP_HOT_TEMP-5) Color.Yellow
  poke Calc(SP_HOT_TEMP-6) Calc(2500/3100)
  poke Calc(SP_HOT_TEMP-7) Color.Green
  poke Calc(SP_HOT_TEMP-8) Calc(2300/3100)
  poke Calc(SP_HOT_TEMP-9) Color.Yellow
  poke Calc(SP_HOT_TEMP-10) 0
  poke Calc(SP_HOT_TEMP-11) Color.Blue

  ; Fuel pressure
  poke Calc(SP_FUEL_PRES-1) 2000
  poke Calc(SP_FUEL_PRES-2) 0.75
  poke Calc(SP_FUEL_PRES-3) Color.Red
  poke Calc(SP_FUEL_PRES-4) 0.55
  poke Calc(SP_FUEL_PRES-5) Color.Orange
  poke Calc(SP_FUEL_PRES-6) 0.45
  poke Calc(SP_FUEL_PRES-7) Color.Green
  poke Calc(SP_FUEL_PRES-8) 0.25
  poke Calc(SP_FUEL_PRES-9) Color.Orange
  poke Calc(SP_FUEL_PRES-10) 0
  poke Calc(SP_FUEL_PRES-11) Color.Red

section application requires definitions

  sb Combustor On 1
loop:
  yield

  ; Ventilation from production unit
  lbn Scratch FlipCoverSwitch VentEnable Setting Sum
  sbn ActiveVent GasProdUnitVent On Scratch

  ; Fuel supply to production staging tank
  lbn Scratch FlipCoverSwitch FuelRegEnable Setting Sum
  sbn PressureRegulator FuelRegulator On Scratch

  ; Fuel regulation control
  lbn Scratch Dial FuelRegSP Setting Sum
  mul Scratch Scratch 1000
  sbn PressureRegulator FuelRegulator Setting Scratch
  mul Scratch2 Scratch 2
  poke Calc(SP_FUEL_PRES-1) Scratch2
  mul Scratch Scratch 1000
  sbn LEDDisplay2 FuelRegSP Setting Scratch

  ; Hot Gas Reheat
  lbn Scratch Dial HGTempSP Setting Sum
  mul Scratch Scratch 10
  sbn LEDDisplay2 HGTempSP Setting Scratch
  add Scratch 273.15 Scratch
  lbn Scratch2 Tank HotTank Temperature Sum
  slt Scratch2 Scratch2 Scratch
  lbn Scratch FlipSwitch RHEnab Setting Sum
  and Scratch Scratch Scratch2
  sb PipeHeater On Scratch
  sbn LabelDiode2 Heat On Scratch
  select Scratch Scratch Color.Red Color.Black
  sbn LabelDiode2 Heat Color Scratch

  ; Hot Gas Production
  lbn Scratch Dial HGPresSP Setting Sum
  mul Scratch Scratch 1000
  mul Scratch2 Scratch 2
  poke Calc(SP_HOT_PRES-1) Scratch2
  mul Scratch2 Scratch 1000
  sbn LEDDisplay2 HGPresSP Setting Scratch2
  lbn Scratch2 Tank HotTank Pressure Sum
  slt Scratch2 Scratch2 Scratch
  lbn Scratch FlipSwitch HGEnab Setting Sum
  and Scratch2 Scratch Scratch2
  sbn VolumePump FuelPump On Scratch2
  sb Combustor Mode Scratch2
  sbn LabelDiode2 Production On Scratch2
  select Scratch2 Scratch2 Color.Yellow Color.Black
  sbn LabelDiode2 Production Color Scratch2

  ; Cold Gas Production
  lbn Scratch Dial CGPresSP Setting Sum
  mul Scratch Scratch 1000
  mul Scratch2 Scratch 2
  poke Calc(SP_COLD_PRES-1) Scratch2
  mul Scratch2 Scratch 1000
  sbn LEDDisplay2 CGPresSP Setting Scratch2
  lbn Scratch2 Tank ColdTank Pressure Sum
  slt Scratch2 Scratch2 Scratch
  lbn Scratch FlipSwitch CGEnab Setting Sum
  and Scratch2 Scratch Scratch2
  sbn VolumePump AirPump On Scratch2
  sbn LabelDiode2 Compression On Scratch2
  select Scratch2 Scratch2 Color.Green Color.Black
  sbn LabelDiode2 Compression Color Scratch2

  lbn Scratch Tank ColdTank Pressure Sum
  move Scratch2 CGPres
  move sp SP_COLD_PRES
  jal gauge

  lbn Scratch Tank ColdTank Temperature Sum
  move Scratch2 CGTemp
  move sp SP_COLD_TEMP
  jal gauge

  lbn Scratch Tank HotTank Pressure Sum
  move Scratch2 HGPres
  move sp SP_HOT_PRES
  jal gauge

  lbn Scratch Tank HotTank Temperature Sum
  move Scratch2 HGTemp
  move sp SP_HOT_TEMP
  jal gauge

  lbn Scratch GasAnalyzer FuelLine Pressure Sum
  move Scratch2 FPres
  move sp SP_FUEL_PRES
  jal gauge

  j loop


gauge:
  snanz Scratch3 Scratch
  select Scratch Scratch3 Scratch 0
  pop Scratch3
  div Scratch Scratch Scratch3
  sbn Gauge Scratch2 Setting Scratch
gauge_col:
  pop Scratch3
  pop Scratch4
  blt Scratch Scratch3 gauge_col
  sbn Gauge Scratch2 Color Scratch4
  j ra
