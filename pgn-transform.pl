#!/usr/bin/perl
use strict;
use warnings;

#
# Description:
#   This script will convert chess games copied from lichess.com to a text files
# to a file in PGN format compatible with SCID and other chess viewer apps.
#
# Author:
#   M.R. Smith - 13-Mar-2021
#
# Usage:
#   perl pgn-transform.pl [<options>] [<inpfile>]
#        <options> ::= <help> | <moves> | <debug>
#           <help> ::= --help | -h
#          <moves> ::= --moves <game-moves> | -m <game-moves>
#          <debug> ::= --debug | -d
#
# Design:
#   Parse a text file (defauts to games.txt) containing games in lichess format
# and write an output PGN file (defaults to the same names as the input file
# with .pgn extension).  For each game there is a header showing the date,
# if I played white or black and the result and a comment.
#
# The game file contains a game represented by just 2 lines as follows:
#   <game-details>
#   <game-moves>
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
#     <game-moves> ::= <move>[<move>]
#           <move> ::= <move-num><white-move>[<black-move>]
#       <move-num> ::= [1..n]
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
#          <check> ::= +              ! Check
#   <double-check> ::= ++             ! Double-Check
#      <checkmate> ::= #              ! Mate
#   <special-move> ::= O-O | O-O-O    ! Castle Kingside or Queenside
#
# So a game and its moves can be quite complex.  Here are some examples:
#
# 21.03.15W1-0
# 1e4c52Nc3d63Nf3g64d4cxd45Nxd4Bg76Bb5+Bd77Bg5Bxb58Ndxb5Qa59O-Oa610Nd4Qxg511f4Qc5
#
# 21.03.19W1-0
# 1d4e52dxe5d53exd6Qxd64Qxd6Bxd65Nc3Bb46Bf4Nf67Nf3O-O8Bxc7Bg49h3Bxf310gxf3Nc611Rg1Bxc3+12bxc3Rad8
#
# The core of the problem/program is to define a regular expression (regex)
# that will match any of the possible legal moves.  After much anaysis and
# experimentation, I came up with this.
#
# Note some patterns are subsets of others, Kingside is a subset of Queenside
# castling for example.  We must therefore put the longer expression first so
# we're testing for the more complex case first.
#

#
# The regex breaks down into the following matches:
#  1. Queenside castling: ^O-O-O
#  2. Kingside castling: ^O-O
#  3. Piece captures WITH a rank or file to resolve ambiquity, WITH promotion
#     and optional check, double-check or mate:
#       ^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]*
#  4. Piece captures WITHOUT a rank or file to resolve ambiquity, WITH promotion
#     and optional check, double-check or mate:
#       ^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]*
#  5. Piece captures WITH a rank or file to resolve ambiquity, WITHOUT promotion
#     and optional check, double-check or mate:
#       ^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]*
#  6. Piece captures WITHOUT a rank or file to resolve ambiquity, WITHOUT
#     promotion and optional check, double-check or mate:
#       ^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]*
#  7. Move (non-capture) WITH promotion and optional check, double-check or
#     mate:
#       ^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][=][QBNR][\\+#]*|
#  8. Move (non-capture) WITHOUT promotion and optional check, double-check or
#     mate:
#       ^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][\\+#]*";
#
#my $regex = "^O-O-O|^O-O|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][\\+#]*";
#
# Modification History:
# Version  Date       Developer     Modification
#  1.0     13-Mar-21  M.R. Smith    Initial Version, no statistics.
#  1.1     23-Apr-21  M.R. Smith    Fixed regex to recognise take with promotion
#                                   and optional check, double-check or mate.
#  1.2     25-Apr-21  M.R. Smith    Add statistics to count wins and draws.
#  1.3     28-Apr-21  M.R. Smith    Condense stats to a single hash.
#  1.4     09-May-21  M.R. Smith    Added command switches to process a single string of moves.
#

my $regex = "^O-O-O|^O-O|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][\\+#]*";

# Process the command line.
# Iterate through the parameters, noting options and filename.
my $debug = 0;
my $help = 0;
my $inpFile = "games.txt";
my $gameMoves = "";
my $i = 0;
foreach my $param (@ARGV) {
  # If the param begins with a - then it's an option.
  if (substr($param, 0, 1) eq "-") {
    if (($param eq "-d") || ($param eq "--debug")) { $debug = 1; }
    if (($param eq "-h") || ($param eq "--help")) { $help = 1; }
    if (($param eq "-m") || ($param eq "--moves")) {
      $gameMoves = $ARGV[$i+1];
      if ($debug) { print "Moves: $gameMoves\n"; }
    }
  } else {
    $inpFile = $param;
  }
  $i++;
}

