include unit_furnace_definitions.asm

section ui_module requires definitions
  alias  BatteryMax                r5
  lbn MasterDevice ICHousingCompact MasterChip ReferenceId Sum

ui_loop:
  yield

  ; Update power information
  lbn Scratch CableAnalyzer EquipSourcePower PowerPotential Sum

  ; Display internal/external power indication
  lbn Scratch2 CableAnalyzer EquipSourcePower PowerRequired Sum
  sge Scratch2 Scratch Scratch2
  select Scratch2 Scratch2 STR("EXT") STR("INT")
  sbn LEDDisplay2 PowerSource Setting Scratch2
  sbn LEDDisplay2 PowerSource Mode CONSOLE_TEXT

  ; Now run battery level estimation
  lbn Scratch2 CableAnalyzer EquipInternalPower PowerPotential Sum
  sub Scratch4 Scratch2 Scratch ; Get available power in battery
  max BatteryMax BatteryMax Scratch4
  div Scratch4 BatteryMax Scratch4
  select Scratch4 BatteryMax Scratch4 0
  sbn LEDDisplay2 PowerSource Setting Scratch4
  sbn LEDDisplay2 PowerSource Mode CONSOLE_PERCENT

  ; Update temperature gauge happy point based on current recipe
  get Scratch MasterDevice MSTR_SP_CURRENT_RECIPE
  add Scratch Scratch RECIPE_OFFSET_TEMP_SP
  get Scratch MasterDevice Scratch
  div Scratch Scratch 2400
  add Scratch2 Scratch UI_TEMP_SPAN
  poke UI_SP_TEMP_HIGH_OK_BOUND Scratch2
  sub Scratch2 Scratch UI_TEMP_SPAN
  poke UI_SP_TEMP_LOW_OK_BOUND Scratch2

  ; Update Chamber Pressure gauge happy point based on current recipe
  get Scratch MasterDevice MSTR_SP_CURRENT_RECIPE
  add Scratch Scratch RECIPE_OFFSET_PRES_SP
  get Scratch MasterDevice Scratch
  div Scratch Scratch 60000
  add Scratch2 Scratch UI_CHBR_SPAN
  poke UI_SP_CHBR_HIGH_OK_BOUND Scratch2
  sub Scratch2 Scratch UI_CHBR_SPAN
  poke UI_SP_CHBR_LOW_OK_BOUND Scratch2

  ; Gas Line gauges

  lbn Scratch GasAnalyzer EquipHotLine Pressure Sum
  move Scratch2 HotLinePressure
  move sp UI_SP_SUPPLY_GAUGE
  jal gauge

  lbn Scratch GasAnalyzer EquipColdLine Pressure Sum
  move Scratch2 ColdLinePressure
  move sp UI_SP_SUPPLY_GAUGE
  jal gauge

  lbn Scratch GasAnalyzer EquipN2Line Pressure Sum
  move Scratch2 N2LinePressure
  move sp UI_SP_SUPPLY_GAUGE
  jal gauge

  lbn Scratch GasAnalyzer EquipExhaustLine Pressure Sum
  move Scratch2 ExhaustLinePressure
  move sp UI_SP_EXHAUST_GAUGE
  jal gauge

  lb Scratch LiquidAnalyzer VolumeOfLiquid Sum
  sgt Scratch Scratch 0.25
  sbn LightDiodeSmall CondensatePresent On Scratch


  ; Chamber Gauges

  lb Scratch AdvancedFurnace Pressure Sum
  move Scratch2 ChamberPressure
  move sp UI_SP_CHAMBER_GAUGE
  jal gauge

  lb Scratch AdvancedFurnace Temperature Sum
  move Scratch2 ChamberTemperature
  move sp UI_SP_TEMPERATURE_GAUGE
  jal gauge


  ; Blanket Gauges

  lb Scratch GasSensor Pressure Sum
  move Scratch2 BlanketPressure
  move sp UI_SP_BLANKET_GAUGE
  jal gauge

  lb Scratch GasSensor Temperature Sum
  move Scratch2 BlanketTemperature
  move sp UI_SP_TEMPERATURE_GAUGE
  jal gauge

  lb Scratch GasSensor RatioNitrogen Sum
  move Scratch2 BlanketPurity
  move sp UI_SP_PURITY_GAUGE
  jal gauge

  lbn Scratch GasAnalyzer EquipBlanketTank Pressure Sum
  move Scratch2 BlanketTankPressure
  move sp UI_SP_BLANKET_TANK_GAUGE
  jal gauge


  ; Fill/Vent Indicators

  lbn Scratch DigitalValve EquipHotLine On Sum
  sbn LightDiodeSmall HotFill On Scratch

  lbn Scratch DigitalValve EquipColdLine On Sum
  sbn LightDiodeSmall ColdFill On Scratch

  lb Scratch PressureRegulator On Sum
  sbn LightDiodeSmall BlanketFill On Scratch

  lb Scratch TurboVolumePump On Sum
  sbn LightDiodeSmall BlanketVent On Scratch

  lb Scratch AdvancedFurnace SettingOutput Sum
  snez Scratch Scratch
  sbn LightDiodeSmall ChamberVent On Scratch


  sb LEDDisplay3 Mode CONSOLE_TEXT

  ; Mode Indicator
  get Scratch MasterDevice MSTR_SP_CHAMBER_STATE
  add Scratch2 Scratch UI_SP_MODE_STRINGS
  get Scratch2 db Scratch2
  sbn LEDDisplay3 StateDisplay Setting Scratch2
  add Scratch2 Scratch UI_SP_MODE_COLORS
  get Scratch2 db Scratch2
  sbn LEDDisplay3 StateDisplay Color Scratch2

  ; Recipe Indicator
  get Scratch MasterDevice MSTR_SP_CURRENT_RECIPE
  get Scratch MasterDevice Scratch
  sbn LEDDisplay3 AlloyDisplay Setting Scratch
  sbn LEDDisplay3 AlloyDisplay Color White

  ; Mix Displays
  move Scratch MSTR_SP_MIX_TABLE
  move sp UI_SP_MIX_NAME_TABLE_END

next_reagent:
  get Scratch2 MasterDevice Scratch
  mod Scratch2 Scratch2 REAGENT_MODULUS
  add Scratch2 Scratch2 UI_SP_REAGENT_NAMES
  get Scratch2 db Scratch2
  add Scratch 1 Scratch
  pop Scratch3
  sbn LEDDisplay2 Scratch3 Setting Scratch2
  sbn LEDDisplay2 Scratch3 Mode CONSOLE_TEXT

  get Scratch2 MasterDevice Scratch
  add Scratch 1 Scratch
  pop Scratch3
  sbn LEDDisplay2 Scratch3 Setting Scratch2
  sbn LEDDisplay2 Scratch3 Mode CONSOLE_MASS
  blt Scratch MSTR_SP_MIX_TABLE_END next_reagent

  j ui_loop

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
