:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :-
    N > 1,
    N1 is N - 1,
    set_nth1(N1, T, V, R).

% Helper to set a specific cell in a 2D board
set_cell(Row, Col, Board, Value, NewBoard) :-
    nth1(Row, Board, OldRow),
    set_nth1(Col, OldRow, Value, NewRow),
    set_nth1(Row, Board, NewRow, NewBoard).

% initial_state(State) - starting board and player
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
current_player(state(_, P), P).

% valid_index(N) - 1 through 8
valid_index(N) :- member(N, [1,2,3,4,5,6,7,8]).

% get_cell(Row,Col,Board,Cell)
get_cell(Row,Col,Board,Cell) :-
    nth1(Row, Board, R),
    nth1(Col, R, Cell).

% opponent(Player,Opponent)
opponent(light, dark).
opponent(dark, light).

% player_pieces(Player,Man,King)
player_pieces(light, light_man, light_king).
player_pieces(dark, dark_man, dark_king).

% piece_belongs(Player,Piece)
piece_belongs(Player, Piece) :-
    player_pieces(Player, Man, King),
    (Piece = Man; Piece = King).

% man_dir(Player,Dir)
man_dir(light, -1).
man_dir(dark, 1).

% legal simple (non-capturing) moves for man
legal_simple(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol)) :-
    valid_index(FromRow),
    valid_index(FromCol),
    get_cell(FromRow, FromCol, Board, Piece),
    player_pieces(Player, Man, _),
    Piece = Man,
    man_dir(Player, Dir),
    ToRow is FromRow + Dir,
    ToRow >= 1, ToRow =< 8,
    member(DCol, [-1, 1]),
    ToCol is FromCol + DCol,
    ToCol >= 1, ToCol =< 8,
    get_cell(ToRow, ToCol, Board, empty).

% legal simple (non-capturing) moves for king
legal_simple(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol)) :-
    valid_index(FromRow),
    valid_index(FromCol),
    get_cell(FromRow, FromCol, Board, Piece),
    player_pieces(Player, _, King),
    Piece = King,
    member(DRow, [-1, 1]),
    member(DCol, [-1, 1]),
    ToRow is FromRow + DRow,
    ToRow >= 1, ToRow =< 8,
    ToCol is FromCol + DCol,
    ToCol >= 1, ToCol =< 8,
    get_cell(ToRow, ToCol, Board, empty).

% legal jump (capturing) moves for man or king
legal_jump(state(Board, Player), move(FromRow, FromCol, ToRow, ToCol)) :-
    valid_index(FromRow),
    valid_index(FromCol),
    get_cell(FromRow, FromCol, Board, Piece),
    piece_belongs(Player, Piece),
    member(DRow, [-2, 2]),
    member(DCol, [-2, 2]),
    ToRow is FromRow + DRow,
    ToRow >= 1, ToRow =< 8,
    ToCol is FromCol + DCol,
    ToCol >= 1, ToCol =< 8,
    get_cell(ToRow, ToCol, Board, empty),
    MidRow is (FromRow + ToRow) // 2,
    MidCol is (FromCol + ToCol) // 2,
    get_cell(MidRow, MidCol, Board, MidPiece),
    opponent(Player, Opp),
    piece_belongs(Opp, MidPiece).

% has_jump(State) if any capturing move exists
has_jump(State) :-
    legal_jump(State, _).

% legal_move(State, Move) - generate all legal moves, enforcing mandatory captures
legal_move(State, Move) :-
    has_jump(State),
    legal_jump(State, Move).
legal_move(State, Move) :-
    \+ has_jump(State),
    legal_simple(State, Move).

% apply_move(State, Move, NewState) - perform move if legal, update board, handle captures, promotion, and turn order
apply_move(state(Board, Player), move(FR, FC, TR, TC), state(NewBoard, NewPlayer)) :-
    legal_move(state(Board, Player), move(FR, FC, TR, TC)),
    get_cell(FR, FC, Board, Piece),
    maybe_promote(Piece, Player, TR, PromotedPiece),
    set_cell(FR, FC, Board, empty, Board1),
    DRdiff is TR - FR,
    AD is abs(DRdiff),
    ( AD =:= 2 ->
        MR is (FR + TR) // 2,
        MC is (FC + TC) // 2,
        set_cell(MR, MC, Board1, empty, Board2)
    ;
        Board2 = Board1
    ),
    set_cell(TR, TC, Board2, PromotedPiece, Board3),
    ( AD =:= 2 ->
        ( has_jump_from(state(Board3, Player), TR, TC) ->
            NewPlayer = Player
        ;
            opponent(Player, NewPlayer)
        )
    ;
        opponent(Player, NewPlayer)
    ),
    NewBoard = Board3.

% maybe_promote(Piece, Player, ToRow, PromotedPiece)
maybe_promote(dark_man, _, ToRow, dark_king) :-
    ToRow =:= 8.
maybe_promote(light_man, _, ToRow, light_king) :-
    ToRow =:= 1.
maybe_promote(Piece, _, _, Piece).

% has_jump_from(State, Row, Col)
has_jump_from(state(Board, Player), Row, Col) :-
    legal_jump(state(Board, Player), move(Row, Col, _, _)).

% no_pieces(Player, Board) - true if Player has no pieces on Board
no_pieces(Player, Board) :-
    flatten(Board, Flat),
    \+ (member(Cell, Flat), piece_belongs(Player, Cell)).

% game_over(State, Player) - Player wins if opponent has no pieces or no legal moves
game_over(state(Board, _), Player) :-
    opponent(Player, Opp),
    no_pieces(Opp, Board).
game_over(state(Board, _), Player) :-
    opponent(Player, Opp),
    \+ legal_move(state(Board, Opp), _).

% draw condition: neither player has any capturing moves
game_over(state(Board, _), draw) :-
    \+ has_jump(state(Board, light)),
    \+ has_jump(state(Board, dark)).

% render_state(State) - print human-readable board and current player
render_state(state(Board, Player)) :-
    render_rows(Board, 1),
    format('    1 2 3 4 5 6 7 8~n'),
    player_abbrev(Player, Abbrev),
    format('Current player: ~w~n', [Abbrev]).

% render_rows(Rows, RowNum)
render_rows([], _).
render_rows([R|Rs], N) :-
    render_row(R, N),
    N1 is N + 1,
    render_rows(Rs, N1).

% render_row(Row, RowNum)
render_row(Row, N) :-
    format('~d | ', [N]),
    render_cells(Row),
    nl.

% render_cells(Cells)
render_cells([C]) :-
    render_cell(C).
render_cells([C|Cs]) :-
    render_cell(C),
    format(' '),
    render_cells(Cs).

% render_cell(Cell)
render_cell(empty) :-
    format('.').
render_cell(light_man) :-
    format('w').
render_cell(light_king) :-
    format('W').
render_cell(dark_man) :-
    format('b').
render_cell(dark_king) :-
    format('B').

% player_abbrev(Player, Abbrev)
player_abbrev(light, w).
player_abbrev(dark, b).

