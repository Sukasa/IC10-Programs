#########################################################################################################################################################
#                                                                                                                                                       #
# Stationeers Greenhouse rack control                                                                                                                   #
# Sectioned into "provision", "extended" and "application" programs, with a common definitions section                                                  #
# The former runs in-situ to set up the stack, the latter runs normally using the same IC10 afterwards (stack is non-volatile)                          #
# "extended" program enables Extended Mode by selectively updating some stack and register data                                                         #
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
#   - Monitors 10 different alarms, including Air/Water Temp; Air, CO2, O2, N2, Volatiles, and Pollutant levels, Power state, and water level           #
#   - Alarm monitoring takes into account selected crop type                                                                                            #
#   - Fully self-configuring with no device screw or code adjustments required*                                                                         #
#                                                                                                                                                       #
#   When configured in Extended Mode:                                                                                                                   #
#   - Provides Seed/Fruit item hash values for LArRE control via second IC (code to be provided in future)                                              #
#   - Controls Wall Heater, Wall Cooler, Liquid Wall Cooler, and Air Conditioner to maintain greenhouse temperature                                     #
#       - Atmospherics systems will be disabled in the event of low air pressure (poor efficiency) or low external power (APC discharging)              #
#   - Controls Active Vent, Volume Pump, and Gas Mixer to maintain pressure and cycle air contents                                                      #
#       - Active Vent will operate to reduce pressure, or pull stale air out to be replaced by fresher air.                                             #
#       - Active Vent will not operate if the air pressure runs low                                                                                     #
#       - Volume Pump and Gas Mixer enable when the greenhouse needs additional air fed in to maintain pressure                                         #
#   - Controls Liquid Pipe Heater to maintain water temperature                                                                                         #
#       - Heater will be disabled in the event of low external power (APC discharging)                                                                  #
#   - Automatically closes all Glass Doors on network to seal greenhouse                                                                                #
#                                                                                                                                                       #
# Setup: This program assumes you have Modular Consoles available.                                                                                      #
#        If you do not, changes the hashes referenced in the 'UI Devices' table below to be vanilla compatible                                          #
#        NOTE: There is no vanilla equivalent of the access card reader, and the controls locking will not be available                                 #
#        When building the controls, build the LED displays in order from BOTTOM TO TOP.  Otherwise, texts will appear in the wrong order               #
#        Use a Logic Mirror to bring the APC's data port onto the greenhouse network.                                                                   #
#                                                                                                                                                       #
#        Load the "Provisioning" code into an active IC10, and wait for the access reader light to change to CARD COLOR, or BLUE if no card.            #
#        If you are running in pure vanilla, you will have to just wait for 10 seconds or so to be sure.                                                #
#        Then (optionally) load the "extended" code and wait for the access reader light to change to PURPLE, to enable Extended Mode.                  #
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
  
  ### Variable Stack Addresses ####
  
  define Display1           0                     # Display 1 (Top) RefId
  define Display2           1                     # Display 2 (Mid) RefId
  define Display3           2                     # Display 3 (Bot) RefId
  define OffTime            3                     # Lights Off time in seconds
  define OnTime             4                     # Lights On time in seconds
  define AlarmTableInit     5                     # Where to start the alarm table scan at  
  define CardColor          6                     # Desired unlock card colour (-1 for none)
  define UnlockStatus       7                     # Unlocked status
  define LightStatus        8                     # Lights On/Off Status
#  define ActiveAlarms       9                     # Active (1 == off-nominal) warnings as bit array
  define SeedHash		        10                    # Hash for the seed item used to plant this plant
  define FruitHash		      11                    # Hash for the fruit item this plant produces
  
  ### Data Table Stack Addresses ####
  
  define CropTable          15                    # Table of crop names
  define TimesTable         40                    # Table of crop on/off times and warning masks
  define WarningTable       65                    # Table of warning text labels
  define DayTable           76                    # Table for day/night text
  define AlarmDefsStart     78                    # Table for warning rules
  define AlarmDefsEnd       118                   # End of standard alarms table + 1 for pop
  define ExtendedTables     118                   # Start of extended alarms table
  define ExtRulesEnd        150                   # End of "extended" alarms table + 1 used to control equipment as well as do alarms
  define SeedHashTable      150                   # Start of seed item hash table
  define FruitHashTable     175                   # Start of fruit item hash table
  define RuleTableStart     200                   # Equipment control rule table
  define RuleTableEnd       236                   # End of Equipment control table + 1 for pop
  
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
  define WallHeater         HASH("StructureWallHeater")
  define WallCooler         HASH("StructureWallCooler")
  define WallCooler2        HASH("StructureWaterWallCooler")
  define VolumePump         HASH("StructureVolumePump")
  define PressureReg        HASH("StructurePressureRegulator")
  define GasMixer           HASH("StructureGasMixer")
  define GlassDoor          HASH("StructureGlassDoor")
  
  ### Various constants used to shrink output program size ####
  
  define Blue               0                     # Colours
  define Gray               1
  define Green              2
  define Orange             3
  define Red                4
  define Yellow             5
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
  define On                 28
  define VolumeOfLiquid     182
  
  define CropsMax           24                    # Number of crop types defined -1
  define CropsStride        25                    # Number of crop types defined
  define WarnInterval       12                    # Interval in ticks between warning displays (must be a multiple of 2 and 3)
  define WarnTimescale      6                     # How many ticks to display each individual warning for (must be a multiple of 2 and 3)
  define WarnInverts        0b0011001010101101000 # Warning alarm/control rule invert masks (constant)
  define ControlMask        0b1111111100100001000 # Bits that are passed through for control flags regardless of alarm state
  
