open util/integer
pred show {}


abstract sig c1_Phone
{ r_c2_networking : one c2_networking
, r_c10_location : lone c10_location
, r_c13_gpu : set c13_gpu }

sig c2_networking
{ r_c3_wifi : lone c3_wifi
, r_c7_bluetooth : lone c7_bluetooth
, r_c8_mobile : lone c8_mobile
, r_c9_nfc : lone c9_nfc }
{ one @r_c2_networking.this }

sig c3_wifi
{ r_c4_typeB : lone c4_typeB
, r_c5_typeG : lone c5_typeG
, r_c6_typeN : lone c6_typeN }
{ one @r_c3_wifi.this }

sig c4_typeB
{}
{ one @r_c4_typeB.this }

sig c5_typeG
{}
{ one @r_c5_typeG.this }

sig c6_typeN
{}
{ one @r_c6_typeN.this }

sig c7_bluetooth
{}
{ one @r_c7_bluetooth.this }

sig c8_mobile
{}
{ one @r_c8_mobile.this }

sig c9_nfc
{}
{ one @r_c9_nfc.this }

sig c10_location
{ r_c11_gps : lone c11_gps
, r_c12_agps : lone c12_agps }
{ one @r_c10_location.this
  let children = (r_c11_gps + r_c12_agps) | one children }

sig c11_gps
{}
{ one @r_c11_gps.this }

sig c12_agps
{}
{ one @r_c12_agps.this }

sig c13_gpu
{}
{ one @r_c13_gpu.this }

lone sig c14_PhoneWithGps extends c1_Phone
{}
{ some (this.@r_c10_location).@r_c11_gps }

lone sig c17_PhoneWithWifi extends c1_Phone
{}
{ some ((this.@r_c2_networking).@r_c3_wifi).@r_c6_typeN }

lone sig c24_PhonewithWifiAndGpsNoBluetoothOrNfc extends c1_Phone
{}
{ ((some (this.@r_c2_networking).@r_c3_wifi) && (some (this.@r_c10_location).@r_c11_gps)) && (!((some (this.@r_c2_networking).@r_c7_bluetooth) || (some (this.@r_c2_networking).@r_c9_nfc))) }

lone sig c37_PhoneWithGpu extends c1_Phone
{}
{ some this.@r_c13_gpu }

fact { all  p : c1_Phone | some (p.@r_c2_networking).@r_c8_mobile }
