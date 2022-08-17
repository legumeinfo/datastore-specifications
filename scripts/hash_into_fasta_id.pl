#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: hash_into_fasta_id.pl [options] -fasta FILE -hash FILE
  
  Read a key-value hash file and a fasta file. 
  Swap the IDs with the values from the hash file.
  
  Required:
  -fasta     (string) Fasta file
  -hash      (string) Key-value hash file, where first column has IDs from fasta file
  
  Options:
  -help   (boolean) This message.
  
EOS

my ($fasta_file, $hash_file, $help);

GetOptions (
  "hash_file=s" =>     \$hash_file,   # required
  "fasta_file=s" =>    \$fasta_file,   # required
  "help" =>            \$help,
);

die "$usage\n" unless (defined($fasta_file) and defined($hash_file));
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

# read fasta and swap IDs
$/="\n>";
open(my $FAS, '<', $fasta_file) or die "can't open in fasta_file, $fasta_file: $!";
while (<$FAS>) {
  chomp;
  s/^>//;
  my ($id, $desc, $seq) = /(\S+)([^\n]*)\n(.*)/s;
  my $new_id = $id_map{$id}; 
  die "could not find $id\n" unless defined $new_id;
  print ">$new_id$desc\n$seq\n";
}
