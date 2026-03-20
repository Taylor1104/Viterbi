module min_state (
    input  wire [3:0] pm_00,
    input  wire [3:0] pm_01,
    input  wire [3:0] pm_10,
    input  wire [3:0] pm_11,

    output reg  [1:0] min_state
);

    wire sel_01;
    wire sel_11;
    wire [3:0] min_0;
    wire [1:0] idx_0;
    wire [3:0] min_1;
    wire [1:0] idx_1;
    wire sel_final;

    assign sel_01 = (pm_01 < pm_00);
    assign sel_11 = (pm_11 < pm_10);

    assign min_0 = sel_01 ? pm_01 : pm_00;
    assign idx_0 = sel_01 ? 2'b01 : 2'b00;

    assign min_1 = sel_11 ? pm_11 : pm_10;
    assign idx_1 = sel_11 ? 2'b11 : 2'b10;

    assign sel_final = (min_1 < min_0);

    always @(*) begin
        min_state = sel_final ? idx_1 : idx_0;
    end

endmodule

