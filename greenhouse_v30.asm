#########################################################################################################################################################
#                                                                                                                                                       #
# Stationeers Greenhouse rack control v3.0                                                                                                              #
# Sectioned into "provision", "extended" and "application" programs, with a common definitions section                                                  #
# The former runs in-situ to set up the stack, the latter runs normally using the same IC10 afterwards (stack is non-volatile)                          #
# "Extended" program enables Extended Mode by selectively updating some stack and register data                                                         #
# Standard mode completes a full scan every second, Extended mode runs at 0.667Hz.                                                                      #
# This file is intended to be pre-processed by my IC10 Inliner program in order to produce the Vanilla-friendly assembly files                          #
# Get that program at https://github.com/Sukasa/IC10-Inliner                                                                                            #
#                                                                                                                                                       #
# **** Single-chip greenhouse controller ****                                                                                                           #
#                                                                                                                                                       #
# A turnkey system that can manage an entire greenhouse (or greenhouse section) with a single IC10 chip.                                                #
#   - Allows the user to start and stop the greenhouse, with support for 25 selectable crops                                                            #
#   - Allows the user to configure an access card needed (by color) in order to allow locking the controls                                              #
#   - Automatically toggles grow lighting based on crop selection                                                                                       #
#   - Monitors 11 different alarms, including Air/Water Temp; Air, CO2, O2, N2, Volatiles, and Pollutant levels, Power state, and water quality         #
#   - Alarm monitoring takes into account selected crop type                                                                                            #
#   - Fully self-configuring with no device screw or code adjustments required.  Only setting names on equipment                                        #
#                                                                                                                                                       #
#   When configured in Extended Mode:                                                                                                                   #
#   - Provides Seed/Fruit item hash values for LArRE control via second IC (code to be provided in future)                                              #
#   - Controls Wall Heater, Wall Cooler, Liquid Wall Cooler, and Air Conditioners named "Temperature Control" to maintain greenhouse temperature        #
#       - Atmospherics systems will be disabled in the event of low air pressure (poor efficiency) or low external power (APC discharging)              #
#   - Controls Active Vent, Volume Pump, and Gas Mixer to maintain pressure and cycle air contents                                                      #
#       - Active Vent or Volume Pump named "Filtration" will operate to reduce pressure, or pull stale air out to be replaced by fresher air.           #
#       - Filtration unit named "Filtration" will change modes to manage air filtration in concert with the above                                       #
#       - Active Vent, Volume Pump, or Gas Mier named "Air Supply" will operate to feed fresh air into the grow chamber                                 #
#       - Active Vents will not operate if the air pressure runs low or if running on battery power                                                     #
#   - Controls Liquid Pipe Heater and Liquid Volume Pump named "Water Supply" to maintain water temperature and quantity                                #
#       - Heater will be disabled in the event of low external power (APC discharging)                                                                  #
#   - Flashing Light named "System Alarm" will turn on if a warning is present                                                                          #
#   - Automatically closes all Glass Doors on network to seal greenhouse                                                                                #
#   - Activates Liquid Filtration unit named "Filtration" if the water loses quality due to contamination of any kind (untested)                        #
#   - Sets up Pressure Regulator and Back Pressure Regulator for passive continous pressure control and air cycling                                     #
#                                                                                                                                                       #
# Setup: This program assumes you have Modular Consoles available.                                                                                      #
#        If you do not, changes the hashes referenced in the 'UI Devices' table below to be vanilla compatible                                          #
#        NOTE: There is no vanilla equivalent to the access card reader, and the controls locking will not be available                                 #
#        When building the controls, build the LED displays in order from BOTTOM TO TOP.  Otherwise, texts will appear in the wrong order               #
#        Use a Logic Mirror to bring the APC's data port onto the greenhouse network.                                                                   #
#                                                                                                                                                       #
#        Load the "Provisioning" code into an active IC10, and wait for the access reader light to change to CARD COLOR, or BLUE if no card.            #
#        Then (optionally) load the "extended" code and wait for the access reader light to change to ORANGE, to enable Extended Mode.                  #
#        Lastly, load the Application code and use your greenhouse!                                                                                     #
#                                                                                                                                                       #
# Future updates will include LArRE control via a second IC10 chip                                                                                      #
#                                                                                                                                                       #
#########################################################################################################################################################