###############################################################################
#  Provisioning Code - Sets up NVRAM, learns unlock card color, maps displays #
###############################################################################

section provisioning requires definitions

  clr db

  move EnabExtended 2                             # Disable extended functions (== 2, as part of LoC optimization)
  poke AlarmTableInit AlarmDefsEnd                # Init alarm table start at normal end
  move sp Display1
  move Scratch1 -1
  
search:
  add Scratch1 Scratch1 1
  get Scratch2 db:0 Scratch1                      # Enumerate network devices, searching for LED displays
  l Scratch3 Scratch2 PrefabHash		              # Check if the last device we got an ID for is an LED display
  bne Scratch3 LEDDisplay search                  # This code doesn't check for end-of-IDs, so I don't know what it will do if it can't find three LED Displays
  push Scratch2                                   # This was a match, so save it to the current display index, and increment index (which is in sp)
  ble sp Display3 search                          # Continue search until we find all displays
  
init_tables:
  poke Calc(CropTable+0)   STR("Potato")
  poke Calc(CropTable+1)   STR("Soy")
  poke Calc(CropTable+2)   STR("Rice")
  poke Calc(CropTable+3)   STR("Tomato")
  poke Calc(CropTable+4)   STR("Wheat")
  poke Calc(CropTable+5)   STR("Fern")
  poke Calc(CropTable+6)   STR("Darga")
  poke Calc(CropTable+7)   STR("Cocoa")
  poke Calc(CropTable+8)   STR("Corn")
  poke Calc(CropTable+9)   STR("Pmpkn")
  poke Calc(CropTable+10)  STR("WnterA")
  poke Calc(CropTable+11)  STR("WnterB")
  poke Calc(CropTable+12)  STR("HadesA")
  poke Calc(CropTable+13)  STR("HadesB")
  poke Calc(CropTable+14)  STR("T Lily")
  poke Calc(CropTable+15)  STR("P Lily")
  poke Calc(CropTable+16)  STR("Sugar")
  poke Calc(CropTable+17)  STR("Flax")
  poke Calc(CropTable+18)  STR("Gorse")
  poke Calc(CropTable+19)  STR("Strbry")
  poke Calc(CropTable+20)  STR("Blubry")
  poke Calc(CropTable+21)  STR("Wtrmln")
  poke Calc(CropTable+22)  STR("Grass")
  poke Calc(CropTable+23)  STR("Mushrm")
  poke Calc(CropTable+24)  STR("Swcgrs")
  
                                                  #  100s = 00C8t Tick conversions
                                                  #  200s = 0190t
                                                  #  300s = 0258t
                                                  #  480s = 01E0t
                                                  #  500s = 01F4t
                                                  #  600s = 04B0t
                                                  # 1024s = 0800t
                                                  # 3600s = 1C20t
  
                                                  # Crop data table (Warn Mask, On Time, Off Time) (SP = 40)
  poke Calc(TimesTable+0)   0x02BF02580190        # 0x02BF << 32 | 300s << 16 |  200s Potato
  poke Calc(TimesTable+1)   0x02FF04B00258        # 0x02FF << 32 | 600s << 16 |  300s Soy
  poke Calc(TimesTable+2)   0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Rice
  poke Calc(TimesTable+3)   0x02BF01E00258        # 0x02BF << 32 | 480s << 16 |  300s Tomato
  poke Calc(TimesTable+4)   0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Wheat
  poke Calc(TimesTable+5)   0x02BF01E00258        # 0x02BF << 32 | 480s << 16 |  300s Fern
  poke Calc(TimesTable+6)   0x02BF01E00258        # 0x02BF << 32 | 480s << 16 |  300s Darga Fern
  poke Calc(TimesTable+7)   0x02BF01F40190        # 0x02BF << 32 | 500s << 16 |  200s Cocoa
  poke Calc(TimesTable+8)   0x02BF01F40190        # 0x02BF << 32 | 500s << 16 |  200s Corn
  poke Calc(TimesTable+9)   0x02BF01F400C8        # 0x02BF << 32 | 500s << 16 |  100s Pumpkin
  poke Calc(TimesTable+10)  0x023F04B00258        # 0x023F << 32 | 600s << 16 |  300s Winterspawn
  poke Calc(TimesTable+11)  0x023F04B00258        # 0x023F << 32 | 600s << 16 |  300s Winterspawn B
  poke Calc(TimesTable+12)  0x033304B00258        # 0x0333 << 32 | 600s << 16 |  300s Hades Flower
  poke Calc(TimesTable+13)  0x033304B00258        # 0x0333 << 32 | 600s << 16 |  300s Hades Flower B
  poke Calc(TimesTable+14)  0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Lily (T)
  poke Calc(TimesTable+15)  0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Lily (P)
  poke Calc(TimesTable+16)  0x02BF01F40190        # 0x02BF << 32 | 500s << 16 |  200s Sugarcane
  poke Calc(TimesTable+17)  0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Gorse
  poke Calc(TimesTable+18)  0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Flax
  poke Calc(TimesTable+19)  0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Strawberry
  poke Calc(TimesTable+20)  0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Blueberry
  poke Calc(TimesTable+21)  0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Watermelon
  poke Calc(TimesTable+22)  0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Grass
  poke Calc(TimesTable+23)  0x03B700001C20        # 0x03B7 << 32 |   0s << 16 | 3600s Mushroom
  poke Calc(TimesTable+24)  0x02BF04B00258        # 0x02BF << 32 | 600s << 16 |  300s Switchgrass

  poke Calc(WarningTable+0)  STR("Warn")          # Warnings table, SP = 65
  poke Calc(WarningTable+1)  STR("Power")         # Warnings table, SP = 66
  poke Calc(WarningTable+2)  STR("Wtr Lo")
  poke Calc(WarningTable+3)  STR("Tox Hi")
  poke Calc(WarningTable+4)  STR("CO2 Lo")
  poke Calc(WarningTable+5)  STR("A Temp")
  poke Calc(WarningTable+6)  STR("A Pres")
  poke Calc(WarningTable+7)  STR("N2 Low")
  poke Calc(WarningTable+8)  STR("Vol Hi")
  poke Calc(WarningTable+9)  STR("O2 Low")
  poke Calc(WarningTable+10) STR("W Temp")
  
  poke Calc(DayTable+0)      STR("Night")         # Day/Night labels, SP = 76
  poke Calc(DayTable+1)      STR("Day")

  #poke Calc(AlarmDefsStart+0) 0                   # 0 == SLE, SP = 78
  poke Calc(AlarmDefsStart+1) 2                   # Alarm if Mode <= 2
  poke Calc(AlarmDefsStart+2) Mode                # LogicType.Mode
  poke Calc(AlarmDefsStart+3) APC                 # APC (via Logic Mirror)
  #poke Calc(AlarmDefsStart+4) 0                   # 0 == SLE
  poke Calc(AlarmDefsStart+5) 0.5                 # Alarm if <= 0.5 l of water left
  poke Calc(AlarmDefsStart+6) VolumeOfLiquid      # LogicType.VolumeOfLiquid
  poke Calc(AlarmDefsStart+7) LiquidSensor        # Liquid Pipe Analyzer (direct)
  #poke Calc(AlarmDefsStart+8) 0                   # 0 == SLE
  poke Calc(AlarmDefsStart+9) 0.001               # Alarm if over 0.1 % Pollutant
  poke Calc(AlarmDefsStart+10) RatioPollutant     # LogicType.RatioPollutant
  poke Calc(AlarmDefsStart+11) GasSensor          # Gas Sensor
  #poke Calc(AlarmDefsStart+12) 0                  # 0 == SLE
  poke Calc(AlarmDefsStart+13) 0.03               # Alarm if less than 3 % CO2
  poke Calc(AlarmDefsStart+14) RatioCarbonDioxide # LogicType.RatioCarbonDioxide
  poke Calc(AlarmDefsStart+15) GasSensor          # Gas Sensor
  poke Calc(AlarmDefsStart+16) 0.016              # Rough guesstimate for the SAP range (c) val
  poke Calc(AlarmDefsStart+17) 298                # Alarm if too far away from 25 Deg.C
  poke Calc(AlarmDefsStart+18) Temperature        # LogicType.Temperature
  poke Calc(AlarmDefsStart+19) GasSensor          # Gas Sensor
  poke Calc(AlarmDefsStart+20) 0.3                # Rough guesstimate for the SAP range (c) val
  poke Calc(AlarmDefsStart+21) 75                 # Alarm if too far away from 75kPa
  poke Calc(AlarmDefsStart+22) Pressure           # LogicType.Pressure
  poke Calc(AlarmDefsStart+23) GasSensor          # Gas Sensor
  #poke Calc(AlarmDefsStart+24) 0                  # 0 == SLE
  poke Calc(AlarmDefsStart+25) 0.03               # Alarm if Less than 3 % N2 gas
  poke Calc(AlarmDefsStart+26) RatioNitrogen      # LogicType.RatioNitrogen
  poke Calc(AlarmDefsStart+27) GasSensor          # Gas Sensor
  #poke Calc(AlarmDefsStart+28) 0                  # 0 == SLE
  poke Calc(AlarmDefsStart+29) 0.001              # Alarm if over 0.1 % Volatiles
  poke Calc(AlarmDefsStart+30) RatioVolatiles     # LogicType.RatioVolatiles
  poke Calc(AlarmDefsStart+31) GasSensor          # Gas Sensor
  #poke Calc(AlarmDefsStart+32) 0                  # 0 == SLE
  poke Calc(AlarmDefsStart+33) 0.015              # Alarm if less then 1.5 % Oxygen
  poke Calc(AlarmDefsStart+34) RatioOxygen        # LogicType.RatioOxygen
  poke Calc(AlarmDefsStart+35) GasSensor          # Gas Sensor
  poke Calc(AlarmDefsStart+36) 0.08               # Rough guesstimate for the SAP range (c) val
  poke Calc(AlarmDefsStart+37) 305.65             # Alarm if too far away from 32.5 Deg.C
  poke Calc(AlarmDefsStart+38) Temperature        # LogicType.Temperature
  poke Calc(AlarmDefsStart+39) LiquidSensor       # Liquid Pipe Analyzer (direct).  After this, further data is defined in the extended section
  
