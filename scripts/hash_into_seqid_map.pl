#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: cat FILE.tsv | hash_into_seqid_map.pl -hash FILE 
  
  Read a key-value hash file, and two-column TSV data on STDIN.
  Swap the IDs in column 2 of the second column with the values from the hash file.
  The values in the second column are to be pattern-matched, e.g.
    CM039426.1	bauva.BV-YZ2020.gnm2.CM039426.1
    ==>
    CM039426.1	bauva.BV-YZ2020.gnm2.Chr01

  Required:
  -hash      (string) Key-value hash file, where second column has values to be patched.
  
  Options:
  -help   (boolean) This message.
  
EOS

my ($hash_file, $help);

GetOptions (
  "hash_file=s" =>  \$hash_file,   # required
  "help" =>         \$help,
);

die "$usage\n" unless (defined($hash_file));
die "$usage\n" if ($help);

# read hash
open(my $HSH, '<', $hash_file) or die "can't open in input_hash, $hash_file: $!";
my %id_map;
while (<$HSH>) {
  chomp;
  /(\S+)\s+(.+)/;
  next if (/^#/);
  my ($id, $hash_val) = ($1,$2);
  $id_map{$id} = $hash_val;   # print "$id, $id_map{$id}\n";
}

# read TSV data file on STDIN and swap IDs
my %patched_new_id;
while (<>) {
  chomp;
  my $line = $_;
  my ($first, $second) = split(/\t/, $line);
  my $new_id = $second;
  for my $id (keys %id_map){
    if ($new_id =~ m/$id$/){
      my $hash_val = $id_map{$id};
      $new_id =~ s/$id$/$hash_val/;
      print "$first\t$new_id\n";
      $patched_new_id{$second}++;
      next;
    }
  }
  unless ($patched_new_id{$second}){ print "$first\t$second\n" }
}