section definitions

  ### Register Assignments ####
  
  alias CropSelect          r15                   # Register assignments
  alias Active              r14                   # System run/idle mode state
  alias LightsOn            r13                   # Grow lights on/off state
  alias Countdown           r12                   # Time left before switching to the next day/night step
  alias WarnFlags           r11                   # Current active warning flags
  alias WarnIdx             r10                   # Index for currently-displayed warning flag
  alias WarnWait            r9                    # Warning flag timing
  alias WarnTick            r8                    # Warning flag timing, part 22
  alias Unlocked            r7                    # Controls unlock state
  alias WarnMask            r6                    # Warning/alarm mask bits for the warning display
  alias ControlFlags        r5                    # "Control" flags, used in the extended-mode equipment control routine
  alias EnabExtended        r4                    # A mix of extended-mode enable, and timing variable
  alias Scratch4            r3                    # Four scratch registers used all over the place
  alias Scratch3            r2
  alias Scratch2            r1
  alias Scratch1            r0
  alias Scratch5            ra
  
  ### Variable Stack Addresses ####
  
  define SP_DISPLAY1            8                     # Display 1 (Top) RefId
  define SP_DISPLAY2            9                     # Display 2 (Mid) RefId
  define SP_DISPLAY3            10                    # Display 3 (Bot) RefId
  define SP_OFFTIME             11                    # Lights Off time in seconds
  define SP_ONTIME              12                    # Lights On time in seconds
  define SP_ALARMTABLEINIT      13                    # Where to start the alarm table scan at
  define SP_CARD_COLOR          14                    # Desired unlock card colour (-1 for none)
  define SP_UNLOCKED            15                    # Unlocked status
  define LightStatus            16                    # Lights On/Off Status
  define ActiveAlarms           17                    # Active (1 == off-nominal) warnings as bit array
  define SeedHash		            18                    # Hash for the seed item used to plant this plant
  define FruitHash		          19                    # Hash for the fruit item this plant produces
  
  ### Data Table Stack Addresses ####
  
  define CROPTABLE_STRIDE       4

  define SP_CROPTABLE           20                    # Table of crop data
  define SP_WARNTABLE           150                   # Table of warning text labels
  define SP_TRIGGERTABLE        200                   # Table for warning rules
  define SP_RULESTABLE          300                   # Equipment control rule table
  
  ### UI Devices.  Change these to the vanilla equivalents for full vanilla friendliness ####
  
  define LogicSwitch	      HASH("ModularDeviceSwitch")
  define LogicDial          HASH("ModularDeviceDial")
  define AccessReader       HASH("ModularDeviceCardReader")
  define LEDDisplay         HASH("ModularDeviceLEDdisplay3")
  define StatusLight        HASH("ModularDeviceLightLarge")
  
  ### Equipment control hashes ####
  
  define GrowLight          HASH("StructureGrowLight")
  define GasSensor          HASH("StructureGasSensor")
  define LiquidSensor       HASH("StructureLiquidPipeAnalyzer")
  define APC                HASH("StructureLogicMirror")
  define ActiveVent         HASH("StructureActiveVent")
  define LiquidHeater       HASH("StructureLiquidPipeHeater")
  define AirConditioner     HASH("StructureAirConditioner")
  define AirCon             HASH("StructureAirConditioner")
  define WallHeater         HASH("StructureWallHeater")
  define WallCooler         HASH("StructureWallCooler")
  define WallCooler2        HASH("StructureWaterWallCooler")
  define VolumePump         HASH("StructureVolumePump")
  define PressureReg        HASH("StructurePressureRegulator")
  define BackPressureReg    HASH("StructureBackPressureRegulator")
  define GasMixer           HASH("StructureGasMixer")
  define GlassDoor          HASH("StructureGlassDoor")
  define Filtration         Hash("StructureFiltration")
  define WaterPump          Hash("StructureLiquidVolumePump")
  define FlashingLight      Hash("StructureFlashingLight")
  define LiquidFiltration   Hash("StructureLiqudFiltration")
  
  ### Various constants used to shrink output program size ####
  
  define Blue               0                     # Colours
  define Gray               1
  define Green              2
  define Orange             3
  define Red                4
  define Yellow             5
  define White              6
  define Black              7
  define Pink               10
  define Purple             11
  
  define Seconds            7                     # Display Modes
  define Text               10
  
  define Open               2
  define Mode               3
  define Pressure           5
  define Temperature        6
  define Setting            12
  define RatioOxygen        14
  define RatioCarbonDioxide 15
  define RatioNitrogen      16
  define RatioPollutant     17
  define RatioVolatiles     18
  define RatioWater         19
  define On                 28
  define VolumeOfLiquid     182
  define RatioPollutedWater 254
  
  define CropsStride        25                    # Number of crop types defined
  define CropsMax           Calc(CropsStride-1)   # Number of crop types defined -1
  define WarnInterval       6                     # Interval in seconds between warning displays
  define WarnTimescale      2                     # How many seconds to display each individual warning for

  define RULE_STRIDE        2
  define RULE_COUNT         14

  define TIME_BITFIELD_LEN  13
  define LIGHT_EFFICIENCY   0.8
  define ALARM_BITS_OFFSET  Calc(TIME_BITFIELD_LEN*2)
  define ALARM_BITS_COUNT   11
  define TRIG_BITS_COUNT    Calc(ALARM_BITS_COUNT+11)
  define COND_BITS_COUNT    Calc(TRIG_BITS_COUNT)
  define EXCL_BITS_COUNT    20
  define CROP_TEMP_BIT_IDX  Calc(ALARM_BITS_OFFSET+ALARM_BITS_COUNT)

  define SECONDS_FACTOR     1

  define  MODE_STANDARD     1
  define  MODE_EXTENDED     2

  define TIME_NONE          0
  define TIME_100s          Calc(100*SECONDS_FACTOR)
  define TIME_200s          Calc(200*SECONDS_FACTOR)
  define TIME_300s          Calc(300*SECONDS_FACTOR)
  define TIME_480s          Calc(480*SECONDS_FACTOR)
  define TIME_500s          Calc(500*SECONDS_FACTOR)
  define TIME_600s          Calc(600*SECONDS_FACTOR)
  define TIME_1H            Calc(3600*SECONDS_FACTOR)

  define ALARM_STRIDE       4

  define ALARM_POWER        0x1
  define ALARM_LOW_WATER    0x2
  define ALARM_HIGH_POL     0x4
  define ALARM_LOW_CO2      0x8

  define ALARM_BAD_ATEMP    0x10
  define ALARM_BAD_PRES     0x20
  define ALARM_LOW_N2       0x40
  define ALARM_HIGH_VOL     0x80

  define ALARM_LOW_O2       0x100
  define ALARM_BAD_WTEMP    0x200
  define ALARM_BAD_WQUAL    0x400

  define TRIG_LOW_CO2       0x800
  define TRIG_HIGH_O2       0x1000
  define TRIG_COLD_WATER    0x2000
  define TRIG_COLD_AIR      0x4000
  define TRIG_WARM_AIR      0x8000
  define TRIG_HIGH_PRES     0x10000
  define TRIG_LOLO_PRES     0x20000
  define TRIG_LO_PRES       0x40000
  define TRIG_LO_O2         0x80000

  define TRIG_WATER_QUAL    0x100000
  define TRIG_LO_WATER      0x200000

  define TRIG_ALL           0x3ff800
  define CONDITION_ANY      0x3fffff
  define ALARM_ANY          0x0007ff

  define WarnInverts        Calc(ALARM_HIGH_POL|ALARM_BAD_ATEMP|ALARM_BAD_PRES|ALARM_HIGH_VOL|ALARM_BAD_WTEMP|TRIG_HIGH_O2|TRIG_WARM_AIR|TRIG_HIGH_PRES)
  define ControlMask        Calc(TRIG_ALL|ALARM_HIGH_POL|ALARM_HIGH_VOL)

  define ALARMS_COMMON      Calc(ALARM_POWER|ALARM_LOW_WATER|ALARM_BAD_WTEMP|ALARM_BAD_ATEMP|ALARM_BAD_PRES|ALARM_BAD_WQUAL)
  define ALARMS_STANDARD    Calc(ALARM_HIGH_POL|ALARM_LOW_CO2|ALARM_HIGH_VOL|ALARMS_COMMON)
  define ALARMS_SOYBEAN     Calc(ALARM_LOW_N2|ALARMS_STANDARD)
  define ALARMS_WINTER      Calc(ALARM_HIGH_POL|ALARM_LOW_O2|ALARM_LOW_N2|ALARMS_COMMON)
  define ALARMS_HADES       Calc(ALARM_LOW_O2|ALARMS_COMMON)
  define ALARMS_MUSHROOM    Calc(ALARM_LOW_O2|ALARM_HIGH_POL|ALARM_HIGH_VOL|ALARMS_COMMON)

  define T_ZERO_C           273.15
  define T_TWENTY_C         Calc(T_ZERO_C+20)
  define TEMP_35_C          15
  define TEMP_30_C          10
  define TEMP_25_C          5
  define TEMP_20_C          0

