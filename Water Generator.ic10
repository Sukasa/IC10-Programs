section definitions

  define LiquidSensor       HASH("StructureLiquidPipeAnalyzer")
  define GasSensor          HASH("StructurePipeAnalysizer")
  define VolumePump         HASH("StructureVolumePump")
  define Liquidpump         HASH("StructureLiquidVolumePump")
  define Composter          HASH("StructureAdvancedComposter")

  define AlcoholSensor      HASH("Alcohol Tank")
  define BeerPump           HASH("Beer Feed")
  define OxyPump            HASH("Oxygen Feed")
  define SupplyAir          HASH("Oxygen Supply")

  alias OxyOkay             r0
  alias BeerOkay            r1

  alias Scratch1            r15
  alias Scratch2            r14

section application requires definitions

loop:
  select Scratch1 OxyOkay 15000 20000
  lbn Scratch2 GasSensor SupplyAir Pressure Sum
  sge OxyOkay Scratch2 Scratch1

  select Scratch1 BeerOkay 1 20
  lbn Scratch2 LiquidSensor AlcoholSensor VolumeOfLiquid Sum
  sge BeerOkay Scratch2 Scratch1

  and Scratch1 OxyOkay BeerOkay
  sbn VolumePump OxyPump On Scratch1
  sbn Liquidpump BeerPump On Scratch1

  lb Scratch1 Composter Quantity Sum
  sge Scratch1 Scratch1 3
  sb Composter Activate Scratch1

  yield
  j loop
