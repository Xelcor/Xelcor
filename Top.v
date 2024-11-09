`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2024 04:16:51 PM
// Design Name: 
// Module Name: Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input CLK100MHZ,
    input reset,
    input signal_in,
    input SW2,      //the switches select the frequency
    input SW3,      //the switches select the frequency
    output S2,S3,
    output [6:0] seg,
    output [3:0] an,
    output [15:0] LED,
    output [2:0] rgb_output
);
    wire [2:0] rgb_output;
    reg [10:0] frequency;            // Register to hold frequency value for seven-segment display
    wire [31:0] red, green, blue;    // Color frequency values from the color sensor
    wire done_color;                 // Done signal from the color sensor state machine                  // Signals to control the DF Color Sensor

    // Assign the RGB output to the lower 3 LEDs for color indication
    assign LED[2:0] = rgb_output;

    // Assign the frequency value to the upper LEDs for debugging
    assign LED[3] = done_color;

    // Seven-segment display for frequency value
    seven_segment_display ssd (
        .CLK100MHZ(CLK100MHZ),
        .frequency({5'b0,frequency}),  // Use the lower 11 bits of the frequency value
        .seg(seg),
        .an(an)
    );

    // Frequency to color converter instance (replacing ColorComparator)
    FrequencyToColorConverter f2 (
        .clk(CLK100MHZ),
        .reset(reset),
        .done_color(done_color),
        .red(red),
        .green(green),
        .blue(blue),
        .rgb_output(rgb_output)
    );

    // Color sensor state machine instance
    ColorSensorStateMachine csm (
        .clk(CLK100MHZ),
        .reset(reset),
        .signal_in(signal_in),
        .done_color(done_color),
        .red(red),
        .green(green),
        .blue(blue),
        .S2(S2),
        .S3(S3)
    );


// Frequency select logic for seven-segment display based on switches
   always @(posedge CLK100MHZ) begin
      if (SW2 == 1'b0 && SW3 == 1'b0) begin
         frequency = red[10:0];    // Display red frequency when switches are in 00 state
      end else if (SW2 == 1'b0 && SW3 == 1'b1) begin
         frequency = green[10:0];  // Display green frequency when switches are in 01 state
      end else if (SW2 == 1'b1 && SW3 == 1'b0) begin
         frequency = blue[10:0];   // Display blue frequency when switches are in 10 state
      end else begin
         frequency = 11'b0;        // Display 0 when switches are in 11 state (or no valid state)
      end
   end
endmodule
