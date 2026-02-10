 .section .data

 msg_prime:
    .ascii " is a Prime Number.\n"
 msg_prime_len:
    .long . - msg_prime
 msg_not_prime:
    .ascii " is not a prime Number.\n"
 msg_not_prime_len:
    .long . - msg_not_prime
 msg_invalid:
    .ascii " is an invalid input.\n"
 msg_invalid_len:
    .long . - msg_invalid

 .section .bss
 .equ   BUFFER_SIZE, 128
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

 pushl  %eax
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

get_prime_loop_begin:

 cmpl   $1, %ebx
 jle    if_not_prime
 movl   %ebx, %edi
 movl   $2, %esi


loop_start:
 pushl  %esi
 pushl  %edi

 call   division
 addl   $8, %esp            #move the stack pointer back
 addl   $1, %esi
 cmpl   $0, %eax
 je     if_not_prime

 cmpl   %esi, %edi
 je     if_prime

 jmp    loop_start


if_not_prime:
 popl   %eax
 movl   $msg_not_prime, %esi     # ESI 指向源字符串
 movl   msg_not_prime_len, %ecx     # ECX 作为计数器
 movl   $BUFFER_DATA, %edi
 addl   %eax, %edi
 decl   %edi

 rep    movsb           # 自动将 ESI 指向的内容拷贝到 EDI，执行 ECX 次
 jmp    print_loop

if_prime:
 popl   %eax
 movl   $msg_prime, %esi     # ESI 指向源字符串
 movl   msg_prime_len, %ecx     # ECX 作为计数器
 movl   $BUFFER_DATA, %edi
 addl   %eax, %edi
 decl   %edi

 rep    movsb           # 自动将 ESI 指向的内容拷贝到 EDI，执行 ECX 次
 jmp    print_loop

if_invalid:
 popl   %eax
 movl   $msg_invalid, %esi     # ESI 指向源字符串
 movl   msg_invalid_len, %ecx     # ECX 作为计数器
 movl   $BUFFER_DATA, %edi
 addl   %eax, %edi
 decl   %edi

 rep    movsb           # 自动将 ESI 指向的内容拷贝到 EDI，执行 ECX 次
 jmp    print_loop


print_loop:
 movl   %edi, %edx
 subl   $BUFFER_DATA, %edx          # EDX 现在存储了拼接后的字节数
 movl   $BUFFER_DATA, %ecx          # 待输出的缓冲区地址
 movl   $SYS_WRITE, %eax
 movl   $STDOUT, %ebx
 int    $LINUX_SYSCALL
 jmp     exit_program

 .type division, @function
division:
 pushl  %ebp            #save old base pointer
 movl   %esp, %ebp      #make stack pointer the base pointer
 subl   $4, %esp        #get room for our local storage

 movl   8(%ebp), %eax   #put first argument in %eax
 cltd                   # 符号扩展，此时 edx:eax 形成 64 位数 10

 movl   12(%ebp), %ecx  #put second argument in %ecx
 idivl  %ecx            # 执行除法

 movl   %edx, %eax      #return value goes in %eax
 movl   %ebp, %esp      #restore the stack pointer
 popl   %ebp            #restore the base pointer
 ret


exit_program:
 movl   $1, %eax              # SYS_EXIT
 movl   $0, %ebx
 int    $LINUX_SYSCALL