learn_card:
  move Scratch3 -1                                # Now scan for the inserted card's color.  Or flag if we don't lock w/ a card, via -1
  
card_search:
  add Scratch3 Scratch3 1                         # Loop through all of the known card colours, and see if the inserted card matches one of them
  sb AccessReader Mode Scratch3                   # When we find a match, store that as the "required" card colour to unlock the controls
  yield
  lb Scratch2 AccessReader Setting Sum
  bgt Scratch3 12 complete_provision              # If we don't find one by the end of the colour reset, re-check in case the card was removed mid search
  beqz Scratch2 card_search                                 

complete_provision:
  poke CardColor Scratch3                         # Card found (or no card inserted); save the current colour (or sentinel value) to stack index
  sb LogicDial Mode CropsMax                      # Set up the logic dial's maximum to be the crop limit
  sb LEDDisplay Mode Text                         # All LED displays to text mode to start
  sb LEDDisplay Color Purple                      # All LED displays to purple text
  
provision_wait_loop:
  sb AccessReader Color Scratch3                  # Colour is .... Blue: No Lock, Gray: Card Lock
  lbs Scratch4 AccessReader 0 Occupied Sum        # Check if a card is inserted
  bnez Scratch4 learn_card                        # If we insert a card late, still let it be learned
  j provision_wait_loop                           # (Leaving a card inserted just wastes cycles, but doesn't break anything)
  
