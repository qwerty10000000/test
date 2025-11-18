print "tcc"



; RAX, RCX, RDX, R8, R9, R10, R11 windows

; RDI, RSI, RDX, RCX, R8, R9  linux

;libc: make library! %libc.so.6

msvcrt: make library! %msvcrt.dll

Kernel32: make library! %Kernel32.dll

tcc: make library! %libtcc.dll

;--------------------------------

memcpy:  make routine! compose [[desc [pointer]  src [pointer] len [int64] return: [uint64]] (msvcrt) "memcpy"]

&: func [ data] [ memcpy data data 0 ]


memset: make routine! compose [[desc [pointer]  src [pointer] len [int64] return: [uint64]] (msvcrt) "memset"]


strlen:  make routine! compose [[desc [pointer]    return: [uint64]] (msvcrt) "strlen"]


;------------------------------------

VirtualProtect: make routine! compose [[lpAddress[ pointer] dwSize [int64] flNewProtect [int64]  lpflOldProtect [ pointer]  return: [uint64]] (Kernel32) "VirtualProtect" ]

PAGE_EXECUTE: to-integer #{10}
PAGE_EXECUTE_READ: to-integer #{20}
PAGE_EXECUTE_READWRITE: to-integer #{40}


;--------------------------------------------------


tcc_new: make routine! compose [[ return: [uint64]] (tcc) "tcc_new"]

tcc_set_output_type: make routine! compose [[ state [int64] output [int64] return: [int32]] (tcc)
"tcc_set_output_type"]

tcc_compile_string: make routine! compose [[ state [int64] buffer [ pointer] return: [int32]] (tcc)
"tcc_compile_string" ]

tcc_relocate: make routine! compose [[ state [int64] ptr [ pointer] return: [int32]] (tcc)
"tcc_relocate" ]

tcc_get_symbol: make routine! compose [[ state [int64] ptr [ pointer] return: [int32]] (tcc)
"tcc_get_symbol" ]



TCC_OUTPUT_MEMORY: 1


;----------------------------------------------------------

memory: to-binary make bitset! 16000

&memory: & memory

test: "ok"

memcpy memory test 2

offset: 0

&protect: & protect: #{0000000000000000}

VirtualProtect memory length? memory PAGE_EXECUTE_READWRITE &protect

offsets: clear copy []

;----------------------------------
tmp*: {
long  add(long  a , long  b)

{

		return a + b ;
	}

}

s: tcc_new

tcc_set_output_type s TCC_OUTPUT_MEMORY


probe tcc_compile_string s tmp* 

;-------------------------

compile: func [ name spec tmp ][source tmp


s: tcc_new

probe tcc_set_output_type s TCC_OUTPUT_MEMORY



probe tcc_compile_string s tmp/1 ; tmp*

null: #{0000000000000000}

 size:  tcc_relocate s  & null

sym: tcc_get_symbol s name

;size: strlen sym

tmp: to-binary make bitset! 16000

&tmp: & tmp

memcpy &tmp sym  length? tmp

parse/all tmp [ thru #{c9c3} pos:  end]

memcpy (skip memory  offset )  tmp  index? pos

 ptr: make routine!   reduce [ spec (&memory +  offset ) ]


insert tail offsets reduce [ name    offset  ]

offset: offset + length? tmp

return :ptr

]


;-------------------------------------


add: compile "add" [a [pointer] b [pointer] return: [pointer]] [


{
long  add(long  a , long  b)

{

		return a + b ;
	}

}


]

probe add 2 3

{

0:  55                      push   rbp
1:  48 89 e5                mov    rbp,rsp
4:  48 81 ec 00 00 00 00    sub    rsp,0x0
b:  48 89 4d 10             mov    QWORD PTR [rbp+0x10],rcx
f:  48 89 55 18             mov    QWORD PTR [rbp+0x18],rdx
13: 8b 45 10                mov    eax,DWORD PTR [rbp+0x10]
16: 8b 4d 18                mov    ecx,DWORD PTR [rbp+0x18]
19: 01 c8                   add    eax,ecx
1b: e9 00 00 00 00          jmp    0x20
20: c9                      leave
21: c3                      ret

}


;---------------------------

sub: compile "sub" [a [pointer] b [pointer] return: [pointer]] [


{
long  sub(long  a , long  b)

{

		return a - b ;
	}

}


]

probe sub 7 5

halt
;--------------------------------------

