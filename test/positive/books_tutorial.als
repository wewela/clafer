open util/integer
pred show {}


abstract sig c1_Book
{ r_c2_title : one c2_title
, r_c4_year : one c4_year
, r_c5_page : set c5_page
, r_c6_format : one c6_format
, r_c10_kind : one c10_kind
, r_c17_authors : some c17_authors
, r_c18_ISBN : lone c18_ISBN }
{ 2 <= #r_c5_page
  all disj x, y : this.@r_c17_authors | (x.@ref) != (y.@ref)
  ((this.(@r_c4_year.@ref)) >= 5) => (some this.@r_c18_ISBN) }

sig c2_title
{ ref : one Int
, r_c3_subtitle : lone c3_subtitle }
{ one @r_c2_title.this }

sig c3_subtitle
{ ref : one Int }
{ one @r_c3_subtitle.this }

sig c4_year
{ ref : one Int }
{ one @r_c4_year.this }

sig c5_page
{}
{ one @r_c5_page.this }

sig c6_format
{ r_c7_paper : lone c7_paper
, r_c9_electronic : lone c9_electronic }
{ one @r_c6_format.this
  let children = (r_c7_paper + r_c9_electronic) | one children }

sig c7_paper
{ r_c8_hardcover : lone c8_hardcover }
{ one @r_c7_paper.this }

sig c8_hardcover
{}
{ one @r_c8_hardcover.this }

sig c9_electronic
{}
{ one @r_c9_electronic.this }

sig c10_kind
{ r_c11_textbook : lone c11_textbook
, r_c12_manual : lone c12_manual
, r_c13_reference : lone c13_reference
, r_c14_fiction : lone c14_fiction
, r_c15_nonfiction : lone c15_nonfiction
, r_c16_other : lone c16_other }
{ one @r_c10_kind.this
  let children = (r_c11_textbook + r_c12_manual + r_c13_reference + r_c14_fiction + r_c15_nonfiction + r_c16_other) | one children }

sig c11_textbook
{}
{ one @r_c11_textbook.this }

sig c12_manual
{}
{ one @r_c12_manual.this }

sig c13_reference
{}
{ one @r_c13_reference.this }

sig c14_fiction
{}
{ one @r_c14_fiction.this }

sig c15_nonfiction
{}
{ one @r_c15_nonfiction.this }

sig c16_other
{ ref : one Int }
{ one @r_c16_other.this }

sig c17_authors
{ ref : one c23_Author }
{ one @r_c17_authors.this }

sig c18_ISBN
{ ref : one Int
, r_c19_GS1 : lone c19_GS1 }
{ one @r_c18_ISBN.this
  (((this.~@r_c18_ISBN).(@r_c4_year.@ref)) >= 6) => (some this.@r_c19_GS1) }

sig c19_GS1
{ ref : one Int }
{ one @r_c19_GS1.this }

abstract sig c20_Person
{ r_c21_name : one c21_name
, r_c22_dob : lone c22_dob }

sig c21_name
{ ref : one Int }
{ one @r_c21_name.this }

sig c22_dob
{ ref : one Int }
{ one @r_c22_dob.this }

abstract sig c23_Author extends c20_Person
{ r_c24_books : some c24_books }
{ all disj x, y : this.@r_c24_books | (x.@ref) != (y.@ref) }

sig c24_books
{ ref : one c1_Book }
{ one @r_c24_books.this }

one sig c25_GenerativeProgramming extends c1_Book
{}
{ (((((((((this.(@r_c2_title.@ref)) = 0) && (no (this.@r_c2_title).@r_c3_subtitle)) && ((this.(@r_c4_year.@ref)) = 5)) && ((#(this.@r_c5_page)) = 4)) && (some (this.@r_c6_format).@r_c7_paper)) && (some (this.@r_c10_kind).@r_c15_nonfiction)) && ((this.(@r_c17_authors.@ref)) = (c26_Czarnecki + c27_Eisenecker))) && ((this.(@r_c18_ISBN.@ref)) = 0)) && (no (this.@r_c18_ISBN).@r_c19_GS1) }

one sig c26_Czarnecki extends c23_Author
{}
{ ((this.(@r_c21_name.@ref)) = 0) && (c25_GenerativeProgramming in (this.(@r_c24_books.@ref))) }

one sig c27_Eisenecker extends c23_Author
{}
{ ((this.(@r_c21_name.@ref)) = 0) && (c25_GenerativeProgramming in (this.(@r_c24_books.@ref))) }