##########################################################################
#  Extended Provisioning Code - optional data for expanded functions
########################################################################## 

section extended requires definitions
  
  move EnabExtended 3                             # Enable extended functions (==3)
  move sp ExtendedTables
  poke AlarmTableInit ExtRulesEnd                 # Init alarm table start at extended end
 
  #poke Calc(AlarmDefsStart+40) 0                                          # 0 == SLE, SP = 118
  poke Calc(AlarmDefsStart+41) 0.15                                       # Flag if less than 15% CO2
  poke Calc(AlarmDefsStart+42) RatioCarbonDioxide                         # LogicType.RatioCarbonDioxide
  poke Calc(AlarmDefsStart+43) GasSensor                                  # Gas Sensor
  #poke Calc(AlarmDefsStart+44) 0                                          # 0 == SLE
  poke Calc(AlarmDefsStart+45) 0.55                                       # Flag if less than 55% O2 (inverted to "at least")
  poke Calc(AlarmDefsStart+46) RatioOxygen                                # LogicType.RatioOxygen
  poke Calc(AlarmDefsStart+47) GasSensor                                  # Gas Sensor
  #poke Calc(AlarmDefsStart+48) 0                                          # 0 == SLE
  poke Calc(AlarmDefsStart+49) 293.15                                     # Flag if water less than 20 Deg.C
  poke Calc(AlarmDefsStart+50) Temperature                                # LogicType.Temperature
  poke Calc(AlarmDefsStart+51) LiquidSensor                               # Gas Sensor
  #poke Calc(AlarmDefsStart+52) 0                                          # 0 == SLE
  poke Calc(AlarmDefsStart+53) 293.15                                     # Flag if air temp less than 20 Deg.C
  poke Calc(AlarmDefsStart+54) Temperature                                # LogicType.Temperature
  poke Calc(AlarmDefsStart+55) GasSensor                                  # Gas Sensor
  #poke Calc(AlarmDefsStart+56) 0                                          # 0 == SLE
  poke Calc(AlarmDefsStart+57) 308.15                                     # Flag if air temp less than 35 Deg.C (inverted to "at least")
  poke Calc(AlarmDefsStart+58) Temperature                                # LogicType.Temperature
  poke Calc(AlarmDefsStart+59) GasSensor                                  # Gas Sensor
  #poke Calc(AlarmDefsStart+60) 0                                          # 0 == SLE
  poke Calc(AlarmDefsStart+61) 95                                         # Flag if air pressure less than 95 kPa (inverted to "at least")
  poke Calc(AlarmDefsStart+62) Pressure                                   # LogicType.Pressure
  poke Calc(AlarmDefsStart+63) GasSensor                                  # Gas Sensor
  #poke Calc(AlarmDefsStart+64) 0                                          # 0 == SLE
  poke Calc(AlarmDefsStart+65) 45                                         # Flag if air pressure less than 45 kPa (extraction safety)
  poke Calc(AlarmDefsStart+66) Pressure                                   # LogicType.Pressure
  poke Calc(AlarmDefsStart+67) GasSensor                                  # Gas Sensor
  #poke Calc(AlarmDefsStart+68) 0                                          # 0 == SLE
  poke Calc(AlarmDefsStart+69) 80                                         # Flag if air pressure less than 80 kPa (call to fill with air)
  poke Calc(AlarmDefsStart+70) Pressure                                   # LogicType.Pressure
  poke Calc(AlarmDefsStart+71) GasSensor                                  # Gas Sensor
  
  poke Calc(SeedHashTable+0)  HASH("SeedBag_Potato")                       # Seed Hash Table, SP = 150
  poke Calc(SeedHashTable+1)  HASH("SeedBag_Soybean")
  poke Calc(SeedHashTable+2)  HASH("SeedBag_Rice")
  poke Calc(SeedHashTable+3)  HASH("SeedBag_Tomato")
  poke Calc(SeedHashTable+4)  HASH("SeedBag_Wheet")
  poke Calc(SeedHashTable+5)  HASH("SeedBag_Fern")
  poke Calc(SeedHashTable+6)  HASH("SeedBag_DargaFern")
  poke Calc(SeedHashTable+7)  HASH("SeedBag_Cocoa")
  poke Calc(SeedHashTable+8)  HASH("SeedBag_Corn")
  poke Calc(SeedHashTable+9)  HASH("SeedBag_Pumpkin")
  poke Calc(SeedHashTable+10) HASH("SeedBag_WinterspawnAlpha")
  poke Calc(SeedHashTable+11) HASH("SeedBag_WinterspawnBeta")
  poke Calc(SeedHashTable+12) HASH("SeedBag_HadesAlpha")
  poke Calc(SeedHashTable+13) HASH("SeedBag_HadesBeta")
  poke Calc(SeedHashTable+14) HASH("ItemTropicalPlant")
  poke Calc(SeedHashTable+15) HASH("ItemPeaceLily")
  poke Calc(SeedHashTable+16) HASH("SeedBag_SugarCane")
  poke Calc(SeedHashTable+17) HASH("ItemFlax")
  poke Calc(SeedHashTable+18) HASH("ItemGorse")
  poke Calc(SeedHashTable+19) HASH("SeedBag_Strawberry")
  poke Calc(SeedHashTable+20) HASH("SeedBag_Blueberry")
  poke Calc(SeedHashTable+21) HASH("SeedBag_Watermelon")
  poke Calc(SeedHashTable+22) HASH("ItemGrass")
  poke Calc(SeedHashTable+23) HASH("SeedBag_Mushroom")
  poke Calc(SeedHashTable+24) HASH("ItemPlantSwitchGrass")
  
  poke Calc(FruitHashTable+0)  HASH("ItemPotato")                         # Fruit Hash Table, SP = 175
  poke Calc(FruitHashTable+1)  HASH("ItemSoybean")
  poke Calc(FruitHashTable+2)  HASH("ItemRice")
  poke Calc(FruitHashTable+3)  HASH("ItemTomato")
  poke Calc(FruitHashTable+4)  HASH("ItemWheat")
  poke Calc(FruitHashTable+5)  HASH("ItemFern")
  poke Calc(FruitHashTable+6)  HASH("ItemFilterFern")
  poke Calc(FruitHashTable+7)  HASH("ItemCocoaTree")
  poke Calc(FruitHashTable+8)  HASH("ItemCorn")
  poke Calc(FruitHashTable+9)  HASH("ItemPumpkin")
  poke Calc(FruitHashTable+10) HASH("ItemPlantEndothermic_Genepool1")
  poke Calc(FruitHashTable+11) HASH("ItemPlantEndothermic_Genepool2")
  poke Calc(FruitHashTable+12) HASH("ItemPlantThermogenic_Genepool1")
  poke Calc(FruitHashTable+13) HASH("ItemPlantThermogenic_Genepool2")
  poke Calc(FruitHashTable+14) HASH("ItemTropicalPlant")
  poke Calc(FruitHashTable+15) HASH("ItemPeaceLily")
  poke Calc(FruitHashTable+16) HASH("ItemSugarCane")
  poke Calc(FruitHashTable+17) HASH("ItemFlax")
  poke Calc(FruitHashTable+18) HASH("ItemGorse")
  poke Calc(FruitHashTable+19) HASH("ItemStrawberry")
  poke Calc(FruitHashTable+20) HASH("ItemBlueberry")
  poke Calc(FruitHashTable+21) HASH("ItemWatermelon")
  poke Calc(FruitHashTable+22) HASH("ItemGrass")
  poke Calc(FruitHashTable+23) HASH("ItemMushroom")
  poke Calc(FruitHashTable+24) HASH("ItemPlantSwitchGrass")

                                                  # Table used to build rule masks (control, alarm, invert)
                                                  #   /- Air Pressure < 80 kPa
                                                  #   |/- Air Pres < 45kPa
                                                  #   ||/- Air Pres > 95kPa
                                                  #   |||/- Air Temp > 30C
                                                  #   ||||/- Air Temp < 20C
                                                  #   |||||/- Water Temp < 20C
                                                  #   ||||||/- O2 > 55%
                                                  #   |||||||/- CO2 < 15%
                                                  #   ||||||||/- Bad Water Temp Alarm
                                                  #   |||||||||/- Low O2 Alarm
                                                  #   ||||||||||/- High Volatiles Alarm
                                                  #   |||||||||||/- Low N2 Alarm
                                                  #   ||||||||||||/- Bad Pressure Alarm
                                                  #   |||||||||||||/- Bad Air Temp Alarm
                                                  #   ||||||||||||||/- Low CO2 Alarm
                                                  #   |||||||||||||||/- High Pollutant Alarm
                                                  #   ||||||||||||||||/- Low Water Alarm
                                                  #   |||||||||||||||||/- Power Alarm
                                                  #   ||||||||||||||||||/- Reserved
                                                  # 0b0000100000000000000

