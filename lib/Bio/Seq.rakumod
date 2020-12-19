unit module Seq:auth<Henri Schmidt (henrischmidt73@gmail.com)>;

my %nuc-map := {'A' => 'T', 'T' => 'A', 'C' => 'G', 'G' => 'C'};

sub complement(Str $seq) is export {
    (map { %nuc-map{$_} }, $seq.comb).join('')
}

sub reverse-complement(Str $seq) is export {
    (map { %nuc-map{$_} }, $seq.comb).reverse.join('')
}

