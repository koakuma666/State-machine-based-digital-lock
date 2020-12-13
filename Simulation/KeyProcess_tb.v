/*
 * KeyProcess Test Bench
 * ======================
 * By: MorseMeow
 * For: State machine based digital lock 
 * Date: May 2020
 
 * Add description here
 * when do this test bench, use the local parameter: localparam CLOCK_COUNT_VALUE = 500, 
 * which means run for 1000 cycles for the full clock count.
 * Because the simulation is too slow to run for a large number of clock cycles.
 */

`timescale 1 ns/100 ps
 
// Test bench module declaration
module KeyProcess_tb;

//
// Parameter Declarations
//
localparam KEY_WIDTH = 4;                                                //Number of Keys KEY[3:0]
localparam KEY_NUMBERS = 6;                                              //The number of keys pressed, that is, the length of the password
localparam KEY_NUMBERS_STORE_WIDTH = 3;                                  //The width of the number of keys stored
localparam CLOCK_COUNT_SOTRE_WIDTH = 40;                                 //Clock count storage width  
localparam TIME_OUTS_TIME = 1;                                           //Timeout time, in seconds

localparam NUM_CYCLES = 1000_000_000;                                    //Simulate this many clock cycles. Max. 1 billion
localparam CLOCK_FREQ = 50_000_000;                                      //Clock frequency (in Hz)
localparam RST_CYCLES = 2;                                               //Number of cycles of reset at beginning.

//
// Test Bench Generated Signals
//
reg                                 clock;                               //System clock, 50MHz
reg                                 reset_n;                             //Reset, active low
reg  [KEY_WIDTH-1:0]                keyInputValue;                       //Single key input value

//
// DUT Output Signals
//
wire [KEY_WIDTH*KEY_NUMBERS-1:0]    keyValueStore;                       //Key input value storage
wire                                timeValueFlag;                       //Timeout flag
wire [KEY_NUMBERS_STORE_WIDTH-1:0]  keyNumbersStore;                     //Store the number of keys pressed

//
// Device Under Test
//
KeyProcess #(
    .KEY_WIDTH                 (KEY_WIDTH              ),                              
    .KEY_NUMBERS               (KEY_NUMBERS            ),                            
    .KEY_NUMBERS_STORE_WIDTH   (KEY_NUMBERS_STORE_WIDTH),                
    .CLOCK_FREQUENCY           (CLOCK_FREQ             ),                            
    .CLOCK_COUNT_SOTRE_WIDTH   (CLOCK_COUNT_SOTRE_WIDTH),                  
    .TIME_OUTS_TIME            (TIME_OUTS_TIME         )                          
) dut (
    .clock                     (clock                  ),                        
    .reset_n                   (reset_n                ),                        
    .keyInputValue             (keyInputValue          ),                            
    .keyValueStore             (keyValueStore          ),                        
    .timeValueFlag             (timeValueFlag          ),                        
    .keyNumbersStore           (keyNumbersStore        )                         
);



//
// Reset Logic
//
initial begin
    reset_n = 1'b0;                                                      //Start in reset.
    repeat(RST_CYCLES) @(posedge clock);                                 //Wait for a couple of clocks
    reset_n = 1'b1;                                                      //Then clear the reset signal.
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
    #(HALF_CLOCK_PERIOD);                                                //Delay for half a clock period.
    clock = ~clock;                                                      //Toggle the clock
    half_cycles = half_cycles + 1;                                       //Increment the counter
    
    //Check if we have simulated enough half clock cycles
    if (half_cycles == (2*NUM_CYCLES)) begin 
        //Once the number of cycles has been reached
		half_cycles = 0; 		                                         //Reset half cycles, so if we resume running with "run -all", we perform another chunk.
        $stop;                                                           //Break the simulation
    end
end


//Generate our stimuli.
initial begin

    $display("%d ns\tSimulation Started",$time);  
    
    //Initialise keyInputValue to 0.
    keyInputValue = 4'b0000;

//The first button is pressed and released, imitating the state of the button click
//keyInputValue is only kept for one cycle. There are key output values and corresponding waveforms for one clock cycle    
    repeat(50) @(posedge clock);                                         //Wait for a couple of clocks 
    @(posedge clock);                                                    //At the rising edge of the clock  
    keyInputValue = 4'b0001;
    repeat(10) @(posedge clock);                                         //Wait for a couple of clocks    
    keyInputValue = 4'b0000;        
    //Now we can check the expected value 
    repeat(10) @(posedge clock);
    if (keyValueStore != 24'b0001) begin
        $display("Error! Output keyValueStore = %B != 0001", keyValueStore);
        $stop;
    end
    if (timeValueFlag != 1'b0) begin
        $display("Error! Output timeValueFlag != 0",timeValueFlag);
        $stop;
    end
    if (keyNumbersStore != 3'd1) begin
        $display("Error! Output keyNumbersStore != 1", keyNumbersStore);
        $stop;
    end

        
////The second button is pressed and released    
    @(posedge clock);                                                    //At the rising edge of the clock    
    keyInputValue = 4'b0010;
    repeat(10) @(posedge clock);                                         //Wait for a couple of clocks 
    keyInputValue = 4'b0000;    
    //Now we can check the expected value keyInputValue
    if (keyValueStore != 24'b00010010) begin
        $display("Error! Output keyValueStore = %B != 00010010", keyValueStore);
        $stop;
    end
    if (timeValueFlag != 1'b0) begin
        $display("Error! Output timeValueFlag != 0",timeValueFlag);
        $stop;
    end
    if (keyNumbersStore != 3'd2) begin
        $display("Error! Output keyNumbersStore != 2", keyNumbersStore);
        $stop;
    end



////The third button is pressed and released     
    @(posedge clock);                                                    //At the rising edge of the clock    
    keyInputValue = 4'b1000;
    repeat(10) @(posedge clock);                                         //Wait for a couple of clocks 
    keyInputValue = 4'b0000;    
    //Now we can check the expected value keyInputValue
    if (keyValueStore != 24'b000100101000) begin
        $display("Error! Output keyValueStore = %B != 000100101000", keyValueStore);
        $stop;
    end
    if (timeValueFlag != 1'b0) begin
        $display("Error! Output timeValueFlag != 0",timeValueFlag);
        $stop;
    end
    if (keyNumbersStore != 3'd3) begin
        $display("Error! Output keyNumbersStore != 3", keyNumbersStore);
        $stop;
    end
 

////The fourth button is pressed and released     
    @(posedge clock);                                                    //At the rising edge of the clock    
    keyInputValue = 4'b0100;
    repeat(10) @(posedge clock);                                         //Wait for a couple of clocks 
    keyInputValue = 4'b0000;    
    //Now we can check the expected value keyInputValue
    if (keyValueStore != 24'b0001001010000100) begin
        $display("Error! Output keyValueStore = %B != 0001001010000100", keyValueStore);
        $stop;
    end
    if (timeValueFlag != 1'b0) begin
        $display("Error! Output timeValueFlag != 0",timeValueFlag);
        $stop;
    end
    if (keyNumbersStore != 3'd4) begin
        $display("Error! Output keyNumbersStore != 4", keyNumbersStore);
        $stop;
    end


////The fifth button is pressed and released     
    @(posedge clock);                                                    //At the rising edge of the clock    
    keyInputValue = 4'b1000;
    repeat(10) @(posedge clock);                                         //Wait for a couple of clocks 
    keyInputValue = 4'b0000;    
    //Now we can check the expected value keyInputValue
    if (keyValueStore != 24'b00010010100001001000) begin
        $display("Error! Output keyValueStore = %B != 00010010100001001000", keyValueStore);
        $stop;
    end
    if (timeValueFlag != 1'b0) begin
        $display("Error! Output timeValueFlag != 0",timeValueFlag);
        $stop;
    end
    if (keyNumbersStore != 3'd5) begin
        $display("Error! Output keyNumbersStore != 5", keyNumbersStore);
        $stop;
    end


////The sixth button is pressed and released     
    @(posedge clock);                                                    //At the rising edge of the clock    
    keyInputValue = 4'b0010;
    repeat(10) @(posedge clock);                                         //Wait for a couple of clocks 
    keyInputValue = 4'b0000;    
    //Now we can check the expected value keyInputValue
    if (keyValueStore != 24'b000100101000010010000010) begin
        $display("Error! Output keyValueStore = %B != 000100101000010010000010", keyValueStore);
        $stop;
    end
    if (timeValueFlag != 1'b0) begin
        $display("Error! Output timeValueFlag != 0",timeValueFlag);
        $stop;
    end
    if (keyNumbersStore != 3'd6) begin
        $display("Error! Output keyNumbersStore != 6", keyNumbersStore);
        $stop;
    end

  
////The seventh button is pressed and released     
    @(posedge clock);                                                    //At the rising edge of the clock    
    keyInputValue = 4'b0001;
    repeat(10) @(posedge clock);                                         //Wait for a couple of clocks 
    keyInputValue = 4'b0000;    
    //Now we can check the expected value keyInputValue
    if (keyValueStore != 24'b0) begin
        $display("Error! Output keyValueStore = %B != 0", keyValueStore);
        $stop;
    end
    if (timeValueFlag != 1'b0) begin
        $display("Error! Output timeValueFlag != 0",timeValueFlag);
        $stop;
    end
    if (keyNumbersStore != 1'd0) begin
        $display("Error! Output keyNumbersStore != 0", keyNumbersStore);
        $stop;
    end
        repeat(50) @(posedge clock);         
        $display("Success!");

//Key timeout test. The key timeout period is set to 1s. 
//The timeout flag is measured when the interval from the previous button is greater than 1s        
    @(posedge clock);                                                    //At the rising edge of the clock     
    repeat(50_001_000) @(posedge clock);       
    keyInputValue = 4'b0100;       
    repeat(10) @(posedge clock);
    keyInputValue = 4'b0000;    
    //Now we can check the expected value 
    if (keyValueStore != 24'b0) begin
        $display("Error! Output keyValueStore = %B != 0", keyValueStore);
        $stop;
    end
    if (timeValueFlag != 1'b1) begin
        $display("Error! Output timeValueFlag != 0",timeValueFlag);
        $stop;
    end
    if (keyNumbersStore != 1'd0) begin
        $display("Error! Output keyNumbersStore != 0", keyNumbersStore);
        $stop;
    end
        repeat(50) @(posedge clock);         
        $display("Success!");
        $stop;        
end  
     
     
endmodule
