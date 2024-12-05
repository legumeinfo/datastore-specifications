#!/usr/bin/env perl
# add_name_attr_to_gff.pl - add Name attribute if it is missing in gff3
use strict;
use warnings;

my $usage = <<EOS;
Usage: zcat FILE.gff3.gz | perl $0 
  For files that lack a Name attribute, add it, using the last part of the ID for the content.
  The script presumes a LIS/SoyBase/PeanutBase prefix structure in the IDs --
  specifically, the prefix has four dot-separated fields, e.g.
    ID=vicfa.Hedin2.gnm1.ann1.1g204480;
    ID=vicfa.Hedin2.gnm1.ann1.1g204480;Name=1g204480;

    ID=glyma.Amsoy.gnm1.ann1.SoyC05_01G000100;
    ID=glyma.Amsoy.gnm1.ann1.SoyC05_01G000100;Name=SoyC05_01G000100;
EOS

while (<>){
  chomp;
  my $line = $_;
  if ($line =~ /^#/){ print "$line\n" }
  else {
    my @parts = split(/\t/, $line);
    if ($parts[2] =~ /gene|mRNA/ && $parts[8] !~ /Name=/){
      my @first_eight = @parts[0..7];
      my $ninth = $parts[8];
      if ( $ninth =~ /ID=[^;]+;.+/ ){ # There are multiple attributes, starting with ID
        $ninth =~ s/ID=([^.]+\.[^.]+\.[^.]+\.[^.]+)\.([^;]+);(.+)/ID=$1.$2;Name=$2;$3/; 
      }
      elsif ( $ninth =~ /ID=[^;]+$/ ) { # There is a single attribute (just ID)
        $ninth =~ s/ID=([^.]+\.[^.]+\.[^.]+\.[^.]+)\.([^;]+)$/ID=$1.$2;Name=$2/; 
      }
      else { die "Unexpected structure in ninth column: \n  [$ninth]\n" }
      print join("\t", @first_eight, $ninth), "\n";
    }
    else {
      print "$line\n";
    }
  }
}

__END__

2024-11-25 sbc Initial version
2024-11-26 sbc Handle additional ninth-column cases
