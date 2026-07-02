:- use_module(library(lists)).
:- use_module(library(apply)).

% Helper to set the Nth element of a list
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% Helper to set a cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% Directions for flip checking
direction(-1, -1).
direction(-1, 0).
direction(-1, 1).
direction(0, -1).
direction(0, 1).
direction(1, -1).
direction(1, 0).
direction(1, 1).

% Opponent relation
opponent(black, white).
opponent(white, black).

% Access a cell value
cell(Board, R, C, Val) :-
    nth1(R, Board, Row),
    nth1(C, Row, Val).

% Collect flippable opponent pieces in one direction
flips_in_dir(Board, Player, R, C, DR, DC, Cells) :-
    opponent(Player, Opp),
    R1 is R + DR,
    C1 is C + DC,
    cell(Board, R1, C1, Opp),
    collect_flips(Board, Player, DR, DC, R1, C1, [(R1,C1)], Cells).

collect_flips(Board, Player, DR, DC, R, C, Acc, Cells) :-
    opponent(Player, Opp),
    R1 is R + DR,
    C1 is C + DC,
    cell(Board, R1, C1, Val),
    ( Val = Opp ->
        collect_flips(Board, Player, DR, DC, R1, C1, [(R1,C1)|Acc], Cells)
    ; Val = Player ->
        reverse(Acc, Cells)
    ; fail ).

% Whether Player has any legal place move
legal_place_move(Board, Player, R, C) :-
    cell(Board, R, C, empty),
    direction(DR, DC),
    flips_in_dir(Board, Player, R, C, DR, DC, _).

% initial state: standard Reversi start
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

% Current player
current_player(state(_, P), P).

% Generative legal moves: place or pass
legal_move(state(Board, Player), place(R, C)) :-
    legal_place_move(Board, Player, R, C).
legal_move(state(Board, Player), pass) :-
    \+ ( legal_place_move(Board, Player, _, _) ).

% Apply a move
apply_move(state(Board, Player), place(R, C), state(NewBoard2, Opp)) :-
    opponent(Player, Opp),
    findall(Cells, (direction(DR,DC), flips_in_dir(Board, Player, R, C, DR, DC, Cells)), All),
    append(All, Flips),
    set_cell(R, C, Board, Player, Board1),
    apply_flips(Board1, Flips, Player, NewBoard2).
apply_move(state(Board, Player), pass, state(Board, Opp)) :-
    opponent(Player, Opp).

% Flip listed cells to Player
apply_flips(Board, [], _, Board).
apply_flips(Board, [(R,C)|Rest], Player, NewBoard) :-
    set_cell(R, C, Board, Player, TempBoard),
    apply_flips(TempBoard, Rest, Player, NewBoard).

% Check if Player has no place moves
no_moves(Board, Player) :-
    \+ legal_place_move(Board, Player, _, _).

% Game over when board full or neither has moves
game_over(state(Board, _), Winner) :-
    ( \+ (cell(Board, _, _, empty))
    ; no_moves(Board, black), no_moves(Board, white)
    ),
    count(Board, black, B),
    count(Board, white, W),
    ( B > W -> Winner = black
    ; W > B -> Winner = white
    ; Winner = draw ).

% Count pieces of Player
count(Board, Player, N) :-
    findall(1, cell(Board, _, _, Player), L),
    length(L, N).

% Render the board to stdout
render_state(state(Board, _)) :-
    maplist(render_row, Board).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_cell(C) :-
    ( C = empty -> format('. ')
    ; C = black -> format('B ')
    ; C = white -> format('W ')
    ).