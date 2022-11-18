#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: zcat FILE.vcf.gz | hash_into_vcf.pl -hash FILE 
        OR     hash_into_vcf.pl -hash FILE < FILE.vcf
  
  Read a key-value hash file, and VCF data on STDIN.
  Swap the IDs with the values from the hash file.

  Required:
  -hash      (string) Key-value hash file, where first column has IDs from VCF file
  
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

# read VCF data file on STDIN and swap IDs
while (<>) {
  chomp;
  my $line = $_;
  if ($_ =~ /^#/){
    print "$line\n";
    next;
  }
  my ($first, @rest) = split(/\t/, $line);
  my $new_id = $id_map{$first}; 
  die "could not find $new_id\n" unless defined $new_id;
  print "$new_id\t", join("\t", @rest), "\n";
}

