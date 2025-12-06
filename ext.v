`timescale 1ns / 1ps

module ext(
    input rst,
    input clk,
    input ext_en,
    input [15:0] i_data,
    output reg [1:0] bmu_din
);

reg [3:0] count;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        count   <= 4'd0;     // Bắt đầu từ LSB
        bmu_din <= 2'b00;
    end else begin
        if (ext_en) begin
            if (count < 15) begin
                bmu_din <= {i_data[count + 1], i_data[count]};
                count   <= count + 2;
            end else begin
                bmu_din <= {i_data[15], i_data[14]};
                count   <= 4'd0;     // reset lại để truyền lại từ đầu
            end
        end else begin
            bmu_din <= 2'b00;
            count   <= count;  // giữ nguyên
        end
    end
end

endmodule
