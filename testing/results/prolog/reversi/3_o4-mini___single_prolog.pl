:- use_module(library(lists)).
:- use_module(library(apply)).

% Representation: Board is a list of 8 rows, each a list of 8 atoms: empty | black | white.

% Helper to set Nth element in a list.
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% Helper to set a cell in a 2D board.
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% Directions for flips.
directions([(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]).

% Next player.
next_player(black, white).
next_player(white, black).

% Check if coordinates are within the board.
within(R, C) :- R >= 1, R =< 8, C >= 1, C =< 8.

% Find flips in one direction.
flips_in_dir(Board, Player, Row, Col, Dr, Dc, Flips) :-
    next_player(Player, Opponent),
    R1 is Row + Dr, C1 is Col + Dc,
    within(R1, C1),
    nth1(R1, Board, RowList1), nth1(C1, RowList1, Opponent),
    collect_flips(Board, Player, R1, C1, Dr, Dc, [(R1,C1)], Flips).

collect_flips(Board, Player, Row, Col, Dr, Dc, Acc, Flips) :-
    Nr is Row + Dr, Nc is Col + Dc,
    within(Nr, Nc),
    nth1(Nr, Board, RowListN), nth1(Nc, RowListN, Cell),
    ( Cell = Player ->
        Flips = Acc
    ; Cell \= empty ->
        append(Acc, [(Nr,Nc)], Acc1),
        collect_flips(Board, Player, Nr, Nc, Dr, Dc, Acc1, Flips)
    ).

% Determine a legal place move.
legal_place(state(Board, Player), move(place, Row, Col)) :-
    between(1, 8, Row), between(1, 8, Col),
    nth1(Row, Board, RowList), nth1(Col, RowList, empty),
    directions(Ds), member((Dr, Dc), Ds),
    flips_in_dir(Board, Player, Row, Col, Dr, Dc, _).

% legal_move: place or pass.
legal_move(State, Move) :- legal_place(State, Move).
legal_move(state(Board, Player), move(pass)) :-
    \+ legal_place(state(Board, Player), _).

% Apply a place move: place and flip, then switch player.
apply_move(state(Board, Player), move(place, Row, Col), state(FinalBoard, Opp)) :-
    legal_place(state(Board, Player), move(place, Row, Col)),
    set_cell(Row, Col, Board, Player, Board1),
    directions(Ds),
    findall((R2,C2),
            ( member((Dr,Dc), Ds),
              flips_in_dir(Board, Player, Row, Col, Dr, Dc, FL),
              member((R2,C2), FL)
            ),
            ToFlip),
    flip_positions(ToFlip, Player, Board1, FinalBoard),
    next_player(Player, Opp).

flip_positions([], _, Board, Board).
flip_positions([(R,C)|T], Player, Board, Final) :-
    set_cell(R, C, Board, Player, Board1),
    flip_positions(T, Player, Board1, Final).

% Apply a pass move: just switch player.
apply_move(state(Board, Player), move(pass), state(Board, Opp)) :-
    \+ legal_place(state(Board, Player), _),
    next_player(Player, Opp).

% Count pieces of a given color.
count_pieces(Board, Color, Count) :-
    flatten(Board, Flat),
    include(==(Color), Flat, L),
    length(L, Count).

% Game over when board full or neither has a legal place move.
game_over(state(Board, Player), Winner) :-
    ( \+ ( member(Row, Board), member(empty, Row) )
    ; ( \+ legal_place(state(Board, Player), _),
        next_player(Player, Opp),
        \+ legal_place(state(Board, Opp), _)
      )
    ),
    count_pieces(Board, black, BCount),
    count_pieces(Board, white, WCount),
    ( BCount > WCount -> Winner = black
    ; WCount > BCount -> Winner = white
    ; Winner = draw
    ).

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

current_player(state(_, P), P).

% Render the board: '.' for empty, 'B' for black, 'W' for white.
render_state(state(Board, _)) :-
    render_rows(Board).

render_rows([]).
render_rows([R|Rs]) :-
    render_row(R),
    format("~n"),
    render_rows(Rs).

render_row([]).
render_row([C|Cs]) :-
    ( C = empty -> format(". ")
    ; C = black -> format("B ")
    ; format("W ")
    ),
    render_row(Cs).