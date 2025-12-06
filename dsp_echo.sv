`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2025 11:51:33 PM
// Design Name: 
// Module Name: dsp_echo
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

module dsp_echo #(
    parameter DELAY_SAMPLES    = 2000,   // ? 43 ms at 46 kHz
    parameter FEEDBACK_SHIFT   = 2       // feedback = 25%
)(
    input  logic        clk,
    input  logic        sample_en,        // one tick per sample (xadc_drdy)
    input  logic [11:0] sample_in,        // raw ADC sample
    output logic [11:0] sample_out        // processed sample
);

    // ---------------------------------------------
    // 1. Delay Line Memory (Circular Buffer)
    // ---------------------------------------------
    localparam ADDR_WIDTH = $clog2(DELAY_SAMPLES);

    logic [11:0] delay_mem [0:DELAY_SAMPLES-1];
    logic [ADDR_WIDTH-1:0] wr_addr = 0;

    logic [11:0] delayed_sample;

    // ---------------------------------------------
    // 2. Main Processing
    // ---------------------------------------------
    always_ff @(posedge clk) begin
        if (sample_en) begin
            // Read delayed sample before overwrite
            delayed_sample <= delay_mem[wr_addr];

            // Write new mixed sample into buffer (feedback loop)
            delay_mem[wr_addr] <= sample_in + (delayed_sample >> FEEDBACK_SHIFT);

            // Output the echo sample
            sample_out <= sample_in + (delayed_sample >> FEEDBACK_SHIFT);

            // Circular increment
            wr_addr <= wr_addr + 1;
        end
    end

endmodule

