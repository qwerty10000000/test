print "nasm"



; RAX, RCX, RDX, R8, R9, R10, R11 windows

; RDI, RSI, RDX, R10, R8, R9  linux

libc: make library! %libc.so.6



;--------------------------------

memcpy:  make routine! compose [[desc [pointer]  src [pointer] len [int64] return: [uint64]] (libc) "memcpy"]

&: func [ data] [ memcpy data data 0 ]


memset: make routine! compose [[desc [pointer]  src [pointer] len [int64] return: [uint64]] (libc) "memset"]

;---------------------------------------------------------------------

execl: make routine! compose [[patch [pointer]   args [pointer] cmd [pointer] null [pointer] return: [uint32]] (libc) "execl"]

execvp: make routine! compose [[patch [pointer]   args [pointer]    return: [int32]] (libc) "execvp"]

fork: make routine! compose [[  return: [uint32]] (libc) "fork"]

getpagesize: make routine! compose [[  return: [int32]] (libc) "getpagesize"]

;------------------------------------



mprotect: make routine! compose [[addr[ pointer] size[int64] prot [int64]  return: [uint64]] (libc) "mprotect" ]

PROT_READ: to-integer #{01}
PROT_WRITE: to-integer #{02}
PROT_EXEC: to-integer #{04}


;--------------------------------------------------

pagesize: getpagesize

source pagesize

memory: to-binary make bitset! pagesize * 8 * 2

&memory: & memory

; algin memoty  to pagedize

&memory:  &memory + offset: pagesize  - mod &memory pagesize

source &memory 

memory: skip memory offset



test: "ok"

memcpy memory test 2

offset: 0

probe mprotect  memory length? memory ( PROT_READ  or  PROT_WRITE or PROT_EXEC) 
;mprotect(0x5c38d1b0c1e0, 4096, PROT_READ|PROT_WRITE|PROT_EXEC) = -1 EINVAL (Invalid argument)
offsets: clear copy []

;----------------------------------

&null: & null: #{0000000000000000}

compile: func [ name spec tmp ][source tmp

 write %tmp.txt ajoin [  {

 BITS 64

} tmp 

{ret} 

]

call/console/wait {./compile}

;fpid: fork



;execvp  "./nasm" "./tmp.txt"  



tmp: read %tmp

source tmp


memcpy (skip memory  offset )  tmp length? tmp

; source spec

 ptr: make routine!   reduce [ spec (&memory +  offset ) ]

insert tail offsets reduce [ name    offset  ]

offset: offset + length? tmp

return :ptr

]


;-------------------------------------

add: compile "add" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rdi
add rax , rsi

}

probe add 1 2

;---------------------------

sub: compile "sub" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rdi
sub rax , rsi

}

probe sub 3 2

;--------------------------------------

mul: compile "mul" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rdi
mul rsi

}

probe mul 3 2

;------------------------------------------------------

div: compile "div" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rdi
mov rcx , rsi
cqo
idiv rcx

}

probe div 6 2

;---------------------------------------------------

loop*: compile "loop*" [a [pointer]  return: [pointer]] {

mov rax , 0
mov rcx , rdi
label:
add rax , 1
loop label
}

probe dt [probe loop* 1000000000  ] ; php 10s , red 48s , vps 

;---------------------------------------

popcnt: compile "popcnt" [a [pointer]  return: [pointer]] {

POPCNT rax , rdi


}

probe popcnt   4294967295 ; 32

;popcnt 281474976710655 ; 48

; popcnt  9223372036854775807 ; 63

; popcnt -1 = 64

;-------------------------------------------------------------

jmp: compile "jmp" [a [pointer] b [pointer] return: [pointer]] ajoin [ {


jmp  } offsets/("add") - offset {



} ]

probe jmp 3 4

;--------------------

call*: compile "call" [a [pointer] b [pointer] return: [pointer]] ajoin [ {


call  } offsets/("add") - offset {



} ]

probe call* 3 4

;---------------------------------------------------------

f: func [ a [integer!]     b [integer!] ][ print "ok" return a + b]

cb: make callback! [ [ a [pointer]b [pointer]  return: [int64] ]  :f]

addr: (reflect cb 'addr)

callback: make routine! compose [[a [pointer]b [pointer]return: [pointer]] addr]

probe callback 1 2

callback: compile "callback"  [a [pointer] b [pointer] return: [pointer]] ajoin [ {


mov rax ,  } addr {
push rbp    
mov rbp, rsp  
sub rsp, 16 
call rax
add rsp, 16 
mov rsp, rbp                   
pop rbp  


} ]

probe callback 1 2

;----------------------------------------

zmm0:  make struct! [s [uint64 [8]]]

&zmm0: (reflect zmm0 'addr)

zmm1:  make struct! [s [uint64 [8]]]

&zmm1: (reflect zmm1 'addr)

zmm1/s: [ 9 10 11 12 13 14 15 16 ] ; 

zmm2:  make struct! [s [uint64 [8]]]

&zmm2: (reflect zmm2 'addr)

zmm2/s: [ 1  2 3 4 5 6 7 8  ] ; 

; axv 512 bit

VPOPCNTQ: compile "VPOPCNTQ" [a [pointer]  return: [pointer]] { ; 512 bit popcount


vpopcntq zmm0, [rdi] 
vmovdqu64 [rdi] ,  zmm0
} 

probe VPOPCNTQ &zmm2
source zmm2

;-----------------------




VPXORQ: compile "VPXORQ" [a [pointer] b [pointer] c [pointer]  return: [pointer]] { ; 512 bit xor


vmovdqu64 zmm1, [rdi] 

vmovdqu64 zmm2, [rsi] 

vpxorq zmm0, zmm1, zmm2

vmovdqu64 [rdx] ,  zmm0
} 

probe VPXORQ &zmm1 &zmm2 &zmm0
source zmm0
;--------------------------------

halt
loop: compile "loop" [a [pointer]  return: [pointer]] {

mov rax , 0

label:
add rax , 1
loop label
}

;dt [probe loop 1000000000 ] ; php 10s , red 48s

;--------------------------------------------


and: compile "and" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rdi
and rax , rsi

}

probe and 7 3
;------------------------------

xor: compile "xor" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rdi
xor rax , rsi

}

probe xor  7 3
;--------------------------

xmm2:  make struct! [s [uint16 [16]]]

&xmm2: (reflect xmm2 'addr)

xmm2/s: [ 1  2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 ] ; 



VPOPCNTQ: compile "VPOPCNTQ" [a [pointer]  return: [pointer]] { ; 256 bit

VPOPCNTW  ymm0 , [rcx]
movdqu [rcx] ,  ymm0
} 

probe VPOPCNTQ &xmm2

halt
