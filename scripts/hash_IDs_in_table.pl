#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

# Parse command line options
my $hash_file;
my $column;
my $log_file;
my $help;

GetOptions(
    'hash=s'   => \$hash_file,
    'column=i' => \$column,
    'log=s'    => \$log_file,
    'help|h'   => \$help,
) or die "Error in command line arguments\n";

# Display usage if help flag is set
if ($help) {
    print_usage();
    exit 0;
}

# Check if STDIN is connected to a terminal (no piped input)
if (-t STDIN) {
    print STDERR "Error: No input data provided on STDIN\n\n";
    print_usage();
    exit 1;
}

# Validate required arguments
unless (defined $hash_file && defined $column && defined $log_file) {
    print STDERR "Error: Missing required arguments\n\n";
    print_usage();
    exit 1;
}

# Adjust column number to 0-based index
my $col_index = $column - 1;
die "Column number must be >= 1\n" if $col_index < 0;

# Read hash file into memory
my %hash_lookup;
open(my $hash_fh, '<', $hash_file) or die "Cannot open hash file '$hash_file': $!\n";
while (my $line = <$hash_fh>) {
    chomp $line;
    # Skip comment lines in hash file
    next if $line =~ /^#/;
    
    my @fields = split(/\t/, $line);
    
    if (@fields >= 2) {
        $hash_lookup{$fields[0]} = $fields[1];
    }
}
close($hash_fh);

# Open log file for writing
open(my $log_fh, '>', $log_file) or die "Cannot open log file '$log_file': $!\n";

# Process STDIN
my $line_number = 0;
while (my $line = <STDIN>) {
    $line_number++;
    chomp $line;
    
    # Pass through comment lines unchanged
    if ($line =~ /^#/) {
        print "$line\n";
        next;
    }
    
    my @fields = split(/\t/, $line);
    
    # Check if the specified column exists
    if ($col_index >= @fields) {
        print $log_fh "Line $line_number: Column $column does not exist (only " . 
                      scalar(@fields) . " columns present)\n";
        print "$line\n";
        next;
    }
    
    my $original_value = $fields[$col_index];
    
    # Check if value exists in hash
    if (exists $hash_lookup{$original_value}) {
        # Swap the value
        $fields[$col_index] = $hash_lookup{$original_value};
        print join("\t", @fields) . "\n";
    } else {
        # Log the unmatched line
        print $log_fh "Line $line_number: No match found for value '$original_value'\n";
        # Output original line unchanged
        print "$line\n";
    }
}

close($log_fh);

# Subroutine to print usage information
sub print_usage {
    print <<'USAGE';
NAME
    hash_IDs_in_table.pl - Replace values in tabular data using a hash lookup file

SYNOPSIS
    cat FILE.tsv | hash_IDs_in_table.pl --hash <hashfile> --column <N> --log <logfile>
    
    hash_IDs_in_table.pl --hash <hashfile> --column <N> --log <logfile> < FILE.tsv

DESCRIPTION
    This script reads tab-delimited data from STDIN and replaces values in a 
    specified column using a two-column hash lookup file. The first column of 
    the hash file contains keys to match, and the second column contains the 
    replacement values.
    
    Lines beginning with '#' are treated as comments and passed through unchanged.
    Lines without matching keys are output unchanged and logged.

OPTIONS
    --hash <file>     Path to the hash lookup file (tab-delimited, 2 columns)
                      Required.
    
    --column <N>      Column number to process (1-based indexing)
                      Required.
    
    --log <file>      Path to the log file for unmatched entries
                      Required.
    
    -h, --help        Display this help message and exit

EXAMPLES
    # Basic usage
    cat data.tsv | hash_IDs_in_table.pl --hash lookup.tsv --column 3 --log errors.log
    
    # Alternative input method
    hash_IDs_in_table.pl --hash lookup.tsv --column 1 --log errors.log < input.tsv
    
    # Redirect output to a file
    cat data.tsv | hash_IDs_in_table.pl --hash lookup.tsv --column 3 --log errors.log > output.tsv

INPUT FORMAT
    Input data (STDIN):     Tab-delimited file with any number of columns
    Hash file (--hash):     Tab-delimited file with exactly 2 columns
                            Column 1: Keys to match
                            Column 2: Replacement values

OUTPUT
    Modified data is written to STDOUT
    Unmatched entries are logged to the specified log file

AUTHOR
    Steven Cannon & Claude Sonnet 4.5

USAGE
}
