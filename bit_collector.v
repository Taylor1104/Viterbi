module bit_collector (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tb_en,
    input  wire        o_bit,
    input  wire        o_valid,

    output reg  [7:0]  o_data,
    output reg         o_done
);
    reg [2:0] idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_data <= 8'b0;
            idx    <= 3'b0;
            o_done <= 1'b0;
        end else if (tb_en && o_valid) begin
            o_data[idx] <= o_bit;
            if (idx == 3'd7) begin
                o_done <= 1'b1;
                idx    <= 3'b0;
            end else begin
                idx <= idx + 1'b1;
                o_done <= 1'b0;
            end
        end else begin
            o_done <= 1'b0;
        end
    end

endmodule

