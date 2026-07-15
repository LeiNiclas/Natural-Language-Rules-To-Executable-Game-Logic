:- use_module(library(lists)).
:- use_module(library(apply)).

%% Helpers for 2D board manipulation
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1, N1 is N-1,
    set_nth1(N1, T, V, R).

set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

%% Opponent relation
opponent(black, white).
opponent(white, black).

%% Check board bounds
within_board(R, C) :-
    R >= 1, R =< 8,
    C >= 1, C =< 8.

%% All eight directions
directions(-1, -1). directions(-1, 0). directions(-1, 1).
directions(0, -1).                 directions(0, 1).
directions(1, -1).  directions(1, 0). directions(1, 1).

%% Find flips in one direction if move at (R,C)
legal_directions(Board, Player, R, C, DR, DC, Flips) :-
    opponent(Player, Opp),
    NextR is R+DR, NextC is C+DC,
    within_board(NextR, NextC),
    nth1(NextR, Board, Row1), nth1(NextC, Row1, Opp),
    collect_direction(Board, Player, Opp, NextR, NextC, DR, DC, [(NextR, NextC)], RevFlips),
    reverse(RevFlips, Flips).

%% Accumulate opponent cells until a player's cell is found
collect_direction(Board, Player, Opp, R, C, DR, DC, Acc, Flips) :-
    NextR is R+DR, NextC is C+DC,
    within_board(NextR, NextC),
    nth1(NextR, Board, RowN), nth1(NextC, RowN, Val),
    ( Val = Opp ->
        collect_direction(Board, Player, Opp, NextR, NextC, DR, DC, [(NextR, NextC)|Acc], Flips)
    ; Val = Player ->
        Flips = Acc
    ; fail
    ).

%% Gather all flips for placing at (R,C)
legal_place_flips(Board, Player, R, C, AllFlips) :-
    findall(Flips,
        ( directions(DR, DC),
          legal_directions(Board, Player, R, C, DR, DC, Flips)
        ),
        FlipsList),
    FlipsList \= [],
    append(FlipsList, AllFlips).

%% Check existence of any placing move
has_place_move(Board, Player) :-
    between(1,8,R), between(1,8,C),
    nth1(R, Board, Row), nth1(C, Row, empty),
    legal_place_flips(Board, Player, R, C, _), !.

%% Initial state: 8×8 board with four center discs
initial_state(state(Board, black)) :-
    Board = [
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,white,black,empty,empty,empty],
      [empty,empty,empty,black,white,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty],
      [empty,empty,empty,empty,empty,empty,empty,empty]
    ].

%% Current player to move
current_player(state(_, Player), Player).

%% Legal moves: place or pass
legal_move(state(Board, Player), place(R, C)) :-
    between(1,8,R), between(1,8,C),
    nth1(R, Board, Row), nth1(C, Row, empty),
    legal_place_flips(Board, Player, R, C, _).

legal_move(state(Board, Player), pass) :-
    \+ ( between(1,8,R), between(1,8,C),
         nth1(R, Board, Row), nth1(C, Row, empty),
         legal_place_flips(Board, Player, R, C, _) ).

%% Apply a move to produce a new state
apply_move(state(Board, Player), place(R, C), state(NewBoard, NextPlayer)) :-
    nth1(R, Board, Row0), nth1(C, Row0, empty),
    legal_place_flips(Board, Player, R, C, Flips),
    set_cell(R, C, Board, Player, Board1),
    apply_flips(Board1, Flips, Player, NewBoard),
    opponent(Player, NextPlayer).

apply_move(state(Board, Player), pass, state(Board, NextPlayer)) :-
    \+ has_place_move(Board, Player),
    opponent(Player, NextPlayer).

%% Flip all opponent discs in Flips to Player
apply_flips(Board, [], _, Board).
apply_flips(Board, [(R,C)|T], Player, NewBoard) :-
    set_cell(R, C, Board, Player, Board1),
    apply_flips(Board1, T, Player, NewBoard).

%% Count how many discs of Player
count_discs(Board, Player, Count) :-
    foldl(count_row(Player), Board, 0, Count).

count_row(Player, Row, Acc, Count) :-
    include(==(Player), Row, L),
    length(L, N),
    Count is Acc + N.

%% Game over when board full or neither player can move
game_over(state(Board,_), Winner) :-
    (   \+ (member(Row, Board), member(empty, Row))
    ;   \+ has_place_move(Board, black), \+ has_place_move(Board, white)
    ),
    count_discs(Board, black, BC),
    count_discs(Board, white, WC),
    ( BC > WC -> Winner = black
    ; WC > BC -> Winner = white
    ; BC =:= WC -> Winner = draw
    ).

%% Render the board: . for empty, B for black, W for white
render_state(state(Board,_)) :-
    maplist(render_row, Board).

render_row(Row) :-
    maplist(render_cell, Row),
    nl.

render_cell(Cell) :-
    ( Cell = empty -> C = '.'
    ; Cell = black -> C = 'B'
    ; Cell = white -> C = 'W'
    ),
    format("~w ", [C]).