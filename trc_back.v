module trc_back (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tb_en,
    input  wire [1:0] min_state,

    input  wire       tbu_out_00,
    input  wire       tbu_out_01,
    input  wire       tbu_out_10,
    input  wire       tbu_out_11,

    output reg        o_bit,
    output reg        o_valid,
    output reg        trc_done,

    output reg [2:0]  tb_idx
);

    reg [1:0] cur_state;
    reg [1:0] prev_state;
    reg       surv_bit;
    reg       active;

    always @(*) begin
        case (cur_state)
            2'b00: surv_bit = tbu_out_00;
            2'b01: surv_bit = tbu_out_01;
            2'b10: surv_bit = tbu_out_10;
            default: surv_bit = tbu_out_11;
        endcase
        prev_state = {cur_state[0], surv_bit};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_state <= 2'b00;
            tb_idx    <= 3'b000;
            o_bit     <= 1'b0;
            o_valid   <= 1'b0;
            trc_done  <= 1'b0;
            active    <= 1'b0;
        end else begin
            if (tb_en && !active) begin
                cur_state <= min_state;
                tb_idx    <= 3'd7;
                o_valid   <= 1'b0;
                trc_done  <= 1'b0;
                active    <= 1'b1;

            end else if (active) begin
                o_bit   <= cur_state[1];
                o_valid <= 1'b1;
                cur_state <= prev_state;

                if (tb_idx == 3'd0) begin
                    trc_done <= 1'b1;
                    active   <= 1'b0;
                end else begin
                    tb_idx <= tb_idx - 1'b1;
                end
            end else begin
                o_valid  <= 1'b0;
                trc_done <= 1'b0;
            end
        end
    end

endmodule

