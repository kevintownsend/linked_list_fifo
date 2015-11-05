module linked_list_fifo(rst, clk, push, push_fifo, pop, pop_fifo, d, q, empty, full, count, almost_full, free_count);
    parameter WIDTH = 8;
    parameter DEPTH = 32;
    parameter FIFOS = 8;
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
    output [(LOG2_DEPTH+1)*(2**FIFOS)-1:0] count;
    output reg almost_full;
    output reg [LOG2_DEPTH:0] free_count;


    reg [WIDTH-1:0] ram [DEPTH - 1:0];
    reg [LOG2_DEPTH:0] linked_ram [DEPTH - 1:0];
    reg ram_we;
    reg [LOG2_DEPTH-1:0] ram_addr_a, ram_addr_b;
    reg [WIDTH-1:0] ram_d, ram_q;
    reg [LOG2_DEPTH:0] linked_ram_d, linked_ram_q;

    reg [WIDTH-1:0] r_q;
    reg [LOG2_DEPTH-1:0] r_beg [FIFOS-1:0];
    reg [LOG2_DEPTH-1:0] r_end [FIFOS-1:0];
    reg [LOG2_DEPTH-1:0] beg_next, beg_curr, end_next, end_curr;
    reg [LOG2_DEPTH-1:0] empty_check;
    reg c_empty;
    reg [LOG2_FIFOS-1:0] beg_ptr, end_ptr;
    reg [LOG2_DEPTH:0] free, next_free;
    reg beg_we, end_we;
    integer i, j, k;
    reg [LOG2_DEPTH:0] rst_counter, next_rst_counter;
    reg [1:0] state, next_state;
    `define RST1 0
    `define RST2 1
    `define STEADY 2

    always @(posedge clk) begin
        if(state != `STEADY) begin
            free_count <= DEPTH-FIFOS;
        end else if(pop & push) begin
        end else if(pop) begin
            free_count <= free_count + 1;
        end else if(push) begin
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
    always @*
        linked_ram_q = linked_ram[ram_addr_b];


    always @(posedge clk) begin
        if(beg_we)
            r_beg[beg_ptr] <= beg_next;
        if(end_we)
            r_end[end_ptr] <= end_next;
    end

    always @* begin
        beg_curr = r_beg[beg_ptr];
        end_curr = r_end[end_ptr];
        empty_check = r_end[beg_ptr];
    end
    always @* begin
        if(empty_check == beg_curr)
            c_empty = 1;
        else
            c_empty = 0;
    end
    assign empty = c_empty;

    always @* begin
        if(rst) begin
            next_rst_counter = 0;
        end else if(rst_counter[LOG2_DEPTH] != 1) begin
            next_rst_counter = rst_counter + 1;
        end else
            next_rst_counter = DEPTH;
    end
    always @(posedge clk)
        rst_counter <= next_rst_counter;

    always @* begin
        if(rst)
            next_state = `RST1;
        else if((state == `RST1) && (next_rst_counter == FIFOS))
            next_state = `RST2;
        else if(rst_counter[LOG2_DEPTH] == 1)
            next_state = `STEADY;
        else
            next_state = state;
    end
    always @(posedge clk) begin
        state <= next_state;
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
        if(state == `RST1)begin
            ram_we = 0;
            beg_we = 1;
            end_we = 1;
            beg_next = rst_counter;
            end_next = rst_counter;
            beg_ptr = rst_counter;
            end_ptr = rst_counter;
            next_free = FIFOS;
            ram_addr_a = end_curr;
            ram_addr_b = beg_curr;
        end else if(state == `RST2) begin
            ram_we = 1;
            linked_ram_d = next_rst_counter;
            ram_addr_a = rst_counter;
        end else if(state == `STEADY) begin
            if(push && pop) begin
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
            end else if(push) begin
                ram_we = 1;
                end_we = 1;
                ram_addr_a = end_curr;
                linked_ram_d = free;
                end_ptr = push_fifo;
                end_next = free;
                ram_addr_b = free;
                next_free = linked_ram_q;
            end else if(pop) begin
                beg_we = 1;
                beg_next = linked_ram_q;
                ram_addr_b = beg_curr;
                ram_addr_a = beg_curr;
                next_free = beg_curr;
                ram_we = 1;
                linked_ram_d = free;
            end
        end
    end

    assign full = free[LOG2_DEPTH];
    `include "log2.vh"

endmodule
