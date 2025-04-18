#!/usr/bin/env perl
# #!/usr/bin/env perl

# Program: split_fasta_to_files_by_name.pl
# See version notes at end of program.

# Read a multi-fasta file and return a directory with single-sequence files. 
# Assumes all seqs have a bioperl-readable accession

# S. Cannon Aug 2004

use strict;
use warnings;

use lib "/home/scannon/miniconda3/lib/perl5/site_perl/5.22.0";
use Bio::SeqIO;
use Bio::Seq;
use Getopt::Long;


############################
# GetOptions 
############################

my $LINE_LEN = 100; # Length of chunks to print
my $min_len = 0; # minimum sequence length to print
my $regex = "(.+)";
my ($input_seq, $out_dir);

GetOptions( "input_seq=s" => \$input_seq,
            "out_dir=s"   => \$out_dir,
            "min_len:i"   => \$min_len,
            "regex:s"     => \$regex,
          );

############################
# Usage, IO 
############################


my $usage_string = <<EOS;
Usage: perl $0 -in input_seq -out out_dir [options]

Required:
  -in Input fasta file to be split
  -out Output directory for component fasta files

Options:
  -min_len  Minimum sequence length to output. Default is 0 (i.e. print out all sequences)
  -regex    The part of the def line to use for new filenames. Enclose in quotes.
            The remainder of the ID will be retained in the new fasta files.
            Examples:
              "gi\\|\\d+\\|\\w+\\|(\\w+\\d+)"   captures accession from Genbank defline
              "(.+)"                     captures all display_id for filenames

EOS

die "\n$usage_string\n" unless ($input_seq && $out_dir);

my $params = <<EOS;
input_seq:  $input_seq
out_dir:    $out_dir
regex:      $regex
min_len:    $min_len
EOS

print "$params";

#my $rex = qr/$regex/;

opendir (DIR, "$out_dir") or mkdir($out_dir); close DIR;

my $in = Bio::SeqIO->new(-file => $input_seq , '-format' => 'Fasta');
my %seen_file;

while ( my $seq = $in->next_seq ) {
  
  my $len = $seq->length;
  next if ($len<$min_len);

  my $display_id = $seq->display_id(); # piece of def line before space
  my $desc = $seq->desc(); # rest of def line
  #$display_id =~ /($rex)/;
  $display_id =~ /($regex)/;
  my $filename = $1;
  if (length($filename) == 0) {
    print "\nParse error.\n";
    print "\tdisplay_id:\t$display_id\n";
    print "\tdesc:\t$desc\n";
    print "\tfilename:\t$filename\n";
    print "\tregex:\t$regex\n";
    die
  }
  my $sequence = $seq->seq();
  my @chunked_sequence = unpack("(A$LINE_LEN)*", $sequence);
  
  if ($seen_file{$filename}) {
    print OUT "\n>$display_id $desc\n";
    print OUT join("\n", @chunked_sequence), "\n";
  }
  else {
    $seen_file{$filename}++;
    my $out_file = "$out_dir/$filename";
    open (OUT, "> $out_file") or die "can't open out $out_file: $!";
    print OUT ">$display_id $desc\n";
    print OUT join("\n", @chunked_sequence), "\n";
    print "$filename ";
  }
}
print "\n"; # Last line return in STDOUT report

__END__
Version
0.1  Aug   04 basic; works OK.
0.2  Feb02'05 take in regex.
0.3  Jan19'08 Write out new file only if ID (and filename) hasn't been seen yet.
0.4  Aug06'10 write diagnostic error message to warn of header parse error.
0.5  Apr09'17 Minor changes: #! line, pragmas, usage notes, 
           and important: add line return at end of $sequence, and wrap sequence.
0.6  May06'19 Add flag to suppress sequences below a specified length
