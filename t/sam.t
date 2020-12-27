use Test;
use Bio::IO::Sam;

plan 2;

use-ok 'Bio::IO::Sam';
my $af = AlignmentFile.new(:bam-file('resources/t/brunello.bam'),
                           :flags("r"));
ok $af ~~ AlignmentFile:D, 'BAM file successfully loaded';

my @recs = $af.query('.');
ok @recs[0].alignment.starts-with: 'ofH01000000000000008ae1f73cffffffff02000000000000008ae1f73cffffffff4924176cffffffff5263ad92ffffffff4a3fa2570000000095301bab0000000003000000000000008ae1f73cffffffff';

done-testing;
