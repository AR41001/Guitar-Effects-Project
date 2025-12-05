`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2025 12:32:14 PM
// Design Name: 
// Module Name: XADC
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
    input  logic clk,            // 100 MHz clock
    input  logic vauxp6,         // VAUX4 analog inputs
    input  logic vauxn6,
    output logic [6:0] seg,      // seven segment segments
    output logic [3:0] an        // anode control
);

    // ============================================================
    // 1. XADC SIGNALS
    // ============================================================
    logic [15:0] xadc_do;
    logic        xadc_drdy;

    // XADC instantiation
    xadc_wiz_0 XADC_inst (
        .dclk_in(clk),
        .reset_in(1'b0),
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .daddr_in(8'h16),   // Address for VAUX4
        .den_in(1'b1),
        .dwe_in(1'b0),
        .di_in(16'b0),
        .do_out(xadc_do),
        .drdy_out(xadc_drdy)
    );

    // ============================================================
    // 2. Capture 12-bit ADC Output
    // ============================================================
    logic [11:0] adc_value;

    always_ff @(posedge clk) begin
        if (xadc_drdy)
            adc_value <= xadc_do[15:4];   // Top 12 bits of conversion
    end

    // ============================================================
    // 3. Scale 12-bit ADC (0-4095) to 0-999 for display
    // ============================================================
    // (adc_value / 4095) * 999
    logic [9:0] scaled_value;

    always_comb begin
        scaled_value = (adc_value * 999) / 4095;
    end

    // ============================================================
    // 4. Convert to BCD (3 digits)
    // ============================================================
    logic [3:0] hundreds, tens, ones;

    always_comb begin
        hundreds = scaled_value / 100;
        tens     = (scaled_value % 100) / 10;
        ones     = scaled_value % 10;
    end

    // ============================================================
    // 5. Seven Segment Multiplexing (1 kHz)
    // ============================================================
    logic [16:0] refresh_cnt;
    logic [1:0]  digit_select;

    always_ff @(posedge clk)
        refresh_cnt <= refresh_cnt + 1;

    assign digit_select = refresh_cnt[16:15]; // slow selection

    logic [3:0] current_digit;

    always_comb begin
        case (digit_select)
            2'b00: begin
                an = 4'b1110;  // digit 0 ON
                current_digit = ones;
            end
            2'b01: begin
                an = 4'b1101;
                current_digit = tens;
            end
            2'b10: begin
                an = 4'b1011;
                current_digit = hundreds;
            end
            default: begin
                an = 4'b0111;      // unused digit
                current_digit = 4'd0;
            end
        endcase
    end

    // ============================================================
    // 6. Segment Decoder (HEX to Seven-Segment)
    // ============================================================
    always_comb begin
        case (current_digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            default: seg = 7'b1111111; // blank
        endcase
    end

endmodule

