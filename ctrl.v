module ctrl #(
    parameter PROC_CYCLES = 8,    // cycle xu ly 8 cap bit
    parameter TRC_DEPTH   = 15    // Traceback depth (5*K, K=3)
)(
    input  wire clk,
    input  wire rst,              
    input  wire en,             
    
    // Tin hieu en
    output reg  ext_en,
    output reg  bmu_en,
    output reg  acs_en,
    output reg  pmu_en,
    output reg  mem_en_wr,        // ghi vao mem
    output reg  mem_en_rd,        // doc tu mem
    output reg  trc_en,
    
    // Tin hieu trang thai
    output reg  done,             // hoan thanh
    output reg  busy              // dang xu ly
);

    localparam [2:0]
        S_IDLE     = 3'd0,
        S_FORWARD  = 3'd1,   // 8 cap bit
        S_TRC      = 3'd2,   // traceback
        S_DONE     = 3'd3;
    
    reg [2:0] state, next_state;
    
    // Counters
    reg [4:0] proc_cnt;   // dem 0?7 (8 cycles)
    reg [4:0] trc_cnt;    // dem 0?14 (15 cycles)
    
    // Thay doi trang thai
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Logic thay doi trang thai
    always @(*) begin
        next_state = state;
        
        case (state)
            S_IDLE: begin
                if (en) next_state = S_FORWARD;
            end
            
            S_FORWARD: begin
                if (proc_cnt == PROC_CYCLES - 1)
                    next_state = S_TRC;
            end
            
            S_TRC: begin
                if (trc_cnt == TRC_DEPTH - 1)
                    next_state = S_DONE;
            end
            
            S_DONE: begin
                next_state = S_IDLE; 
            end
            
            default: next_state = S_IDLE;
        endcase
    end
    
    // Output
    always @(*) begin
        ext_en    = 0;
        bmu_en    = 0;
        acs_en    = 0;
        pmu_en    = 0;
        mem_en_wr = 0;
        mem_en_rd = 0;
        trc_en    = 0;
        done      = 0;
        busy      = 1;
        
        case (state)
            S_IDLE: begin
                busy = 0;
            end
            
            S_FORWARD: begin
                // Cycle 0: ext
                if (proc_cnt == 0) begin
                    ext_en = 1;
                end
                // Cycle 1: ext + bmu
                else if (proc_cnt == 1) begin
                    ext_en = 1;
                    bmu_en = 1;
                end
                // Cycle 2-7: full pipeline
                else begin
                    ext_en    = 1;
                    bmu_en    = 1;
                    acs_en    = 1;
                    pmu_en    = 1;
                    mem_en_wr = 1;
                end
            end
            
            S_TRC: begin
                trc_en    = 1;
                pmu_en    = 1;  // TRC doc PM cuoi
                mem_en_rd = 1;  // TRC doc survivor bits
            end
            
            S_DONE: begin
                done = 1;
                busy = 0;
            end
        endcase
    end

    // logic dem
    always @(posedge clk) begin
        if (rst) begin
            proc_cnt <= 0;
            trc_cnt  <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    proc_cnt <= 0;
                    trc_cnt  <= 0;
                end
                
                S_FORWARD: begin
                    if (proc_cnt < PROC_CYCLES - 1)
                        proc_cnt <= proc_cnt + 1;
                end
                
                S_TRC: begin
                    if (trc_cnt < TRC_DEPTH - 1)
                        trc_cnt <= trc_cnt + 1;
                end
                
                S_DONE: begin
                    proc_cnt <= 0;
                    trc_cnt  <= 0;
                end
            endcase
        end
    end

endmodule