macro trigger Index Approximation Setpoint LogicType PrefabHash
  if Calc(Approximation!=0)
    poke Calc(Index*ALARM_STRIDE+SP_TRIGGERTABLE+0) Approximation
  endif
  if Calc(Setpoint!=0)
    poke Calc(Index*ALARM_STRIDE+SP_TRIGGERTABLE+1) Setpoint
  endif
    poke Calc(Index*ALARM_STRIDE+SP_TRIGGERTABLE+2) LogicType
    poke Calc(Index*ALARM_STRIDE+SP_TRIGGERTABLE+3) PrefabHash
endmacro

###############################################################################
#  Provisioning Code - Sets up NVRAM, learns unlock card color, maps displays #
###############################################################################

section provisioning requires definitions

  clr db

  move EnabExtended MODE_STANDARD                           # Disable extended functions and set end of trigger table to end of normal alarms list
  poke SP_ALARMTABLEINIT Calc(ALARM_BITS_COUNT*ALARM_STRIDE+SP_TRIGGERTABLE)
  move sp SP_DISPLAY1
  move Scratch1 -1
  sb AccessReader Color Color.Yellow                        # Colour for "initializing"
  
search:
  add Scratch1 Scratch1 1
  get Scratch2 db:0 Scratch1                                # Enumerate network devices, searching for LED displays
  l Scratch3 Scratch2 PrefabHash		                        # Check if the last device we got an ID for is an LED display
  bne Scratch3 LEDDisplay search                            # This code doesn't check for end-of-IDs, so I don't know what it will do if it can't find three LED Displays
  push Scratch2                                             # This was a match, so save it to the current display index, and increment index (which is in sp)
  ble sp SP_DISPLAY3 search                                 # Continue search until we find all displays
  
macro crop_entry Index NameString ConfigTemperature ConfigOnTime ConfigOffTime ConfigAlarmMask
  define __OnTime Calc(ConfigOnTime/LIGHT_EFFICIENCY<<TIME_BITFIELD_LEN)
  define __OffTime Calc(ConfigOffTime)
  define __Temperature Calc(ConfigTemperature<<CROP_TEMP_BIT_IDX)
  define __Mask Calc(ConfigAlarmMask<<ALARM_BITS_OFFSET)

  poke Calc(Index*4+SP_CROPTABLE+0) NameString
  poke Calc(Index*4+SP_CROPTABLE+3) Calc(__OnTime|__OffTime|__Temperature|__Mask)
