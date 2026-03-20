`timescale 1ns/1ps
module single_case_tb;
    reg clk;
    reg rst_n;
    always #10 clk = ~clk;   
    reg         en;
    reg [15:0]  rx_data;
    wire [7:0]  o_data;
    wire        o_done;

    vit_212_top dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .en      (en),
        .rx_data (rx_data),
        .o_data  (o_data),
        .o_done  (o_done)
    );

    reg [7:0] expected;

    initial begin
        clk      = 1'b0;
        rst_n    = 1'b0;
        en       = 1'b0;
        rx_data  = 16'b0;
        expected = 8'b0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        @(posedge clk);
        rx_data  <= 16'b1110000101111110;  // encoded input
        expected <= 8'b10110010;           // expected decoded
        en       <= 1'b1;

        // WAIT FOR DONE (sync clk)
        @(posedge clk);
        while (!o_done)
            @(posedge clk);

        // ch? thêm 1 cycle ?? data ?n ??nh
        @(posedge clk);
        en <= 1'b0;


        // CHECK RESULT
        if (o_data === expected) begin
            $display("======================================");
            $display("PASS SINGLE CASE");
            $display("Input  (encoded) = %b", rx_data);
            $display("Output (decoded) = %b", o_data);
            $display("Expected         = %b", expected);
            $display("======================================");
        end else begin
            $display("======================================");
            $display("FAIL SINGLE CASE");
            $display("Input  (encoded) = %b", rx_data);
            $display("Output (decoded) = %b", o_data);
            $display("Expected         = %b", expected);
            $display("======================================");
        end

        repeat (3) @(posedge clk);
        $finish;
    end

endmodule

