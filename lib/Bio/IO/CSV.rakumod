unit module CSV:auth<Henri Schmidt (henrischmidt73@gmail.com)>;

sub read-csv-with-header($filename, $delim = ",") is export {
    my $lines = $filename.IO.lines;
    my $hdr := (split $delim, $lines[0]).cache;

    sub parse-row($row) {
        my $parts := split $delim, $row;
        my %row_dict;
        for (zip $hdr, $parts) { %row_dict{$_[0]} = $_[1] };
        return %row_dict;
    }

    $lines[1..*].map: &parse-row; 
}

sub read-csv($filename, $delim = ',') is export {
    $filename.IO.lines.map: { split($delim, $_) }
}

sub write-csv(@rows, $delim = ',', IO::Handle $handle = $*OUT) is export {
    sub delim-row(@row) { reduce {$^a ~ $delim ~ $^b}, @row };
    if @rows[0] ~~ Associative:D {
        my @hdr = @rows[0].keys;
        @rows = map -> $row { map -> $k { $row{$k} }, @hdr }, @rows;
        $handle.print(delim-row @hdr);
        $handle.print-nl;
        return write-csv @rows, $handle;
    }

    for @rows {
        $handle.print(delim-row $_);
        $handle.print-nl;
    }
}
