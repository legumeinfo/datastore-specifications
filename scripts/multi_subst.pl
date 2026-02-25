#!/usr/bin/env perl

use strict;
use warnings;

sub usage {
    print <<"END_USAGE";
Usage: $0 HASHFILE < input > output

Performs multiple string substitutions on STDIN using HASHFILE,
which must contain two columns per line:

    STRING   REPLACEMENT

Each occurrence of STRING in the input is replaced with REPLACEMENT.

Options:
    -h, --help    Show this help message

Notes:
    - Matching is literal (not regex)
    - Replacements are applied in file order
    - Blank lines and lines starting with # are ignored

Example:
    $0 hash.txt < input.txt > output.txt

END_USAGE
    exit;
}

# Show help if requested
usage() if !@ARGV || $ARGV[0] =~ /^-h|--help$/;

my $hashfile = shift @ARGV;

# Read substitution pairs
open my $fh, '<', $hashfile
    or die "Error: Cannot open '$hashfile': $!\n";

my (@keys, @vals);

while (<$fh>) {
    chomp;
    next if /^\s*$/;
    next if /^\s*#/;

    my ($k, $v) = split(/\s+/, $_, 2);

    if (!defined $v) {
        warn "Warning: skipping malformed line: $_\n";
        next;
    }

    push @keys, $k;
    push @vals, $v;
}

close $fh;

# Process input
while (<>) {
    for my $i (0 .. $#keys) {
        s/\Q$keys[$i]\E/$vals[$i]/g;
    }
    print;
}

