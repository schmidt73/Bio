# Bio

In my work as a Computational Biologist I often find myself
reimplementing the same or similar set of functionality across several
places and script. I can't count the number of times I've implemented
simple `reverse-complement`, `parse-csv`, or efficient string
searching algorithms. This module serves to tackle this problem by
putting this functionality in one convenient place. 

## Functionality

* `Bio::IO` implements common parsers and pretty-printers for many of
  the file formats I deal with daily. Current sub-modules include:
  * `Bio::IO::CSV` for manipulating CSV files.
  * `Bio::IO::Fasta` for manipulating FASTA files.
  * `Bio::IO::BAM` for manipulating BAM/SAM files
  * `Bio::IO::FastQ` for manipulating FastQ sequence read files.
* `Bio::Seq` implements common sequence manipulation functionality.

## Examples

```raku
my $bam   = "test.bam";

my $af = AlignmentFile.new(:bam-file($bam), :flags("r"));
my @results = $af.query('chr1:20000-20000');

for @results { say $_.seq };
```