endmacro

  # Packed crop table, using interleaved data and a lot of bit-packing.  Not that many more LoC to read on the application side
  # But far fewer LoC to store on the provisioning side(s)
  crop_entry 00 Str("Potato") TEMP_25_C TIME_300s TIME_200s ALARMS_STANDARD
  crop_entry 01 Str("Soy")    TEMP_25_C TIME_600s TIME_300s ALARMS_SOYBEAN
  crop_entry 02 Str("Rice")   TEMP_25_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 03 Str("Tomato") TEMP_25_C TIME_480s TIME_300s ALARMS_STANDARD
  crop_entry 04 Str("Wheat")  TEMP_25_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 05 Str("Fern")   TEMP_25_C TIME_480s TIME_300s ALARMS_STANDARD
  crop_entry 06 Str("Darga")  TEMP_25_C TIME_480s TIME_300s ALARMS_STANDARD
  crop_entry 07 Str("Cocoa")  TEMP_35_C TIME_500s TIME_200s ALARMS_STANDARD
  crop_entry 08 Str("Corn")   TEMP_25_C TIME_500s TIME_200s ALARMS_STANDARD
  crop_entry 09 Str("Pmpkn")  TEMP_25_C TIME_500s TIME_100s ALARMS_STANDARD
  crop_entry 10 Str("WnterA") TEMP_20_C TIME_600s TIME_300s ALARMS_WINTER
  crop_entry 11 Str("WnterB") TEMP_20_C TIME_600s TIME_300s ALARMS_WINTER
  crop_entry 12 Str("HadesA") TEMP_25_C TIME_600s TIME_300s ALARMS_HADES
  crop_entry 13 Str("HadesB") TEMP_25_C TIME_600s TIME_300s ALARMS_HADES
  crop_entry 14 Str("T Lily") TEMP_25_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 15 Str("P Lily") TEMP_25_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 16 Str("Sugar")  TEMP_25_C TIME_500s TIME_200s ALARMS_STANDARD
  crop_entry 17 Str("Flax")   TEMP_20_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 18 Str("Gorse")  TEMP_20_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 19 Str("Strbry") TEMP_25_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 20 Str("Blubry") TEMP_25_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 21 Str("Wtrmln") TEMP_25_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 22 Str("Grass")  TEMP_20_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 23 Str("Mushrm") TEMP_25_C TIME_NONE TIME_1H   ALARMS_MUSHROOM
  crop_entry 24 Str("Swtgrs") TEMP_30_C TIME_600s TIME_300s ALARMS_STANDARD
  crop_entry 25 Str("DUMMY")  TEMP_30_C TIME_300s TIME_200s ALARMS_STANDARD
  crop_entry 26 Str("DUMMY")  TEMP_25_C TIME_300s TIME_200s ALARMS_STANDARD

  # Store warning label strings
  poke Calc(SP_WARNTABLE+00) STR("Power")                   # Power alarm - no battery or discharging
  poke Calc(SP_WARNTABLE+01) STR("W Quan")                  # Water Quantity alarm (low)
  poke Calc(SP_WARNTABLE+02) STR("Pol Hi")                  # Pollutants present
  poke Calc(SP_WARNTABLE+03) STR("CO2 Lo")                  # CO2 Low
  poke Calc(SP_WARNTABLE+04) STR("A Temp")                  # Air Temperature Bad (high or low)
  poke Calc(SP_WARNTABLE+05) STR("A Pres")                  # Air Pressure Bad (high or low)
  poke Calc(SP_WARNTABLE+06) STR("N2 Low")                  # Low Nitrogen (for soy)
  poke Calc(SP_WARNTABLE+07) STR("Vol Hi")                  # Volatiles present
  poke Calc(SP_WARNTABLE+08) STR("O2 Low")                  # Low Oxygen
  poke Calc(SP_WARNTABLE+09) STR("W Temp")                  # Water Temperature Bad (high or low)
  poke Calc(SP_WARNTABLE+10) STR("W Prty")                  # Water Contamination (purity)

  # Alarm triggers for above alarm strings
  trigger 00  0       2       Mode                APC
  trigger 01  0       5       VolumeOfLiquid      LiquidSensor
  trigger 02  0       0.001   RatioPollutant      GasSensor
  trigger 03  0       0.03    RatioCarbonDioxide  GasSensor
  trigger 04  0.016   298     Temperature         GasSensor
  trigger 05  0.28    75      Pressure            GasSensor
  trigger 06  0       0.03    RatioNitrogen       GasSensor
  trigger 07  0       0.001   RatioVolatiles      GasSensor
  trigger 08  0       0.015   RatioOxygen         GasSensor
  trigger 09  0       298.15  Temperature         LiquidSensor
  trigger 10  0       0.995   RatioWater          LiquidSensor

learn_card:
  move Scratch3 -1                                          # Now scan for the inserted card's color
  
card_search:
  add Scratch3 Scratch3 1                                   # Loop through all of the known card colours, and see if the inserted card matches one of them
  sb AccessReader Mode Scratch3                             # When we find a match, store that as the "required" card colour to unlock the controls
  lb Scratch2 AccessReader Setting Sum
  bgt Scratch3 12 complete_provision                        # If we don't find one by the end of the colour reset, re-check in case the card was removed mid search
  beqz Scratch2 card_search                                 

complete_provision:
  poke SP_CARD_COLOR Scratch3                               # Card found (or no card inserted); save the current colour (or sentinel value) to stack index
  sb LogicDial Mode CropsMax                                # Set up the logic dial's maximum to be the crop limit
  sb LEDDisplay Mode Text                                   # All LED displays to text mode to start
  sb LEDDisplay Color Purple                                # All LED displays to purple text
  
  sb AccessReader Color Scratch3                            # Colour is blue: No Lock, else inserted card (...including blue)
  bgt Scratch3 12 learn_card
  
