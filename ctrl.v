module ctrl (
    input  wire clk,
    input  wire rst_n,

    input  wire en,
    input  wire tb_done,

    output reg  load_rx,
    output reg  ext_en,
    output reg  pm_we,
    output reg  smu_we,
    output reg  tb_en,

    output reg  [2:0] fw_idx
);

    localparam IDLE            = 3'd0;
    localparam LOAD            = 3'd1;
    localparam FORWARD         = 3'd2;
    localparam FORWARD_COMMIT  = 3'd3;
    localparam TRACEBACK       = 3'd4;
    reg [2:0] state, state_n;
    // state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= state_n;
    end
    // fw_idx counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fw_idx <= 3'd0;
        else if (load_rx)
            fw_idx <= 3'd0;
        else if (state == FORWARD_COMMIT) begin
            if (fw_idx < 3'd7)
                fw_idx <= fw_idx + 1'b1;
        end
    end

    always @(*) begin
        load_rx = 1'b0;
        ext_en  = 1'b0;
        pm_we   = 1'b0;
        smu_we  = 1'b0;
        tb_en   = 1'b0;
        state_n = state;
        case (state)
            IDLE: begin
                if (en)
                    state_n = LOAD;
            end
            LOAD: begin
                load_rx = 1'b1;
                state_n = FORWARD;
            end
            FORWARD: begin
                ext_en  = 1'b1;     // phát symbol + tính ACS
                state_n = FORWARD_COMMIT;
            end
            FORWARD_COMMIT: begin
                pm_we  = 1'b1;      // ghi PM
                smu_we = 1'b1;      // ghi survivor
                if (fw_idx == 3'd7)
                    state_n = TRACEBACK;
                else
                    state_n = FORWARD;
            end
            TRACEBACK: begin
                tb_en = 1'b1;
                if (tb_done)
                    state_n = IDLE;
            end
            default: state_n = IDLE;
        endcase
    end

endmodule