# Equipment Control Table, SP = 200
  poke Calc(RuleTableStart+0) 0b01000000000000000100000100000000000000   # Run if air temp <= 20C while not low power or low air pressure
  poke Calc(RuleTableStart+1) On                                         # LogicType.On
  poke Calc(RuleTableStart+2) WallHeater
  poke Calc(RuleTableStart+3) 0b01000000000000000100001000000000000000   # Run if air temp > 30C while not low power or low air pressure
  poke Calc(RuleTableStart+4) On                                         # LogicType.On
  poke Calc(RuleTableStart+5) WallCooler
  poke Calc(RuleTableStart+6) 0b01000000000000000100001000000000000000   # Run if air temp > 30C while not low power or low air pressure
  poke Calc(RuleTableStart+7) On                                         # LogicType.On
  poke Calc(RuleTableStart+8) WallCooler2
  poke Calc(RuleTableStart+9) 0b01000000000000000100001100000000100000   # Run if air temp > 30C or <= 20C or "bad" while not low power or low air pressure
  poke Calc(RuleTableStart+10) Mode                                       # LogicType.Mode
  poke Calc(RuleTableStart+11) AirConditioner
  poke Calc(RuleTableStart+12) 0b01000000000000000100011001100111011000   # Active vent on if air pressure high or o2 level high or air alarm while not low power or low air pressure
  poke Calc(RuleTableStart+13) On                                         # LogicType.On
  poke Calc(RuleTableStart+14) ActiveVent
  poke Calc(RuleTableStart+15) 0b00000000000000000100000010000000000000   # Liquid heater on if water temp <= 20C while not low power
  poke Calc(RuleTableStart+16) On                                         # LogicType.On
  poke Calc(RuleTableStart+17) LiquidHeater
  poke Calc(RuleTableStart+18) 0b00000000000000000001000000000000000000   # Volume pump on if low pressure
  poke Calc(RuleTableStart+19) On                                         # LogicType.On
  poke Calc(RuleTableStart+20) VolumePump
  poke Calc(RuleTableStart+21) 0b00100000000000000001100001010100100000   # Gas Mixer on if low pressure, Low Gases, while not high pressure
  poke Calc(RuleTableStart+22) On                                         # LogicType.On
  poke Calc(RuleTableStart+23) GasMixer
  poke Calc(RuleTableStart+24) 0b00000000000000000000000000000000000000   # Door always closed (every 2 or 3 ticks, enough time to get in)
  poke Calc(RuleTableStart+25) Open                                       # LogicType.Open
  poke Calc(RuleTableStart+26) GlassDoor                                  # Glass door, SP = 236
  
  sb AccessReader Color Purple                    # Purple LED means extended functions are set up
  sb PressureReg Setting 95                       # Regulator to 95kPa - Configure equipment defaults
  sb AirConditioner Setting 298.15                # AC to 25C
  sb VolumePump Setting 5                         # Pump 5 l/t into greenhouse when there's a call for air fill
  sb GasMixer Setting 50                          # Init to 50/50 split
  sb ActiveVent Mode 1                            # Active vent INWARD to pull air (otherwise, we're going to pop the greenhouse)
  
