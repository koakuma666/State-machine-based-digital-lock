/*
 * Top
 * ----------------
 * By: MorseMeow
 * For: State machine based digital lock 
 * Date: May 2020
 *
 * Description
 * -----------
 * The module is a sublevel module to convert states, remain the display time and change the outputs. 
 *
 * -------------------------------------------------------
 * Overtime clock count value calculation:
 * CLOCK_PERIOD = 1/CLOCK_FREQUENCY;                                 
 * CLOCK_COUNT_VALUE = TIME_OUTS_TIME/CLOCK_PERIOD;                  
 * so, CLOCK_COUNT_VALUE = TIME_OUTS_TIME*CLOCK_FREQUENCY;

 *--------------------------------------------------------
 */
module StateMachine #(
    parameter KEY_WIDTH = 4,                                                  //Number of Keys KEY[3:0]
    parameter KEY_NUMBERS = 6,                                                //The number of keys pressed, that is, the length of the password
    parameter KEY_NUMBERS_STORE_WIDTH = 3,                                    //The width of the number of keys stored
    parameter CLOCK_FREQUENCY = 50_000_000,                                   //System clock frequency, in Hz
    parameter CLOCK_COUNT_SOTRE_WIDTH = 40,                                   //Clock count storage width   
    parameter STATE_NUMBERS_SOTRE_WIDTH = 4,                                  //state numbers store width
    parameter DELAY_TIME = 2                                                  //State transition delay timer, in seconds
)(  
    input                                      clock,                         //system clock, 50MHz
    input                                      reset_n,                       //reset, active low    
    input                                      timeValueFlag,                 //overtime flag    
    input [KEY_WIDTH*KEY_NUMBERS-1:0]          keyValueStore,                 //key input value store
    input [KEY_NUMBERS_STORE_WIDTH-1:0]        keyNumbersStore,               //Store the number of keys pressed

    output reg [3:0] stateOutputs,                                            //Every status outputs
    output reg       keyInputClear                                            //key input value clear
    
);

reg [CLOCK_COUNT_SOTRE_WIDTH-1:0]   clockCountValueStore;                     //Clock timing storage Used to remain the display of the intermediate state
reg [CLOCK_COUNT_SOTRE_WIDTH-1:0]   clockCountValueStoreDuringInput;          //Clock timing storage under input state Used to delay the display the last 6 digits of input
reg [STATE_NUMBERS_SOTRE_WIDTH-1:0] state;                                    //State storage register
reg [KEY_WIDTH*KEY_NUMBERS-1:0]     inputkeyValueStore;                       //Key input value storage
reg [KEY_WIDTH*KEY_NUMBERS-1:0]     keyValueStoreForComparison;               //The stored value of the key is used to compare whether the two keys are equal

localparam CLOCK_COUNT_VALUE = DELAY_TIME*CLOCK_FREQUENCY;                    //Delay time clock count value calculation
  
//for test bench only - maintaining time count 
//localparam CLOCK_COUNT_VALUE = 500;  

  
localparam UNLOCKED_STATE  = 4'd0;                                            //Initial state, showing unlocked
localparam UNLOCKED_KEY_INPUT_DISPLAY = 4'd1;                                 //Unlocked, the key input shows the digital status
localparam UNLOCKED_KEY_INPUT_OVERTIME = 4'd2;                                //Under the key input, the key input times out, and displays overtime
localparam RE_ENTER_STATE = 4'd3;                                             //Unlocked, the key input is complete, the first pass value is saved, and the re-enter is displayed
localparam RE_ENTER_KEY_INPUT_DISPLAY = 4'd4;                                 //Re-enter the key to enter the display number
localparam RE_ENTER_KEY_INPUT_OVERTIME = 4'd5;                                //RE-ENTER key input timeout, display overtime
localparam RE_ENTER_KEY_NOT_MATCH_ERROR = 4'd6;                               //In RE-ENTER, the second key input is compared with the first pass, it does not match, and error is displayed
localparam LOCKED_STATE = 4'd7;                                               //In RE-ENTER, the two input values match and enter the locked state
localparam LOCKED_STATE_KEY_INPUT_DISPLAY = 4'd8;                             //In the LOCKED state, the key input shows the number
localparam LOCKED_STATE_KEY_INPUT_OVERTIME = 4'd9;                            //In the locked state, the key input times out, and displays overtime
localparam LOCKED_STATE_NOT_MATCH_ERROR = 4'd10;                              //In the locked state, the key input does not match the stored second key input value, and error is displayed
localparam OPEN_STATE = 4'd11;                                                //In the LOCKED state, the key input matches the stored second key input value, and it is successfully unlocked, showing OPEN