##########################################################################
#  Extended Provisioning Code - optional data for expanded functions
########################################################################## 

section extended requires definitions
  
  move EnabExtended MODE_EXTENDED                           # Enable extended functions (==3), then store the extended trigger table end address
  poke SP_ALARMTABLEINIT Calc(TRIG_BITS_COUNT*ALARM_STRIDE+SP_TRIGGERTABLE)
 
  trigger 11  0       0.15    RatioCarbonDioxide  GasSensor
  trigger 12  0       0.55    RatioOxygen         GasSensor
  trigger 13  0       295.15  Temperature         LiquidSensor
  trigger 14  0       293.15  Temperature         GasSensor
  trigger 15  0       308.15  Temperature         GasSensor
  trigger 16  0       95      Pressure            GasSensor
  trigger 17  0       45      Pressure            GasSensor
  trigger 18  0       80      RatioCarbonDioxide  GasSensor
  trigger 19  0       0.15    RatioOxygen         GasSensor
  trigger 20  0       4       VolumeOfLiquid      LiquidSensor
  trigger 21  0       0.998   RatioWater          LiquidSensor

macro extended_entry Index SeedHash FruitHash
  poke Calc(Index*4+SP_CROPTABLE+1) FruitHash
  poke Calc(Index*4+SP_CROPTABLE+2) SeedHash
endmacro

  extended_entry 00 HASH("SeedBag_Potato") HASH("ItemPotato")
  extended_entry 01 HASH("SeedBag_Soybean") HASH("ItemSoybean")
  extended_entry 02 HASH("SeedBag_Rice") HASH("ItemRice")
  extended_entry 03 HASH("SeedBag_Tomato") HASH("ItemTomato")
  extended_entry 04 HASH("SeedBag_Wheet") HASH("ItemWheat")
  extended_entry 05 HASH("SeedBag_Fern") HASH("ItemFern")
  extended_entry 06 HASH("SeedBag_DargaFern") HASH("ItemFilterFern")
  extended_entry 07 HASH("SeedBag_Cocoa") HASH("ItemCocoaTree")
  extended_entry 08 HASH("SeedBag_Corn") HASH("ItemCorn")
  extended_entry 09 HASH("SeedBag_Pumpkin") HASH("ItemPumpkin")
  extended_entry 10 HASH("SeedBag_WinterspawnAlpha") HASH("ItemPlantEndothermic_Genepool1")
  extended_entry 11 HASH("SeedBag_WinterspawnBeta") HASH("ItemPlantEndothermic_Genepool2")
  extended_entry 12 HASH("SeedBag_HadesAlpha") HASH("ItemPlantThermogenic_Genepool1")
  extended_entry 13 HASH("SeedBag_HadesBeta") HASH("ItemPlantThermogenic_Genepool2")
  extended_entry 14 HASH("ItemTropicalPlant") HASH("ItemTropicalPlant")
  extended_entry 15 HASH("ItemPeaceLily") HASH("ItemPeaceLily")
  extended_entry 16 HASH("SeedBag_SugarCane") HASH("ItemSugarCane")
  extended_entry 17 HASH("ItemFlax") HASH("ItemFlax")
  extended_entry 18 HASH("ItemGorse") HASH("ItemGorse")
  extended_entry 19 HASH("SeedBag_Strawberry") HASH("ItemStrawberry")
  extended_entry 20 HASH("SeedBag_Blueberry") HASH("ItemBlueberry")
  extended_entry 21 HASH("SeedBag_Watermelon") HASH("ItemWatermelon")
  extended_entry 22 HASH("ItemGrass") HASH("ItemGrass")
  extended_entry 23 HASH("SeedBag_Mushroom") HASH("ItemMushroom")
  extended_entry 24 HASH("ItemPlantSwitchGrass") HASH("ItemPlantSwitchGrass")
  extended_entry 25 HASH("DUMMY") HASH("DUMMY")
  extended_entry 26 HASH("DUMMY") HASH("DUMMY")

  define  LOGIC_ON    0
  define  LOGIC_MODE  1
  define  LOGIC_OPEN  2

  poke LOGIC_ON   LogicType.On
  poke LOGIC_MODE LogicType.Mode
  poke LOGIC_OPEN LogicType.Open

  define  CONDITION_COLD_AIR    Calc(TRIG_COLD_AIR)
  define  CONDITION_WARM_AIR    Calc(TRIG_WARM_AIR)
  define  CONDITION_BAD_ATEMP   Calc(TRIG_COLD_AIR|TRIG_WARM_AIR|ALARM_BAD_ATEMP)
  define  CONDITION_BAD_AQUAL   Calc(ALARM_HIGH_POL|ALARM_LOW_CO2|TRIG_LOW_CO2|ALARM_LOW_N2|ALARM_HIGH_VOL|ALARM_LOW_O2|TRIG_HIGH_O2)
  define  CONDITION_COLD_WATER  Calc(TRIG_COLD_WATER)

  define  CONDITION_NEED_CYCLE  Calc(TRIG_HIGH_PRES|CONDITION_BAD_AQUAL)
  define  CONDITION_NEED_SUPPLY Calc(ALARM_LOW_CO2|TRIG_LOW_CO2|TRIG_LO_PRES|ALARM_LOW_O2)

  define  CONDITION_WATER_QUAL  Calc(TRIG_WATER_QUAL|ALARM_BAD_WQUAL)
  define  CONDITION_LOW_WATER   Calc(ALARM_LOW_WATER|TRIG_LO_WATER)

  define  EXCLUSION_POWER_AIR   Calc(ALARM_POWER|TRIG_LOLO_PRES)
  define  EXCLUSION_HAS_WATER   Calc(ALARM_POWER|ALARM_LOW_WATER)
  define  EXCLUSION_AIR_PRES    Calc(ALARM_POWER|TRIG_HIGH_PRES)

