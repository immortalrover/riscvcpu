# singlecyclecpu

> 来自武汉大学计算机学院计算机组成与设计课程设计
> RISC-V 实现

## 仓库介绍

个人认为对CPU设计的关键之处在于译码阶段。
但是在本科教学阶段，学校并没有过深讲述译码这个过程，而是更多的强调学生的动手能力。
实验课上，交给学生一个勉强够用的模板文件便草草了事。

个人认为学校的模板并没有降低设计的难度，反而增加了阅读所需要的成本。
于是我决定跟据自己的想法实现一部分更好的代码，拥有更清晰、更完整的逻辑框架，而不仅仅局限于学校的教学目标。

## 设计原则

变量名要尽可能体现它的意义，因为太短的变量名不够醒目，长时间未接触便会忘记其功能。
过去的程序员还在考虑变量名所占用的字节空间，但现在的编程语言根本不需要考虑变量名的长度。

单一的模块，其代码长度不应该过长，50行以内是最优的，超过100行是不可接受的。

## 从0开始

个人认为要实现一个好的CPU，可以先考虑实现一些逻辑独立的单元，并分开单独测试。
这样可以避免出现bug的时候，无从下手debug的窘境。

主要就是从易到难。

## 较简单的模块

我认为封装下面这些模块对整个项目的设计来说影响不会太大，一旦写好了就基本不需要维护。

-   RegsFile：这个文件是一个寄存器堆，需要根据寄存器数字读写数据。
-   InstrMem：存储待运行指令的一个地方，需要读取外部文件，根据传入的地址读取相应的指令。
-   DataMem：存储数据的一个地方，实现的功能主要是模仿硬盘，根据传入的地址读写相应的数据。

### 测试方法

根据需求修改MakeFile，包括但不限于在SOURCES_SELECT中填写对应的文件名、修改成您的verilog编译器、修改成您的仿真环境。

## 稍微复杂的模块

-   ALU：算术运算单元，需要根据不同的指令进行不同的二元运算。
-   InstrProc：实现的功能主要是计算一些指令所需要的立即数。

### ALU

将一系列可进行的二元运算添加合适的操作名，并且写入Defines.v文件以避免重复定义。

### InstrProc

原身为一个立即数生成器，但经过实际设计后发现，与其写入一个单独的模块，不如将其写在每个单周期过程的开头，这样能够节省一些不必要的线设计。

## 复杂的模块

-   InstrDec：处理整个CPU的逻辑，让不同的指令进行不同的操作。