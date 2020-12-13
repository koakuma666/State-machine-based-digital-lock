/*
 * DigitalLock Test Bench (in total)
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
module DigitalLock_tb;

//
// Parameter Declarations
//
localparam KEY_WIDTH = 4;                                         
localparam KEY_NUMBERS = 6;                                                  
localparam KEY_NUMBERS_STORE_WIDTH = 3;                             
localparam CLOCK_COUNT_SOTRE_WIDTH = 40;                                
localparam STATE_NUMBERS_SOTRE_WIDTH = 4;
localparam SEGMENT_NUMBER = 7;                                 
localparam BIT_WIDTH = 6;                                                                       

localparam NUM_CYCLES = 1000_000_000;                                //Simulate this many clock cycles. Max. 1 billion
localparam CLOCK_FREQ = 50_000_000;                                  //Clock frequency (in Hz)
localparam RST_CYCLES = 2;                                           //Number of cycles of reset at beginning.


//
// Test Bench Generated Signals
//
reg                                      clock;                            
reg                                      reset_n;                              
reg   [KEY_WIDTH-1:0]                    keyInputValue_n;                     

//
// DUT Output Signals
//
wire  [SEGMENT_NUMBER*BIT_WIDTH-1:0]     ledDisplay_n;
//
// Device Under Test
//
DigitalLock #(
    .KEY_WIDTH                 (KEY_WIDTH                ),                                                 
    .KEY_NUMBERS               (KEY_NUMBERS              ),                                               
    .KEY_NUMBERS_STORE_WIDTH   (KEY_NUMBERS_STORE_WIDTH  ),                                  
    .CLOCK_FREQUENCY           (CLOCK_FREQ               ),                                               
    .CLOCK_COUNT_SOTRE_WIDTH   (CLOCK_COUNT_SOTRE_WIDTH  ),                                  
    .STATE_NUMBERS_SOTRE_WIDTH (STATE_NUMBERS_SOTRE_WIDTH),
    .SEGMENT_NUMBER            (SEGMENT_NUMBER           ),
    .BIT_WIDTH                 (BIT_WIDTH                )

) dut (
    .clock                     (clock                    ),                                
    .reset_n                   (reset_n                  ),                                
    .keyInputValue_n           (keyInputValue_n          ),                                
    .ledDisplay_n              (ledDisplay_n             )                                
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
    
    //Initialise keyInputValue_n Value.
    keyInputValue_n = {(SEGMENT_NUMBER*BIT_WIDTH){1'b1}};    

//In the unlocked state, no key is pressed, keep the unlocked state * At this time, the input value does not change 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    @(posedge clock);    //At the rising edge of the clock     
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0111110_1010100_0111000_1011100_0111001_1111010) begin
        $display("Error! Output ledDisplay_n = %B != 0111110_1010100_0111000_1011100_0111001_1111010", ledDisplay_n);
        $stop;
    end
    
//in the unloced state, key 1 is pressed, convert to UNLOCKED_KEY_INPUT_DISPLAY state
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    @(posedge clock);    //At the rising edge of the clock             
    keyInputValue_n = {{(20){1'b1}},4'b1110};    
    
    //Now we can check the expected value    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110", ledDisplay_n);
        $stop;
    end 
    
//in the UNLOCKED_KEY_INPUT_DISPLAY state, time over the set value, convert to UNLOCKED_KEY_INPUT_OVERTIME 
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    keyInputValue_n = {(24){1'b1}};      
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b1011100_1100010_1111000_0010000_1010101_1111001) begin
        $display("Error! Output ledDisplay_n = %B != 1011100_1100010_1111000_0010000_1010101_1111001", ledDisplay_n);
        $stop;
    end
    
//in the UNLOCKED_KEY_INPUT_OVERTIME, 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    keyInputValue_n = {(24){1'b1}};    
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b1011100_1100010_1111000_0010000_1010101_1111001) begin
        $display("Error! Output ledDisplay_n = %B != 1011100_1100010_1111000_0010000_1010101_1111001", ledDisplay_n);
        $stop;
    end
    
// in the overtime state, need to remain for 500 cycles and then convert to unlocked
//in the UNLOCKED state, press the key convert to UNLOCKED_KEY_INPUT_DISPLAY state, key number = 1
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock     
    keyInputValue_n = {{(20){1'b1}},4'b1110};    
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110) begin
        $display("Error! Output ledDisplay_n = %B != 7'b0000110", ledDisplay_n);
        $stop;
    end       
 
//UNLOCKED_KEY_INPUT_DISPLAY key number = 2
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(16){1'b1}},8'b1110_1101}; 
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011", ledDisplay_n);
        $stop;
    end
        
//UNLOCKED_KEY_INPUT_DISPLAY key number = 3
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock        
    keyInputValue_n = {{(12){1'b1}},12'b1110_1101_1011};    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_10110111_1001111", ledDisplay_n);
        $stop;
    end        

//UNLOCKED_KEY_INPUT_DISPLAY key number = 4 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(8){1'b1}},16'b1110_1101_1011_0111};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110", ledDisplay_n);
        $stop;
    end
//UNLOCKED_KEY_INPUT_DISPLAY key number = 5 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(4){1'b1}},20'b1110_1101_1011_0111_1110};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110_0000110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110_0000110", ledDisplay_n);
        $stop;
    end 
    
//UNLOCKED_KEY_INPUT_DISPLAY key number = 6 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = 24'b1110_1101_1011_0111_1110_0111;

    repeat(10) @(posedge clock);    
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110_0000110_1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110_0000110_1100110", ledDisplay_n);
        $stop;
    end
    
//UNLOCKED_KEY_INPUT_DISPLAY key number = 6 The counter will keep displaying password if it is less than 500cycles.
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110_0000110_1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110_0000110_1100110", ledDisplay_n);
        $stop;
    end
    
//UNLOCKED_KEY_INPUT_DISPLAY key number = 6, the conuter is over 500 cycles. convert to re-enter state
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    keyInputValue_n = {(24){1'b1}}; 
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b1010000_1111001_1111001_1010100_1111000_1010000) begin
        $display("Error! Output ledDisplay_n = %B != b1010000_1111001_1111001_1010100_1111000_1010000", ledDisplay_n);
        $stop;
    end  
    
//re-enter display and delay
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    keyInputValue_n = {(24){1'b1}}; 
    //Now we can check the expected value          
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b1010000_1111001_1111001_1010100_1111000_1010000) begin
        $display("Error! Output ledDisplay_n = %B != 1010000_1111001_1111001_1010100_1111000_1010000", ledDisplay_n);
        $stop;
    end  
     
    
//key pressed, re-enter state convert to re-enter key input state key number = 1
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    @(posedge clock);    //At the rising edge of the clock             
    keyInputValue_n = {{(20){1'b1}},4'b1110};    
    
    //Now we can check the expected value    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110", ledDisplay_n);
        $stop;
    end 

//in re-enter input display state, pressed key, key number =2, still keep re-enter input state
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(16){1'b1}},8'b1110_1101}; 
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011", ledDisplay_n);
        $stop;
    end

//in re-enter input display state, pressed key, key number =3, still keep re-enter input state
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock        
    keyInputValue_n = {{(12){1'b1}},12'b1110_1101_1011};    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_10110111_1001111", ledDisplay_n);
        $stop;
    end
    
//in re-enter input display state, pressed key, key number =4, still keep re-enter input state
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(8){1'b1}},16'b1110_1101_1011_0111};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110", ledDisplay_n);
        $stop;
    end

//in re-enter input display state, pressed key, key number =5, still keep re-enter input state
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(4){1'b1}},20'b1110_1101_1011_0111_1110};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110_0000110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110_0000110", ledDisplay_n);
        $stop;
    end

//in re-enter input display state, pressed key, key number =6, still keep re-enter input state
    repeat(200) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = 24'b1110_1101_1011_0111_1110_0111;
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110_0000110_1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110_0000110_1100110", ledDisplay_n);
        $stop;
    end
    
//in re-enter input display state， after maintain 500 cycles, 
//the password is correct, convert to re-enter state
    repeat(600) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    keyInputValue_n = {(24){1'b1}};      
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0111000_1011100_0111001_1111010_1111001_1011110) begin
        $display("Error! Output ledDisplay_n = %B != 0111000_1011100_0111001_1111010_1111001_1011110", ledDisplay_n);
        $stop;
    end

//in re-enter state, key 1 is pressed, convert to LOCKED_KEY_INPUT_DISPLAY stste
    repeat(50) @(posedge clock);      //Wait for a couple of clocks
    @(posedge clock);    //At the rising edge of the clock             
    keyInputValue_n = {{(20){1'b1}},4'b1110};    
    
    //Now we can check the expected value    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110", ledDisplay_n);
        $stop;
    end 
    
//LOCKED_KEY_INPUT_DISPLAY key number = 2
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(16){1'b1}},8'b1110_1101}; 
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011", ledDisplay_n);
        $stop;
    end        


//LOCKED_KEY_INPUT_DISPLAY key number = 3
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock        
    keyInputValue_n = {{(12){1'b1}},12'b1110_1101_1011};    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_10110111_1001111", ledDisplay_n);
        $stop;
    end        


//LOCKED_KEY_INPUT_DISPLAY key number = 4 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(12){1'b1}},16'b1110_1101_1011_1110};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_0000110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_0000110", ledDisplay_n);
        $stop;
    end        

//LOCKED_KEY_INPUT_DISPLAY key number = 5
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(8){1'b1}},16'b1110_1101_1011_1110_1011};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_0000110_1001111) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_0000110_1001111", ledDisplay_n);
        $stop;
    end
//LOCKED_KEY_INPUT_DISPLAY key number = 6 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(4){1'b1}},16'b1110_1101_1011_1110_1011_0111};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_0000110_1001111_1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_0000110_1001111_1100110", ledDisplay_n);
        $stop;
    end

//LOCKED_KEY_INPUT_DISPLAY key number = 6 The counter will keep displaying password if it is less than 500cycles.
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(4){1'b1}},16'b1110_1101_1011_1110_1011_0111};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_0000110_1001111__1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_0000110_1001111__1100110", ledDisplay_n);
        $stop;
    end 
    
//LOCKED_KEY_INPUT_DISPLAY key number = 6, the password is not correct, convert to error state
    repeat(500) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    keyInputValue_n = {(24){1'b1}};      
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b1111001_1010000_1010000_1011100_1010000_0000000) begin
        $display("Error! Output ledDisplay_n = %B != 1111001_1010000_1010000_1011100_1010000_0000000", ledDisplay_n);
        $stop;
    end 

//in the error state, show"error"
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    keyInputValue_n = {(24){1'b1}};      
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b1111001_1010000_1010000_1011100_1010000_0000000) begin
        $display("Error! Output ledDisplay_n = %B != 1111001_1010000_1010000_1011100_1010000_0000000", ledDisplay_n);
        $stop;
    end    
// in the error state, need to remain for 500 cycles and then convert to locked
//in the LOCKED state, press the key convert to LOCKED_KEY_INPUT_DISPLAY state, key number = 1
    repeat(600) @(posedge clock);      //Wait for a couple of clocks
    @(posedge clock);    //At the rising edge of the clock             
    keyInputValue_n = {{(20){1'b1}},4'b1110};    
    
    //Now we can check the expected value    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110", ledDisplay_n);
        $stop;
    end 
    
//LOCKED_KEY_INPUT_DISPLAY key number = 2
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(16){1'b1}},8'b1110_1101}; 
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011", ledDisplay_n);
        $stop;
    end

//LOCKED_KEY_INPUT_DISPLAY key number = 3
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock        
    keyInputValue_n = {{(12){1'b1}},12'b1110_1101_1011};    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_10110111_1001111", ledDisplay_n);
        $stop;
    end         


//LOCKED_KEY_INPUT_DISPLAY key number = 4 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(8){1'b1}},16'b1110_1101_1011_0111};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110", ledDisplay_n);
        $stop;
    end
    
//LOCKED_KEY_INPUT_DISPLAY key number = 5 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = {{(4){1'b1}},20'b1110_1101_1011_0111_1110};
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110_0000110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110_0000110", ledDisplay_n);
        $stop;
    end
//LOCKED_KEY_INPUT_DISPLAY key number = 6 
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = 24'b1110_1101_1011_0111_1110_0111;
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110_0000110__1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110_0000110__1100110", ledDisplay_n);
        $stop;
    end
    

//LOCKED_KEY_INPUT_DISPLAY key number = 6 The counter will keep displaying password if it is less than 500cycles.
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock         
    keyInputValue_n = 24'b1110_1101_1011_0111_1110_0111;
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0000110_1011011_1001111_1100110_0000110__1100110) begin
        $display("Error! Output ledDisplay_n = %B != 0000110_1011011_1001111_1100110_0000110__1100110", ledDisplay_n);
        $stop;
    end
    
//LOCKED_KEY_INPUT_DISPLAY key number = 6, the conuter is over 500 cycles. convert to open state
    repeat(510) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    keyInputValue_n = {(24){1'b1}};      
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b1011100_1110011_1111001_1010100_0000000_0000000) begin
        $display("Error! Output ledDisplay_n = %B != 1011100_1110011_1111001_1010100_0000000_0000000", ledDisplay_n);
        $stop;
    end 

//open display and maintain
    repeat(50) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    keyInputValue_n = {(24){1'b1}};      
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b1011100_1110011_1111001_1010100_0000000_0000000) begin
        $display("Error! Output ledDisplay_n = %B != 1011100_1110011_1111001_1010100_0000000_0000000", ledDisplay_n);
        $stop;
    end      
    
//convert to unlocked state
    repeat(510) @(posedge clock);      //Wait for a couple of clocks 
    @(posedge clock);    //At the rising edge of the clock 
    keyInputValue_n = {(24){1'b1}};      
    
    repeat(10) @(posedge clock);
    if (ledDisplay_n != ~42'b0111110_1010100_0111000_1011100_0111001_1111010) begin
        $display("Error! Output ledDisplay_n = %B != 0111110_1010100_0111000_1011100_0111001_1111010", ledDisplay_n);
        $stop;
    end
        repeat(50) @(posedge clock);         
        $display("Success!");
        $stop;
    end 
     
endmodule
