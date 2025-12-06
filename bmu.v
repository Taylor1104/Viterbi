module bmu (
    input [1:0] bmu_din ,     
    input rst,           
    input bmu_en,      
    input clk, 
    output reg [1:0] acs_op0, // Khoảng cách đến output 00 (state00→state00)
    output reg [1:0] acs_op1, // Khoảng cách đến output 11 (state00→state10)
    output reg [1:0] acs_op2, // Khoảng cách đến output 10 (state10→state01)
    output reg [1:0] acs_op3, // Khoảng cách đến output 01 (state10→state11)
    output reg [1:0] acs_op4, // Khoảng cách đến output 11 (state01→state00)
    output reg [1:0] acs_op5, // Khoảng cách đến output 00 (state01→state10)
    output reg [1:0] acs_op6, // Khoảng cách đến output 01 (state11→state01)
    output reg [1:0] acs_op7  // Khoảng cách đến output 10 (state11→state11)
);

// Hàm tính khoảng cách Hamming giữa 2 vector 2-bit
function [1:0] calculate_hamming_distance;
    input [1:0] received;
    input [1:0] expected;
    begin
        calculate_hamming_distance = (received[0] != expected[0]) + 
                                   (received[1] != expected[1]);
    end
endfunction

// Logic chính tính toán branch metrics
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset: đặt tất cả branch metrics về 0
        {acs_op0, acs_op1, acs_op2, acs_op3, acs_op4, acs_op5, acs_op6, acs_op7} = 0;
    end else if (bmu_en) begin
        // Tính khoảng cách cho 8 chuyển trạng thái có thể
        acs_op0 <= calculate_hamming_distance(bmu_din, 2'b00);  // state00→state00
        acs_op1 <= calculate_hamming_distance(bmu_din, 2'b11);  // state00→state10
        acs_op2 <= calculate_hamming_distance(bmu_din, 2'b10);  // state10→state01
        acs_op3 <= calculate_hamming_distance(bmu_din, 2'b01);  // state10→state11
        acs_op4 <= calculate_hamming_distance(bmu_din, 2'b11);  // state01→state00
        acs_op5 <= calculate_hamming_distance(bmu_din, 2'b00);  // state01→state10
        acs_op6 <= calculate_hamming_distance(bmu_din, 2'b01);  // state11→state01
        acs_op7 <= calculate_hamming_distance(bmu_din, 2'b10);  // state11→state11
    end else begin
        // Khi không enable, giữ output ở 0
        {acs_op0, acs_op1, acs_op2, acs_op3, acs_op4, acs_op5, acs_op6, acs_op7} = 0;
    end
end

endmodule