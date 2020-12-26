unit module Sam:auth<Henri Schmidt (henrischmidt73@gmail.com)>;

use NativeCall;

constant HTSLIB is export = %?RESOURCES<libraries/hts>;
say "hi";
say HTSLIB;
#constant HTSLIB = "hts";

class SamIndex is repr('CPointer') is export { }
class SamIterator is repr('CPointer') is export { }
class SamHdr is repr('CPointer') is export { }
class SamFile is repr('CPointer') is export { }

class BamRecordCore is repr('CStruct') {
    has int64 $.pos;
    has int32 $.tid;
    has uint16 $.bin;
    has uint8 $.qual;
    has uint8 $.l_extranul;
    has uint16 $.flag;
    has uint16 $.l_qname;
    has uint32 $.n_cigar;
    has int32 $.l_qseq;
    has int32 $.mtid;
    has int64 $.mpos;
    has int64 $.isize;
}

class BamRecord is repr('CStruct') {
    HAS BamRecordCore $.core;
    has uint64 $.id;
    has CArray[uint8] $.data;
    has int32 $.l_data;
    has uint32 $.m_data;
    has uint32 $.mempolicy;

    method seq {
        constant %nuc-map = {
            0x1 => 'A',
            0x2 => 'C',
            0x4 => 'G',
            0x8 => 'T',
            0xF => 'N',
        };

        my $off = ($!core.n_cigar +< 2) + $!core.l_qname;

        sub decode($idx) {
            my uint8 $x = $.data[($off + $idx / 2).floor];
            %nuc-map{($x +> (4 * (($idx + 1) % 2))) +& 0x0F}
        }

        (0 .. $!core.l_qseq - 1).map(&decode).join();
    }
}

sub hts_open(Str is encoded('utf8'), Str is encoded('utf8'))
    is native(HTSLIB) is export returns SamFile { * }

sub hts_close(SamFile)
    is native(HTSLIB) is export returns int32 { * }

sub sam_index_load(SamFile, Str is encoded('utf8'))
    is native(HTSLIB) is export returns SamIndex { * }

sub sam_hdr_read(SamFile)
    is native(HTSLIB) is export returns SamHdr { * }

sub sam_hdr_destroy(SamHdr)
    is native(HTSLIB) is export { * }

sub sam_itr_querys(SamIndex, SamHdr, Str is encoded('utf8'))
    is native(HTSLIB) is export returns SamIterator { * }

sub sam_iterator_next(SamFile, SamFile, Pointer[BamRecord])
    is native(HTSLIB) is export returns int32 { * }

sub bam_init1() is native(HTSLIB) is export returns Pointer[BamRecord] { * }

# # my $index = "../../../../guidescan-state-of-the-art/results/bam_files/brunello.bam.bai";
# my $bam   = "../guidescan-state-of-the-art/results/bam_files/human_all.bam";

# my $fh = hts_open($bam, "r");
# my $header = sam_hdr_read($fh);
# my $idx = sam_index_load($fh, $bam);
# 
# my $itr = sam_itr_querys($idx, $header, ".");
# 
# my $rec = bam_init1();
# my $ret = sam_iterator_next($fh,  $itr, $rec);
# 
# say $ret;
# say $rec.deref.seq;
# say $rec.deref.data[0 ... 100];
# 
# hts_close($fh);
