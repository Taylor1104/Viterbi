//==============================================================
//  acs.v  –  Add – Compare – Select
//==============================================================

module acs (
    input  wire        clk,
    input  wire        rst,
    input  wire        acs_en,

    //==========================================================
    //  BM: khoảng cách Hamming cho từng nhánh (2 bit)
    //  Mapping theo LSB-first:
    //  00 ← 00(op0), 01(op4)
    //  01 ← 10(op2), 11(op6)
    //  10 ← 00(op1), 01(op5)
    //  11 ← 10(op3), 11(op7)
    //==========================================================
    input  wire [1:0]  acs_op0,
    input  wire [1:0]  acs_op4,
    input  wire [1:0]  acs_op1,
    input  wire [1:0]  acs_op5,
    input  wire [1:0]  acs_op2,
    input  wire [1:0]  acs_op6,
    input  wire [1:0]  acs_op3,
    input  wire [1:0]  acs_op7,

    //==========================================================
    //  PM hiện tại từ PMU (5 bit)
    //==========================================================
    input  wire [4:0]  pm_val_00,
    input  wire [4:0]  pm_val_01,
    input  wire [4:0]  pm_val_10,
    input  wire [4:0]  pm_val_11,

    //==========================================================
    //  PM mới (ACS output) ghi vào PMU ở posedge clk
    //==========================================================
    output reg  [4:0]  pm_val_next_00,
    output reg  [4:0]  pm_val_next_01,
    output reg  [4:0]  pm_val_next_10,
    output reg  [4:0]  pm_val_next_11,

    //==========================================================
    //  Survivor bits cho TRC
    //==========================================================
    output reg         mem_surv_00,
    output reg         mem_surv_01,
    output reg         mem_surv_10,
    output reg         mem_surv_11
);

    //==========================================================
    //  Tính toán PM candidate cho từng trạng thái đích
    //  Tất cả đều dựa trên bảng mapping LSB-first trong báo cáo
    //==========================================================

    // ---------- Trạng thái đích 00 ----------
    wire [5:0] pm00_cand0 = pm_val_00 + acs_op0;   // từ 00
    wire [5:0] pm00_cand1 = pm_val_01 + acs_op4;   // từ 01

    // ---------- Trạng thái đích 01 ----------
    wire [5:0] pm01_cand0 = pm_val_10 + acs_op2;   // từ 10
    wire [5:0] pm01_cand1 = pm_val_11 + acs_op6;   // từ 11

    // ---------- Trạng thái đích 10 ----------
    wire [5:0] pm10_cand0 = pm_val_00 + acs_op1;   // từ 00
    wire [5:0] pm10_cand1 = pm_val_01 + acs_op5;   // từ 01

    // ---------- Trạng thái đích 11 ----------
    wire [5:0] pm11_cand0 = pm_val_10 + acs_op3;   // từ 10
    wire [5:0] pm11_cand1 = pm_val_11 + acs_op7;   // từ 11

    //==========================================================
    //  Chốt kết quả tại posedge clk
    //==========================================================
    always @(posedge clk) begin
        if (!rst) begin
            // Reset → toàn bộ PM_next = 0, survivor = 0
            pm_val_next_00 <= 5'd0;
            pm_val_next_01 <= 5'd0;
            pm_val_next_10 <= 5'd0;
            pm_val_next_11 <= 5'd0;

            mem_surv_00    <= 1'b0;
            mem_surv_01    <= 1'b0;
            mem_surv_10    <= 1'b0;
            mem_surv_11    <= 1'b0;

        end else if (acs_en) begin
            //=============================
            //  Trạng thái 00
            //=============================
            if (pm00_cand0 <= pm00_cand1) begin
                pm_val_next_00 <= pm00_cand0[4:0];
                mem_surv_00    <= 1'b0;  // chọn nhánh từ 00
            end else begin
                pm_val_next_00 <= pm00_cand1[4:0];
                mem_surv_00    <= 1'b1;  // chọn nhánh từ 01
            end

            //=============================
            //  Trạng thái 01
            //=============================
            if (pm01_cand0 <= pm01_cand1) begin
                pm_val_next_01 <= pm01_cand0[4:0];
                mem_surv_01    <= 1'b0;  // từ 10
            end else begin
                pm_val_next_01 <= pm01_cand1[4:0];
                mem_surv_01    <= 1'b1;  // từ 11
            end

            //=============================
            //  Trạng thái 10
            //=============================
            if (pm10_cand0 <= pm10_cand1) begin
                pm_val_next_10 <= pm10_cand0[4:0];
                mem_surv_10    <= 1'b0;  // từ 00
            end else begin
                pm_val_next_10 <= pm10_cand1[4:0];
                mem_surv_10    <= 1'b1;  // từ 01
            end

            //=============================
            //  Trạng thái 11
            //=============================
            if (pm11_cand0 <= pm11_cand1) begin
                pm_val_next_11 <= pm11_cand0[4:0];
                mem_surv_11    <= 1'b0;  // từ 10
            end else begin
                pm_val_next_11 <= pm11_cand1[4:0];
                mem_surv_11    <= 1'b1;  // từ 11
            end

        end
        // acs_en = 0 → giữ nguyên (không cập nhật)
    end

endmodule
