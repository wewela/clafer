open util/integer
pred show {}


fact { #c1_Kernel <= 0 }
abstract sig c1_Kernel
{ r_c2_memory : lone c2_memory }

sig c2_memory
{}
{ one @r_c2_memory.this }

lone sig c3_Phone
{ r_c4_name : one c4_name }
{ some c1_Kernel.@r_c2_memory }

lone sig c4_name
{ ref : one Int }
{ one r_c4_name }