macro equip_rule Index PrefabHash NameHash LogicType Condition Exclusion
  define __lutpos Calc(EXCL_BITS_COUNT)
  define __logic  Calc(LogicType<<__lutpos)
  define __nshift Calc(EXCL_BITS_COUNT+2)
  define __name   Calc(1<<__nshift*NameHash)
  define __prefab Calc(1<<COND_BITS_COUNT*PrefabHash)

  poke Calc(Index*RULE_STRIDE+SP_RULESTABLE)   Calc(__logic|__name|Exclusion)
  poke Calc(Index*RULE_STRIDE+SP_RULESTABLE+1) Calc(__prefab|Condition)
endmacro

  define TemperatureName  Hash("Temperature Control")
  define FiltrationName   Hash("Air Filter")
  define AirSupplyName    Hash("Air Supply")
  define WaterSupplyName  Hash("Water Supply")
  define AlarmName        Hash("System Alarm")

  equip_rule 00 WallHeater        TemperatureName LOGIC_ON   CONDITION_COLD_AIR    EXCLUSION_POWER_AIR
  equip_rule 01 WallCooler        TemperatureName LOGIC_ON   CONDITION_WARM_AIR    EXCLUSION_POWER_AIR
  equip_rule 02 WallCooler2       TemperatureName LOGIC_ON   CONDITION_WARM_AIR    EXCLUSION_POWER_AIR
  equip_rule 03 AirCon            TemperatureName LOGIC_MODE CONDITION_BAD_ATEMP   EXCLUSION_POWER_AIR
  equip_rule 04 ActiveVent        FiltrationName  LOGIC_ON   CONDITION_NEED_CYCLE  EXCLUSION_POWER_AIR
  equip_rule 05 Filtration        FiltrationName  LOGIC_MODE CONDITION_NEED_CYCLE  EXCLUSION_POWER_AIR
  equip_rule 06 VolumePump        FiltrationName  LOGIC_ON   CONDITION_NEED_CYCLE  EXCLUSION_POWER_AIR
  equip_rule 07 ActiveVent        AirSupplyName   LOGIC_ON   CONDITION_NEED_SUPPLY EXCLUSION_AIR_PRES
  equip_rule 08 VolumePump        AirSupplyName   LOGIC_ON   CONDITION_NEED_SUPPLY EXCLUSION_AIR_PRES
  equip_rule 09 GasMixer          AirSupplyName   LOGIC_ON   CONDITION_NEED_SUPPLY EXCLUSION_AIR_PRES
  equip_rule 10 WaterPump         WaterSupplyName LOGIC_ON   CONDITION_LOW_WATER   ALARM_POWER
  equip_rule 11 LiquidHeater      WaterSupplyName LOGIC_ON   CONDITION_COLD_WATER  EXCLUSION_HAS_WATER
  equip_rule 12 FlashingLight     AlarmName       LOGIC_ON   ALARM_ANY             0
  equip_rule 13 LiquidFiltration  FiltrationName  LOGIC_ON   CONDITION_WATER_QUAL  EXCLUSION_HAS_WATER


  sb PressureReg Setting 95                                 # Regulator to 95kPa - Configure equipment defaults
  sb BackPressureReg Setting 93                             # Regulator to 93kPa - Configure equipment defaults
  sb VolumePump Setting 1                                   # Pump 1 l/t into greenhouse when there's a call for air fill
  sb WaterPump Setting 10                                   # Pump 10 l/t into greenhouse when there's a call for air fill
  sb GasMixer Setting 50                                    # Init to 50/50 split
  sbn ActiveVent FiltrationName Mode 1                      # Active vent INWARD to pull air (otherwise, we're going to pop the greenhouse)
  sbn ActiveVent FiltrationName PressureInternal 30000      # Try to run filtration at high efficiency

  sb AccessReader Color Orange                              # Orange LED means extended functions are set up

  
##################################################################################
#  Application Code - Runs system normally, for both Standard and Extended modes #
##################################################################################
  
section application requires definitions
  
mode_idle:                                                  # Idle/Stop mode handler.  Lets the user select what crop to load, and extracts control values from stack to have ready for run mode handler
  beqz Unlocked lock_dial                                   # Only read in the crop select if unlocked
  lb CropSelect LogicDial Setting Sum
  
