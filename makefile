vim:
	vim -p makefile test.do linked_list_fifo.v linked_list_fifo_tb.v linked_list_fifo_gold.v

vsim_linked_list_fifo = work/linked_list_fifo
vsim_linked_list_fifo_gold = work/linked_list_fifo_gold
vsim_linked_list_fifo_tb = work/linked_list_fifo_tb

$(vsim_linked_list_fifo) : work linked_list_fifo.v
	vlog linked_list_fifo.v +incdir+../common

$(vsim_linked_list_fifo_gold) : work linked_list_fifo_gold.v
	vlog linked_list_fifo_gold.v +incdir+../common
$(vsim_linked_list_fifo_tb) : work linked_list_fifo_tb.v
	vlog linked_list_fifo_tb.v +incdir+../common

work:
	vlib work

sim: work $(vsim_linked_list_fifo) $(vsim_linked_list_fifo_tb) $(vsim_linked_list_fifo_gold)
	echo -e "vsim work.linked_list_fifo_tb\nrun -all" | vsim
