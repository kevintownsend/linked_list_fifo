module linked_list_fifo(rst, clk, push, push_fifo, pop, pop_fifo, d, q, empty, full, count, almost_full, free_count);
    parameter WIDTH = 64;
    parameter DEPTH = 2048;
    parameter FIFOS = 4;
    parameter GEN_COUNTERS = 1;
    parameter LOG2_FIFOS = log2(FIFOS-1);
    parameter LOG2_DEPTH = log2(DEPTH-1);
    parameter FIFO_COUNT = FIFOS;
    input rst;
    input clk;
    input push;
    input [LOG2_FIFOS-1:0] push_fifo;
    input pop;
    input [LOG2_FIFOS-1:0] pop_fifo;
    input [WIDTH-1:0] d;
    output [WIDTH-1:0] q;
    output empty;
    output full;
    //output [(LOG2_DEPTH+1)*(2**FIFOS)-1:0] count;
    output [(LOG2_DEPTH)*(FIFOS)-1:0] count;
    output reg almost_full;
    output reg [LOG2_DEPTH:0] free_count;

    wire pop_internal = pop && !empty;
    wire push_internal = push && !full;

    reg [LOG2_DEPTH - 1:0] count_internal [0:FIFOS - 1];
    genvar g;
    integer i;
    generate if(GEN_COUNTERS) begin: assign_count0
        for(g = 0; g < FIFOS; g = g + 1) begin: assign_count
            assign count[(g+1)*LOG2_DEPTH - 1 -:LOG2_DEPTH] = count_internal[g];
        end
        initial for(i = 0; i < FIFOS; i = i + 1)
            count_internal[i] = 0;

        always @(posedge clk) begin
            if(pop_internal && push_internal && push_fifo == pop_fifo) begin
            end else begin
                if(pop_internal)
                    count_internal[pop_fifo] = count_internal[pop_fifo] - 1;
                if(push_internal)
                    count_internal[push_fifo] = count_internal[push_fifo] + 1;
            end
        end
    end else begin
        assign count = 0;
    end endgenerate


    reg [WIDTH-1:0] ram [DEPTH - 1:0];
    reg [LOG2_DEPTH:0] linked_ram [DEPTH - 1:0];

    reg ram_we;
    reg [LOG2_DEPTH-1:0] ram_addr_a, ram_addr_b;
    reg [WIDTH-1:0] ram_d, ram_q;
    reg [LOG2_DEPTH:0] linked_ram_d;

    reg [WIDTH-1:0] r_q;
    reg [LOG2_DEPTH-1:0] r_beg [FIFOS-1:0];
    reg [LOG2_DEPTH-1:0] r_end [FIFOS-1:0];
    reg [LOG2_DEPTH-1:0] beg_next, end_next;
    reg c_empty;
    reg [LOG2_FIFOS-1:0] beg_ptr, end_ptr;
    reg [LOG2_DEPTH:0] free, next_free;
    reg beg_we, end_we;

    initial for(i = 0; i < DEPTH; i = i + 1) begin
        linked_ram[i] = i + 1;
    end
    initial for(i = 0; i < FIFOS; i = i + 1) begin
        r_beg[i] = i;
        r_end[i] = i;
    end
    initial free = FIFOS;
    initial free_count = DEPTH - FIFOS;
    always @(posedge clk) begin
        if(pop_internal & push_internal) begin
        end else if(pop_internal) begin
            free_count <= free_count + 1;
        end else if(push_internal) begin
            free_count <= free_count - 1;
        end
    end
    always @*
        if(free_count < 2)
            almost_full = 1;
        else
            almost_full = 0;

    always @(posedge clk) begin
        if(ram_we) begin
            ram[ram_addr_a] <= ram_d;
        end
        ram_q <= ram[ram_addr_b];
    end
    assign q = ram_q;
    always @*
        ram_d = d;

    always @(posedge clk) begin
        if(ram_we) begin
            linked_ram[ram_addr_a] <= linked_ram_d;
        end
    end
    wire [LOG2_DEPTH:0] linked_ram_q = linked_ram[ram_addr_b];


    always @(posedge clk) begin
        if(beg_we)
            r_beg[beg_ptr] <= beg_next;
        if(end_we)
            r_end[end_ptr] <= end_next;
    end

    wire [LOG2_DEPTH-1:0] beg_curr = r_beg[beg_ptr];
    wire [LOG2_DEPTH-1:0] end_curr = r_end[end_ptr];
    generate if(GEN_COUNTERS) begin: assign_empty
        wire count_empty = count_internal[pop_fifo] == 0;
        assign empty = count_empty;
    end else begin
        wire [LOG2_DEPTH-1:0] empty_check = r_end[beg_ptr];
        always @* begin
            if(empty_check == beg_curr)
                c_empty = 1;
            else
                c_empty = 0;
        end
        assign empty = c_empty;
    end endgenerate

    always @(posedge clk) begin
        free <= next_free;
    end

    always @* begin
        ram_we = 0;
        beg_next = 0;
        beg_we = 0;
        end_we = 0;
        end_next = 0;
        beg_ptr = pop_fifo;
        end_ptr = push_fifo;
        next_free = free;
        ram_addr_a = end_curr;
        ram_addr_b = beg_curr;
        linked_ram_d = 0;
        if(push_internal && pop_internal) begin
            ram_we = 1;
            beg_we = 1;
            end_we = 1;
            ram_addr_a = end_curr;
            linked_ram_d = beg_curr;
            end_ptr = push_fifo;
            beg_ptr = pop_fifo;
            end_next = beg_curr;
            beg_next = linked_ram_q;
            ram_addr_b = beg_curr;
        end else if(push_internal) begin
            ram_we = 1;
            end_we = 1;
            ram_addr_a = end_curr;
            linked_ram_d = free;
            end_ptr = push_fifo;
            end_next = free;
            ram_addr_b = free;
            next_free = linked_ram_q;
        end else if(pop_internal) begin
            beg_we = 1;
            beg_next = linked_ram_q;
            ram_addr_b = beg_curr;
            ram_addr_a = beg_curr;
            next_free = beg_curr;
            ram_we = 1;
            linked_ram_d = free;
        end
    end
    integer error;
    initial error = 0;

    assign full = free[LOG2_DEPTH];
    `include "log2.vh"

    always @(posedge clk) begin
        if(push && full) begin
            $display("ERROR: Overflow at %m");
            //$finish;
        end
    end
endmodule
