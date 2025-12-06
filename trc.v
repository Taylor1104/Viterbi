//=============================================================
//  trc.v  -  Traceback Unit
//  - Thực hiện truy ngược trellis để sinh chuỗi bit đã giải mã
//  - Đọc dữ liệu survivor từ MEM (registered read → latency 1 clk)
//  - Chọn best-state dựa vào path metric từ PMU
//  - Mỗi bước traceback sinh 1 decoded bit và shift vào o_data
//=============================================================

module trc #(
    parameter L       = 8,        // độ dài traceback
    parameter ADDR_W  = 3,        // log2(L) = 3
    parameter PMW     = 5         // độ rộng path metric
)(
    input  wire              clk,
    input  wire              rst,        // active-high reset
    input  wire              trc_en,     // bắt đầu traceback

    // Path metric từ PMU
    input  wire [PMW-1:0]    pm_val_00,
    input  wire [PMW-1:0]    pm_val_01,
    input  wire [PMW-1:0]    pm_val_10,
    input  wire [PMW-1:0]    pm_val_11,

    // Survivor word từ MEM (registered-read)
    input  wire [3:0]        trc_rd_surv_word,

    // Xuất địa chỉ đọc tới MEM
    output reg  [ADDR_W-1:0] rd_addr,     // khai báo
                             
    // Dữ liệu giải mã
    output reg  [L-1:0]      o_data,      // khai báo
    output reg               o_done       // khai báo
);

    //===========================================================
    // 1. KHAI BÁO BIẾN NỘI BỘ 
    //===========================================================

    // FSM states
    reg [2:0] state;        
    initial state = 0;

    localparam IDLE      = 3'd0;
    localparam INIT      = 3'd1;
    localparam ISSUE_RD  = 3'd2;
    localparam WAIT_RD   = 3'd3;
    localparam PROCESS   = 3'd4;
    localparam DONE      = 3'd5;

    // state hiện tại trong traceback
    reg [1:0] state_cur;  
    initial state_cur = 2'b00;

    // state trước đó
    reg [1:0] prev_state; 
    initial prev_state = 2'b00;

    // biến tạm cho survivor bit
    reg surv_bit;        
    initial surv_bit = 1'b0;

    // biến tạm cho bit giải mã
    reg decode_bit;     
    initial decode_bit = 1'b0;

    // bộ đếm số bước traceback
    reg [ADDR_W:0] step_counter; 
    initial step_counter = 0;


    //===========================================================
    // 2. ALWAYS @(posedge clk) – RESET & FSM
    //===========================================================

    always @(posedge clk) begin
        
        //=======================================================
        // RESET
        //=======================================================
        if (rst) begin
            state         <= IDLE;
            rd_addr       <= 0;
            o_data        <= 0;
            o_done        <= 0;
            state_cur     <= 0;
            prev_state    <= 0;
            surv_bit      <= 0;
            decode_bit    <= 0;
            step_counter  <= 0;
        end

        //=======================================================
        // FSM HOẠT ĐỘNG
        //=======================================================
        else begin
            case (state)

            //---------------------------------------------------
            // IDLE – chờ tín hiệu trc_en
            //---------------------------------------------------
            IDLE: begin
                o_done <= 0;
                if (trc_en) begin
                    state <= INIT;
                end
            end

            //---------------------------------------------------
            // INIT – chọn best state và khởi tạo
            //---------------------------------------------------
            INIT: begin
                // chọn best-state từ 4 PM
                if (pm_val_00 <= pm_val_01 && pm_val_00 <= pm_val_10 && pm_val_00 <= pm_val_11)
                    state_cur <= 2'b00;
                else if (pm_val_01 <= pm_val_10 && pm_val_01 <= pm_val_11)
                    state_cur <= 2'b01;
                else if (pm_val_10 <= pm_val_11)
                    state_cur <= 2'b10;
                else
                    state_cur <= 2'b11;

                rd_addr      <= L - 1;
                step_counter <= 0;
                o_data       <= 0;
                o_done       <= 0;

                state        <= ISSUE_RD;
            end

            //---------------------------------------------------
            // ISSUE_RD – gửi rd_addr sang MEM
            //---------------------------------------------------
            ISSUE_RD: begin
                // MEM cần 1 clk để xuất dữ liệu
                state <= WAIT_RD;
            end

            //---------------------------------------------------
            // WAIT_RD – chờ MEM xuất survivor word
            //---------------------------------------------------
            WAIT_RD: begin
                state <= PROCESS;
            end

            //---------------------------------------------------
            // PROCESS – tính toán 1 bước traceback
            //---------------------------------------------------
            PROCESS: begin
                // survivor bit
                surv_bit   <= trc_rd_surv_word[state_cur];

                // bit giải mã = MSB của state_cur
                decode_bit <= state_cur[1];

                // shift-left, đưa bit mới vào LSB
                o_data <= (o_data << 1) | state_cur[1];

                // tính prev_state
                prev_state <= { state_cur[0],trc_rd_surv_word[state_cur] };
                state_cur  <= { state_cur[0],trc_rd_surv_word[state_cur] };

                // giảm rd_addr
                rd_addr <= rd_addr - 1;

                // tăng step counter
                step_counter <= step_counter + 1;

                // kiểm tra kết thúc
                if (step_counter == L-1)
                    state <= DONE;
                else
                    state <= ISSUE_RD;
            end

            //---------------------------------------------------
            // DONE – báo hoàn tất
            //---------------------------------------------------
            DONE: begin
                o_done <= 1'b1;

                // chờ trc_en hạ xuống
                if (!trc_en)
                    state <= IDLE;
            end

            endcase
        end
    end

endmodule

