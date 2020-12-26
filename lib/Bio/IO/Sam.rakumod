unit module Sam:auth<Henri Schmidt (henrischmidt73@gmail.com)>;

use NativeCall;

constant HTSLIB is export = %?RESOURCES<libraries/hts>;

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

        my $off = ($.core.n_cigar +< 2) + $.core.l_qname;

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

sub hts_idx_destroy(SamIndex)
    is native(HTSLIB) is export { * }

sub sam_hdr_read(SamFile)
    is native(HTSLIB) is export returns SamHdr { * }

sub sam_hdr_destroy(SamHdr)
    is native(HTSLIB) is export { * }

sub sam_itr_querys(SamIndex, SamHdr, Str is encoded('utf8'))
    is native(HTSLIB) is export returns SamIterator { * }

sub sam_iterator_next(SamFile, SamIterator, Pointer[BamRecord])
    is native(HTSLIB) is export returns int32 { * }

sub hts_itr_destroy(SamIterator) is native(HTSLIB) is export { * }

sub bam_init1() is native(HTSLIB) is export returns Pointer[BamRecord] { * }
sub bam_destroy1(Pointer[BamRecord]) is native(HTSLIB) is export { * }

class Sam::HeaderReadException is Exception {
    has $.bam-file;
    
    method message() {
        "Failed to read header of \"$.bam-file\"."
    }
}

class Sam::FileOpenException is Exception {
    has $.bam-file;
    has $.flags;
    
    method message() {
        "Failed to open: \"$.bam-file\" with flags \"$.flags\"."
    }
}


class Sam::IndexLoadException is Exception {
    has $.bam-file;
    
    method message() {
        "Failed to load index for \"$.bam-file\"."
    }
}

class SamRecordIterator does Iterator {
    has $!query;
    has SamFile $!fh;
    has SamHdr $!hdr;
    has SamIndex $!idx;

    has SamIterator $!iter;

    submethod BUILD(:$!query, :$!fh, :$!hdr, :$!idx) { }
    
    method TWEAK() {
        $!iter = sam_itr_querys($!idx, $!hdr, $!query);     
        if $!iter ~~ SamIterator:U {
            die "Failed to open iterator."
        }
    }

    submethod DESTROY() {
        hts_itr_destroy($!iter);
    }

    method pull-one {
        my $rec = bam_init1();
        my $ret = sam_iterator_next($!fh,  $!iter, $rec);

        if $ret >= 0 {
            return $rec.deref;
        }

        bam_destroy1($rec);
        if $ret == -1 {
            return IterationEnd;
        } 

        die "Iterator exception.";
    }

}

class AlignmentFile {
    has $.bam-file;
    has $.flags;

    has SamFile $!fh;
    has SamHdr $!hdr;
    has SamIndex $!idx;

    submethod BUILD(:$!bam-file, :$!flags) { }

    method TWEAK() {
        $!fh = hts_open($.bam-file, $.flags);
        if $!fh ~~ SamFile:U {
            Sam::FileOpenException.new(:bam-file($.bam-file), :flags($.flags)).throw;
        }

        $!hdr = sam_hdr_read($!fh);
        if $!hdr ~~ SamHdr:U {
            Sam::HeaderReadException.new(:bam-file($.bam-file)).throw;
        }

        $!idx = sam_index_load($!fh, $.bam-file);
        if $!idx ~~ SamIndex:U {
            Sam::IndexLoadException.new(:bam-file($.bam-file)).throw;
        }
    }


    submethod DESTROY() {
        hts_idx_destroy($!idx);
        sam_hdr_destroy($!hdr);
        hts_close($!fh);
    }

    method query($q) {
        Seq.new(SamRecordIterator.new(:fh($!fh), :hdr($!hdr), :idx($!idx), :query($q)))
    }
}
