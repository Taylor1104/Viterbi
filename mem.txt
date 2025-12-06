//===========================================================
//  mem.v  -  Survivor Memory Unit (SMU)
//  Lưu trữ survivor bit cho 4 trạng thái theo từng thời điểm
//  Mỗi ô nhớ lưu 4 bit dạng {s00, s01, s10, s11}
//
//  - Ghi: synchronous write khi mem_en_wr = 1
//  - Đọc: synchronous read khi mem_en_rd = 1
//
//  Chú thích tiếng Việt, tách riêng khai báo - reset - hoạt động
//===========================================================

module mem #(
    parameter ADDR_WIDTH = 3,      // Độ rộng địa chỉ -> 2^3 = 8 ô nhớ
    parameter DATA_W     = 4       // 4 survivor bit {s00,s01,s10,s11}
)(
    input  wire                  clk,
    input  wire                  rst,            // active-high reset

    // --- GHI ---
    input  wire                  mem_en_wr,      // enable ghi
    input  wire [ADDR_WIDTH-1:0] wr_addr,        // địa chỉ ghi
    input  wire                  mem_surv_00,    // survivor state 00
    input  wire                  mem_surv_01,    // survivor state 01
    input  wire                  mem_surv_10,    // survivor state 10
    input  wire                  mem_surv_11,    // survivor state 11

    // --- ĐỌC ---
    input  wire                  mem_en_rd,      // enable đọc
    input  wire [ADDR_WIDTH-1:0] rd_addr,        // địa chỉ đọc
    output reg  [DATA_W-1:0]     trc_rd_surv_word // word survivor cho TRC
);

    //===============================================================
    // 1. Khai báo bộ nhớ
    //===============================================================
    localparam DEPTH = (1 << ADDR_WIDTH);       // 8 ô nhớ

    reg [DATA_W-1:0] smem [0:DEPTH-1];          // mảng 8 x 4-bit

    integer i;

    //===============================================================
    // 2. Khối always xử lý Reset, Ghi, Đọc
    //===============================================================
    always @(posedge clk) begin
        
        //===========================================================
        // Reset bộ nhớ & output
        //===========================================================
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                smem[i] <= 4'b0000;

            trc_rd_surv_word <= 4'b0000;
        end 
        
        else begin
            //=======================================================
            // Ghi dữ liệu (synchronous write)
            //=======================================================
            if (mem_en_wr) begin
                smem[wr_addr] <= {mem_surv_00, mem_surv_01,
                                  mem_surv_10, mem_surv_11};
            end

            //=======================================================
            // Đọc dữ liệu (registered read)
            //=======================================================
            if (mem_en_rd) begin
                trc_rd_surv_word <= smem[rd_addr];
            end
            else begin
                trc_rd_surv_word <= trc_rd_surv_word;   // giữ nguyên
            end
        end
    end

endmodule
