BUILD_DIR		:= build
SOURCES			:= $(shell find . -name '*.v' -not -path './tb/*')
SOURCES_SELECT	:= RegsFile.v tb/RegsFile_tb.v Defines.v
COMPILER		:= iverilog
RUNTIME			:= vvp
SHOW			:= gtkwave

all: compile simulate

compile:
	@mkdir -p ${BUILD_DIR}
	@echo "#############   Generating test.vvp   #############"
	${COMPILER} -o ${BUILD_DIR}/test.vvp $(if $(SOURCES_SELECT),$(SOURCES_SELECT),$(SOURCES))
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

