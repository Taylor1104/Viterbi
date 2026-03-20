`timescale 1ns/1ps
module vit_212_auto_tb;

    logic        clk;
    logic        rst_n;
    logic        en;
    logic [15:0] rx_data;
    logic [7:0]  o_data;
    logic        o_done;

    vit_212_top dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .en      (en),
        .rx_data (rx_data),
        .o_data  (o_data),
        .o_done  (o_done)
    );

    always #5 clk = ~clk;

    int fin, fout;
    string line_in, line_out;

    logic [15:0] in_vec;
    logic [7:0]  exp_vec;

    int test_id;
    int pass_cnt;
    int fail_cnt;


    // RESET TASK
    task automatic reset_dut;
    begin
        rst_n   = 1'b0;
        en      = 1'b0;
        rx_data = 16'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
    end
    endtask

    // RUN ONE TEST CASE
    task automatic run_one_case(
        input logic [15:0] encoded,
        input logic [7:0]  expected
    );
    begin
        reset_dut();

        rx_data = encoded;
        en      = 1'b1;

        // chờ hoàn tất traceback (theo clock)
        @(posedge clk);
        while (!o_done)
            @(posedge clk);

        // chờ thêm 1 cycle để data ổn định
        @(posedge clk);
        en = 1'b0;

        if (o_data !== expected) begin
            $display("=================================");
            $display("FAIL CASE %0d", test_id);
            $display("Input  (encoded) = %b", encoded);
            $display("Output (decoded) = %b", o_data);
            $display("Expected         = %b", expected);
            $display("=================================");
            fail_cnt++;
        end else begin
            $display("PASS CASE %0d : %b -> %b",
                     test_id, encoded, o_data);
            pass_cnt++;
        end

        repeat (3) @(posedge clk);
    end
    endtask

    // MAIN
    initial begin
        clk      = 1'b0;
        rst_n    = 1'b0;
        en       = 1'b0;
        rx_data  = 16'b0;

        pass_cnt = 0;
        fail_cnt = 0;
        test_id  = 0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        fin  = $fopen("input.txt",  "r");
        fout = $fopen("output.txt", "r");

        if (fin == 0 || fout == 0) begin
            $fatal("ERROR: Cannot open input.txt or output.txt");
        end

        while (!$feof(fin) && !$feof(fout)) begin
            void'($fgets(line_in,  fin));
            void'($fgets(line_out, fout));

            if ($sscanf(line_in,  "%b", in_vec)  != 1) continue;
            if ($sscanf(line_out, "%b", exp_vec) != 1) continue;

            test_id++;
            run_one_case(in_vec, exp_vec);
        end

        $display("=================================");
        $display("TEST SUMMARY");
        $display("TOTAL : %0d", test_id);
        $display("PASS  : %0d", pass_cnt);
        $display("FAIL  : %0d", fail_cnt);
        $display("=================================");

        $finish;
    end

endmodule
