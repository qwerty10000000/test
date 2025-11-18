print "nasm"



; RAX, RCX, RDX, R8, R9, R10, R11 windows

; RDI, RSI, RDX, RCX, R8, R9  linux

;libc: make library! %libc.so.6

msvcrt: make library! %msvcrt.dll

Kernel32: make library! %Kernel32.dll

;--------------------------------

memcpy:  make routine! compose [[desc [pointer]  src [pointer] len [int64] return: [uint64]] (msvcrt) "memcpy"]

&: func [ data] [ memcpy data data 0 ]


memset: make routine! compose [[desc [pointer]  src [pointer] len [int64] return: [uint64]] (msvcrt) "memset"]



;------------------------------------

VirtualProtect: make routine! compose [[lpAddress[ pointer] dwSize [int64] flNewProtect [int64]  lpflOldProtect [ pointer]  return: [uint64]] (Kernel32) "VirtualProtect" ]

PAGE_EXECUTE: to-integer #{10}
PAGE_EXECUTE_READ: to-integer #{20}
PAGE_EXECUTE_READWRITE: to-integer #{40}


;--------------------------------------------------


;---------------------------

memory: to-binary make bitset! 16000

&memory: & memory

test: "ok"

memcpy memory test 2

offset: 0

&protect: & protect: #{0000000000000000}

VirtualProtect memory length? memory PAGE_EXECUTE_READWRITE &protect

offsets: clear copy []

;----------------------------------


compile: func [ name spec tmp ][source tmp

 write %tmp.txt ajoin [  {

 BITS 64

} tmp 

{ret} 

]
call/console/wait "nasm.exe tmp.txt"

tmp: read %tmp



memcpy (skip memory  offset )  tmp length? tmp

; source spec

 ptr: make routine!   reduce [ spec (&memory +  offset ) ]

insert tail offsets reduce [ name    offset  ]

offset: offset + length? tmp

return :ptr

]


;-------------------------------------


add: compile "add" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rcx
add rax , rdx

}

probe add 1 2

;---------------------------

sub: compile "sub" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rcx
sub rax , rdx

}

probe sub 3 2

;--------------------------------------

mul: compile "mul" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rcx
mul rdx

}

probe mul 3 2

;------------------------------------------------------

div: compile "div" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rcx
mov rcx , rdx
cqo
idiv rcx

}

probe div 6 2

;---------------------------------------------------

popcnt: compile "popcnt" [a [pointer]  return: [pointer]] {

POPCNT rax , rcx


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

;---------------------------------------------------------


loop: compile "loop" [a [pointer]  return: [pointer]] {

mov rax , 0

label:
add rax , 1
loop label
}

dt [probe loop 1000000000 ] ; php 10s , red 48s

;--------------------------------------------


and: compile "and" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rcx
and rax , rdx

}

probe and 7 3
;------------------------------

xor: compile "xor" [a [pointer] b [pointer] return: [pointer]] {

mov rax , rcx
xor rax , rdx

}

probe xor  7 3
;--------------------------

xmm0:  make struct! [s [uint8 [16]]]

xmm0/s: [ 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ] ; 128 bit

&xmm0: (reflect xmm0 'addr)


xmm1:  make struct! [s [uint8 [16]]]

xmm1/s: [ 1  2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 ] ; 

&xmm1: (reflect xmm1 'addr)


;--------------------------------------------------

pand: compile "pand" [a [pointer] b [pointer] return: [pointer]] {; 128 bit

movdqu xmm0 , [rcx]
 pand  xmm0 , [rdx]
movdqu [rcx] , xmm0

}

probe pand &xmm0 &xmm1
source xmm0

;---------------------------


xmm0/s: [ 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ]

pxor: compile "pxor" [a [pointer] b [pointer] return: [pointer]] {

movdqu xmm0 , [rcx]
 pxor  xmm0 , [rdx]
movdqu [rcx] , xmm0

}

; F30F6F01660FEF02F30F7F01C3

probe pxor &xmm0 &xmm1
source xmm0
source xmm1
;------------------------------------


ymm0:  make struct! [s [uint8 [32]]]

ymm0/s: [ 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1] 

&ymm0: (reflect ymm0 'addr)


ymm1:  make struct! [s [uint8 [32]]]

ymm1/s: [ 1  2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32] 

&ymm1: (reflect ymm1 'addr)


ymm2:  make struct! [s [uint8 [32]]]

&ymm2: (reflect ymm2 'addr)

ymm2/s: [ 1  2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32] ; 



;-------------------------------------------


vpxor: compile "pxor" [a [pointer] b [pointer] return: [pointer]] { ; 256 bit

vmovdqu ymm0 , [rcx]
 vpxor  ymm0 , [rdx]
vmovdqu [rcx] , ymm0

}

; F30F6F01660FEF02F30F7F01C3

probe vpxor &ymm0 &ymm1
source ymm0
source ymm1


;------------------------------------------

; https://stackoverflow.com/questions/42613821/how-do-i-perform-a-bitwise-not-in-sse-avx
 

ymm0/s: [ 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1] ; 


vpnot: compile "vpnot" [a [pointer] return: [pointer]] { ; 256 bit

vmovdqu ymm0 , [rcx]
VPCMPEQB  ymm1, ymm1, ymm1 
VPANDN    ymm0, ymm0, ymm1
vmovdqu [rcx] , ymm0


}

probe vpnot  &ymm1

source ymm1

;--------------------------------------------------


ymm0/s: [ 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1] ; 

ymm1/s: [ 1  2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32] 


vpopcnt: compile "vpopcnt" [a [pointer] return: [pointer]] { ; 256 bit

vmovdqu ymm0 , [rcx]
vpopcntb  ymm1, ymm0
vmovdqu [rcx] , ymm1

}

probe vpopcnt  &ymm1

source ymm1


;----------------------------------------------

ymm2:  make struct! [s [uint64 [4]]]

ymm2/s: [ 1234567  7654321  123456789 987654321] ; 4 * 64 bit

&ymm2: (reflect ymm2 'addr)

vpopcntq: compile "vpopcnt" [a [pointer] return: [pointer]] { ; 256 bit

vmovdqu ymm0 , [rcx]
vpopcntq  ymm1, ymm0

vmovdqu [rcx] , ymm1

} ; VPADDQ

probe vpopcntq  &ymm2

source ymm2

;-------------------------------\


halt
