#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: gzcat FASTAFILE.fas.gz | hash_into_fasta_simple.pl -hash FILE 
        OR     hash_into_fasta_simple.pl -hash FILE < FASTAFILE.fas
  
  Read a key-value hash file, and a fasta file on STDIN.
  Swap the IDs with the values from the hash file.

  NOTE: The hash file must have each ID in the fasta file, INCLUDING splice variants, e.g.
    GmISU01.03G078800.1  glyma.Wm82_ISU01.gnm2.ann1.03G078800.1 
    GmISU01.03G078800.2  glyma.Wm82_ISU01.gnm2.ann1.03G078800.1 
    GmISU01.03G078800.3  glyma.Wm82_ISU01.gnm2.ann1.03G078800.1 

  If you wish to do anything fancier with splice variants or suffixes, use
  the program hash_into_gff_id.pl instead of this "simple" script.
  
  Required:
  -hash      (string) Key-value hash file, where first column has IDs from fasta file
  
  Options:
  -help   (boolean) This message.
  
EOS

my ($hash_file, $help);

GetOptions (
  "hash_file=s" =>     \$hash_file,   # required
  "help" =>            \$help,
);

die "$usage\n" unless (defined($hash_file));
die "$usage\n" if ($help);

# read hash
open(my $HSH, '<', $hash_file) or die "can't open in input_hash, $hash_file: $!";
my %id_map;
while (<$HSH>) {
  chomp;
  /(\S+)\s+(.+)/;
  my ($id, $hash_val) = ($1,$2);
  $id_map{$id} = $hash_val;   # print "$id, $id_map{$id}\n";
}

# read fasta on STDIN and swap IDs
$/="\n>";
while (<>) {
  chomp;
  s/^>//;
  my ($id, $desc, $seq) = /(\S+)([^\n]*)\n(.*)/s;
  my $new_id = $id_map{$id}; 
  die "could not find $id\n" unless defined $new_id;
  print ">$new_id$desc\n$seq\n";
}
