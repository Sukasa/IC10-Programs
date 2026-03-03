section definitions

  ; Reagent Hashes
  define  ReagentCoal               Hash("Hydrocarbon")
  define  ReagentSilver             Hash("Silver")
  define  ReagentSilicon            Hash("Silicon")
  define  ReagentNickel             Hash("Nickel")
  define  ReagentLead               Hash("Lead")
  define  ReagentIron               Hash("Iron")
  define  ReagentGold               Hash("Gold")
  define  ReagentCopper             Hash("Copper")
  define  ReagentCobalt             Hash("Cobalt")
  define  ReagentSteel              Hash("Steel")
  define  ReagentSolder             Hash("Solder")
  define  ReagentInvar              Hash("Invar")
  define  ReagentElectrum           Hash("Electrum")
  define  ReagentConstantan         Hash("Constantan")
  define  ReagentWaspaloy           Hash("Waspaloy")
  define  ReagentStellite           Hash("Stellite")
  define  ReagentInconel            Hash("Inconel")
  define  ReagentHastelloy          Hash("Hastelloy")
  define  ReagentAstroloy           Hash("Astroloy")

  ; UI Component Hashes
  define  UtilityButton             Hash("ModularDeviceUtilityButton2x2")
  define  FlipCoverSwitch           Hash("ModularDeviceFlipCoverSwitch")
  define  FlipSwitch                Hash("ModularDeviceFlipSwitch")
  define  Gauge                     Hash("ModularDeviceGauge2x2")
  define  Dial                      Hash("ModularDeviceDialSmall")
  define  LEDDisplay2               Hash("ModularDeviceLEDdisplay2")
  define  LEDDisplay3               Hash("ModularDeviceLEDdisplay3")
  define  ToggleSwitch              Hash("ModularDeviceSwitch")
  define  PushButtonSquare          Hash("ModularDeviceSquareButton")
  define  BigLever                  Hash("ModularDeviceBigLever")
  define  LightDiodeSmall           Hash("ModularDeviceLightSmall")

  ; Equipment Hashes
  define  LogicMemory               Hash("StructureLogicMemory")
  define  GasAnalyzer               Hash("StructurePipeAnalysizer")
  define  GasSensor                 Hash("StructureGasSensor")
  define  ICHousingCompact          Hash("StructureCircuitHousingCompact")
  define  LiquidAnalyzer            Hash("StructureLiquidPipeAnalyzer")
  define  CableAnalyzer             Hash("StructureCableAnalysizer")
  define  ActiveVent                Hash("StructureActiveVent")
  define  VolumePump                Hash("StructureVolumePump")
  define  PressureRegulator         Hash("StructurePressureRegulator")
  define  TurboVolumePump           Hash("StructureTurboVolumePump")
  define  DigitalValve              Hash("StructureDigitalValve")
  define  AdvancedFurnace           Hash("StructureAdvancedFurnace")
  define  WallHeater                Hash("StructureWallHeater")

  ; Name Hashes

  ; Chip Names
  define  UIChip                    Hash("Display Controller")
  define  MasterChip                Hash("Master Controller")
  define  RecipeChip                Hash("Recipe Controller")
  define  EquipmentChip             Hash("Equipment Controller")

  ; UI Gauges
  define  HotLinePressure           Hash("Hot Gas Pressure")
  define  ColdLinePressure          Hash("Cold Gas Pressure")
  define  N2LinePressure            Hash("N2 Line Pressure")
  define  ExhaustLinePressure       Hash("Waste Line Pressure")
  define  ChamberPressure           Hash("Chamber Pressure")
  define  ChamberTemperature        Hash("Chamber Temperature")
  define  BlanketPressure           Hash("Blanket Pressure")
  define  BlanketTemperature        Hash("Blanket Temperature")
  define  BlanketPurity             Hash("Blanket Purity")
  define  BlanketTankPressure       Hash("Blanket Tank Pressure")

  ; State Indicators
  define  CondensatePresent         Hash("Condensate Present")
  define  HotFill                   Hash("Hot Gas Fill")
  define  ColdFill                  Hash("Cold Gas Fill")
  define  BlanketFill               Hash("Blanket Tank Fill")
  define  BlanketVent               Hash("Blanket Tank Vent")
  define  ChamberVent               Hash("Chamber Vent")
  define  Reagent1                  Hash("Reagent 1")
  define  Reagent1Qty               Hash("Reagent 1 Quantity")
  define  Reagent2                  Hash("Reagent 2")
  define  Reagent2Qty               Hash("Reagent 2 Quantity")
  define  Reagent3                  Hash("Reagent 3")
  define  Reagent3Qty               Hash("Reagent 3 Quantity")
  define  StateDisplay              Hash("Process State")
  define  AlloyDisplay              Hash("Current Recipe")
  define  PowerSource               Hash("Power Source")
  define  BatteryCharge             Hash("Battery Charge")

  ; Controls
  define  CtrlRecipePrevious        Hash("Previous Recipe")
  define  CtrlReceipeNext           Hash("Next Recipe")
  define  CtrlHotGasValve           Hash("Hot Gas Valve")
  define  CtrlColdGasValve          Hash("Cold Gas Valve")
  define  CtrlBlanketHeater         Hash("Blanket Heater")
  define  CtrlOpenCrucible          Hash("Open Crucible")
  define  CtrlChamberFillRate       Hash("Chamber Fill Rate l/s")
  define  CtrlChamberVentRate       Hash("Chamber Vent Rate l/s")
  define  CtrlBlanketFillPres       Hash("Blanket Pressurize Setpoint kPa")e
  define  CtrlBlanketVentPres       Hash("Blanket Depressurize Setpoint kPa")
  define  CtrlBlanketTankFillPres   Hash("Blanket Tank Pressurize Setpoint kPa")
  define  CtrlBlanketTankVentRate   Hash("Blanket Tank Vent Rate l/s")
  define  CtrlBlanketPumpDir        Hash("Blanket Pump Direction")
  define  CtrlBlanketPumpEnable     Hash("Blanket Pump Toggle")
  define  CtrlBlanketTankFillEnab   Hash("Fill Blanket Tank")
  define  CtrlBlanketTankVentEnab   Hash("Vent Blanket Tank")

  ; Equipment
  define  EquipHotLine              Hash("Hot Line")
  define  EquipColdLine             Hash("Cold Line")
  define  EquipN2Line               Hash("N2 Line")
  define  EquipExhaustLine          Hash("Exhaust Line")
  define  EquipBlanketTank          Hash("Blanket Tank")
  define  EquipCondensateLine       Hash("Condensate Line")
  define  EquipIntakeLine           Hash("Intake Line")
  define  EquipSourcePower          Hash("Source Power")
  define  EquipInternalPower        Hash("Internal Power")

  alias   Scratch                   r0
  alias   Scratch2                  r1
  alias   Scratch3                  r2
  alias   Scratch4                  r3

  alias   MasterDevice              r15
  alias   DisplayDevice             r14
  alias   CurrentMode               r13
  alias   FurnaceRefId              r12

  define  LINE_PRESSURE_MAX         6000
  define  EXHAUST_PRESSURE_MAX      600
  define  NUM_RECIPES               1 ; Number of valid recipes

  define  UI_TEMP_SPAN              Calc(75/2400) ; = 75 k / Temperature gauge scale
  define  UI_CHBR_SPAN              Calc(50/60000) ; = 100 kPA / Temperature gauge scale

  define  UI_SP_BLANKET_GAUGE       190 ; Blanket Pressure kPa
  define  UI_SP_BLANKET_TANK_GAUGE  180 ; Blanket Tank PRessure kPa
  define  UI_SP_PURITY_GAUGE        170 ; N2 gas feed purity
  define  UI_SP_SUPPLY_GAUGE        162 ; TODO all the 0 addresses need to be allocated
  define  UI_SP_EXHAUST_GAUGE       150
  define  UI_SP_TEMPERATURE_GAUGE   140
  define  UI_SP_TEMP_LOW_OK_BOUND   Calc(UI_SP_TEMPERATURE_GAUGE-4)
  define  UI_SP_TEMP_HIGH_OK_BOUND  Calc(UI_SP_TEMPERATURE_GAUGE-2)
  define  UI_SP_CHAMBER_GAUGE       130
  define  UI_SP_CHBR_LOW_OK_BOUND   Calc(UI_SP_CHAMBER_GAUGE-4)
  define  UI_SP_CHBR_HIGH_OK_BOUND  Calc(UI_SP_CHAMBER_GAUGE-2)


  define  UI_SP_MIX_NAME_TABLE_END  395
  define  UI_SP_MIX_NAME_TABLE_R1   Calc(UI_SP_MIX_NAME_TABLE_END-6)
  define  UI_SP_MIX_NAME_TABLE_R1Q  Calc(UI_SP_MIX_NAME_TABLE_END-5)
  define  UI_SP_MIX_NAME_TABLE_R2   Calc(UI_SP_MIX_NAME_TABLE_END-4)
  define  UI_SP_MIX_NAME_TABLE_R2Q  Calc(UI_SP_MIX_NAME_TABLE_END-3)
  define  UI_SP_MIX_NAME_TABLE_R3   Calc(UI_SP_MIX_NAME_TABLE_END-2)
  define  UI_SP_MIX_NAME_TABLE_R3Q  Calc(UI_SP_MIX_NAME_TABLE_END-1)

  define  UI_SP_MODE_STRINGS        110
  define  UI_SP_MODE_COLORS         100

  define  RECIPE_STRIDE             11

  define  UI_SP_REAGENT_NAMES       430
  define  REAGENT_MODULUS           78 ; TODO

  define  MSTR_SP_RECIPE_TABLE      200
  define  MSTR_SP_RECIPE_TABLE_END  Calc(RECIPE_STRIDE*10+MSTR_SP_RECIPE_TABLE)
  define  MSTR_SP_MIX_TABLE         300
  define  MSTR_SP_MIX_TABLE_END     6; MSTR_SP_MIX_TABLE + 6

  define  MSTR_SP_CHAMBER_STATE     10
  define  MSTR_SP_LOAD_STATE        11
  define  MSTR_SP_CURRENT_RECIPE    12 ; Pointer to current active recipe

  define  RCP_SP_REAGENT_TABLE      120 ; Recipe reagent table (reagents to scan for in the crucible contents list)
  define  RCP_SP_REAGENT_TABLE_END  Calc(RCP_SP_REAGENT_TABLE+19)

  define  CHAMBER_IDLE              0
  define  CHAMBER_LOAD              1 ; Load chamber while tempering / pressurizing
  define  CHAMBER_COOK              2 ; Heat/Cool/Vent mode
  define  CHAMBER_DUMP              3 ; Dump successful recipe
  define  CHAMBER_ABORT             4 ; Abort - cancel command or improper load
  define  CHAMBER_MANUAL            5 ; Chamber in Manual mode

  define  THERMAL_FLAGS_NONE        0
  define  THERMAL_FLAG_TEMP_OK      1;
  define  THERMAL_FLAG_PRES_OK      2;
  define  THERMAL_FLAG_READY        3;

  define  LOAD_INCOMPLETE           0 ; Not all reagents loaded
  define  LOAD_IMBALANCE            1 ; Right reagents present, wrong ratio
  define  LOAD_BALANCED             2 ; Right reagents present, right ratio
  define  LOAD_IMPROPER             3 ; Wrong reagent present

  define  CONSOLE_TEXT              10
  define  CONSOLE_MASS              0 ; No actual mass mode but just in case...
  define  CONSOLE_PERCENT           1 ; No actual mass mode but just in case...

  define  RECIPE_OFFSET_NAME        0
  define  RECIPE_OFFSET_RESULT      1
  define  RECIPE_OFFSET_TEMP_SP     2
  define  RECIPE_OFFSET_PRES_SP     3
  define  RECIPE_OFFSET_REAGENT1    4
  define  RECIPE_OFFSET_QUANTITY1   5
  define  RECIPE_OFFSET_TERMINATOR  10

  define  RECIPE_STRIDE_REAGENT     2 ; Stride between reagent entries

  define  ACTIVE_VENT_INWARD        1