end_extended:
  j end_extended
  
  
##################################################################################
#  Application Code - Runs system normally, for both Standard and Extended modes #
##################################################################################
  
section application requires definitions
  
mode_idle:                                        # Idle/Stop mode handler.  Lets the user select what crop to load, and extracts control values from stack to have ready for run mode handler
  beqz Unlocked lock_dial                         # Only read in the crop select if unlocked
  lb CropSelect LogicDial Setting Sum
  
lock_dial:
  sb LogicDial Setting CropSelect                 # Then write our current crop select back to the dial (does nothing if we're unlocked as we'd be writing what it already was.  In locked mode, may do something)
  add Scratch1 CropSelect TimesTable              # Now take the currently selected crop, load its bit-packed control data, and extract that to the stack variables
  get Scratch1 db Scratch1                        # Then read on/off light times plus warning mask and store to stack
  ext Scratch2 Scratch1 0 16
  poke OffTime Scratch2
  ext Scratch2 Scratch1 16 16
  poke OnTime Scratch2
  ext WarnMask Scratch1 31 16                     # Intentionally off by one, since the result of the LSB technically maps to "no warning", so it's not useful or worth storing

  # TODO need to read temp SP and write to AC somehow

  move Countdown 0                                # Reset control state to "lights off, instant switch to day, no warnings"
  move LightsOn 0
  move WarnFlags 0
  bne EnabExtended 3 update_common                # Don't update hash data if in Standard mode (tables not initialized)
  add Scratch1 SeedHashTable CropSelect           # Read Seed/Fruit hash tables and store for LArRE
  get Scratch2 db Scratch1
  poke SeedHash Scratch2
  add Scratch1 Scratch1 CropsStride
  get Scratch2 db Scratch1
  poke FruitHash Scratch2
  j update_common                                 # And jump to common update
  
