/*
 * StateMachine Test Bench
 * ======================
 * By: MorseMeow
 * For: State machine based digital lock 
 * Date: May 2020
 
 * Add description here
 * when do this test bench, use the local parameter: localparam CLOCK_COUNT_VALUE = 500, 
 * which means run for 1000 cycles for the full clock count.
 * Because the simulation is too slow to run for a large number of clock cycles.
 */
// Timescale indicates unit of delays.
`timescale 1 ns/100 ps
 
// Test bench module declaration 
module State_Machine_tb;

//
// Parameter Declarations
//
localparam KEY_WIDTH = 4;                                                 
localparam KEY_NUMBERS = 4;                                               
localparam KEY_NUMBERS_STORE_WIDTH = 3;                                   
localparam CLOCK_COUNT_SOTRE_WIDTH = 40;                                    

localparam STATE_NUMBERS_SOTRE_WIDTH = 4;                                 

localparam NUM_CYCLES = 1000_000_000;                                //Simulate this many clock cycles. Max. 1 billion
localparam CLOCK_FREQ = 50_000_000;                                  //Clock frequency (in Hz)
localparam RST_CYCLES = 2;                                           //Number of cycles of reset at beginning.


//
// Test Bench Generated Signals
//
reg                                      clock;                            
reg                                      reset_n;                              
reg                                      timeValueFlag;                    
reg [KEY_WIDTH*KEY_NUMBERS-1:0]          keyValueStore;                    
reg [KEY_NUMBERS_STORE_WIDTH-1:0]        keyNumbersStore;                  

//
// DUT Output Signals
//
wire [STATE_NUMBERS_SOTRE_WIDTH-1:0]     stateOutputs;                  
wire                                     keyInputClear;                //key input value clear 
//
// Device Under Test
//
StateMachine #(
    .KEY_WIDTH                 (KEY_WIDTH                ),                                                 
    .KEY_NUMBERS               (KEY_NUMBERS              ),                                               
    .KEY_NUMBERS_STORE_WIDTH   (KEY_NUMBERS_STORE_WIDTH  ),                                  
    .CLOCK_FREQUENCY           (CLOCK_FREQ               ),                                               
    .CLOCK_COUNT_SOTRE_WIDTH   (CLOCK_COUNT_SOTRE_WIDTH  ),                                  
    .STATE_NUMBERS_SOTRE_WIDTH (STATE_NUMBERS_SOTRE_WIDTH)                                    

) dut (
    .clock                     (clock                    ),                                
    .reset_n                   (reset_n                  ),                                
    .keyValueStore             (keyValueStore            ),                                
    .timeValueFlag             (timeValueFlag            ),                                
    .keyNumbersStore           (keyNumbersStore          ),                                
    .stateOutputs              (stateOutputs             ),
    .keyInputClear             (keyInputClear            )
);



//
// Reset Logic
//
initial begin
    reset_n = 1'b0;                                      //Start in reset.
    repeat(RST_CYCLES) @(posedge clock);               //Wait for a couple of clocks
    reset_n = 1'b1;                                      //Then clear the reset signal.
end

//
//Clock generator + simulation time limit.
//
initial begin
    clock = 1'b0; //Initialise the clock to zero.
end

real HALF_CLOCK_PERIOD = (1000000000.0 / $itor(CLOCK_FREQ)) / 2.0;

//Now generate the clock
integer half_cycles = 0;
always begin
    //Generate the next half cycle of clock
    #(HALF_CLOCK_PERIOD);          //Delay for half a clock period.
    clock = ~clock;                //Toggle the clock
    half_cycles = half_cycles + 1; //Increment the counter
    
    //Check if we have simulated enough half clock cycles
    if (half_cycles == (2*NUM_CYCLES)) begin 
        //Once the number of cycles has been reached
		half_cycles = 0; 		   //Reset half cycles, so if we resume running with "run -all", we perform another chunk.
        $stop;                     //Break the simulation
    end
end


//Generate our stimuli.
initial begin

    $display("%d ns\tSimulation Started",$time);  
    
    //Initialise Value to 0.
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0;     
    keyNumbersStore = 3'd0;    

//In the unlocked state, no key is pressed, keep the unlocked state * At this time, the input value does not change 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    @(posedge clock);    //At the rising edge of the clock     
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd0) begin
        $display("Error! Output stateOutputs = %B != 0", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end
    
//in the unloced state, key 1 is pressed, convert to UNLOCKED_KEY_INPUT_DISPLAY stste
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    @(posedge clock);    //At the rising edge of the clock        
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100; 
    keyNumbersStore = 3'd1;     
    
    //Now we can check the expected value    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd1) begin
        $display("Error! Output stateOutputs = %B != 1", stateOutputs);
        $stop;
    end 
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end
    
//in the UNLOCKED_KEY_INPUT_DISPLAY state, time over the set value, convert to UNLOCKED_KEY_INPUT_OVERTIME 
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b1;
    repeat(1) @(posedge clock);      //Wait for a couple of clocks    
    timeValueFlag = 1'b0;        
    repeat(1) @(posedge clock);  
    keyValueStore = 16'b0; 
    keyNumbersStore = 3'd0;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd2) begin
        $display("Error! Output stateOutputs = %B != 2", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b1) begin
        $display("Error! Output keyInputClear = %B != 1", keyInputClear);
        $stop;        
    end
    
//in the UNLOCKED_KEY_INPUT_OVERTIME, 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd2) begin
        $display("Error! Output stateOutputs = %B != 2", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b1) begin
        $display("Error! Output keyInputClear = %B != 1", keyInputClear);
        $stop;        
    end    
// in the overtime state, need to remain for 500 cycles and then convert to unlocked
//in the UNLOCKED state, press the key convert to UNLOCKED_KEY_INPUT_DISPLAY state, key number = 1
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100; 
    keyNumbersStore = 3'd1;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd1) begin
        $display("Error! Output stateOutputs = %B != 1", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end        

 
//UNLOCKED_KEY_INPUT_DISPLAY key number = 2
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b01000100; 
    keyNumbersStore = 3'd2;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd1) begin
        $display("Error! Output stateOutputs = %B != 1", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end         


//UNLOCKED_KEY_INPUT_DISPLAY key number = 3
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock    
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b010001000001; 
    keyNumbersStore = 3'd3;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd1) begin
        $display("Error! Output stateOutputs = %B != 1", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end         


//UNLOCKED_KEY_INPUT_DISPLAY key number = 4 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100010000011000; 
    keyNumbersStore = 3'd4;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd1) begin
        $display("Error! Output stateOutputs = %B != 1", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end         


//UNLOCKED_KEY_INPUT_DISPLAY key number = 4 The counter will keep displaying password if it is less than 500cycles.
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100010000011000; 
    keyNumbersStore = 3'd4;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd1) begin
        $display("Error! Output stateOutputs = %B != 1", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end 
    
//UNLOCKED_KEY_INPUT_DISPLAY key number = 4, the conuter is over 500 cycles. convert to re-enter state
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100010000011000; 
    keyNumbersStore = 3'd4;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd3) begin
        $display("Error! Output stateOutputs = %B != 3", stateOutputs);
        $stop;
    end 
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end 
    
//re-enter display and delay
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0; 
    keyNumbersStore = 3'd0;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd3) begin
        $display("Error! Output stateOutputs = %B != 3", stateOutputs);
        $stop;
    end     
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end 
    
//key pressed, re-enter state convert to re-enter key input state key number = 1
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100; 
    keyNumbersStore = 3'd1;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd4) begin
        $display("Error! Output stateOutputs = %B != 4", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end 

//in re-enter input display state, pressed key, key number =2, still keep re-enter input state
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b01000100;
    keyNumbersStore = 3'd2;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd4) begin
        $display("Error! Output stateOutputs = %B != 4", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end 

//in re-enter input display state, pressed key, key number =3, still keep re-enter input state
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b010001000001;
    keyNumbersStore = 3'd3;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd4) begin
        $display("Error! Output stateOutputs = %B != 4", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end
    
//in re-enter input display state, pressed key, key number =4, still keep re-enter input state
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100010000011000;
    keyNumbersStore = 3'd4;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd4) begin
        $display("Error! Output stateOutputs = %B != 4", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end 

//in re-enter input display state， after maintain 500 cycles, 
//the password is correct, convert to clocked
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100010000011000;
    keyNumbersStore = 3'd3;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd7) begin
        $display("Error! Output stateOutputs = %B != 7", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end

//in re-enter state, key 1 is pressed, convert to LOCKED_KEY_INPUT_DISPLAY stste
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    @(posedge clock);    //At the rising edge of the clock        
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b1000; 
    keyNumbersStore = 3'd1;     
    
    //Now we can check the expected value    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end 
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end
    
//LOCKED_KEY_INPUT_DISPLAY key number = 2
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b10000100; 
    keyNumbersStore = 3'd2;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end         


//LOCKED_KEY_INPUT_DISPLAY key number = 3
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock    
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b100001000001; 
    keyNumbersStore = 3'd3;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end         


//LOCKED_KEY_INPUT_DISPLAY key number = 4 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b1000010000011000; 
    keyNumbersStore = 3'd4;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end         


//LOCKED_KEY_INPUT_DISPLAY key number = 4 The counter will keep displaying password if it is less than 500cycles.
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b1000010000011000; 
    keyNumbersStore = 3'd4;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end 
    
//LOCKED_KEY_INPUT_DISPLAY key number = 4, the password is not correct, convert to error state
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0; 
    keyNumbersStore = 3'd0;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd10) begin
        $display("Error! Output stateOutputs = %B != 10", stateOutputs);
        $stop;
    end 
    if (keyInputClear != 1'b1) begin
        $display("Error! Output keyInputClear = %B != 1", keyInputClear);
        $stop;        
    end 

//in the error state, show"error"
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd10) begin
        $display("Error! Output stateOutputs = %B != 10", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b1) begin
        $display("Error! Output keyInputClear = %B != 1", keyInputClear);
        $stop;        
    end    
// in the error state, need to remain for 500 cycles and then convert to locked
//in the LOCKED state, press the key convert to LOCKED_KEY_INPUT_DISPLAY state, key number = 1
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100; 
    keyNumbersStore = 3'd1;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end
//LOCKED_KEY_INPUT_DISPLAY key number = 2
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b01000100; 
    keyNumbersStore = 3'd2;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end         


//LOCKED_KEY_INPUT_DISPLAY key number = 3
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock    
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b010001000001; 
    keyNumbersStore = 3'd3;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end         


//LOCKED_KEY_INPUT_DISPLAY key number = 4 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100010000011000; 
    keyNumbersStore = 3'd4;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end         


//LOCKED_KEY_INPUT_DISPLAY key number = 4 The counter will keep displaying password if it is less than 500cycles.
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100010000011000; 
    keyNumbersStore = 3'd4;     
    
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd8) begin
        $display("Error! Output stateOutputs = %B != 8", stateOutputs);
        $stop;
    end
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end 
    
//LOCKED_KEY_INPUT_DISPLAY key number = 4, the conuter is over 500 cycles. convert to open state
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0100010000011000; 
    keyNumbersStore = 3'd4;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd11) begin
        $display("Error! Output stateOutputs = %B != 11", stateOutputs);
        $stop;
    end 
    if (keyInputClear != 1'b1) begin
        $display("Error! Output keyInputClear = %B != 1", keyInputClear);
        $stop;        
    end 

//open display and maintain
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0; 
    keyNumbersStore = 3'd0;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd11) begin
        $display("Error! Output stateOutputs = %B != 11", stateOutputs);
        $stop;
    end     
    if (keyInputClear != 1'b1) begin
        $display("Error! Output keyInputClear = %B != 1", keyInputClear);
        $stop;        
    end     
    
//convert to unlocked state
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    timeValueFlag = 1'b0;  
    keyValueStore = 16'b0; 
    keyNumbersStore = 3'd0;
    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (stateOutputs != 4'd0) begin
        $display("Error! Output stateOutputs = %B != 0", stateOutputs);
        $stop;
    end     
    if (keyInputClear != 1'b0) begin
        $display("Error! Output keyInputClear = %B != 0", keyInputClear);
        $stop;        
    end     
        repeat(50) @(posedge clock);         
        $display("Success!");
        $stop;
    end
     
endmodule
