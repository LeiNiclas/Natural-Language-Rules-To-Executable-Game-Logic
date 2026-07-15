:- use_module(library(lists)).
:- use_module(library(apply)).

% set_nth1(Index, List, Value, NewList)
set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N-1,
    set_nth1(N1, T, V, R).

% set_cell(Row, Col, Board, Value, NewBoard)
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% initial_state(State)
initial_state(state(
  [
    [empty,dark_man,empty,dark_man,empty,dark_man,empty,dark_man],
    [dark_man,empty,dark_man,empty,dark_man,empty,dark_man,empty],
    [empty,dark_man,empty,dark_man,empty,dark_man,empty,dark_man],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [empty,empty,empty,empty,empty,empty,empty,empty],
    [light_man,empty,light_man,empty,light_man,empty,light_man,empty],
    [empty,light_man,empty,light_man,empty,light_man,empty,light_man],
    [light_man,empty,light_man,empty,light_man,empty,light_man,empty]
  ],
  dark
)).

% current_player(State, Player)
current_player(state(_, Player), Player).

% piece_at(Board, Row, Col, Piece)
piece_at(Board, Row, Col, Piece) :-
    nth1(Row, Board, RowList),
    nth1(Col, RowList, Piece).

% belongs_to(Piece, Player)
belongs_to(light_man, light).
belongs_to(light_king, light).
belongs_to(dark_man, dark).
belongs_to(dark_king, dark).

% opponent(Player, Opponent)
opponent(light, dark).
opponent(dark, light).

% is_man(Piece)
is_man(light_man).
is_man(dark_man).

% is_king(Piece)
is_king(light_king).
is_king(dark_king).

% forward_delta(Player, Delta)
forward_delta(dark, 1).
forward_delta(light, -1).

% simple_step(FromR,FromC,ToR,ToC,Player,Board)
simple_step(FromR, FromC, ToR, ToC, Player, Board) :-
    piece_at(Board, FromR, FromC, Piece),
    abs(ToR-FromR) =:= 1,
    abs(ToC-FromC) =:= 1,
    (   is_king(Piece)
    ;   is_man(Piece),
        forward_delta(Player, D),
        ToR-FromR =:= D
    ).

% jump_move(FromR,FromC,ToR,ToC,Player,Board)
jump_move(FromR, FromC, ToR, ToC, Player, Board) :-
    piece_at(Board, FromR, FromC, Piece),
    abs(ToR-FromR) =:= 2,
    abs(ToC-FromC) =:= 2,
    RowMid is (FromR + ToR) // 2,
    ColMid is (FromC + ToC) // 2,
    piece_at(Board, RowMid, ColMid, MidPiece),
    opponent(Player, Opp),
    belongs_to(MidPiece, Opp).

% any_capture_exists(Board, Player)
any_capture_exists(Board, Player) :-
    between(1,8,FromR),
    between(1,8,FromC),
    piece_at(Board, FromR, FromC, Piece),
    belongs_to(Piece, Player),
    between(1,8,ToR),
    between(1,8,ToC),
    piece_at(Board, ToR, ToC, empty),
    jump_move(FromR, FromC, ToR, ToC, Player, Board),
    !.

% legal_move(State, Move) generates all legal moves for the current player
legal_move(state(Board, Player), move(FromR, FromC, ToR, ToC)) :-
    any_capture_exists(Board, Player),
    between(1,8,FromR),
    between(1,8,FromC),
    piece_at(Board, FromR, FromC, Piece),
    belongs_to(Piece, Player),
    between(1,8,ToR),
    between(1,8,ToC),
    piece_at(Board, ToR, ToC, empty),
    jump_move(FromR, FromC, ToR, ToC, Player, Board).

legal_move(state(Board, Player), move(FromR, FromC, ToR, ToC)) :-
    \+ any_capture_exists(Board, Player),
    between(1,8,FromR),
    between(1,8,FromC),
    piece_at(Board, FromR, FromC, Piece),
    belongs_to(Piece, Player),
    between(1,8,ToR),
    between(1,8,ToC),
    piece_at(Board, ToR, ToC, empty),
    (   simple_step(FromR, FromC, ToR, ToC, Player, Board)
    ;   jump_move(FromR, FromC, ToR, ToC, Player, Board)
    ).

% apply_move(State, Move, NewState)
apply_move(state(Board, Player), move(FromR, FromC, ToR, ToC), state(FinalBoard, NextPlayer)) :-
    legal_move(state(Board, Player), move(FromR, FromC, ToR, ToC)),
    piece_at(Board, FromR, FromC, Piece),
    set_cell(FromR, FromC, Board, empty, Board1),
    (   abs(ToR-FromR) =:= 2
    ->  RowMid is (FromR + ToR) // 2,
        ColMid is (FromC + ToC) // 2,
        set_cell(RowMid, ColMid, Board1, empty, Board2),
        Jumped = true
    ;   Board2 = Board1,
        Jumped = false
    ),
    (   is_man(Piece),
        ( Player = dark, ToR =:= 8
        ; Player = light, ToR =:= 1 )
    ->  ( Player = dark -> NewPiece = dark_king ; NewPiece = light_king )
    ;   NewPiece = Piece
    ),
    set_cell(ToR, ToC, Board2, NewPiece, Board3),
    (   Jumped = true,
        piece_at(Board3, ToR, ToC, NewPiece),
        between(1,8,NextR),
        between(1,8,NextC),
        piece_at(Board3, NextR, NextC, empty),
        jump_move(ToR, ToC, NextR, NextC, Player, Board3)
    ->  FinalBoard = Board3,
        NextPlayer = Player
    ;   FinalBoard = Board3,
        opponent(Player, NextPlayer)
    ).

% count_pieces(Board, Player, Count)
count_pieces(Board, Player, Count) :-
    findall(Piece, (
        member(Row, Board),
        member(Piece, Row),
        belongs_to(Piece, Player)
    ), Pieces),
    length(Pieces, Count).

% game_over(State, Winner)
% Winner is Player if opponent has no pieces or no legal moves
game_over(state(Board, Player), Player) :-
    opponent(Player, Opp),
    (   count_pieces(Board, Opp, 0)
    ;   \+ legal_move(state(Board, Opp), _)
    ).

% game_over(State, draw) when neither player has any capture moves
game_over(state(Board, _), draw) :-
    \+ any_capture_exists(Board, light),
    \+ any_capture_exists(Board, dark).

% symbol_char maps pieces to display characters
symbol_char(empty, '.').
symbol_char(light_man, 'l').
symbol_char(light_king, 'L').
symbol_char(dark_man, 'd').
symbol_char(dark_king, 'D').

% render_state(State) prints the board and current player
render_state(state(Board, Player)) :-
    render_rows(Board, 1),
    format('    '),
    forall(between(1,8,C), format('~w ', [C])),
    nl,
    format('Current player: ~w~n', [Player]).

render_rows([], _).
render_rows([Row|Rest], N) :-
    format('~w | ', [N]),
    render_row_cells(Row),
    nl,
    N1 is N+1,
    render_rows(Rest, N1).

render_row_cells([]).
render_row_cells([Cell|Cells]) :-
    symbol_char(Cell, C),
    format('~w ', [C]),
    render_row_cells(Cells).
