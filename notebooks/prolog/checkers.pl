:- use_module(library(lists)).
:- use_module(library(apply)).

set_nth1(1, [_|T], V, [V|T]).
set_nth1(N, [H|T], V, [H|R]) :- N > 1, N1 is N-1, set_nth1(N1, T, V, R).

% state(Board, Player)
% Board = list of 64 atoms (row-major, 1-indexed)
% Player = player1 | player2

initial_state(state(Board, player1)) :-
    findall(Piece,
            ( between(1,8,Row),
              between(1,8,Col),
              ( (Row+Col) mod 2 =:= 0 ->
                  ( Row =< 3 -> Piece = p1
                  ; Row >= 6 -> Piece = p2
                  ; Piece = empty )
              ; Piece = empty
              )
            ),
            Board).

current_player(state(_, P), P).

% Move term: move(SR,SC,ER,EC)
legal_move(state(Board, Player), Move) :-
    (   exists_jump(state(Board, Player), Player)
    ->  legal_jump(state(Board, Player), Player, Move)
    ;   legal_simple(state(Board, Player), Player, Move)
    ).

% ---------- helpers ----------
piece_at(Board, R, C, Piece) :-
    idx(R, C, Ix),
    nth1(Ix, Board, Piece).

idx(R, C, Ix) :- Ix is (R-1)*8 + C.

other_player(player1, player2).
other_player(player2, player1).

% piece belongs to player?
own_piece(Piece, Player) :-
    (   Player = player1 ->
        ( Piece = p1 ; Piece = p1_king )
    ;   Player = player2 ->
        ( Piece = p2 ; Piece = p2_king )
    ).

opp_piece(Piece, Player) :-
    other_player(Player, Opp),
    own_piece(Piece, Opp).

% direction lists
dirs_normal(player1, [[1,-1],[1,+1]]).
dirs_normal(player2, [[-1,-1],[-1,+1]]).

% get directions for a piece
piece_dirs(Piece, Player, DirList) :-
    (   (Piece = p1_king ; Piece = p2_king) ->
        DirList = [[1,-1],[1,+1],[-1,-1],[-1,+1]]
    ;   dirs_normal(Player, DirList)
    ).

% simple move generation
legal_simple(state(Board, Player), Player, move(SR,SC,ER,EC)) :-
    piece_at(Board, SR, SC, Piece),
    own_piece(Piece, Player),
    piece_dirs(Piece, Player, DirList),
    member([dR,dC], DirList),
    ER is SR + dR,
    EC is SC + dC,
    in_bounds(ER,EC),
    piece_at(Board, ER, EC, empty).

% jump move generation
legal_jump(state(Board, Player), Player, move(SR,SC,ER,EC)) :-
    piece_at(Board, SR, SC, Piece),
    own_piece(Piece, Player),
    piece_dirs(Piece, Player, DirList),
    member([dR,dC], DirList),
    ER is SR + 2*dR,
    EC is SC + 2*dC,
    in_bounds(ER,EC),
    MidR is SR + dR,
    MidC is SC + dC,
    piece_at(Board, MidR, MidC, OppPiece),
    opp_piece(OppPiece, Player),
    piece_at(Board, ER, EC, empty).

% check if any jump exists for player
exists_jump(state(Board, Player), Player) :-
    exists_jump_from(state(Board, Player), Player, _, _).

exists_jump_from(state(Board, Player), Player, SR, SC) :-
    piece_at(Board, SR, SC, Piece),
    own_piece(Piece, Player),
    piece_dirs(Piece, Player, DirList),
    member([dR,dC], DirList),
    ER is SR + 2*dR,
    EC is SC + 2*dC,
    in_bounds(ER,EC),
    MidR is SR + dR,
    MidC is SC + dC,
    piece_at(Board, MidR, MidC, OppPiece),
    opp_piece(OppPiece, Player),
    piece_at(Board, ER, EC, empty).

in_bounds(R,C) :- R >= 1, R =< 8, C >= 1, C =< 8.

% ---------- apply_move ----------
apply_move(state(Board, Player), move(SR,SC,ER,EC), state(NewBoard, NextPlayer)) :-
    piece_at(Board, SR, SC, Piece),
    own_piece(Piece, Player),
    DeltaR is ER - SR,
    DeltaC is EC - SC,
    (   abs(DeltaR) =:= 2, abs(DeltaC) =:= 2 ->
        Jump = true,
        MidR is SR + DeltaR//2,
        MidC is SC + DeltaC//2
    ;   Jump = false,
        MidR = 0, MidC = 0
    ),
    % remove from start
    set_nth1(idx(SR,SC), Board, empty, B1),
    % possibly promote
    (   Piece = p1, ER = 8 ->
        Promoted = p1_king
    ;   Piece = p2, ER = 1 ->
        Promoted = p2_king
    ;   Promoted = Piece
    ),
    % place at destination
    set_nth1(idx(ER,EC), B1, Promoted, B2),
    % remove jumped piece if any
    (   Jump ->
        set_nth1(idx(MidR,MidC), B2, empty, B3)
    ;   B3 = B2
    ),
    % decide next player
    (   Jump ->
        (   exists_jump_from(state(B3, Player), Player, ER, EC) ->
            NextPlayer = Player
        ;   NextPlayer = other_player(Player)
        )
    ;   NextPlayer = other_player(Player)
    ),
    NewBoard = B3.

% ---------- game_over ----------
game_over(state(Board, Player), Winner) :-
    (   \+ player_has_piece(Board, Player)
    ->  Winner = other_player(Player)
    ;   \+ legal_move(state(Board, Player), _)
    ->  Winner = other_player(Player)
    ).

player_has_piece(Board, Player) :-
    member(Piece, Board),
    own_piece(Piece, Player).

% ---------- render_state ----------
render_state(state(Board, Player)) :-
    format("Player: ~w~n", [Player]),
    forall(between(1,8,Row),
           (   format("  "),
                forall(between(1,8,Col),
                       (   idx(Row,Col,Ix),
                           nth1(Ix,Board,Piece),
                           piece_char(Piece, Ch),
                           format("~w ", [Ch])
                       )),
                nl
           )).

piece_char(empty, '.').
piece_char(p1, 'b').
piece_char(p1_king, 'B').
piece_char(p2, 'w').
piece_char(p2_king, 'W').

% ==== QUERY REFERENCE ====
% ?- initial_state(S).
% ?- initial_state(S), current_player(S, P).
% ?- initial_state(S), legal_move(S, M).
% ?- initial_state(S), apply_move(S, move(3,2,4,3), S2), render_state(S2).
% ?- initial_state(S), game_over(S, W).