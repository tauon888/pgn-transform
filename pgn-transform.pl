#!/usr/bin/perl
use strict;
use warnings;

#
# Description:
#   This script will process chess games copied from lichess.com into a PGN
# format for Scid.
#
# Author:
#   M.R. Smith - 13-Mar-2021
#
# Usage:
#   perl pgn-transform.pl [<inpfile>]
#
# Design:
#   Parse a text file containing games in lichess format and a result header
# and write an output PGN file readable by SCID.
#
# The game file contains a game represented by just 2 lines as follows:
#
# <game-details-header>
# <game>
#
# The above lines are defined as follows:
#   <game-details> ::= <date><my-colour><result>[<comment>]
#           <date> ::= <game-date>
#      <game-date> ::= YY.MM.DD
#      <my-colour> ::= W | B
#         <result> ::= <win-for-white> | <win-for-black> | <draw> | <open>
#  <win-for-white> ::= 1-0
#  <win-for-black> ::= 0-1
#           <draw> ::= .5-.5
#           <open> ::= *
#
#           <game> ::= <move>[<move>]
#           <move> ::= <move-num><white-move>[<black-move>]
#       <move-num> ::= [1..n]               ! Integer > 1
#     <white-move> ::= <ply>
#     <black-move> ::= <ply>
#            <ply> ::= [<piece>][<file>][<rank>]<location>[<promotion>][<check>][<double-check>][<checkmate>] | <special-move>
#          <piece> ::= K | Q | B | N | R
#           <file> ::= a | b | c | d | e | f | g | h
#           <rank> ::= 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8
#       <location> ::= <file><rank>
#      <promotion> ::= <equals><promoted-piece>
#         <equals> ::= =
# <promoted-piece> ::= Q | B | N | R
#          <check> ::= +
#   <double-check> ::= ++
#      <checkmate> ::= #
#   <special-move> ::= O-O | O-O-O      ! Castle Kingside and Queenside
#
# So a list of moves can be quite complex.  Here are some examples:
#
# 21.03.15W1-0
# 1e4c52Nc3d63Nf3g64d4cxd45Nxd4Bg76Bb5+Bd77Bg5Bxb58Ndxb5Qa59O-Oa610Nd4Qxg511f4Qc5
#
# 21.03.19W1-0
# 1d4e52dxe5d53exd6Qxd64Qxd6Bxd65Nc3Bb46Bf4Nf67Nf3O-O8Bxc7Bg49h3Bxf310gxf3Nc611Rg1Bxc3+12bxc3Rad8
#
# The core of the program is to define a regular expression (regex) that will
# match any of the possible legal moves.  After digesting the anaysis above and
# some experimentation, I came up with the following regular expression.
#
my $regex = "^O-O-O|^O-O|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][\\+#]*";

#
# To Do:
# - Prune down temporary variables.
# - Add a hash of dates and frequency and out as a CSV.
#

# Process the command line.
my ($inpFile, $debug) = @ARGV;
if (not defined $inpFile) {
  $inpFile = "games.txt";
  #die "Need an input file of games to process\n";
}
if (not defined $debug) { $debug = 0; }

# Variables.
my $title = "PGN Game Transformer for Lichess game strings V1.1";
my $outFile = "games.pgn";
my $gameCount = 0;
my $totalWins = 0;
my %dateHash = ();
my %winsHash = ();

print "$title Starting...\n";
print "Input Game file: $inpFile\n";
print "Output PGN file: $outFile\n";
print "Processing...\n";

# Open input file.
open INP, $inpFile or die "Can't open $inpFile\n";

# Open output file.
open OUT, ">$outFile" or die "Can't open $outFile\n";

# Read and process input file writing to output.
my $moveNum = 1;
my $moveStr = "";
my $move = 1;
my $moveLen = 1;
my $idx = 0;
my $game = 1;
my $buffer = "";
my $lineLen = 0;
my $fin = "";
my $comment = "";
while (my $line = <INP>) {
  chomp($line);
  $line =~ s/^\s+|\s+$//g;
  # Only process non-blank lines.
  $lineLen = length($line);
  if (($lineLen > 0) && (substr($line, 0, 1) ne "#")) {
    print "I: $line\n";
    # Process each line.

    # If the line contains a result, process it and remember the outcome.
    if ((substr($line, 2, 1) eq "\.") && (substr($line, 5, 1) eq "\.")) {
      &printHeader($game, $line, \$fin, \$comment);
      $game++;
    } else {
      $idx = 0;
      while ($idx < $lineLen) {
        # Extract the move number.
        &extractMoveNumber($line, \$idx);

        # Extract White's move.
        &extractWhitesMove($line, \$idx);

        if ($idx < $lineLen) {
          # Extract Black's move.
          &extractBlacksMove($line, \$idx);
        } else {
          &printNewline();
        }
        if ($debug) { &pause(); }
      }
      if ($comment ne "") {
        &printLine("{$comment}");
      }
      &printLine($fin);
      &printNewline();
      $gameCount++;
    }
  }
}

