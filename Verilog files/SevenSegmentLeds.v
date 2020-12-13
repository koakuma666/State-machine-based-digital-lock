/*
 * Top
 * ----------------
 * By: MorseMeow
 * For: State machine based digital lock 
 * Date: May 2020
 *
 * Description
 * -----------
 * The module is a sublevel module to output 7-segment leds values according to the states. 
 *
 */
module SevenSegmentLeds #(
    parameter KEY_NUMBERS = 4,                                                           //The number of keys pressed, that is, the length of the password
    parameter SEGMENT_NUMBER = 7,                                                        //Number of segments
    parameter BIT_WIDTH = 6,                                                             //leds width
    parameter KEY_WIDTH = 4,                                                             //Number of Keys KEY[3:0]    
    parameter STATE_NUMBERS_SOTRE_WIDTH = 4
)(
    input      [BIT_WIDTH*KEY_NUMBERS-1:0]          keyValueStore,                       //Key input value storage
    input      [STATE_NUMBERS_SOTRE_WIDTH-1:0]      stateOutputs,                        //Every status outputs    
    output     [SEGMENT_NUMBER*BIT_WIDTH-1:0]       ledDisplay_n                         //led display outputs    
    
);

reg [SEGMENT_NUMBER*BIT_WIDTH-1:0]       ledDisplay;

localparam UNLOCKED_STATE  = 4'd0;                                                       //Initial state, showing unlocked
localparam UNLOCKED_KEY_INPUT_DISPLAY = 4'd1;                                            //Unlocked, the key input shows the digital status
localparam UNLOCKED_KEY_INPUT_OVERTIME = 4'd2;                                           //Under the key input, the key input times out, and displays overtime
localparam RE_ENTER_STATE = 4'd3;                                                        //Unlocked, the key input is complete, the first pass value is saved, and the re-enter is displayed
localparam RE_ENTER_KEY_INPUT_DISPLAY = 4'd4;                                            //Re-enter the key to enter the display number
localparam RE_ENTER_KEY_INPUT_OVERTIME = 4'd5;                                           //RE-ENTER key input timeout, display overtime
localparam RE_ENTER_KEY_NOT_MATCH_ERROR = 4'd6;                                          //In RE-ENTER, the second key input is compared with the first pass, it does not match, and error is displayed
localparam LOCKED_STATE = 4'd7;                                                          //In RE-ENTER, the two input values match and enter the locked state
localparam LOCKED_STATE_KEY_INPUT_DISPLAY = 4'd8;                                        //In the LOCKED state, the key input shows the number
localparam LOCKED_STATE_KEY_INPUT_OVERTIME = 4'd9;                                       //In the locked state, the key input times out, and displays overtime
localparam LOCKED_STATE_NOT_MATCH_ERROR = 4'd10;                                         //In the locked state, the key input does not match the stored second key input value, and error is displayed
localparam OPEN_STATE = 4'd11;                                                           //In the LOCKED state, the key input matches the stored second key input value, and it is successfully unlocked, showing OPEN 

assign ledDisplay_n = ~ledDisplay;                                                       //Because led is active low, so invert
            integer i;  
            integer j;
            integer k;            
