section definitions

alias RefID       r0
alias Parameter   r1
alias Scratch     r2
alias Scratch2    r3
alias Scratch3    r4

alias Blinker     r12
alias Instruction r13
alias BlinkColor  r14
alias Accumulator r15

define Red        4
define Black      7

section application requires definitions

start:
  yield
  get sp db 0
  seqz Blinker Blinker
  
next_ins:
  pop Instruction
  ext ra Instruction 0 7
  ext RefID Instruction 7 23
  ext Parameter Instruction 30 23
  j ra
  
func_read_prop:                                     # Accumulator = RefID::Parameter
  l Accumulator RefID Parameter
  j next_ins

func_read_batch_prop:                               # Accumulator = <ReferenceId>(StackParam::Parameter) where ReferenceId is any of SUM, MIN, MAX, AVG
  pop Scratch
  lb Accumulator Scratch Parameter RefID
  j next_ins

func_read_named_prop:                               # Accumulator = batch named read
  pop Scratch
  pop Scratch2
  lbn Accumulator Scratch Scratch2 Parameter RefID

func_read_slot:                                     # Accumulator = RefID[StackParam]::Parameter
  pop r2
  ls Accumulator RefID Parameter r2
  j next_ins

func_read_named_slot:                               # Read slot of named object (always in SUM mode)
  pop Scratch
  pop Scratch2
  lbns Accumulator Scratch Scratch2 RefID Parameter Sum
  j next_ins

func_read_prop_mapped:                              # Accumulator = Stack[RefID::StackParameter + Parameter]
  pop Scratch
  l Accumulator RefID Scratch
  
func_read_table:                                    # Accumulator = Stack[Accumulator + Parameter]
  add Parameter Accumulator Parameter
  
func_read_own_stack:                                # Stack[Parameter] = Accumulator
  l RefID db ReferenceId
  
func_read_stack:                                    # Accumulator = RefID::Stack[Parameter]
  get Accumulator RefID Parameter
  j next_ins

func_read_param:                                    # Accumulator = RefID | (Parameter << 30)
  ext Accumulator Instruction 7 46
  j next_ins
  
func_sm_double:                                     # Accumulator = (Accumulator - StackParam1) * StackParam2
  pop RefID
  pop Parameter
  
func_sm_uint:                                       # Accumulator = (Accumulator - RefID) * Parameter
  sub Accumulator Accumulator RefID
  mul Accumulator Accumulator Parameter
  j next_ins
  
func_ad_uint:                                       # Accumulator = (Accumulator + RefID) / Parameter
  add Accumulator Accumulator RefID
  div Accumulator Accumulator Parameter
  j next_ins

func_move:                                          # Reg[RefID] = Reg[Parameter]; Only really useful for reading Blinker
  move rr0 rr1
  j next_ins

func_select_double:                                 # Accumulator = Accumulator ? StackParam1 : StackParam2
  pop r0
  pop r1
  
func_select_uint:                                   # Accumulator = Accumulator ? RefID : Parameter
  select Accumulator Accumulator r0 r1
  j next_ins

func_xfer2:                                         # RefID::Parameter = StackParam[10..32]::StackParam[0..9]
  pop ra
  ext Scratch ra 10 23
  ext ra ra 0 10
  l Accumulator Scratch ra
  j func_write_prop
  
func_xfer:                                          # Copy a LogicType value from StackParam::Parameter to RefID::Parameter
  pop Scratch
  l Accumulator Scratch Parameter

func_write_prop:                                    # RefID::Parameter = Accumulator
  s RefID Parameter Accumulator
  j next_ins

func_xfer_mode_on:                                  # "Common" function: transferring 'on' state from device to indicator
  l Accumulator RefID Mode
  j _write_on

func_xfer_on_on:                                    # "Common" function: transferring 'run' mode from device to indicator
  l Accumulator RefID On

_write_on:
  s Parameter On Accumulator
  j next_ins
  
func_write_slot:                                    # RefID[StackParam]::Parameter = Accumulator
  pop Scratch
  ss RefID Parameter Scratch Accumulator
  j next_ins

func_write_own_stack:                               # Stack[Parameter] = Accumulator
  l RefID db ReferenceId

func_write_stack:                                   # RefID::Stack[Parameter] = Accumulator
  put RefID Parameter Accumulator
  j next_ins

func_write_batch_prop:                              # BATCH(StackParam::Parameter) = Accumulator
  pop RefID
  sb RefID Parameter Accumulator
  j next_ins

func_write_named_prop:
  pop Scratch
  pop RefID
  sbn Scratch RefID Parameter Accumulator
  j next_ins

func_fixed:                                         # RefID::Parameter = StackParam
  pop Scratch
  s RefID Parameter Scratch
  j next_ins

func_bucket_map:                                    # Perform bucket classification using table starting at Stack[RefID] and proceeding DOWN the stack from there
  move ra sp                                        # Given a null-terminated list of sorted (Descending, by Key) Key:Value pairs, find the FIRST pair
  move sp RefID                                     # where Accumulator >= Key and return its matching Value.  Returns Parameter if no match found.
  
_next_bucket:
  pop Scratch2
  beqz Scratch2 _end_bucket
  pop Scratch3
  blt Accumulator Scratch2 _next_bucket
  move Parameter Scratch3
  
_end_bucket:
  move Accumulator Parameter
  move sp ra
  j next_ins
  
func_switch:                                        # RefID::Color = Stack[Parameter + RefID::Setting], Accumulator = RefID::Setting
  l Accumulator RefID Setting
  add Accumulator Accumulator Parameter
  get Accumulator db Accumulator
  s RefID Color Accumulator
  l Accumulator RefID Setting
  j next_ins
  
func_yield:                                         # Yield for a tick, if you need it for any particular reason
  yield
  j next_ins
  
func_dial_stack:                                    # Stack[Parameter] += RefID::Setting - 50; RefID::Maximum = 100; RefID::Setting = 50;
  get Accumulator db Parameter
  l Scratch RefID Setting
  add Accumulator Accumulator Scratch
  sub Accumulator Accumulator 50
  s RefID Maximum 100
  s RefID Setting 50
  put db Parameter Accumulator
  j next_ins

func_scaled_display_stack:                          # RefID::Setting = Stack[Parameter] * StackParam
  get Accumulator db Parameter
  
func_scaled_display_accumulator:                    # RefID::Setting = Accumulator * StackParam
  pop Scratch
  mul Accumulator Accumulator Scratch
  s RefID Setting Accumulator
  j next_ins

func_filter_blink:                                  # See below
  move Scratch2 1
  j _do_blink
  
func_gauge_blink:                                   # If Accumulator / 100 < (Parameter / 1000) { RefID::Setting = (IsFilterBlink ? 1 : Accumulator); RefID::Color = Blinker ? Red : Black } else { RefID::Setting = Accumulator, RefID::Color = Scratch }
  move Scratch2 Accumulator                         # To be used properly this function needs you to set Accumulator to the normal colour (might be a bucket classify), then reg_move that from r15 to r14

_do_blink:
  div Parameter Parameter 100
  bgt Accumulator Parameter _ok
  select BlinkColor Blinker Red Black
  move Accumulator Scratch2
  
_ok:
  s RefID Setting Accumulator
  s RefID Color BlinkColor
  j next_ins
