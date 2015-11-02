module linked_fifo_gold(rst, clk, push, push_fifo, pop, pop_fifo, d, q, empty, full, count);
    parameter WIDTH = 8;
    parameter DEPTH = 32;
    parameter FIFOS = 8;
    parameter FIFO_LOG2 = log2(FIFOS-1);
    parameter DEPTH_LOG2 = log2(DEPTH-1);
    input rst, clk, push;
    input [FIFO_LOG2-1:0] push_fifo;
    input pop;
    input [FIFO_LOG2-1:0] pop_fifo;
    input [WIDTH-1:0] d;
    output reg [WIDTH-1:0] q;
    output reg empty, full;
    output reg [(DEPTH_LOG2+1)*FIFOS-1:0] count;

    reg [WIDTH-1:0] memory [0:FIFOS-1][0:DEPTH-1];
    reg [DEPTH_LOG2:0] r_beg [0:FIFOS-1];
    reg [DEPTH_LOG2:0] r_end [0:FIFOS-1];

    integer i;
    always @(posedge clk) begin
        if(rst) begin
            for(i=0; i < FIFOS; i=i+1) begin
                r_beg[i] <= 0;
                r_end[i] <= 0;
            end
        end else begin
            if(push) begin
                r_end[push_fifo] <= r_end[push_fifo] + 1;
            end
            if(pop) begin
                r_beg[pop_fifo] <= r_beg[pop_fifo] + 1;
            end

        end
        q <= memory[pop_fifo][r_beg[pop_fifo][DEPTH_LOG2-1:0]];
        memory[push_fifo][r_end[push_fifo][DEPTH_LOG2-1:0]] <= d;
    end
    always @* begin
        empty = r_beg[pop_fifo] == r_end[pop_fifo];
        //TODO: full
        full = 0;
        //TODO: count
        count = 0;
    end
    always @(posedge clk) begin
        if(empty && pop) begin
            $display("ERROR: underflow: %m");
            $finish;
        end
    end
    //TODO finish
    `include "log2.vh"
endmodule
