#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $usage = <<EOS;
  Synopsis: zcat FILE.vcf.gz | hash_into_vcf.pl -hash FILE [options]
        OR     hash_into_vcf.pl -hash FILE < FILE.vcf
  
  Read a key-value hash file, and VCF data on STDIN.

  The program can either swap the CHROM values (column 1; default action),
  based on a hash of those CHROM values;
  OR the CHROM and POS values, based on the existing ID values (column 3; flag -swap_positions)

  In the latter mode (-swap_positions), the -hash_file should have three columns:
    #CHROM  POS  ID
    Chr1   1234  SNP1
    Chr1   6789  SNP2

  Required:
  -hash     (string) Key-value hash file, where first column has one of two formats:
              CHROM_ID_CURRENT  chrom_id_new
              chrom_ID_new      position_new   SNP_ID_CURRENT
  
  Options:
  -swap_pos (boolean) Use the provided SNP_ID (in col 3) to swap chrom_ID and position (cols 1, 2)
  -add_id   (boolean) Construct and write a feature ID in the third column, with the form CHROM.POS
  -outfile  (string)  Filename for writing ammended VCF
  -help     (boolean) This message.
EOS

my ($hash_file, $swap_pos, $add_id, $outfile, $help);

GetOptions (
  "hash_file=s" =>  \$hash_file,   # required
  "swap_pos" =>     \$swap_pos,
  "add_id" =>       \$add_id,
  "outfile:s" =>    \$outfile,
  "help" =>         \$help,
);

die "$usage\n" unless (defined($hash_file));
die "$usage\n" if ($help);

my $OUT;
if ($outfile){
  open($OUT, ">", $outfile) or die "Can't open out $outfile: $!\n";
}

# read hash
open(my $HSH, '<', $hash_file) or die "can't open in input_hash, $hash_file: $!";
my %snpid_map;
my %chrid_map;
while (<$HSH>) {
  chomp;
  my ($key, $hash_val);
  next if (/^$/ || /^#/);
  my @bits = split(/\s+/, $_);
  if ($swap_pos){ # Three-column, -swap_pos mode: Use the SNP_ID (in col 3) to swap chrom_ID and position (cols 1, 2)
    if (scalar(@bits) != 3){
      warn "With option -swap_pos, provide data in three fields: chrom_ID_new  position_new  SNP_ID_CURRENT.\n" .
           "Row $. has values: [$_]\n";
      die;
    }
    else { # Read three fields into a key and a combined value
      ($key, $hash_val) = ($bits[2], "$bits[0] $bits[1]");
    }
    $snpid_map{$key} = $hash_val;   # print "$key, $snpid_map{$key}\n";
  } 
  else { # Two-column mode (NOT -swap_pos), to swap CHROM IDs
    ($key, $hash_val) = ($bits[0], $bits[1]);
    $chrid_map{$key} = $hash_val;   # print "$key, $chrid_map{$key}\n";
  }
}

my $comment_str = "";
my $comment_ct  = 0;
my $variant_ct = 0;
# read VCF data file on STDIN and swap IDs
while (<>) {
  chomp;
  if ($swap_pos){ # Three-column, -swap_pos mode: Use the SNP_ID (in col 3) to swap chrom_ID and position (cols 1, 2)
    if (/^#/) { # print comment line 
      if (/##contig=/){ next; } # Skip these contig lines, The new contigs/chromosomes probably don't correspond with the previous.
      else {
        &printstr("$_\n");
        $comment_ct++;
      }
    }
    else { # body of the VCF
      my @fields = split(/\t/, $_);
      my $chr_id = shift(@fields);
      my $pos = shift(@fields);
      my $current_id = shift(@fields);
      if ($snpid_map{$current_id}){ # value "CHROM POS", with key $current_id}
        &printstr("$snpid_map{$current_id}\t$current_id\t", join("\t", @fields), "\n");
        $variant_ct++;
      }
      else {
        warn "Warning: No matching CHROM and POS for SNP $current_id\n";
      }
    }
  }
  else { # Two-column mode (NOT -swap_pos), to swap CHROM IDs
    if (/(^#.+)/) { # print comment line 
      $comment_str=$1;
      if($comment_str=~/##contig=<ID=([^,]+),length=(\d+)>/){
        if ($chrid_map{$1}){
          my $new_chr_ID=$chrid_map{$1};
          &printstr("##contig=<ID=$new_chr_ID,length=$2>\n");
        }
      }
      else { # structure like "##contig=<ID=CM003504.1,length=36501346>" isn't seen, so print what was there
        &printstr("$comment_str\n");
      }
      $comment_ct++;
    }
    else { # body of the VCF
      my @fields = split(/\t/, $_);
      my $chr_id = shift(@fields);
      my $pos = shift(@fields);
      my $current_id = shift(@fields);
      if ($chrid_map{$chr_id}){
        if ($add_id){
          my $feat_id = "$chrid_map{$chr_id}.$pos";
          &printstr("$chrid_map{$chr_id}\t$pos\t$feat_id\t", join("\t", @fields), "\n");
        }
        else { # don't print constructed feat_id
          &printstr("$chrid_map{$chr_id}\t$pos\t$current_id\t", join("\t", @fields), "\n");
        }
        $variant_ct++;
      }
      else {
        warn "Warning: No matching ID for contig $chr_id\n";
      }
    }
  }
}

warn "\nPrinted $comment_ct lines of comments and $variant_ct lines of variants.\n\n";

#####################
sub printstr {
  my $str_to_print = join("", @_);
  if ($outfile) {
    print $OUT $str_to_print;
  }
  else {
    print $str_to_print;
  }
}

__END__
S. Cannon
2022-11-17 New script
2022-11-18 Handle identifiers in vcf comment block, e.g. ##contig=<ID=CM003504.1,length=36501346>
2022-11-21 Add -swap_pos mode. Add function printstr.

