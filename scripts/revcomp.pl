#!/usr/bin/env perl
#
# FILE: revcomp.pl
# Read a fasta file and are return reverse-complement. 
# S. Cannon Feb 2025

# SeqIO for importing sequences
use Bio::SeqIO;
use Bio::Seq;
use strict;
use warnings;
use feature "say";
use Getopt::Long;

my ($in_file, $help);
my $width = 100;

GetOptions (
  "in_file=s" => \$in_file,   # required
  "width:i" =>   \$width,
  "help" =>      \$help,
);


my $usage = <<EOS;
  Usage: perl $0 [-options]

  Reverse-complement the sequence provided as input

   Required:
     -in    fasta-format sequence to be reverse-complemented

   Options:
     -width       (integer) width for wrapping fasta sequence; default 100
     -help        for more info
EOS

die $usage if ($help);
die $usage unless (-e $in_file);

my $in  = Bio::SeqIO->new(-file => $in_file, '-format' => 'Fasta');

while ( my $seqobj = $in->next_seq ) {
  
  my $display_id = $seqobj->display_id();
  
  my $desc = $seqobj->desc();
  
  my $rev_obj = $seqobj->revcom();
  my $rev_seq = $rev_obj->seq();
  $rev_seq =~ s/(.{$width})/$1\n/gs; # break lines at $width;
  chomp $rev_seq;
  
  # Print the sequence ourselves rather than with write_seq in order to control line wrap length
  if ($desc){
    say ">$display_id $desc\n$rev_seq";
  }
  else {
    say ">$display_id\n$rev_seq";
  }
}

__END__
2025-02-11 S. Cannon First version