# Variables.
my %stats = ();
my $title = "PGN Game Transformer for Lichess game strings V1.4";
if ($help) {
  print "\n";
  print "  Usage: perl pgn-transform.pl [<options>] [<inpfile>]\n";
  print "\n";
  print "    <options> ::= <help> | <moves> | <debug>\n";
  print "       <help> ::= --help | -h\n";
  print "      <moves> ::= --moves <game-moves> | -m <game-moves>\n";
  print "      <debug> ::= --debug | -d\n";
  print "\n";
} elsif ($gameMoves eq "") {
  print "$title...\n";

  my ($fileName, $fileType) = split(/\./, $inpFile);
  my $outFile = "$fileName.pgn";
  my $csvFile = "$fileName.csv";

  print "Input Game file: $inpFile\n";
  print "Output PGN file: $outFile\n";
  print "Output CSV file: $csvFile\n";
  print "Processing...\n";

  &processGamesFile($inpFile, $outFile);
  &displayAndLogStats($csvFile);
  print "$title Complete\n";
} else {
  print "$title...\n";
  &processMoves($gameMoves);
  print "$title Complete\n";
}


#
# Subroutines.
#
sub processMoves {
  my ($moves) = @_;
  chomp($moves);
  $moves =~ s/^\s+|\s+$//g;

  print "Moves: $moves\n";
  print "Processing...\n";

  # Read and process input file writing to output.
  my $moveNum = "";
  my $move = "";
  my $idx = 0;
  my $lineLen = length($moves);
  while ($idx < $lineLen) {
    # Extract the move number.
    $moveNum = &extractMoveNumber($moves, \$idx);
    printStr("$moveNum. ", 0);

    # Extract White's move.
    $move = &extractWhitesMove($moves, \$idx);
    printStr("$move ", 0);

    if ($idx < $lineLen) {
      # Extract Black's move.
      $move = &extractBlacksMove($moves, \$idx);
      printStr("$move\n", 0);
    } else {
      &printNewline(0);
    }
  }
  &printNewline(0);
}

sub processGamesFile {
  my ($inpFile, $outFile) = @_;

  # Open the input text file of games.
  open INP, $inpFile or die "Can't open $inpFile\n";

  # Create the output text file of converted PGN.
  open OUT, ">$outFile" or die "Can't open $outFile\n";

  # Read and process input file writing to output.
  my $moveNum = "";
  my $move = "";
  my $game = 1;
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
        my $idx = 0;
        while ($idx < $lineLen) {
          # Extract the move number.
          $moveNum = &extractMoveNumber($line, \$idx);
          printStr("$moveNum. ", 1);

          # Extract White's move.
          $move = &extractWhitesMove($line, \$idx);
          printStr("$move ", 1);

          if ($idx < $lineLen) {
            # Extract Black's move.
            $move = &extractBlacksMove($line, \$idx);
            printStr("$move\n", 1);
          } else {
            &printNewline(1);
          }
          if ($debug) { &pause(); }
        }
        if ($comment ne "") {
          &printStr("{$comment}\n", 1);
        }
        &printStr("$fin\n", 1);
        &printNewline(1);
      }
    }
  }

  # Close files.
  close OUT;
  close INP;
}

