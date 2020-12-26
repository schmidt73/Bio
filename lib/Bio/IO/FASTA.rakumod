unit module FASTA:auth<Henri Schmidt (henrischmidt73@gmail.com)>;

class FASTARecord {
    has %.identifier-map;
    has $.body;

    has Str $!sequence;
    
    method seq(--> Str) {
        if $!sequence.defined {
            return $!sequence;
        }

        $!sequence = self.body.comb.grep(/ \w /).join("").uc;
        return self.seq();
    }

    method Str(--> Str) {
        my @lines = self.body.split(/ \n /);
        my $line-str;

        if @lines.elems > 6 {
            $line-str = @lines.head(3).join("\n") ~ "\n...\n" ~ @lines.tail(3).join("\n");
        } else {
            $line-str = @lines.join("\n");
        }

        "<Record Type>: %.identifier-map{'name'}" ~ "\n" ~
        "<Accession>: %.identifier-map{'accession'}" ~ "\n" ~
        "<Sequence>:\n$line-str"
    }

    method gist() {
        self.Str();
    }
}

constant $fasta-extensions = rx[fa||fna||fasta||ffn||faa];
constant $is-fasta = rx:i/ .*\.<$fasta-extensions>$ /;

sub load-fasta-file(Str $filename) {
    parse-fasta-string $filename.IO.slurp;
}

constant %record-types = {
    lcl => {name => "Local", pattern => rx:i/ lcl\|(\w+|\d+) / },
    bbs => {name => "GenInfo backbone seqid", pattern => rx:i/ bbs\|(\d+) /}
}

sub parse-fasta-string($str) {
    my @parsed-records = $str.split(/ \n /).map: {
        if $_ ~~ / [^\>] / {
            my $type = $_.match(/ \>(\w+)\| /).first().Str;
            my %record-type = %record-types{$type};
            my $accession = $_.match(%record-type{'pattern'}).first().Str;
            my $name = %record-type{'name'};
            {type => $type, name => $name, accession => $accession};
        } else {
            $_;
        }
    };

    my @identifier-indices is default(Inf) = @parsed-records.grep: Associative:D, :k;
    my @bodies = (0 .. @identifier-indices.elems).map: {
        my $start-idx = @identifier-indices[$_] + 1;
        my $end-idx = @identifier-indices[$_ + 1] - 1;
        @parsed-records[$start-idx .. $end-idx].join("\n");
    };

    my @fasta-records = (@identifier-indices Z @bodies).map: {
        FASTARecord.new: identifier-map => @parsed-records[$_[0]], body => $_[1];
    };

    return @fasta-records;
}
