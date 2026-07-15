:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList): replace element at position Index in List with Value, yielding NewList
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% set_cell(Board, Row, Col, Player, NewBoard): replace cell at (Row,Col) in 2D Board with Player
set_cell(Board, Row, Col, Player, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Player, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% initial_state(State): starting Reversi position on 8x8 board, Black to move
initial_state(state(
    [
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,white,black,empty,empty,empty],
      [empty,empty,empty,black,white,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty]
    ],
    black
)).

% current_player(State, Player): Player to move in State
current_player(state(_, Player), Player).

% opponent(Player, Opponent)
opponent(black, white).
opponent(white, black).

% directions(ListOfDirTerms)
directions([dir(-1,-1),dir(-1,0),dir(-1,1),dir(0,-1),dir(0,1),dir(1,-1),dir(1,0),dir(1,1)]).

% in_bounds(Row, Col)
in_bounds(Row, Col) :-
    Row >= 1,
    Row =< 8,
    Col >= 1,
    Col =< 8.

% get_cell(Board, Row, Col, Cell)
get_cell(Board, Row, Col, Cell) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell).

% collect_flips(Board, Player, Row, Col, Dir, Flips)
collect_flips(Board, Player, Row, Col, dir(DR,DC), Flips) :-
    opponent(Player, Opp),
    Row1 is Row + DR,
    Col1 is Col + DC,
    in_bounds(Row1, Col1),
    get_cell(Board, Row1, Col1, Opp),
    collect_line(Board, Player, Opp, Row1, Col1, DR, DC, [(Row1,Col1)], Flips).

% collect_line(Board, Player, Opponent, Row, Col, DR, DC, Acc, Flips)
collect_line(Board, Player, Opponent, Row, Col, DR, DC, Acc, Flips) :-
    Row1 is Row + DR,
    Col1 is Col + DC,
    in_bounds(Row1, Col1),
    get_cell(Board, Row1, Col1, Cell),
    ( Cell = Opponent ->
        collect_line(Board, Player, Opponent, Row1, Col1, DR, DC, [(Row1,Col1)|Acc], Flips)
    ; Cell = Player ->
        reverse(Acc, Flips)
    ).

% all_flips(Board, Player, Row, Col, AllFlips)
all_flips(Board, Player, Row, Col, AllFlips) :-
    directions(Dirs),
    findall(Flips, (member(Dir, Dirs), collect_flips(Board, Player, Row, Col, Dir, Flips)), Lists),
    append(Lists, AllFlips).

% legal_place_move(Board, Player, Row, Col)
legal_place_move(Board, Player, Row, Col) :-
    between(1,8,Row),
    between(1,8,Col),
    get_cell(Board, Row, Col, empty),
    all_flips(Board, Player, Row, Col, Flips),
    Flips \= [].

% has_place_move(Board, Player)
has_place_move(Board, Player) :-
    legal_place_move(Board, Player, _, _).

% legal_move(State, place(Row, Col))
legal_move(state(Board, Player), place(Row, Col)) :-
    legal_place_move(Board, Player, Row, Col).

% legal_move(State, pass)
legal_move(state(Board, Player), pass) :-
    \+ has_place_move(Board, Player).

% apply_move(State, place(Row, Col), NewState)
apply_move(state(Board, Player), place(Row, Col), state(NewBoard, NextPlayer)) :-
    legal_move(state(Board, Player), place(Row, Col)),
    all_flips(Board, Player, Row, Col, Flips),
    set_cell(Board, Row, Col, Player, Board1),
    flip_positions(Board1, Player, Flips, NewBoard),
    opponent(Player, NextPlayer).

% apply_move(State, pass, NewState)
apply_move(state(Board, Player), pass, state(Board, NextPlayer)) :-
    legal_move(state(Board, Player), pass),
    opponent(Player, NextPlayer).

% flip_positions(Board, Player, Positions, NewBoard): flip pieces at Positions to Player
flip_positions(Board, _, [], Board).
flip_positions(Board, Player, [(R,C)|Rest], NewBoard) :-
    set_cell(Board, R, C, Player, TempBoard),
    flip_positions(TempBoard, Player, Rest, NewBoard).

% board_full(Board): true if no empty cells remain
board_full(Board) :-
    \+ (member(Row, Board), member(empty, Row)).

% count_in_row(Player, Row, Count): count Player occurrences in Row
count_in_row(Player, Row, Count) :-
    include(=(Player), Row, L),
    length(L, Count).

% count_pieces(Board, Player, Count): total Player pieces on Board
count_pieces(Board, Player, Count) :-
    maplist(count_in_row(Player), Board, Counts),
    sum_list(Counts, Count).

% game_over(State, Winner): true when game ends; Winner is black, white, or draw
game_over(state(Board, Player), Winner) :-
    (board_full(Board);
     (\+ has_place_move(Board, Player),
      opponent(Player, Opp),
      \+ has_place_move(Board, Opp))),
    count_pieces(Board, black, BCount),
    count_pieces(Board, white, WCount),
    (BCount > WCount ->
        Winner = black
    ; BCount < WCount ->
        Winner = white
    ; Winner = draw).

% render_state(State): print human-readable board and current player
render_state(state(Board, Player)) :-
    format('  '),
    print_cols_header,
    nl,
    print_rows(Board, 1),
    format('Current player: ~w~n', [Player]).

% print_cols_header: prints column numbers 1 to 8
print_cols_header :-
    between(1,8,C),
    format(' ~w', [C]),
    fail.
print_cols_header.

% print_rows(BoardRows, RowNum): prints each row with its number
print_rows([], _).
print_rows([Row|Rest], N) :-
    format('~w', [N]),
    print_row(Row),
    nl,
    N1 is N + 1,
    print_rows(Rest, N1).

% print_row(Row): prints cells in Row
print_row([]).
print_row([C|Cs]) :-
    ( C = empty -> Char = '.'
    ; C = black -> Char = b
    ; C = white -> Char = w ),
    format(' ~w', [Char]),
    print_row(Cs).