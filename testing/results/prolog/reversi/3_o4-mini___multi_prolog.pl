:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N - 1, set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, V, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, V, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

initial_state(state([
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,white,black,empty,empty,empty],
  [empty,empty,empty,black,white,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty],
  [empty,empty,empty,empty,empty,empty,empty,empty]
], black)).

current_player(state(_, P), P).

opponent(black, white).
opponent(white, black).

directions([[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]).

in_bounds(R, C) :-
    R >= 1, R =< 8, C >= 1, C =< 8.

board_cell(Board, Row, Col, Cell) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Cell).

captures(Board, Player, Row, Col, Dr, Dc) :-
    NextR is Row + Dr,
    NextC is Col + Dc,
    in_bounds(NextR, NextC),
    opponent(Player, Opp),
    board_cell(Board, NextR, NextC, Opp),
    follow_line(Board, Player, NextR, NextC, Dr, Dc).

follow_line(Board, Player, R, C, Dr, Dc) :-
    NextR is R + Dr,
    NextC is C + Dc,
    in_bounds(NextR, NextC),
    board_cell(Board, NextR, NextC, Cell),
    ( Cell == Player
    ; ( opponent(Player, Opp), Cell == Opp, follow_line(Board, Player, NextR, NextC, Dr, Dc) )
    ).

legal_place(state(Board, Player), Row, Col) :-
    board_cell(Board, Row, Col, empty),
    opponent(Player, _),
    directions(Dirs),
    member([Dr, Dc], Dirs),
    captures(Board, Player, Row, Col, Dr, Dc),
    !.

legal_move(State, place(Player, Row, Col)) :-
    current_player(State, Player),
    legal_place(State, Row, Col).

legal_move(State, pass(Player)) :-
    current_player(State, Player),
    \+ legal_place(State, _, _).

collect_opponents(Board, Player, R, C, Dr, Dc, []) :-
    board_cell(Board, R, C, Player).
collect_opponents(Board, Player, R, C, Dr, Dc, [[R,C]|Rest]) :-
    opponent(Player, Opp),
    board_cell(Board, R, C, Opp),
    NextR is R + Dr,
    NextC is C + Dc,
    collect_opponents(Board, Player, NextR, NextC, Dr, Dc, Rest).

flip_positions(Board, Player, Row, Col, Dr, Dc, Positions) :-
    NextR is Row + Dr,
    NextC is Col + Dc,
    collect_opponents(Board, Player, NextR, NextC, Dr, Dc, Positions).

flip_list([], _, Board, Board).
flip_list([[R,C]|Rest], Player, BoardIn, BoardOut) :-
    set_cell(R, C, BoardIn, Player, BoardNext),
    flip_list(Rest, Player, BoardNext, BoardOut).

apply_capture_dirs(Board, _, _, _, [], Board).
apply_capture_dirs(BoardIn, Player, Row, Col, [[Dr,Dc]|Rest], BoardOut) :-
    flip_positions(BoardIn, Player, Row, Col, Dr, Dc, Positions),
    flip_list(Positions, Player, BoardIn, BoardNext),
    apply_capture_dirs(BoardNext, Player, Row, Col, Rest, BoardOut).

apply_move(state(Board, Player), place(Player, Row, Col), state(BoardFinal, NextPlayer)) :-
    legal_move(state(Board, Player), place(Player, Row, Col)),
    set_cell(Row, Col, Board, Player, Board1),
    directions(Dirs),
    findall([Dr,Dc],
        ( member([Dr,Dc], Dirs),
          captures(Board, Player, Row, Col, Dr, Dc)
        ),
        CapDirs),
    apply_capture_dirs(Board1, Player, Row, Col, CapDirs, BoardFinal),
    opponent(Player, NextPlayer).

apply_move(state(Board, Player), pass(Player), state(Board, NextPlayer)) :-
    legal_move(state(Board, Player), pass(Player)),
    opponent(Player, NextPlayer).

game_over(state(Board,_), Winner) :-
    flatten(Board, Cells),
    ( \+ member(empty, Cells)
    ; \+ ( legal_place(state(Board, black), _, _) ; legal_place(state(Board, white), _, _) )
    ),
    include(==(black), Cells, Blacks),
    length(Blacks, NBlack),
    include(==(white), Cells, Whites),
    length(Whites, NWhite),
    ( NBlack > NWhite -> Winner = black
    ; NWhite > NBlack -> Winner = white
    ; Winner = draw ).

% render_state prints the board with row and column labels and the current player
render_state(state(Board, Player)) :-
    print_col_labels,
    print_rows(Board, 1),
    format('Current player: ~w~n', [Player]).

% print column labels 1 to 8
print_col_labels :-
    write('    '),
    print_col_nums(1).

print_col_nums(9) :- nl.
print_col_nums(N) :-
    N =< 8,
    format('~w ', [N]),
    N1 is N + 1,
    print_col_nums(N1).

% print each row with its index
print_rows([], _) :- !.
print_rows([Row|Rest], N) :-
    format('~w | ', [N]),
    maplist(cell_symbol, Row, Syms),
    print_cells(Syms),
    N1 is N + 1,
    print_rows(Rest, N1).

% print the symbols of a row
print_cells([]) :- nl.
print_cells([C|Rest]) :-
    format('~w ', [C]),
    print_cells(Rest).

% map board cell to display symbol
cell_symbol(empty, '.').
cell_symbol(black, 'b').
cell_symbol(white, 'w').
