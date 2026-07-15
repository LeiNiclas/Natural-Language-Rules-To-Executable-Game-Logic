:- use_module(library(lists)).
:- use_module(library(apply)).

% 2D board helper predicates
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% get_cell(Board,Row,Col,Value)
get_cell(Board, Row, Col, Value) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Value).

% opponent relation
opponent(black, white).
opponent(white, black).

% on_board(Row,Col)
on_board(Row, Col) :-
    between(1, 8, Row),
    between(1, 8, Col).

% eight directions
direction(-1, -1).
direction(-1,  0).
direction(-1,  1).
direction( 0, -1).
direction( 0,  1).
direction( 1, -1).
direction( 1,  0).
direction( 1,  1).

% can flip in a direction if adjacent opponent pieces lead to player piece
can_flip_in_direction(Board, Row, Col, DR, DC, Player) :-
    opponent(Player, Opp),
    Row1 is Row+DR, Col1 is Col+DC,
    on_board(Row1, Col1),
    get_cell(Board, Row1, Col1, Opp),
    next_cell_sequence(Board, Row1, Col1, DR, DC, Player).

next_cell_sequence(Board, Row, Col, DR, DC, Player) :-
    Row1 is Row+DR, Col1 is Col+DC,
    on_board(Row1, Col1),
    get_cell(Board, Row1, Col1, Cell),
    ( Cell = Player ->
        true
    ; Cell \= empty,
      Cell \= Player,
      next_cell_sequence(Board, Row1, Col1, DR, DC, Player)
    ).

% collect positions to flip in one direction
positions_in_direction(Board, Row, Col, DR, DC, Player, Positions) :-
    opponent(Player, Opp),
    Row1 is Row+DR, Col1 is Col+DC,
    on_board(Row1, Col1),
    get_cell(Board, Row1, Col1, Opp),
    collect_positions(Board, Row1, Col1, DR, DC, Player, [(Row1,Col1)], Positions).

collect_positions(Board, Row, Col, DR, DC, Player, Acc, Positions) :-
    Row1 is Row+DR, Col1 is Col+DC,
    on_board(Row1, Col1),
    get_cell(Board, Row1, Col1, Cell),
    ( Cell = Player ->
        Positions = Acc
    ; Cell \= empty, Cell \= Player ->
        collect_positions(Board, Row1, Col1, DR, DC, Player, [(Row1,Col1)|Acc], Positions)
    ).

% all flippable positions for a move
flippable_positions(Board, Row, Col, Player, Positions) :-
    findall(PosList,
        ( direction(DR,DC),
          positions_in_direction(Board, Row, Col, DR, DC, Player, PosList)
        ),
        Lists),
    flatten(Lists, Positions).

% check existence of any place move
has_place_move(Board, Player) :-
    on_board(Row, Col),
    get_cell(Board, Row, Col, empty),
    flippable_positions(Board, Row, Col, Player, Positions),
    Positions \= [].

% count pieces
count_row(Player, Row, Count) :-
    include(==(Player), Row, L),
    length(L, Count).
count_pieces(Board, Player, Count) :-
    maplist(count_row(Player), Board, Counts),
    sum_list(Counts, Count).

% game end conditions
game_end(Board) :-
    \+ ( member(Row, Board), member(empty, Row) )
    ;
    ( \+ has_place_move(Board, black),
      \+ has_place_move(Board, white)
    ).

% initial state setup
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

% current player
current_player(state(_, P), P).

% legal moves: place or pass
legal_move(state(Board, Player), place(Row, Col)) :-
    get_cell(Board, Row, Col, empty),
    flippable_positions(Board, Row, Col, Player, Positions),
    Positions \= [].
legal_move(state(Board, Player), pass) :-
    \+ legal_move(state(Board, Player), place(_, _)).

% apply place move: set cell and flip
apply_move(state(Board, Player), place(Row, Col), state(NewBoard2, NextPlayer)) :-
    legal_move(state(Board, Player), place(Row, Col)),
    flippable_positions(Board, Row, Col, Player, Positions),
    set_cell(Row, Col, Board, Player, Board1),
    foldl(
      [ (R,C), B, NB ]>>set_cell(R,C,B,Player,NB),
      Positions,
      Board1,
      NewBoard2
    ),
    opponent(Player, NextPlayer).
% apply pass move
apply_move(state(Board, Player), pass, state(Board, NextPlayer)) :-
    legal_move(state(Board, Player), pass),
    opponent(Player, NextPlayer).

% game over and winner or draw
game_over(state(Board,_), Winner) :-
    game_end(Board),
    count_pieces(Board, black, B),
    count_pieces(Board, white, W),
    ( B > W -> Winner = black
    ; W > B -> Winner = white
    ; Winner = draw
    ).

% render the board
render_state(state(Board,_)) :-
    maplist(render_row, Board).
render_row(Row) :-
    maplist(render_cell, Row),
    nl.
render_cell(Cell) :-
    ( Cell = empty -> format('. ')
    ; Cell = black -> format('B ')
    ; Cell = white -> format('W ')
    ).