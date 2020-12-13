
/*
 * Top
 * ----------------
 * By: MorseMeow
 * For: State machine based digital lock 
 * Date: May 2020
 *
 * Description
 * -----------
 * The module is a top level module to instantiates submodule instances 
 * and Make some connections between inputs and outputs.
 *
 * -------------------------------------------------------
 * Overtime clock count value calculation:
 * CLOCK_PERIOD = 1/CLOCK_FREQUENCY;                                 
 * CLOCK_COUNT_VALUE = TIME_OUTS_TIME/CLOCK_PERIOD;                  
 * so, CLOCK_COUNT_VALUE = TIME_OUTS_TIME*CLOCK_FREQUENCY;

 *--------------------------------------------------------
 */
 
module DigitalLock #(
    parameter KEY_WIDTH = 4,                                     //Number of Keys KEY[3:0]      
    parameter KEY_NUMBERS = 6,                                   //The number of keys pressed, that is, the length of the password                
    parameter KEY_NUMBERS_STORE_WIDTH = 3,                       //The width of the number of keys stored      
    parameter CLOCK_FREQUENCY = 50_000_000,                      //System clock frequency, in Hz      
    parameter CLOCK_COUNT_SOTRE_WIDTH = 40,                      //Clock count storage width          
    parameter TIME_OUTS_TIME = 5,                                //Timeout time, in seconds      
    parameter STATE_NUMBERS_SOTRE_WIDTH = 4,                     //state machine store width
    parameter SEGMENT_NUMBER = 7,                                //segment numbers of leds                               
    parameter BIT_WIDTH = 6,                                     //leds width                            
    parameter DELAY_TIME = 1                                     //maintain state time, in seconds                                      

)(
    input                                     clock,             //System clock, 50MHz  
    input                                     reset_n,           //Reset, active low  
    input   [KEY_WIDTH-1:0]                   keyInputValue_n,   //Single key input value  
    
    output  [SEGMENT_NUMBER*BIT_WIDTH-1:0]    ledDisplay_n       //led display outputs     
);


wire [KEY_WIDTH-1:0]                      keyInputValue;
wire [KEY_WIDTH*KEY_NUMBERS-1:0]          keyValueStore;
wire                                      timeValueFlag;
wire [KEY_NUMBERS_STORE_WIDTH-1:0]        keyNumbersStore;
wire [STATE_NUMBERS_SOTRE_WIDTH-1:0]      stateOutputs;            
wire                                      keyInputClear;

assign keyInputValue = ~keyInputValue_n;                         //convert key input value to active low            

//instantiates KeyProcess instances
KeyProcess #(
    .KEY_WIDTH                 (KEY_WIDTH                ),
    .KEY_NUMBERS               (KEY_NUMBERS              ),
    .KEY_NUMBERS_STORE_WIDTH   (KEY_NUMBERS_STORE_WIDTH  ),
    .CLOCK_FREQUENCY           (CLOCK_FREQUENCY          ),
    .CLOCK_COUNT_SOTRE_WIDTH   (CLOCK_COUNT_SOTRE_WIDTH  ),
    .TIME_OUTS_TIME            (TIME_OUTS_TIME           )
) myKeyProcess (
    .clock                     (clock                    ),
    .reset_n                   (reset_n                  ),
    .keyInputValue             (keyInputValue            ),
    .keyInputClear             (keyInputClear            ),
    .keyValueStore             (keyValueStore            ),
    .timeValueFlag             (timeValueFlag            ),
    .keyNumbersStore           (keyNumbersStore          )
);

//instantiates StateMachine instances
StateMachine #(
    .KEY_WIDTH                 (KEY_WIDTH                ),
    .KEY_NUMBERS               (KEY_NUMBERS              ),
    .KEY_NUMBERS_STORE_WIDTH   (KEY_NUMBERS_STORE_WIDTH  ),
    .CLOCK_FREQUENCY           (CLOCK_FREQUENCY          ),
    .CLOCK_COUNT_SOTRE_WIDTH   (CLOCK_COUNT_SOTRE_WIDTH  ),
    .STATE_NUMBERS_SOTRE_WIDTH (STATE_NUMBERS_SOTRE_WIDTH),
    .DELAY_TIME                (DELAY_TIME               )
) myStateMachine (
    .clock                     (clock                    ),
    .reset_n                   (reset_n                  ),
    .timeValueFlag             (timeValueFlag            ),
    .keyValueStore             (keyValueStore            ),
    .keyNumbersStore           (keyNumbersStore          ),
    .stateOutputs              (stateOutputs             ),
    .keyInputClear             (keyInputClear            )
    
);

//instantiates SevenSegmentLeds instances
SevenSegmentLeds #(
    .KEY_NUMBERS               (KEY_NUMBERS              ),
    .SEGMENT_NUMBER            (SEGMENT_NUMBER           ),
    .BIT_WIDTH                 (BIT_WIDTH                ),
    .KEY_WIDTH                 (KEY_WIDTH                ),
    .STATE_NUMBERS_SOTRE_WIDTH (STATE_NUMBERS_SOTRE_WIDTH)
) mySevenSegmentLeds (
    .keyValueStore             (keyValueStore            ),
    .stateOutputs              (stateOutputs             ),
    .ledDisplay_n              (ledDisplay_n             ) 
    
);


endmodule 