mode_run:                                         # Run mode handler.  Ticks lights, timer, and monitors alarms
  sb LogicDial Setting r15                        # Keep the logic dial from turning during run
  sub Countdown Countdown EnabExtended            # If running, first we decrement the current timer
  bgtz Countdown continue_countdown               # If the countdown is positive, then we haven't reached the end of this day/night cycle step

no_period:                                        # If the countdown HAS elapsed (or if the other step has a zero-tick step time) then we need to toggle the light state and reload the timer
  seqz LightsOn LightsOn                          # Invert lights-on flag
  add Scratch1 LightsOn OffTime                   # Load cycle step time, with table array math
  get Countdown db Scratch1
  beqz Countdown no_period                        # If we got no time, re-do this to run the same step again WITHOUT updating the grow light (no flicker)
  
continue_countdown:                               # During run we check a number of alarm conditions, and do so by reading out alarm definitions from the stack (saves on LoC)
  get sp db AlarmTableInit                        # Start by initializing the stack pointer to the end of the alarms array (pop does backwards through the stack)

next_alarm:   
  pop Scratch1                                    # Now for each alarm, first we pull the device PrefabHash.
  pop Scratch2                                    # Then we pull the LogicType to read
  lb Scratch3 Scratch1 Scratch2 Sum               # And we get the value via sum batch read
  pop Scratch1                                    # Now we pull the comparison args
  pop Scratch2                                    # Two of them.  If the second (Scratch2) is non-zero, we treat them as args to an SAP opcode.  If it IS zero, we treat the first arg as the comparison point for an SLE opcode
  sap Scratch4 Scratch3 Scratch1 Scratch2         # The invert mask (applied later) lets us conditionally switch SAP and SLE for SNA and SGT (they are the logical inverses)
  sle Scratch3 Scratch3 Scratch1                  # Run both comparisons and then select between them
  select Scratch1 Scratch2 Scratch4 Scratch3      # Select based on whether Scratch2 is nonzero (i.e. if we want the SAP variant or not)
  ins WarnFlags Scratch1 0 1                      # We don't have an index reg, so bit-shift it in.  We insert THEN shift, since the LSB is the no alarm bit at the end so needs to remain reserved
  sll WarnFlags WarnFlags 1
  bgt sp AlarmDefsStart next_alarm                # If we're not at the start of the alarms table, we have further to go
  
end_alarms:
  xor WarnFlags WarnFlags WarnInverts             # Once we finish the alarm list, apply invert mask, for the SAP/SLE -> SNA/SGT logical conversions.  And also rule inverts, for extended mode.
  and ControlFlags WarnFlags ControlMask          # Extract all the equipment rules from the warnings and store
  and WarnFlags WarnFlags WarnMask                # Now mask out warnings on a per-crop basis, by pulling the pre-set (from idle mode) mask flags.  Also clears leftover bits from the last scan for free
  or ControlFlags ControlFlags WarnFlags          # Merge the masked warnings back into the control flags for later

update_common:                                    # Update the display with current config data, and do some common work such as alarms, mode select, unlock, stack updates, etc
  yield                                           # Tick wait here for entire system
  get Scratch1 db CardColor                       # Check if we're not using a card (> 12)
  sgt Scratch1 Scratch1 12                        # Process Locked/Unlocked state, allowing perma-unlock if provisioned with no card
  lb Unlocked AccessReader Setting Sum            # Check if the stop switch can be checked, by seeing if the card reader has the right card OR if Scratch1 is set (i.e. colour needed == -1)
  or Unlocked Unlocked Scratch1
  poke UnlockStatus Unlocked
  select Scratch1 Unlocked Green Red              # Change access reader colour based on unlock state
  sb AccessReader Color Scratch1                  # Access reader color = unlock state
  lb Scratch1 LogicSwitch Setting Sum             # Set switch colour based on run state + unlock state
  seq Scratch4 Scratch1 Active                    # Scratch1 := Switch matches state
  select Scratch3 Active Green Red                # Switch is Green if on + onlocked, red if off + unlocked (or if switch matches state)
  select Scratch2 Scratch4 Scratch3 Orange        # If unlocked or matches, use unlocked colour.  If locked and mismatch, orange.
  select Scratch4 Unlocked Scratch3 Scratch2
  sb LogicSwitch Color Scratch4
  select Active Unlocked Scratch1 Active
  
