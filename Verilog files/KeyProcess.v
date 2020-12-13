
/*
 * Top
 * ----------------
 * By: MorseMeow
 * For: State machine based digital lock 
 * Date: May 2020
 *
 * Description
 * -----------
 * The module is a sublevel module to deal with the input key values, 
 * keyinput detection, generate timeout flag and set the timeout value.
 *
 * -------------------------------------------------------
 * Overtime clock count value calculation:
 * CLOCK_PERIOD = 1/CLOCK_FREQUENCY;                                 
 * CLOCK_COUNT_VALUE = TIME_OUTS_TIME/CLOCK_PERIOD;                  
 * so, CLOCK_COUNT_VALUE = TIME_OUTS_TIME*CLOCK_FREQUENCY;

 *--------------------------------------------------------
 */
 
module KeyProcess #(
    parameter KEY_WIDTH = 4,                                               //Number of Keys KEY[3:0]
    parameter KEY_NUMBERS = 6,                                             //The number of keys pressed, that is, the length of the password
    parameter KEY_NUMBERS_STORE_WIDTH = 3,                                 //The width of the number of keys stored
    parameter CLOCK_FREQUENCY = 50_000_000,                                //System clock frequency, in Hz
    parameter CLOCK_COUNT_SOTRE_WIDTH = 40,                                //Clock count storage width  
    parameter TIME_OUTS_TIME = 1                                           //Timeout time, in seconds
)(
    input                                     clock,                       //System clock, 50MHz
    input                                     reset_n,                     //Reset, active low
    input      [KEY_WIDTH-1:0]                keyInputValue,               //Single key input value
    input                                     keyInputClear,
    
    output reg [KEY_WIDTH*KEY_NUMBERS-1:0]    keyValueStore,               //Key input value storage
    output reg                                timeValueFlag,               //Timeout flag
    output reg [KEY_NUMBERS_STORE_WIDTH-1:0]  keyNumbersStore              //Store the number of keys pressed
);

reg [CLOCK_COUNT_SOTRE_WIDTH-1:0]             clockCountValueStore;        //Clock count storage
reg [KEY_WIDTH-1:0]                           KeyInputOneCycle;            //One cycle of key input is used for key edge detection 
reg [KEY_WIDTH-1:0]                           KeyInputDelayOneCycle;       //Key input delay one cycle for key edge detection

wire                                          keyInputFlag;                //Key input flag, 1 bit

localparam CLOCK_COUNT_VALUE = TIME_OUTS_TIME*CLOCK_FREQUENCY;             //Overtime clock count value calculation

//for test bench only - overtime count 
//localparam CLOCK_COUNT_VALUE = 500;

//clock count， timeout count
//When the key input flag is valid, clear the clockCountValueStore.
//When the value of the counter is less than the set clock timeout value, the counter value is +1
//when the timer is full, then clear the clockCountValueStore
always @ (posedge clock or posedge keyInputFlag or negedge reset_n) begin
    if (!reset_n) begin
        clockCountValueStore <= {(CLOCK_COUNT_SOTRE_WIDTH){1'b0}};           
    end else if (keyInputFlag) begin
        clockCountValueStore <= 1'b0;
    end else if (clockCountValueStore < CLOCK_COUNT_VALUE - 1) begin         
        clockCountValueStore <= clockCountValueStore + 1'b1;                 
    end else begin
        clockCountValueStore <= {(CLOCK_COUNT_SOTRE_WIDTH){1'b0}};
    end
end

//Generate key timeout flag
//The set timeout count value is full, Activate timeout flag. Active high. 
always @ (posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        timeValueFlag <= 1'b0;                                        
    end else if (clockCountValueStore == CLOCK_COUNT_VALUE - 1) begin            
        timeValueFlag <= 1'b1;                                             //Key timeout flag is valid        
        end else begin                                                         
        timeValueFlag <= 1'b0;                                             //Key timeout flag is invalid
    end
end

//Key edge detection. Detect whether the key is pressed, and generate a key input flag
//I refer to this method from SURF VHDL.
//The website is https://surf-vhdl.com/how-to-design-a-good-edge-detector/.
always @ (posedge clock or negedge reset_n) begin                            
    if (!reset_n) begin
        KeyInputOneCycle <= 1'b0;
        KeyInputDelayOneCycle <= 1'b0;
    end else begin
        KeyInputOneCycle <= keyInputValue;
        KeyInputDelayOneCycle <= KeyInputOneCycle;
    end
end
assign keyInputFlag = |((KeyInputOneCycle) & (~KeyInputDelayOneCycle));    //Determine whether the key input flag is generated, posedge edge detection

//Key input flag and key clear flag control key input
//when keyInputClear is actived by high level, the key value and numbers are cleared 
//when the keyInputFlag is actived by high level, the key numbers and values will be stored with registers. 
always @ (posedge keyInputClear or posedge keyInputFlag or negedge reset_n) begin
    if (!reset_n) begin
        keyValueStore = {(KEY_WIDTH*KEY_NUMBERS){1'b0}};                     
        keyNumbersStore = {(KEY_NUMBERS_STORE_WIDTH){1'b0}};                 
    end else if (keyInputClear) begin
        keyValueStore = {(KEY_WIDTH*KEY_NUMBERS){1'b0}};                     
        keyNumbersStore = {(KEY_NUMBERS_STORE_WIDTH){1'b0}};                 
    end else begin
        if (keyNumbersStore == KEY_NUMBERS) begin                            
            keyValueStore = 0;
            keyNumbersStore = 0;
        end else if (keyNumbersStore < KEY_NUMBERS) begin
            keyValueStore = keyValueStore << 4;                              
            keyValueStore [KEY_WIDTH-1:0] = keyInputValue; 
            keyNumbersStore = keyNumbersStore + 1'b1;                       
        end
    end
end


endmodule 
