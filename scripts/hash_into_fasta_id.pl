#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

my $usage = <<EOS;
 Synopsis: gzcat FASTAFILE.fas.gz | hash_into_fasta_id.pl [options] -hash FILE 
        OR     hash_into_fasta_id.pl [options] -hash FILE < FASTAFILE.fas
  
  Read a key-value hash file, and a fasta file on STDIN.
  Swap the IDs with the values from the hash file.
  The hash file can be created to match the full ID, including splice variants,
  OR created to match just the gene IDs, excluding splice variants.
  In the latter case, provide -splice_regex to give the form of the splice variant.
  
  Required:
  -hash      (string) Key-value hash file, where first column has IDs from fasta file
  [fasta in stream via STDIN]
  
  Options:
  -nodef          (boolean) Don't print the def-line description (print only the ID).
  -splice_regex   (string) quoted portion of regular expression to use to exclude the 
                  splice variant suffix of a feature name during the match. 
         Example 1: For transcripts like Gene1234.1,      use "\\.\\d+"  
         Example 2: For transcripts like Gene1234-mRNA-1, use "\\-mRNA-\\d+" 
         Example 3: For proteins like    Gene1234.1.p,    use "\\.\\d+\\.p"
  
  -help   (boolean) This message.
  
EOS

my ($hash_file, $splice_regex, $nodef, $help, $REX);

GetOptions (
  "hash_file=s" =>     \$hash_file,   # required
  "splice_regex:s" =>  \$splice_regex,   
  "nodef" =>           \$nodef,   
  "help" =>            \$help,
);

die "$usage\n" unless (defined($hash_file));
die "$usage\n" if ($help);

if ($splice_regex){ $REX=qr/$splice_regex/ }
else { $REX=qr/$/ }

# read hash in
open(my $HSH, '<', $hash_file) or die "can't open in input_hash, $hash_file: $!";
my %hash;
while (<$HSH>) {
  chomp;
  /(\S+)\s+(.+)/;
  my ($id, $hash_val) = ($1,$2);
  $hash{$id} = $hash_val;   # print "$id, $hash{$id}\n";
}

# Read in the sequence 
while (<STDIN>){
  chomp;
  my $line = $_;
  my ($display_id, $desc, $seq, $base_id, $suffix);
  if ($line =~ /^>(\S+) +(\S.+)/){
    $display_id = $1;
    $desc = $2;
    $seq = "";
    #print "1:[$display_id] {$desc}\n";

    # strip off splice variant
    $display_id =~ m/(.+)($REX)$/;
    ($base_id, $suffix) = ($1, $2);
    #print "[$base_id] [$suffix]\n";
    
    $hash{$base_id} = "$base_id HASH UNDEFINED" unless defined ($hash{$base_id});
    if ($nodef){ # DON'T print the defline description
      print ">$hash{$base_id}$suffix\n";
    }
    else { # DO print the defline description
      print ">$hash{$base_id}$suffix $desc\n";
    }
  }
  elsif ($line =~ /^>(\S+) *$/){
    $display_id = $1;
    $seq = "";
    #print "2:[$display_id]\n";

    # strip off splice variant
    $display_id =~ m/(.+)($REX)$/;
    ($base_id, $suffix) = ($1, $2);
    #print "[$base_id] [$suffix]\n";
    
    $hash{$base_id} = "$base_id HASH UNDEFINED" unless defined ($hash{$base_id});
    print ">$hash{$base_id}$suffix\n";
  }
  elsif ($line !~ /^>/){
    $seq .= $line;
    print "$seq\n";
  }
}

__END__

# Steven Cannon 

Versions
v01 2014-05-21 New script, derived from hash_into_fasta_description.pl
v02 2018-02-09 Handle suffixes (e.g. for splice variants)
v03 2019-05-07 Print original ID if no hash is found
v04 2021-11-01 Don't print final ">" without ID or sequence!
v05 2021-11-04 Add warning for undefined hash
v06 2022-10-04 Remove BioPerl dependency, and take fasta in via STDIN.
                Change handling of the splice variant matching.

