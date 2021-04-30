# pgn-transform.pl

## Description:
This script will convert chess games copied from lichess.com to a text files to a file in PGN format compatible with SCID and other chess viewer apps.

## Author:
   M.R. Smith - 13-Mar-2021

## Usage:
```
   perl pgn-transform.pl [<inpfile>]
```
## Example:
```
$ perl pgn-transform.pl test.txt
PGN Game Transformer for Lichess game strings V1.3 Starting...
Input Game file: test.txt
Output PGN file: test.pgn
Output CSV file: test.csv
Processing...
I: 21.04.07W1-0pp
[Event "lichess.com"]
[Site "lichess.com"]
[Date "2021.04.07"]
[Round "1"]
[White "Mike"]
[Black "Anon"]
[Result "1-0"]
I: 1d4d52Bf4c63Nf3e64e3h65c3Nf66h3Be77Bd3Nbd78Qc2O-O9Nbd2c510O-O-Oc411Be2Qa512Kb1Qb513Rdg1Nb614g4Na415g5h516gxf6Bxf617Be5Bxe518Nxe5Qa519Bxh5b520Nc6Qc721Nb4a522b3axb423bxa4bxa424cxb4Rb825a3Qe726Qc3Qh427Bd1Qxf228h4Qf5+29Bc2Qh530Rg5Qe231h5f632Rg6Kh733Rhg1Kh834Rxg7Rb735h6Rxg736hxg7+Kg837gxf8=Q+Kxf838Rg6Kf739b5f540Rg1Qf241Rf1Qe242Bxa4Bb743b6Kf644Bd1Qd3+45Qxd3cxd346a4Ke747a5Kd748Ba4+Kc849Rh1Ba650Rh8+Kb751Rh7+Kb852Rc7
1. d4 d5
2. Bf4 c6
3. Nf3 e6
4. e3 h6
5. c3 Nf6
6. h3 Be7
7. Bd3 Nbd7
8. Qc2 O-O
9. Nbd2 c5
10. O-O-O c4
11. Be2 Qa5
12. Kb1 Qb5
13. Rdg1 Nb6
14. g4 Na4
15. g5 h5
16. gxf6 Bxf6
17. Be5 Bxe5
18. Nxe5 Qa5
19. Bxh5 b5
20. Nc6 Qc7
21. Nb4 a5
22. b3 axb4
23. bxa4 bxa4
24. cxb4 Rb8
25. a3 Qe7
26. Qc3 Qh4
27. Bd1 Qxf2
28. h4 Qf5+
29. Bc2 Qh5
30. Rg5 Qe2
31. h5 f6
32. Rg6 Kh7
33. Rhg1 Kh8
34. Rxg7 Rb7
35. h6 Rxg7
36. hxg7+ Kg8
37. gxf8=Q+ Kxf8
38. Rg6 Kf7
39. b5 f5
40. Rg1 Qf2
41. Rf1 Qe2
42. Bxa4 Bb7
43. b6 Kf6
44. Bd1 Qd3+
45. Qxd3 cxd3
46. a4 Ke7
47. a5 Kd7
48. Ba4+ Kc8
49. Rh1 Ba6
50. Rh8+ Kb7
51. Rh7+ Kb8
52. Rc7 
{pp}
1-0

Date        Played  Won  As White  As Black  Draws
==========  ======  ===  ========  ========  =====
2021.04.07     1     1       1         0       0
1 played, 1 won (100.0%), 1 won as white (100.0%), 0 won as black (0.0%), 0 draws (0.0%)
PGN Game Transformer for Lichess game strings V1.3 Complete
```


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
```
   ^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]*
```
5. Piece captures WITH a rank or file to resolve ambiquity, WITHOUT promotion and optional check, double-check or mate:
```
   ^[KQBNR][abcdefgh12345678]?[x][abcdefgh][12345678][=][QBNR][\\+#]*
```
6. Piece captures WITHOUT a rank or file to resolve ambiquity, WITHOUT promotion and optional check, double-check or mate:
```
   ^[KQBNRabcdefgh][x][abcdefgh][12345678][=][QBNR][\\+#]*
```
7. Move (non-capture) WITH promotion and optional check, double-check or mate:
```
   ^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][=][QBNR][\\+#]*
```
8. Move (non-capture) WITHOUT promotion and optional check, double-check or mate:
```
   ^[KQBNR]?([abcdefgh]?|[12345678]?)[abcdefgh][12345678][\\+#]*
```


## Modification History:
| Version | Date      | Developer   | Modification Details                            |
|:-------:|:---------:|:------------|:------------------------------------------------|
|  1.0    | 13-Mar-21 | M.R. Smith  | Initial Verion, no statistics.                  |
|  1.1    | 23-Apr-21 | M.R. Smith  | Fixed regex to recognise take with promotion and optional check, double-check or mate. |
|  1.2    | 25-Apr-21 | M.R. Smith  | Add statistics to count wins and draws.|
|  1.3    | 28-Apr-21 | M.R. Smith  | Condense stats to a single hash.|

