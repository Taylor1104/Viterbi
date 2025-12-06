//==============================================================
//  pmu.v  –  Path Metric Unit cho mã tích chập (2,1,2)
//==============================================================

module pmu (
    input  wire         clk,                // clock hệ thống
    input  wire         rst,                // reset đồng bộ mức thấp
    input  wire         pmu_en,             // enable cập nhật pmu

    //==========================================================
    //  PM mới từ khối acs (5 bit mỗi PM)
    //==========================================================
    input  wire [4:0]   pm_val_next_00,
    input  wire [4:0]   pm_val_next_01,
    input  wire [4:0]   pm_val_next_10,
    input  wire [4:0]   pm_val_next_11,

    //==========================================================
    //  PM hiện tại xuất sang khối acs và trc
    //==========================================================
    output reg  [4:0]   pm_val_00,
    output reg  [4:0]   pm_val_01,
    output reg  [4:0]   pm_val_10,
    output reg  [4:0]   pm_val_11
);

    //==========================================================
    //  Reset và cập nhật PM
    //==========================================================
    always @(posedge clk) begin
        if (!rst) begin
            // Trạng thái 00 là trạng thái bắt đầu → PM = 0
            pm_val_00 <= 5'd0;

            // Các trạng thái còn lại được gán giá trị "vô cùng"
            pm_val_01 <= 5'h1F;   // INF = 11111
            pm_val_10 <= 5'h1F;
            pm_val_11 <= 5'h1F;

        end else begin
            if (pmu_en) begin
                //==================================================
                //  Ghi 4 PM mới do acs cung cấp
                //==================================================
                pm_val_00 <= pm_val_next_00;
                pm_val_01 <= pm_val_next_01;
                pm_val_10 <= pm_val_next_10;
                pm_val_11 <= pm_val_next_11;
            end
            // Nếu pmu_en = 0 → giữ nguyên giá trị (không làm gì)
        end
    end

endmodule