# Close files.
close OUT;
close INP;

my $pcentWins = sprintf("%.1f", $totalWins * 100 / $gameCount);
print "$gameCount games processed, $totalWins wins ($pcentWins%)\n";
foreach my $key (sort keys %dateHash) {
  print "$key played $dateHash{$key} games, $winsHash{$key} won\n";
}
print "$title Complete\n";

sub printHeader {
  my ($gameCount, $result, $resultRef, $commentRef) = @_;

  #
  # Result is passed in the form:
  #  21.03.17W*
  #  21.03.17W1-0
  #  21.03.17W1-0great game of tactics
  #  21.03.17W*great game of tactics
  #
  # If a comment is passed, then it is added at the end.
  #

  # Extract the date.
  my $date = "20" . substr($result, 0, 8);
  my $playingWhite = 0;
  my $playingBlack = 0;
  my $gameWon = 0;
  my $totalWon = 0;

  &printLine("[Event \"lichess.com\"]");
  &printLine("[Site \"lichess.com\"]");
  &printLine("[Date \"$date\"]");
  &printLine("[Round \"$gameCount\"]");

  # Note if I played as white or black.
  if (substr($result, 8, 1) eq "W") {
    $playingWhite = 1;
    &printLine("[White \"Mike\"]");
    &printLine("[Black \"Anon\"]");
  } else {
    $playingBlack = 1;
    &printLine("[White \"Anon\"]");
    &printLine("[Black \"Mike\"]");
  }

  # Note the result: *, 1-0, 0-1 or .5-.5 and process any final comment.
  if (substr($result, 9, 1) eq "*") {
    &printLine("[Result \"*\"]");
    $$resultRef = "*";
    $$commentRef = substr($result, 10);
  }
  if (substr($result, 9, 1) eq "1") {
    &printLine("[Result \"1-0\"]");
    $$resultRef = "1-0";
    $$commentRef = substr($result, 12);
    if ($playingWhite) { $gameWon = 1; }
  }
  if (substr($result, 9, 1) eq "0") {
    &printLine("[Result \"0-1\"]");
    $$resultRef = "0-1";
    $$commentRef = substr($result, 12);
    if ($playingBlack) { $gameWon = 1; }
  }
  if (substr($result, 9, 1) eq ".") {
    &printLine("[Result \"1/2-1/2\"]");
    $$resultRef = "1/2-1/2";
    $$commentRef = substr($result, 14);
  }

  # Update the date and wins hash to count the games per day.
  if (exists($dateHash{$date})) {
    $dateHash{$date} = $dateHash{$date} + 1;
  } else {
    $dateHash{$date} = 1;
  }
  if ($gameWon) {
    $totalWins++;
    if (exists($winsHash{$date})) {
      $winsHash{$date} = $winsHash{$date} + 1;
    } else {
      $winsHash{$date} = 1;
    }
  }

  return;
}

sub printLine {
  my ($str) = @_;
  print OUT "$str\n";
  print "$str\n";
}

sub printNewline {
  print OUT "\n";
  print "\n";
}

sub extractMoveNumber {
    my ($string, $idxRef) = @_;
    my $buffer = substr($string, $$idxRef);
    #print "Buffer: $buffer\n";
    my $regex1 = "\\d*";
    #print "Regex: $regex\n";
    my ($result) = ($buffer =~ m/($regex1)/);
    if ($debug) { print "Move: $result\n"; }
    print OUT $result, ".";
    print $result, ". ";
    # Increment the index to point beyond the move number.
    $$idxRef = $$idxRef + length($result);
    return $result;
}

sub extractWhitesMove {
    my ($string, $idxRef) = @_;
    my $move = &extractMove($string, $idxRef);
    print OUT $move, " ";
    print $move, " ";
    $$idxRef = $$idxRef + length($move);
    return $move;
}

sub extractBlacksMove {
    my ($string, $idxRef) = @_;
    my $move = &extractMove($string, $idxRef);
    print OUT $move, " ";
    print $move, "\n";
    $$idxRef = $$idxRef + length($move);
    return $move;
}

sub extractMove {
    my ($string, $idxRef) = @_;
    my $buffer = substr($string, $$idxRef);
    if ($debug) { print "\nbuf: $buffer\n"; }
    #my $regex = "^O-O-O|^O-O|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][\\+#]*";
    #print "Regex: $regex\n";
    my ($result) = ($buffer =~ m/($regex)/);
    if (not defined $result) {
      print "No Match - Buffer: $buffer\n";
      exit 1;
    }
    #print "emResult: $result\n";
    return $result;
}

sub pause {
  print "Press \"c\" to continue, \"e\" to exit: ";
  while (1) {
    my $input = lc(getc());
    chomp ($input);
    if ($input eq 'c') {
      last;
    }
    elsif ($input eq 'e') {
      exit 1;
    }
  }
}