//To remain the display intermediate status 
//The state transition needs the status of the delay display, and the state judgment needs to be added.
//After the state transition, the counter is cleared and recounted
always @ (posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        clockCountValueStore <= {(CLOCK_COUNT_SOTRE_WIDTH){1'b0}};                     
    end else if ((state == UNLOCKED_KEY_INPUT_OVERTIME) || (state == RE_ENTER_KEY_INPUT_OVERTIME) || (state == RE_ENTER_KEY_NOT_MATCH_ERROR) || (state == LOCKED_STATE_KEY_INPUT_OVERTIME) || (state == LOCKED_STATE_NOT_MATCH_ERROR) || (state == OPEN_STATE)) begin
        if (clockCountValueStore < CLOCK_COUNT_VALUE - 1) begin               
            clockCountValueStore <= clockCountValueStore + 1'b1;              
        end else begin
            clockCountValueStore <= {(CLOCK_COUNT_SOTRE_WIDTH){1'b0}};
        end
    end else begin
        clockCountValueStore <= {(CLOCK_COUNT_SOTRE_WIDTH){1'b0}};        
    end
end

//To remain the display the last 6 digits of input
//After the state transition, the counter is cleared and recounted
always @ (posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        clockCountValueStoreDuringInput <= {(CLOCK_COUNT_SOTRE_WIDTH){1'b0}};                     
    end else if ((state == UNLOCKED_KEY_INPUT_DISPLAY) || (state == RE_ENTER_KEY_INPUT_DISPLAY) || (state == LOCKED_STATE_KEY_INPUT_DISPLAY) ) begin
        if (clockCountValueStoreDuringInput < CLOCK_COUNT_VALUE - 1) begin                        
            clockCountValueStoreDuringInput <= clockCountValueStoreDuringInput + 1'b1;           
        end else begin
            clockCountValueStoreDuringInput <= {(CLOCK_COUNT_SOTRE_WIDTH){1'b0}};
        end
    end else begin
        clockCountValueStoreDuringInput <= {(CLOCK_COUNT_SOTRE_WIDTH){1'b0}};        
    end
end

//define the outputs for each state, which are only dependent on the state
always @ (state) begin
    stateOutputs = 4'd0; //default value for output
    case (state) 
        UNLOCKED_STATE: begin 
            stateOutputs = 4'd0;
        end
        UNLOCKED_KEY_INPUT_DISPLAY: begin 
            stateOutputs = 4'd1;
        end
        UNLOCKED_KEY_INPUT_OVERTIME: begin 
            stateOutputs = 4'd2;
        end 
        RE_ENTER_STATE: begin
            stateOutputs = 4'd3;
        end 
        RE_ENTER_KEY_INPUT_DISPLAY: begin 
            stateOutputs = 4'd4;
        end 
        RE_ENTER_KEY_INPUT_OVERTIME: begin 
            stateOutputs = 4'd5;
        end 
        RE_ENTER_KEY_NOT_MATCH_ERROR: begin 
            stateOutputs = 4'd6;
        end 
        LOCKED_STATE: begin 
            stateOutputs = 4'd7;
        end 
        LOCKED_STATE_KEY_INPUT_DISPLAY: begin 
            stateOutputs = 4'd8;
        end 
        LOCKED_STATE_KEY_INPUT_OVERTIME: begin 
            stateOutputs = 4'd9;
        end 
        LOCKED_STATE_NOT_MATCH_ERROR: begin 
            stateOutputs = 4'd10;
        end 
        OPEN_STATE: begin 
            stateOutputs = 4'd11;
        end        
    endcase
end

//Define state transitions, which are synchronous 
always @ (posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        keyValueStoreForComparison <= {(KEY_WIDTH*KEY_NUMBERS){1'b0}};
        inputkeyValueStore <= {(KEY_WIDTH*KEY_NUMBERS){1'b0}};
        state <= UNLOCKED_STATE;                                                        //define state unlocked as initial state
    end else begin
        case (state)
            UNLOCKED_STATE: begin
                keyInputClear <= 0;                                                     
                if (keyNumbersStore == 1) begin                                         //if has key input, convert to key input display
                    state <= UNLOCKED_KEY_INPUT_DISPLAY;
                end
                if (keyNumbersStore != 1) begin                                         //if no key input, stay unlocked state
                    state <= UNLOCKED_STATE;
                end
            end
            UNLOCKED_KEY_INPUT_DISPLAY: begin                                            
                keyInputClear <= 0;
                if (timeValueFlag) begin                                                //if key input overtime, convert to  key input overtime state                                                        
                    state <= UNLOCKED_KEY_INPUT_OVERTIME;
                end
                if ((keyNumbersStore < KEY_NUMBERS) & (!timeValueFlag)) begin           //if key input numbers is less than the set maximum key number, stay key input state           
                    inputkeyValueStore <= keyValueStore;
                    state <= UNLOCKED_KEY_INPUT_DISPLAY;
                end
                if ((keyNumbersStore == KEY_NUMBERS) & (!timeValueFlag)) begin          //if key numbers is equal to the set maximum key number,                
                    if (clockCountValueStoreDuringInput < CLOCK_COUNT_VALUE - 1) begin  //if the clock count is less than the given value, continue to maintain this state 
                        state <=  UNLOCKED_KEY_INPUT_DISPLAY;                        
                    end            
                    if (clockCountValueStoreDuringInput == CLOCK_COUNT_VALUE - 1) begin // There is a key value and the value is complete passwords. Convert to the re-enter state
                        state <= RE_ENTER_STATE; 
                        keyValueStoreForComparison <= inputkeyValueStore;               //assign the key value to the intermediate variable
                        keyInputClear <= 1;
                    end
                end                
            end
            //key input overtime state convert to unlocked state or stay current state, for maintaining the display 
            UNLOCKED_KEY_INPUT_OVERTIME: begin                                                                 
                keyInputClear <= 1;
                inputkeyValueStore <= 0;            
                if (clockCountValueStore == CLOCK_COUNT_VALUE - 1) begin                                    
                    state <= UNLOCKED_STATE;                    
                end
                if (clockCountValueStore < CLOCK_COUNT_VALUE - 1) begin                                    
                    state <=  UNLOCKED_KEY_INPUT_OVERTIME;   
                end                
            end
            //re-enter state convert to key input display state or stay current state, for maintaining the display 
            RE_ENTER_STATE: begin  
                keyInputClear <= 0;
                if (keyNumbersStore == 1) begin 
                    state <= RE_ENTER_KEY_INPUT_DISPLAY;
                end
                if (keyNumbersStore != 1) begin 
                    state <= RE_ENTER_STATE;
                end
            end
            //re-enter key input display state convert to overtime state when overtime
            //stay re-enter key input display when the input key number is less than the set key number
            //convert to locked state when the input key is the set key number and match the first sequence of password
            //convert to the key not match error display when the second sequence of password is not match the first sequence.
            RE_ENTER_KEY_INPUT_DISPLAY: begin   
                keyInputClear <= 0;
                if (timeValueFlag) begin  
                    state <= RE_ENTER_KEY_INPUT_OVERTIME;
                end
                if ((keyNumbersStore < KEY_NUMBERS) & (!timeValueFlag)) begin 
                    inputkeyValueStore <= keyValueStore;
                    state <= RE_ENTER_KEY_INPUT_DISPLAY;
                end                
                if ((keyNumbersStore == KEY_NUMBERS) & (!timeValueFlag)) begin 
                    if (keyValueStoreForComparison == inputkeyValueStore) begin                    
                        if (clockCountValueStoreDuringInput < CLOCK_COUNT_VALUE - 1) begin  
                            state <= RE_ENTER_KEY_INPUT_DISPLAY;
                        end            
                        if (clockCountValueStoreDuringInput == CLOCK_COUNT_VALUE - 1) begin 
                            state <= LOCKED_STATE; 
                            keyInputClear <= 1;
                        end
                    end else begin
                        if (clockCountValueStoreDuringInput < CLOCK_COUNT_VALUE - 1) begin  
                            state <= RE_ENTER_KEY_INPUT_DISPLAY;
                        end            
                        if (clockCountValueStoreDuringInput == CLOCK_COUNT_VALUE - 1) begin 
                            state <= RE_ENTER_KEY_NOT_MATCH_ERROR; 
                            keyInputClear <= 1;
                        end
                    end
                end                
            end
            //re-enter key input display state convert to unlocked state or stay current state, for maintaining the display 
            RE_ENTER_KEY_INPUT_OVERTIME: begin
                keyInputClear <= 1;
                inputkeyValueStore <= 0;            
                if (clockCountValueStore == CLOCK_COUNT_VALUE - 1) begin                     
                    state <= UNLOCKED_STATE;                    
                end
                if (clockCountValueStore < CLOCK_COUNT_VALUE - 1) begin                     
                    state <=  RE_ENTER_KEY_INPUT_OVERTIME;   
                end                
            end
            //re-enter key input not match state convert to unlocked state or stay current state, for maintaining the display 
            RE_ENTER_KEY_NOT_MATCH_ERROR: begin 
                keyInputClear <= 1;
                inputkeyValueStore <= 0;            
                if (clockCountValueStore == CLOCK_COUNT_VALUE - 1) begin                     
                    state <= UNLOCKED_STATE;                    
                end
                if (clockCountValueStore < CLOCK_COUNT_VALUE - 1) begin                     
                    state <=  RE_ENTER_KEY_NOT_MATCH_ERROR;   
                end                
            end
            //locked state convert to unlocked key input state or stay current state, for maintaining the display 
            LOCKED_STATE: begin              
                keyInputClear <= 0;
                if (keyNumbersStore == 1) begin 
                    state <= LOCKED_STATE_KEY_INPUT_DISPLAY;
                end
                if (keyNumbersStore != 1) begin 
                    state <= LOCKED_STATE;
                end                
            end
            //locked key input display state convert to overtime state when overtime
            //stay locked key input display when the input key number is less than the set key number
            //convert to open state when the input key is the set key number and match the set password
            //convert to the key not match error display when the password is not match the set password.
            LOCKED_STATE_KEY_INPUT_DISPLAY: begin 
                keyInputClear <= 0;
                if (timeValueFlag) begin  
                    state <= LOCKED_STATE_KEY_INPUT_OVERTIME;
                end
                if ((keyNumbersStore < KEY_NUMBERS) & (!timeValueFlag)) begin 
                    inputkeyValueStore <= keyValueStore;
                    state <= LOCKED_STATE_KEY_INPUT_DISPLAY;
                end                
                if ((keyNumbersStore == KEY_NUMBERS) & (!timeValueFlag)) begin 
                    if (keyValueStoreForComparison == inputkeyValueStore) begin                    
                        if (clockCountValueStoreDuringInput < CLOCK_COUNT_VALUE - 1) begin  
                            state <= LOCKED_STATE_KEY_INPUT_DISPLAY;
                        end            
                        if (clockCountValueStoreDuringInput == CLOCK_COUNT_VALUE - 1) begin 
                            state <= OPEN_STATE; 
                            keyInputClear <= 1;
                        end
                    end else begin
                        if (clockCountValueStoreDuringInput < CLOCK_COUNT_VALUE - 1) begin  
                            state <= LOCKED_STATE_KEY_INPUT_DISPLAY;
                        end            
                        if (clockCountValueStoreDuringInput == CLOCK_COUNT_VALUE - 1) begin 
                            state <= LOCKED_STATE_NOT_MATCH_ERROR; 
                            keyInputClear <= 1;
                        end
                    end
                end                 
            end
            //locked key input overtime state convert to locked state or stay current state, for maintaining the display 
            LOCKED_STATE_KEY_INPUT_OVERTIME: begin  
                keyInputClear <= 1;
                inputkeyValueStore <= 0;            
                if (clockCountValueStore == CLOCK_COUNT_VALUE - 1) begin                     
                    state <= LOCKED_STATE;                    
                end
                if (clockCountValueStore < CLOCK_COUNT_VALUE - 1) begin                     
                    state <=  LOCKED_STATE_KEY_INPUT_OVERTIME;   
                end                
            end
            //locked not match error state convert to unlocked key locked state or stay current state, for maintaining the display  
            LOCKED_STATE_NOT_MATCH_ERROR: begin 
                keyInputClear <= 1;
                inputkeyValueStore <= 0;            
                if (clockCountValueStore == CLOCK_COUNT_VALUE - 1) begin                     
                    state <= LOCKED_STATE;                    
                end
                if (clockCountValueStore < CLOCK_COUNT_VALUE - 1) begin                     
                    state <=  LOCKED_STATE_NOT_MATCH_ERROR;   
                end                
            end
            //open state convert to unlocked state or stay current state, for remaing the display 
            OPEN_STATE: begin 
                keyInputClear <= 1;
                inputkeyValueStore <= 0;            
                if (clockCountValueStore == CLOCK_COUNT_VALUE - 1) begin                    
                    state <= UNLOCKED_STATE;                    
                end
                if (clockCountValueStore < CLOCK_COUNT_VALUE - 1) begin                     
                    state <=  OPEN_STATE;   
                end                
            end           
        endcase
    end
end

endmodule 
