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
    input start,
    input reset,
    input signal_in,
    input SW2,
    input SW3,
    output S2, S3,
    output [6:0] seg,
    output [3:0] an,
    output [15:0] LED,
    output pwm_signal,
    output rgb_output
);

    wire [2:0] rgb_output;
    reg [31:0] frequency;
    wire [31:0] red, green, blue;
    wire done_color;

    assign LED[2:0] = rgb_output;
    assign LED[3] = done_color;

    seven_segment_display ssd (
        .CLK100MHZ(CLK100MHZ),
        .frequency({5'b0, frequency}),
        .seg(seg),
        .an(an)
    );

    FrequencyToColorConverter f2 (
        .clk(CLK100MHZ),
        .reset(reset),
        .done_color(done_color),
        .red(red),
        .green(green),
        .blue(blue),
        .rgb_output(rgb_output)
    );

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

    always @(posedge CLK100MHZ) begin
        if (reset) begin
            frequency <= 0;
        end else if (SW2 == 1'b0 && SW3 == 1'b0) begin
            frequency <= red;
        end else if (SW2 == 1'b0 && SW3 == 1'b1) begin
            frequency <= green;
        end else if (SW2 == 1'b1 && SW3 == 1'b0) begin
            frequency <= blue;
        end else begin
            frequency <= 0;
        end
    end

    IR_emitter ire(
    .clk(CLK100MHZ),
    .start(1'b1),
    .rgb(rgb_output),
    .pwm_signal(pwm_signal)
    );
    endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////


module IR_emitter(
    input clk,                    
    input start, 
    input [2:0] rgb,
    output pwm_signal
    );
    reg [16:0]duty;
    reg [16:0] max_value;
    initial begin

    end
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps



//////////////////////////////////////////////////////////////////////////////////


module freq_meas(
    input CLK100MHZ,
    input signal_in,
    input reset,
    output reg [31:0] frequency,
    output reg done
);

    reg [31:0] edge_count;
    reg [31:0] time_counter;
    reg prev_signal_in;
    reg [31:0] clk_cycles_in_test_period = 'd1000000; // 0.01 seconds at 100 MHz

    initial begin
        edge_count = 0;
        time_counter = 0;
        frequency = 0;
        prev_signal_in = 0;
        done = 0;
    end

    always @(posedge CLK100MHZ or posedge reset) begin
        if (reset) begin
            edge_count <= 0;
            time_counter <= 0;
            frequency <= 0;
            prev_signal_in <= 0;
            done <= 0;
        end else begin
            time_counter <= time_counter + 1;

            // Edge detection
            if (prev_signal_in == 0 && signal_in == 1) begin
                edge_count <= edge_count + 1;
                $display("Edge detected: %d at time %t", edge_count, $time);
            end
            prev_signal_in <= signal_in;

            // Measurement period complete
            if (time_counter == clk_cycles_in_test_period) begin
                frequency <= edge_count; // Scaled for 0.1 second period
                done <= 1;
                $display("Measurement complete: Frequency = %d at time %t", frequency, $time);
                time_counter <= 0;
                edge_count <= 0;
            end else begin
                done <= 0;
            end
        end
    end
endmodule
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module seven_segment_display(
    input CLK100MHZ,
    input [31:0] frequency,
    output reg [6:0] seg,
    output reg [3:0] an
);

    reg [3:0] digit;
    reg [1:0] digit_select;
    reg [16:0] refresh_counter;
    reg [10:0] frequency_reg;

    reg [3:0] thousands;
    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;

    initial begin
        refresh_counter = 0;
        digit_select = 0;
    end

    always @(posedge CLK100MHZ) begin
        if(refresh_counter == 0) begin
            frequency_reg <= frequency;
        end

        thousands = (frequency_reg / 1000) % 10;
        hundreds  = (frequency_reg / 100) % 10;
        tens      = (frequency_reg / 10) % 10;
        ones      = frequency_reg % 10;

        refresh_counter <= refresh_counter + 1;
        if (refresh_counter >= 100000) begin
            refresh_counter <= 0;
            digit_select <= digit_select + 1;
        end
    end

    always @(*) begin
        case (digit_select)
            2'b00: begin
                an = 4'b1110;
                digit = ones;
            end
            2'b01: begin
                an = 4'b1101;
                digit = tens;
            end
            2'b10: begin
                an = 4'b1011;
                digit = hundreds;
            end
            2'b11: begin
                an = 4'b0111;
                digit = thousands;
            end
            default: begin
                an = 4'b1111;
            end
        endcase
    end

    always @(*) begin
        case (digit)
            4'b0000: seg = 7'b1000000; // 0
            4'b0001: seg = 7'b1111001; // 1
            4'b0010: seg = 7'b0100100; // 2
            4'b0011: seg = 7'b0110000; // 3
            4'b0100: seg = 7'b0011001; // 4
            4'b0101: seg = 7'b0010010; // 5
            4'b0110: seg = 7'b0000010; // 6
            4'b0111: seg = 7'b1111000; // 7
            4'b1000: seg = 7'b0000000; // 8
            4'b1001: seg = 7'b0010000; // 9
            default: seg = 7'b1111111; // Blank
        endcase
    end
endmodule   

