#!/usr/bin/perl
use strict;
use warnings;

#
# Description:
#   This script will test the pgn-transform.pl script.
#
# Author:
#   M.R. Smith - 10-May-2021
#
# Usage:
#   perl pgn-tests.pl
#
# Design:
#   Run a series of tests and compare the output PGN and CSV files with a saved
# reference file.
#
# Modification History:
# Version  Date       Developer     Modification
#  1.0     10-May-21  M.R. Smith    Initial Version.
#
my @testData = qw(test small games m1|1e4e52Nf3Nf63Nxe5Nc64Nxc6dxc65Nc3Bc56d3O-O7Bg5Nxe48Bxd8Bxf2+9Ke2Bg4#);

my $passes = 0;
my $title = "PGN Game Transformer Tester V1.0";
print "$title...\n";
my $t = 1;
foreach my $data (@testData) {
  # Work out the filename and any moves.
  my ($inpFile, $moves) = split(/\|/, $data);
  if (not defined $moves) { $moves = ""; }

  # Run the program on the test file or moves.
  &runProgram($t++, $inpFile, $moves);

  # Compare the output with reference files.
  if (&checkOutputFiles($inpFile, $moves)) {
    $passes++;
  }
  print "\n";
}

# Check all tests passed.
my $failed = @testData - $passes;
if ($failed) {
  print "$passes passed, $failed failed\n";
} else {
  print "All tests passed\n";
}

print "$title Complete\n";


#
# Subroutines.
#
sub runProgram {
  my ($testNo, $testFile, $moveString) = @_;

  # Run the program.
  my $cmd = "";
  if ($moveString eq "") {
    # The test data is an input file.
    $cmd = "perl pgn-transform.pl $testFile.txt > $testFile.new";
    print "Test $testNo - Transforming games file $testFile.txt\n";
  } else {
    # The test data is a move string.
    $cmd = "perl pgn-transform.pl -m $moveString > $testFile.new";
    print "Test $testNo - Transforming moves $moveString\n";
  }
  print "Executing: $cmd\n";
  system($cmd);
}

sub checkOutputFiles {
  my ($testFile, $moveString) = @_;

  # Check the output.
  my $outFile = "$testFile.new";
  my $outRefFile = "$testFile-out.ref";
  print "checking $outFile against $outRefFile... ";
  my $matched = &compareFiles($outFile, $outRefFile);

  if ($moveString eq "") {
    # Check the PGN.
    my $pgnFile = "$testFile.pgn";
    my $pgnRefFile = "$testFile-pgn.ref";
    print "checking $pgnFile against $pgnRefFile... ";
    $matched = $matched && &compareFiles($pgnFile, $pgnRefFile);

    # Check the CSV.
    my $csvFile = "$testFile.csv";
    my $csvRefFile = "$testFile-csv.ref";
    print "checking $csvFile against $csvRefFile... ";
    $matched = $matched && &compareFiles($csvFile, $csvRefFile);
  }
  return $matched;
}

sub compareFiles {
  my ($f1, $f2) = @_;

  my $exitStatus = system("diff $f1 $f2");
  my $matched = 0;
  if ($exitStatus) {
    print "NOT MATCHED\n";
  } else {
    print "MATCHED\n";
    $matched = 1;
  }
  return $matched;
}
