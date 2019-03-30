## Resolution
- 480*640 pixels
- 120*160 tiles

## Background Picture
- format : 
  - 480*640 12bit-RGB = 460800 Bytes

## Object
- attributes:
  1. *type: 2bits (0: player, 1: wall, 2: monster)*
  2. *shape: 2bits*
  3. *x_size: 8bits*
  4. *y_size: 7bits*
  5. *color: 12bits RGB*
  6. *move_enable: 1bit*
  7. *control_enable: 1bit*
  8. *trail_length (number of tiles, >0 means being enabled): 15bits*
  9. *init_x_velocity*
  10. *init_y_velocity*
  11. *x*
  12. *y*
  13. visible / enable
  14. x_velocity
  15. y_velocity
  16. score
- max number of objects: 128, 2^7
- attributes in *Italian* are initially read from ROM 
- max number of players: 2
- players are always at the head of the object data

## Event Function
- dynamic functions for collision events
- read from ROM
- max number of functions: 64, 2^6
- format:
  - colliding obects
    - type: 2bits (0: type to type, 1: type to object | object to type, 2: object to object)
    - A_number: 7bits
    - B_number: 7bits
    - A_attribute: 4bits
    - B_attribute: 4bits
    - A_operation: 2bits (0: set to, 1:add, 2:mul)
    - B_operation: 2bits (0: set to, 1:add, 2:mul)
    - A_param: 8bits (signed number)
    - B_param: 8bits (signed number)

## ROM Data Format

- starting from the end of the memory, going up
- 1. background picture
  2. object number
  3. objects
  4. function number
  5. function

## MODULE objects_registers

- inputs:
  - wr_en: 1bit
  - obj_num: 7bits
  - obj_attr1: 4bits (wr_attr)
  - obj_attr2: 4bits
  - obj_attr3: 4bits
  - wr_value: 8bits
  - clk
  - reset
- outputs:
  - attr1_v: 8bits
  - attr2_v: 8bits
  - attr3_v: 8bits
- functionality:
  - store the current states and data of objects
  - basically is an array of registers
  - read 3 attributes from 1 object each time
  - write 1 attribute to the object each time

## MODULE functions_registers

- inputs:
  - funct_num: 6bits
  - clk
  - reset
- outputs:
  - type: 2bits 
  - A_num: 7bits
  - B_num: 7bits
  - A_attr: 4bits
  - B_attr: 4bits
  - A_op: 2bits
  - B_op: 2bits
  - A_param: 8bits
  - B_param: 8bits
- functionality:
  - store event functions
  - read only

## MODULE synthesizer

- inputs:
  - clk
  - vga_x
  - vga_y
- outputs:
  - red
  - green
  - blue
- functionality:
  - synthesize different layers to vga
    - background
    - objects
    - mouse cursor
  - render objects
    - judge whether this pixel lies in a object

## MODULE ROM_reader

 - inputs:
    - addr
    - bits
    - clk
- ouputs:
  - data: 16bits
- functionality:
  - read from the given number of bits from the address
  - always output 16bits data, the redundant bits are sign-extended

## MODULE PS2_receiver

 - inputs:

    - clk
    - kclk / PS2clk
    - kdata / PS2data
- outputs:

  - keycodeout
- functionality:
    - receive keyboard pressing
    - output corresponding keycodes

### MODULE debouncer

## MODULE keyboard_control

## MODULE movement_control

## MODULE collision_checker



