# pgn-transform.pl

## Description:
This script will convert chess games copied from lichess.com to a text files to a file in PGN format compatible with SCID and other chess viewer apps.

## Author:
   M.R. Smith - 13-Mar-2021

## Usage:
   perl pgn-transform.pl [<inpfile>]

## Design:
Parse a text file (defauts to games.txt) containing games in lichess format and write an output PGN file (defaults to the same names as the input file
with .pgn extension).  For each game there is a header showing the date, if I played white or black and the result and a comment.

The game file contains a game represented by just 2 lines as follows:
```
   <game-details>
   <game-moves>
```
The above lines are defined as follows:
```
   <game-details> ::= <date><my-colour><result>[<comment>]
           <date> ::= <game-date>
      <game-date> ::= YY.MM.DD
      <my-colour> ::= W | B
         <result> ::= <win-for-white> | <win-for-black> | <draw> | <open>
  <win-for-white> ::= 1-0
  <win-for-black> ::= 0-1
           <draw> ::= .5-.5
           <open> ::= *
```
and
```
     <game-moves> ::= <move>[<move>]
           <move> ::= <move-num><white-move>[<black-move>]
       <move-num> ::= [1..n]
     <white-move> ::= <ply>
     <black-move> ::= <ply>
            <ply> ::= [<piece>][<file>][<rank>]<location>[<promotion>][<check>][<double-check>][<checkmate>] | <special-move>
          <piece> ::= K | Q | B | N | R
           <file> ::= a | b | c | d | e | f | g | h
           <rank> ::= 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8

       <location> ::= <file><rank>
      <promotion> ::= <equals><promoted-piece>
         <equals> ::= =
 <promoted-piece> ::= Q | B | N | R
          <check> ::= +              ! Check
   <double-check> ::= ++             ! Double-Check
      <checkmate> ::= #              ! Mate
   <special-move> ::= O-O | O-O-O    ! Castle Kingside or Queenside
```
So a game and its moves can be quite complex!  Here are some examples:

*21.03.15W1-0*  <-- Game details\
*1e4c52Nc3d63Nf3g64d4cxd45Nxd4Bg76Bb5+Bd77Bg5Bxb58Ndxb5Qa59O-Oa610Nd4Qxg511f4Qc5*  <-- Game moves\

*21.03.19W1-0*  <-- Game details\
*1d4e52dxe5d53exd6Qxd64Qxd6Bxd65Nc3Bb46Bf4Nf67Nf3O-O8Bxc7Bg49h3Bxf310gxf3Nc611Rg1Bxc3+12bxc3Rad8*  <-- Game moves\

The core of the problem/program is to define a regular expression (regex) that will match any of the possible legal moves.  After much anaysis and experimentation, I came up with this...

```
my $regex = "^O-O-O|^O-O|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][\\+#]*|^[KQBNRabcdefgh][x][abcdefgh][12345678][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][=][QBNR][\\+#]*|^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][\\+#]*";
```

Note some patterns are subsets of others, Kingside is a subset of Queenside castling for example.  We must therefore put the longer expression first so we're testing for the more complex case first.

The regex breaks down into the following matches:
1. Queenside castling: ^O-O-O
2. Kingside castling: ^O-O
3. Piece captures WITH a rank or file to resolve ambiquity, WITH promotion and optional check, double-check or mate:
```
   ^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]*
```
4. Piece captures WITHOUT a rank or file to resolve ambiquity, WITH promotion and optional check, double-check or mate:
   *^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]\**
5. Piece captures WITH a rank or file to resolve ambiquity, WITHOUT promotion and optional check, double-check or mate:
   *^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]\**
6. Piece captures WITHOUT a rank or file to resolve ambiquity, WITHOUT promotion and optional check, double-check or mate:
   *^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]\**
7. Move (non-capture) WITH promotion and optional check, double-check or mate:
   *^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][=][QBNR][\\+#]\**
8. Move (non-capture) WITHOUT promotion and optional check, double-check or mate:
   *^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][\\+#]\**


## Modification History:
| Version | Date      | Developer   | Modification Details                            |
|---------|-----------|-------------|-------------------------------------------------|
|  1.0    | 13-Mar-21 | M.R. Smith  | Initial Verion, no statistics.                  |
|  1.1    | 23-Apr-21 | M.R. Smith  | Fixed regex to recognise take with promotion and optional check, double-check or mate. |
|  1.2    | 25-Apr-21 | M.R. Smith  | Add statistics to count wins and draws.|
|  1.3    | 28-Apr-21 | M.R. Smith  | Condense stats to a single hash.|