lock_dial:
  sb LogicDial Setting CropSelect                           # Then write our current crop select back to the dial (does nothing if we're unlocked as we'd be writing what it already was.  In locked mode, may do something)
  mul Scratch1 CropSelect CROPTABLE_STRIDE
  add sp Scratch1 Calc(SP_CROPTABLE+CROPTABLE_STRIDE)       # Now take the currently selected crop, load its bit-packed control data, and extract that to the stack variables
  pop Scratch1                                              # Then read on/off light times plus warning mask and store to stack
  ext Scratch2 Scratch1 0 TIME_BITFIELD_LEN
  poke SP_OFFTIME Scratch2
  ext Scratch2 Scratch1 TIME_BITFIELD_LEN TIME_BITFIELD_LEN
  poke SP_ONTIME Scratch2
  ext WarnMask Scratch1 ALARM_BITS_OFFSET ALARM_BITS_COUNT  #
  srl Scratch1 Scratch1 CROP_TEMP_BIT_IDX                   # Get happy temperature of plant
  add Scratch1 Scratch1 T_TWENTY_C
  sb AirConditioner Setting Scratch1                        # AC to crop setpoint
  poke Calc(4*ALARM_STRIDE+SP_TRIGGERTABLE+1) Scratch1      # Write crop desired temperature to alarms
  sub Scratch2 Scratch1 2
  poke Calc(14*ALARM_STRIDE+SP_TRIGGERTABLE+1) Scratch2     # Write crop heating setpoint to control rules
  add Scratch2 Scratch1 2
  poke Calc(15*ALARM_STRIDE+SP_TRIGGERTABLE+1) Scratch2     # Write crop cooling setpoint to control rules
  move Countdown 0                                          # Reset control state to "lights off, instant switch to day, no warnings"
  move LightsOn 0
  move WarnFlags 0
  move ControlFlags 0
  pop Scratch2
  poke SeedHash Scratch2
  pop Scratch2
  poke FruitHash Scratch2
  pop Scratch1                                              # Used all the way down in equip_ctrl to set crop title
  j update_common                                           # And jump to common update
  
mode_run:                                                   # Run mode handler.  Ticks lights, timer, and monitors alarms
  sb LogicDial Setting r15                                  # Keep the logic dial from turning during run
  sub Countdown Countdown EnabExtended                      # If running, first we decrement the current timer
  bgtz Countdown continue_countdown                         # If the countdown is positive, then we haven't reached the end of this day/night cycle step

no_period:                                                  # If the countdown HAS elapsed (or if the other step has a zero-tick step time) then we need to toggle the light state and reload the timer
  seqz LightsOn LightsOn                                    # Invert lights-on flag
  add Scratch1 LightsOn SP_OFFTIME                          # Load cycle step time, with table array math
  get Countdown db Scratch1
  beqz Countdown no_period                                  # If we got no time, re-do this to run the same step again WITHOUT updating the grow light (no flicker)
  poke LightStatus LightsOn
  
continue_countdown:                                         # During run we check a number of alarm conditions, and do so by reading out alarm definitions from the stack (saves on LoC)
  get sp db SP_ALARMTABLEINIT                               # Start by initializing the stack pointer to the end of the alarms array (pop does backwards through the stack)

next_alarm:   
  pop Scratch1                                              # Now for each alarm, first we pull the device PrefabHash.
  pop Scratch2                                              # Then we pull the LogicType to read
  lb Scratch3 Scratch1 Scratch2 Average                     # And we get the value via sum batch read
  pop Scratch1                                              # Now we pull the comparison args
  pop Scratch2                                              # If the second (Scratch2) is non-zero, we treat them as args to SAP.  If it IS zero, we treat the first arg as the comparison point for SLE
  sap Scratch4 Scratch3 Scratch1 Scratch2                   # The invert mask (applied later) lets us conditionally switch SAP and SLE for SNA and SGT (they are the logical inverses)
  sle Scratch3 Scratch3 Scratch1                            # Run both comparisons and then select between them
  select Scratch1 Scratch2 Scratch4 Scratch3                # Select based on whether Scratch2 is nonzero (i.e. if we want the SAP variant or not)
  sll WarnFlags WarnFlags 1
  ins WarnFlags Scratch1 0 1                                # We don't have an index reg, so bit-shift it in.
  bgt sp SP_TRIGGERTABLE next_alarm                         # If we're not at the start of the alarms table, we have further to go
  
end_alarms:
  xor WarnFlags WarnFlags WarnInverts                       # Once we finish the alarm list, apply invert mask, for the SAP/SLE -> SNA/SGT logical conversions.  And also rule inverts, for extended mode.
  and ControlFlags WarnFlags ControlMask                    # Extract all the equipment rules from the warnings and store
  and WarnFlags WarnFlags WarnMask                          # Now mask out warnings on a per-crop basis, by pulling the pre-set (from idle mode) mask flags.  Also clears leftover bits from the last scan for free
  or ControlFlags ControlFlags WarnFlags                    # Merge the masked warnings back into the control flags for later

