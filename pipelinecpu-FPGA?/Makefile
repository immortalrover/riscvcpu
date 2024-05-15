BUILD_DIR		:= build
# SOURCES			:= $(shell find . -name '*.v' -not -path './tb/*') tb/CPU_tb.v
# SOURCES_SELECT	:= $(shell find . -name '*.v' -not -path './tb/*')
COMPILER		:= iverilog
RUNTIME			:= vvp
SHOW			:= gtkwave

all: compile simulate

compile:
	@mkdir -p ${BUILD_DIR}
	@echo "#############   Generating test.vvp   #############"
	# ${COMPILER} -o ${BUILD_DIR}/test.vvp $(if $(SOURCES_SELECT),$(SOURCES_SELECT),$(SOURCES))
	${COMPILER} *.v
	@echo "#############         Success         #############"

simulate: ${BUILD_DIR}/test.vvp
	@echo "#############     Begin simulation    #############"
	${RUNTIME} ${BUILD_DIR}/test.vvp
	@echo "#############     Simulation ended    #############"


.PHONY: clean show
clean:
	@echo "#############        Clean begin      #############"
	-rm -rf ${BUILD_DIR}
	@echo "#############        Clean ended      #############"

show:
	@echo "#############     Opening waveform    #############"
	${SHOW} ${BUILD_DIR}/test.vcd

show2:
	@echo "#############     Opening waveform    #############"
	${SHOW} ${BUILD_DIR}/*.gtkw