sub displayAndLogStats {
  my ($csvFile) = @_;

  # Create the output CSV file for stats.
  open CSV, ">$csvFile" or die "Can't open $csvFile\n";

  # Print some stats and calculate totals.
  my $gameCount = 0;
  my $totalWins = 0;
  my $totalWinsAsWhite = 0;
  my $totalWinsAsBlack = 0;
  my $totalDraws = 0;
  print "Date        Played  Won  As White  As Black  Draws\n";
  print "==========  ======  ===  ========  ========  =====\n";
  foreach my $date (sort keys %stats) {
    my ($games, $winsAsWhite, $winsAsBlack, $draws) = split(/\|/, $stats{$date});
    my $wins = $winsAsWhite + $winsAsBlack;
    #print "$date - $games played, $wins won, $winsAsWhite as white, $winsAsBlack as black, $draws draws\n";
    print sprintf("$date  %4s%6s%8s%10s%8s", $games, $wins, $winsAsWhite, $winsAsBlack, $draws) . "\n";
    print CSV "$date, $games, $wins, $winsAsWhite, $winsAsBlack, $draws\n";

    # Running totals.
    $gameCount += $games;
    $totalWins += $wins;
    $totalWinsAsWhite += $winsAsWhite;
    $totalWinsAsBlack += $winsAsBlack;
    $totalDraws += $draws;
  }

  # Compute percentages.
  my $pcentWins = sprintf("%.1f", $totalWins * 100 / $gameCount);
  my $pcentWinsAsWhite = sprintf("%.1f", $totalWinsAsWhite * 100 / $gameCount);
  my $pcentWinsAsBlack = sprintf("%.1f", $totalWinsAsBlack * 100 / $gameCount);
  my $pcentDraws = sprintf("%.1f", $totalDraws * 100 / $gameCount);

  # Print summary.
  print "$gameCount played, $totalWins won ($pcentWins%), $totalWinsAsWhite won as white ($pcentWinsAsWhite%), $totalWinsAsBlack won as black ($pcentWinsAsBlack%), $totalDraws draws ($pcentDraws%)\n";
  print CSV "Date, Played, Won, Won as White, Won as Black, Drawn\n";
  print CSV "\n";
  print CSV ", $gameCount played, $totalWins won ($pcentWins%), $totalWinsAsWhite won as white ($pcentWinsAsWhite%), $totalWinsAsBlack won as black ($pcentWinsAsBlack%), $totalDraws draws ($pcentDraws%)\n";

  close CSV;
}

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
    # Update the stats.
    if ($playingWhite) {
      &updateStats($date, 1, 0, 0);
    }
  }
  if (substr($result, 9, 1) eq "0") {
    &printLine("[Result \"0-1\"]");
    $$resultRef = "0-1";
    $$commentRef = substr($result, 12);
    # Update the stats.
    if ($playingBlack) {
      &updateStats($date, 0, 1, 0);
    }
  }
  if (substr($result, 9, 5) eq ".5-.5") {
    &printLine("[Result \"1/2-1/2\"]");
    $$resultRef = "1/2-1/2";
    $$commentRef = substr($result, 14);
    # Update the stats.
    &updateStats($date, 0, 0, 1);
  }

  return;
}

sub updateStats {
  my ($date, $w, $b, $d) = @_;
  # Update the stats to count the wins as white and black and draws each day.
  # We are given a delta so update the hash here.
  # Hash contains: Games | Wins as White | Wins as Black | Draws.
  # If this is a new date then update with the 1st game's result.

  # Zero hashes for the given date.
  if (!exists($stats{$date})) {
    $stats{$date} = "1|$w|$b|$d";
  } else {
    my ($games, $winsAsWhite, $winsAsBlack, $draws) = split(/\|/, $stats{$date});
    $games++;
    if ($w) { $winsAsWhite++; }
    if ($b) { $winsAsBlack++; }
    if ($d) { $draws++; }
    $stats{$date} = "$games|$winsAsWhite|$winsAsBlack|$draws";
  }
}

sub printLine {
  my ($str) = @_;
  print OUT "$str\n";
  print "$str\n";
}

sub printStr {
  my ($str, $oFlag) = @_;
  if ($oFlag) { print OUT "$str"; }
  print "$str";
}

sub printNewline {
  my ($oFlag) = @_;
  if ($oFlag) { print OUT "\n"; }
  print "\n";
}

sub extractMoveNumber {
    my ($string, $idxRef) = @_;

    my $buffer = substr($string, $$idxRef);
    my $regex1 = "\\d*";
    my ($result) = ($buffer =~ m/($regex1)/);
    if ($debug) { print "Move number: $result\n"; }
    # Increment the index to point beyond the move number.
    $$idxRef = $$idxRef + length($result);
    return $result;
}

sub extractWhitesMove {
    my ($string, $idxRef) = @_;

    my $move = &extractMove($string, $idxRef);
    # Increment the index to point beyond the move.
    $$idxRef = $$idxRef + length($move);
    return $move;
}

sub extractBlacksMove {
    my ($string, $idxRef) = @_;

    my $move = &extractMove($string, $idxRef);
    # Increment the index to point beyond the move.
    $$idxRef = $$idxRef + length($move);
    return $move;
}

sub extractMove {
    my ($string, $idxRef) = @_;
    my $buffer = substr($string, $$idxRef);
    if ($debug) { print "\nbuf: $buffer\n"; }
    my ($result) = ($buffer =~ m/($regex)/);
    if (not defined $result) {
      print "No Match - Buffer: $buffer\n";
      exit 1;
    }
    return $result;
}

sub pause {
  print "Press C to continue or E to exit: ";
  while (1) {
    my $input = lc(getc());
    chomp ($input);
    if ($input eq 'c') {
      last;
    } elsif ($input eq 'e') {
      exit 1;
    }
  }
}
