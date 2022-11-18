#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: zcat FILE.vcf.gz | hash_into_vcf.pl -hash FILE 
        OR     hash_into_vcf.pl -hash FILE < FILE.vcf
  
  Read a key-value hash file, and VCF data on STDIN.
  Swap the CHROM_IDs with the values from the hash file.

  Required:
  -hash      (string) Key-value hash file, where first column has CHROM_IDs from VCF file
  
  Options:
  -add_id (boolean) Construct and write a feature ID in the third column, with the form CHROM.POS
  -help   (boolean) This message.
  
EOS

my ($hash_file, $add_id, $help);

GetOptions (
  "hash_file=s" =>  \$hash_file,   # required
  "add_id" =>       \$add_id,
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
  my ($chr_id, $hash_val) = ($1,$2);
  $id_map{$chr_id} = $hash_val;   # print "$chr_id, $id_map{$chr_id}\n";
}

# read VCF data file on STDIN and swap IDs
my $comment_str = "";
my ($gene_name, $new_id);
while (<>) {
  chomp;

  # print comment line 
  if (/(^#.+)/) {
    $comment_str=$1;
    if($comment_str=~/##contig=<ID=([^,]+),length=(\d+)>/){
      if ($id_map{$1}){
        my $new_chr_ID=$id_map{$1};
        print "##contig=<ID=$new_chr_ID,length=$2>\n";
      }
    }
    else { # structure like "##contig=<ID=CM003504.1,length=36501346>" isn't seen, so print what was there
      print "$comment_str\n";
    }
  }
  else { # body of the VCF
    my @fields = split(/\t/, $_);
    my $chr_id = shift(@fields);
    my $pos = shift(@fields);
    my $current_id = shift(@fields);
    if ($id_map{$chr_id}){
      if ($add_id){
        my $feat_id = "$id_map{$chr_id}.$pos";
        print "$id_map{$chr_id}\t$pos\t$feat_id\t", join("\t", @fields), "\n";
      }
      else { # don't print constructed feat_id
        print "$id_map{$chr_id}\t$pos\t$current_id\t", join("\t", @fields), "\n";
      }
    }
    else {
      warn "Warning: No matching ID for contig $chr_id\n";
    }
  }
}

__END__
S. Cannon
2022-11-17 New script
2022-11-18 Handle identifiers in vcf comment block, e.g. ##contig=<ID=CM003504.1,length=36501346>
