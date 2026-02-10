 .section .data

 msg_prime msg_invalid:
    .ascii "Invalid input.\n"
 msg_invalid_len:
    .long . - msg_invalid

 .section .bss
 .equ   BUFFER_SIZE, 64
 .lcomm BUFFER_DATA, BUFFER_SIZE

 .section .text
 .global _start

 .equ   SYS_READ, 3
 .equ   SYS_WRITE, 4
 .equ   STDIN, 0
 .equ   STDOUT, 1
 .equ   LINUX_SYSCALL, 0x80

 .equ   SMALLEST_NUMBER, '0'
 .equ   LARGEST_NUMBER, '9'

_start:
read_loop:
 movl   $0, %edi
 movl   $0, %ebx

 movl   $SYS_READ, %eax
 movl   $STDIN, %ebx
 movl   $BUFFER_DATA, %ecx
 movl   $BUFFER_SIZE, %edx
 int    $LINUX_SYSCALL

 cmpl   $1, %eax
 jl     exit_program

conversion_loop:
 movb   BUFFER_DATA(,%edi,1), %cl
 cmpb   $10, %cl
 je     conversion_done

 cmpb   $SMALLEST_NUMBER, %cl
 jl     if_invalid
 cmpb   $LARGEST_NUMBER, %cl
 jg     if_invalid

 subb   $'0', %cl
 movzbl %cl, %ecx

 imull  $10, %ebx
 addl   %ecx, %ebx

 incl   %edi
 cmpl   %edi, %eax
 jne    conversion_loop

conversion_done:
 imull  $2, %ebx
 pushl  $-1

push_stack_loop:
 subl   $2, %ebx
 pushl  %ebx
 cmpl   $0, %ebx
 jle    push_stack_end
 jmp    push_stack_loop

push_stack_end:

print_begin:
 popl   %eax                # 1. 弹出要输出的数

 cmpl   $-1, %eax
 je     exit_program
 # --- 数值转字符串逻辑 ---
 movl    $BUFFER_DATA, %edi  # 指向缓冲区起始位置
 addl    $BUFFER_SIZE, %edi  # 指向缓冲区末尾，我们从后往前填
 decl    %edi                # 留一个位置给换行符
 movb    $10, (%edi)         # 存入换行符 \n
 movl    $1, %ecx            # 计数器：记录字符长度（初始包含换行符）

 movl    $10, %ebx           # 除数

convert_loop:
 xorl    %edx, %edx      # 清空 edx 准备除法
 divl    %ebx            # eax / 10, 商在 eax, 余数在 edx
 addb    $'0', %dl       # 将余数转换为 ASCII
 decl    %edi            # 缓冲区指针前移
 movb    %dl, (%edi)     # 存入字符
 incl    %ecx            # 长度计数 +1

 testl   %eax, %eax      # 检查商是否为 0
 jnz     convert_loop    # 如果不为 0，继续处理下一位

 # --- 执行输出 ---
 # 此时 %edi 指向字符串的首个数字，%ecx 是总长度
 movl   $SYS_WRITE, %eax
 movl   $STDOUT, %ebx
 movl   %ecx, %edx          # 之前累加的总长度
 movl   %edi, %ecx          # 缓冲区中字符串的实际起始地址
 movl   $SYS_WRITE, %eax    # 系统调用号 4
 movl   $STDOUT, %ebx       # 句柄 1
 int    $LINUX_SYSCALL

 jmp    print_begin

if_invalid:
 movl   $SYS_WRITE, %eax
 movl   $STDOUT, %ebx
 movl   $msg_invalid, %ecx
 movl   msg_invalid_len, %edx
 int    $LINUX_SYSCALL
 jmp    exit_program

exit_program:
 movl   $1, %eax
 movl   $0, %ebx
 int    $LINUX_SYSCALL