is_locked:                                        # If the switch is locked we skip reading active state, and move on to updating the displays
  sb GrowLight On LightsOn                        # Update lights with 'lights on' state
  poke LightStatus LightsOn
  add WarnTick WarnTick EnabExtended              # Time up the warning iterate tick
  mod WarnTick WarnTick WarnTimescale             # And modulus it by the iteration timescale
  sb StatusLight On Active                        # Now update the status light with the current state
  select Scratch1 WarnFlags Orange Green          # Orange if warning, Green if happy
  select Scratch1 Active Scratch1 Black           # Black if idle
  sb StatusLight Color Scratch1                   # Including color
  add Scratch1 CropSelect CropTable
  get Scratch1 db Scratch1                        # Write the name of the selected crop to the top display
  get Scratch2 db Display1
  sb LEDDisplay On Active                         # And toggle displays based on active state
  s Scratch2 On 1                                 # Turn top display on all the time.  Due to how updates are processed, this will make the top display blink when the system is inactive
  beqz Active equip_ctrl                          # If not active, jump to mode handler
  
start_warnings:
  get Scratch4 db Display2                        # Then the RefID of the middle display
  get Scratch2 db Display3                        # Load RefID of bottom display
  bgtz WarnWait nowarn                            # Next if WarnWait is still ticking down, we don't show any warnings
  bnez WarnFlags haswarning                       # Then if we *have* warnings, show them
  j nowarn                                        # Otherwise we just jump to no-warnings.
  
warndone:
  move WarnWait WarnInterval                      # If we finished looping through all the warning flags or have no active warnings, we want to just display the normal screen for a bit
  
nowarn:
  sub WarnTick 0 EnabExtended                     # There are no warnings (or we completed the iteration), so reset timers and index
  move WarnIdx 0
  sub WarnWait WarnWait EnabExtended              # Decrement warning wait timer (until we iterate through active warnings again)
  add Scratch1 LightsOn DayTable                  # Now update display for day/night display
  get Scratch3 db Scratch1
  s Scratch4 Color Purple
  srl Scratch1 Countdown 1                       # And then update display for time left in day/night cycle step
  s Scratch2 Color Pink
  s Scratch2 Mode Seconds
  j equip_ctrl                                    # Jump to equipment control handler
 
haswarning:                                       # If we have a warning, then advance through the warning list after the iterate delay
  bnez WarnTick foundwarning                      # If WarnTick != 0, we're still in the wait period to keep the current warning readable, so don't advance through the list
  add WarnIdx WarnIdx 1                           # Advance to the next warning index
  srl Scratch1 WarnFlags WarnIdx                  # Then, bit-shift out all of the warning flags we've iterated past
  beqz Scratch1 warndone                          # Now check if there are any further warning flags to show - if not (Scratch1 == 0), branch to the end of warnings handler
  and Scratch2 Scratch1 1                         # check if the current warning index is set
  beqz Scratch2 haswarning                        # If not, we need to iterate further to find the next set warning flag (while incrementing the index as well)
  
foundwarning:
  get Scratch3 db WarningTable                    # Display "WARN" text, first by getting the warning teext
  s Scratch4 Color Orange
  add Scratch1 WarnIdx WarningTable               # Now get the text correponding to the current displayed warning flag
  get Scratch1 db Scratch1                        # by doing array index math and loading that stack index to Scratch1
  s Scratch2 Mode Text
  s Scratch2 Color Orange                         # Lastly, fall through to equipment control handler
  
equip_ctrl:
  s Scratch2 Setting Scratch1
  s Scratch4 Setting Scratch3
  bne EnabExtended 3 next_mode                    # Skip control handler if extended functions not enabled
  move sp RuleTableEnd
  
next_rule:
  pop Scratch1                                    # Pull rule definition from stack and then process
  pop Scratch2
  pop Scratch3
  srl Scratch4 Scratch3 19
  and Scratch3 Scratch3 ControlFlags              # Rules are a pair of AND masks with the control flags.  Output = Scratch3 && !Scratch4
  and Scratch4 Scratch4 ControlFlags
  snez Scratch3 Scratch3
  select Scratch3 Scratch4 0 Scratch3
  sb Scratch1 Scratch2 Scratch3                   # Output written to Mode/On (based on rule) for device by prefab hash (based on rule)
  bgt sp RuleTableStart next_rule                 # If we've got more rules to process, continue loop
  
next_mode:
  bnez Active mode_run                            # Otherwise jump back to the active mode handler
  j mode_idle                                     # IC10 doesn't loop around to line 0, unfortunately.