always @ (*) begin
    case (stateOutputs)
        UNLOCKED_STATE: begin
            ledDisplay = 42'b0111110_1010100_0111000_1011100_0111001_1111010;            //display "unlock"
        end
        UNLOCKED_KEY_INPUT_DISPLAY: begin
            //Every four-bit key input corresponds to every seven-bit output of led
            //integer i;      
            for (i = 0; i < BIT_WIDTH; i = i + 1) begin: iloop
                case (keyValueStore[KEY_WIDTH*i+:KEY_WIDTH])                             
                    4'b0001: ledDisplay[SEGMENT_NUMBER*i+:SEGMENT_NUMBER] = 7'b0000110;  //display the number of 1
                    4'b0010: ledDisplay[SEGMENT_NUMBER*i+:SEGMENT_NUMBER] = 7'b1011011;  //display the number of 2
                    4'b0100: ledDisplay[SEGMENT_NUMBER*i+:SEGMENT_NUMBER] = 7'b1001111;  //display the number of 3
                    4'b1000: ledDisplay[SEGMENT_NUMBER*i+:SEGMENT_NUMBER] = 7'b1100110;  //display the number of 4
                    default: ledDisplay[SEGMENT_NUMBER*i+:SEGMENT_NUMBER] = 7'b0000000;  //nothing to display
                endcase
            end
        end
        UNLOCKED_KEY_INPUT_OVERTIME: begin
            ledDisplay = 42'b1011100_1100010_1111000_0010000_1010101_1111001;            //display "ovtime" 
        end
        RE_ENTER_STATE: begin
            ledDisplay = 42'b1010000_1111001_1111001_1010100_1111000_1010000;            //display "reentr"
        end
        RE_ENTER_KEY_INPUT_DISPLAY: begin
            //Every four-bit key input corresponds to every seven-bit output of led
        //integer j;    
        for (j = 0; j < BIT_WIDTH; j = j + 1) begin: jloop
                case (keyValueStore[KEY_WIDTH*j+:KEY_WIDTH])  
                    4'b0001: ledDisplay[SEGMENT_NUMBER*j+:SEGMENT_NUMBER] = 7'b0000110;  //display the number of 1
                    4'b0010: ledDisplay[SEGMENT_NUMBER*j+:SEGMENT_NUMBER] = 7'b1011011;  //display the number of 2
                    4'b0100: ledDisplay[SEGMENT_NUMBER*j+:SEGMENT_NUMBER] = 7'b1001111;  //display the number of 3
                    4'b1000: ledDisplay[SEGMENT_NUMBER*j+:SEGMENT_NUMBER] = 7'b1100110;  //display the number of 4
                    default: ledDisplay[SEGMENT_NUMBER*j+:SEGMENT_NUMBER] = 7'b0000000;  //nothing to display
                endcase
            end
        end
        RE_ENTER_KEY_INPUT_OVERTIME: begin
            ledDisplay = 42'b1011100_1100010_1111000_0010000_1010101_1111001;            //display "ovtime"
        end
        RE_ENTER_KEY_NOT_MATCH_ERROR: begin
            ledDisplay = 42'b1111001_1010000_1010000_1011100_1010000_0000000;            //display "error"
        end          
        LOCKED_STATE: begin          
            ledDisplay = 42'b0111000_1011100_0111001_1111010_1111001_1011110;            //display "locked"
        end
        LOCKED_STATE_KEY_INPUT_DISPLAY: begin
            //Every four-bit key input corresponds to every seven-bit output of led
        //integer k;
            for (k = 0; k < BIT_WIDTH; k = k + 1) begin:kloop
                case (keyValueStore[KEY_WIDTH*k+:KEY_WIDTH])  
                    4'b0001: ledDisplay[SEGMENT_NUMBER*k+:SEGMENT_NUMBER] = 7'b0000110;  //display the number of 1
                    4'b0010: ledDisplay[SEGMENT_NUMBER*k+:SEGMENT_NUMBER] = 7'b1011011;  //display the number of 2
                    4'b0100: ledDisplay[SEGMENT_NUMBER*k+:SEGMENT_NUMBER] = 7'b1001111;  //display the number of 3
                    4'b1000: ledDisplay[SEGMENT_NUMBER*k+:SEGMENT_NUMBER] = 7'b1100110;  //display the number of 4
                    default: ledDisplay[SEGMENT_NUMBER*k+:SEGMENT_NUMBER] = 7'b0000000;  //nothing to display
                endcase
            end
        end
        LOCKED_STATE_KEY_INPUT_OVERTIME: begin
            ledDisplay = 42'b1011100_1100010_1111000_0010000_1010101_1111001;            //display "ovtime"
        end                                                                              
        LOCKED_STATE_NOT_MATCH_ERROR: begin                                              
            ledDisplay = 42'b1111001_1010000_1010000_1011100_1010000_0000000;            //display "error"
        end                                                                              
        OPEN_STATE: begin                                                                
            ledDisplay = 42'b1011100_1110011_1111001_1010100_0000000_0000000;            //display "open"
        end
        default: begin
            ledDisplay = 42'b0;
        end
    endcase
end

endmodule 