update_common:                                              # Update the display with current config data, and do some common work such as alarms, mode select, unlock, stack updates, etc
  yield                                                     # Tick wait here for entire system
  get Scratch5 db SP_CARD_COLOR                             # Check if we're not using a card (> 12)
  sgt Scratch5 Scratch5 12                                  # Process Locked/Unlocked state, allowing perma-unlock if provisioned with no card
  lb Unlocked AccessReader Setting Sum                      # Check if the stop switch can be checked, by seeing if the card reader has the right card OR if Scratch1 is set (i.e. colour needed == -1)
  or Unlocked Unlocked Scratch5
  poke SP_UNLOCKED Unlocked
  select Scratch2 Unlocked Green Red                        # Change access reader colour based on unlock state
  sb AccessReader Color Scratch2                            # Access reader color = unlock state
  lb Scratch2 LogicSwitch Setting Sum                       # Set switch colour based on run state + unlock state
  seq Scratch4 Scratch2 Active                              # Scratch4 := Switch matches state
  select Scratch3 Active Green Red                          # Switch is Green if on + onlocked, red if off + unlocked (or if switch matches state)
  select Scratch5 Scratch4 Scratch3 Orange                  # If unlocked or matches, use unlocked colour.  If locked and mismatch, orange.
  select Scratch4 Unlocked Scratch3 Scratch5
  sb LogicSwitch Color Scratch4
  select Active Unlocked Scratch2 Active
  sb GrowLight On LightsOn                                  # Update lights with 'lights on' state
  add WarnTick WarnTick EnabExtended                        # Time up the warning iterate tick
  mod WarnTick WarnTick WarnTimescale                       # And modulus it by the iteration timescale
  sb StatusLight On Active                                  # Now update the status light with the current state
  select Scratch2 WarnFlags Orange Green                    # Orange if warning, Green if happy
  select Scratch2 Active Scratch2 Black                     # Black if idle
  sb StatusLight Color Scratch2                             # Including color
  get Scratch2 db SP_DISPLAY1
  sb LEDDisplay On Active                                   # And toggle displays based on active state
  s Scratch2 On 1                                           # Turn top display on all the time.  Due to how updates are processed, this will make the top display blink when the system is inactive
  get Scratch4 db SP_DISPLAY2                               # Then the RefID of the middle display
  beqz Active equip_ctrl                                    # If not active, jump to mode handler
  get Scratch2 db SP_DISPLAY3                               # Load RefID of bottom display
  
start_warnings:
  bgtz WarnWait nowarn                                      # Next if WarnWait is still ticking down, we don't show any warnings
  bnez WarnFlags haswarning                                 # Then if we *have* warnings, show them
  j nowarn                                                  # Otherwise we just jump to no-warnings.
  
warndone:
  move WarnWait WarnInterval                                # If we finished looping through all the warning flags or have no active warnings, we want to just display the normal screen for a bit
  
nowarn:
  sub WarnTick 0 EnabExtended                               # There are no warnings (or we completed the iteration), so reset timers and index
  move WarnIdx -1
  sub WarnWait WarnWait EnabExtended                        # Decrement warning wait timer (until we iterate through active warnings again)
  select Scratch3 LightsOn Str("Day") Str("Night")
  select Scratch5 LightsOn Yellow White
  s Scratch4 Color Scratch5
  move Scratch1 Countdown                                   # And then update display for time left in day/night cycle step
  s Scratch2 Color Pink
  s Scratch2 Mode Seconds
  j equip_ctrl                                              # Jump to equipment control handler
 
haswarning:                                                 # If we have a warning, then advance through the warning list after the iterate delay
  bnez WarnTick foundwarning                                # If WarnTick != 0, we're still in the wait period to keep the current warning readable, so don't advance through the list
next_warning:
  add WarnIdx WarnIdx 1                                     # Advance to the next warning index
  srl Scratch1 WarnFlags WarnIdx                            # Then, bit-shift out all of the warning flags we've iterated past
  beqz Scratch1 warndone                                    # Now check if there are any further warning flags to show - if not (Scratch1 == 0), branch to the end of warnings handler
  and Scratch1 Scratch1 1                                   # check if the current warning index is set
  beqz Scratch1 next_warning                                # If not, we need to iterate further to find the next set warning flag (while incrementing the index as well)
  
foundwarning:
  move Scratch3 Str("WARN")                                 # Display "WARN" text
  s Scratch4 Color Orange
  add Scratch1 WarnIdx SP_WARNTABLE                         # Now get the text correponding to the current displayed warning flag
  get Scratch1 db Scratch1                                  # by doing array index math and loading that stack index to Scratch1
  s Scratch2 Mode Text
  s Scratch2 Color Orange                                   # Lastly, fall through to equipment control handler
  
equip_ctrl:
  s Scratch2 Setting Scratch1
  s Scratch4 Setting Scratch3
  bne EnabExtended MODE_EXTENDED next_mode                  # Skip control handler if extended functions not enabled
  sb GlassDoor Open 0
  move sp Calc(RULE_COUNT*RULE_STRIDE+SP_RULESTABLE)
  
next_rule:
  pop Scratch1                                              # Pull rule definition from stack and then process
  ext Scratch2 Scratch1 0 COND_BITS_COUNT                   # Scratch2 = Conditions
  sra Scratch1 Scratch1 COND_BITS_COUNT                     # Scratch1 = PrefabHash
  pop Scratch3
  sra Scratch4 Scratch3 Calc(EXCL_BITS_COUNT+2)             # Scratch4 = NameHash
  ext Scratch5 Scratch3 EXCL_BITS_COUNT 2
  get Scratch5 db Scratch5                                  # Scratch5 = LogicType
  ext Scratch3 Scratch3 0 EXCL_BITS_COUNT                   # Scratch3 = Exclusions
  and Scratch3 Scratch3 ControlFlags                        # Rules are a pair of AND masks with the control flags.  Output = Scratch3 && !Scratch4
  and Scratch2 Scratch2 ControlFlags                        # It takes 8 LoC to unpack the rule and 5 to actually execute it..
  snez Scratch2 Scratch2
  select Scratch2 Scratch3 0 Scratch2
  sbn Scratch1 Scratch4 Scratch5 Scratch2                   # Output written to Mode/On/Open (based on rule) for device by prefab (based on rule) and name (based on rule)
  bgt sp SP_RULESTABLE next_rule                            # If we've got more rules to process, continue loop
  
next_mode:
  bnez Active mode_run                                      # Otherwise jump back to the active mode handler
  j mode_idle                                               # IC10 doesn't loop around to line 0 so jump
