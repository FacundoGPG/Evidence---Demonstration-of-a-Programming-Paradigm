:- use_module(library(clpfd)).

% sudoku/1
% Entry predicate. Receives the board as a list of 9 rows,
% each row being a list of 9 variables or fixed digits.
% Variables (_) represent empty cells.

sudoku(Rows) :-
    length(Rows, 9),
    maplist(length_(9), Rows),
    append(Rows, Cells),
    Cells ins 1..9,
    maplist(all_distinct, Rows),
    transpose(Rows, Cols),
    maplist(all_distinct, Cols),
    boxes(Rows),
    maplist(label, Rows).

% length_/2
% Helper to enforce each row has exactly 9 elements.
length_(L, Lst) :- length(Lst, L).

% boxes/1
% Extracts all nine 3x3 subgrids and applies all_distinct to each.
boxes([A,B,C,D,E,F,G,H,I]) :-
    box(A, B, C),
    box(D, E, F),
    box(G, H, I).

% box/3
% Takes three rows and checks all three 3x3 blocks across them.
box([], [], []).
box([A,B,C|R1], [D,E,F|R2], [G,H,I|R3]) :-
    all_distinct([A,B,C,D,E,F,G,H,I]),
    box(R1, R2, R3).

% pretty_print/1
% Prints the solved board as a readable 9x9 grid with box separators.
pretty_print(Rows) :-
    write('+-------+-------+-------+'), nl,
    print_rows(Rows, 1).

% print_rows/2
% Iterates over each row, printing it and adding horizontal separators
% after rows 3, 6, and 9.
print_rows([], _).
print_rows([Row|Rest], N) :-
    write('| '),
    print_cells(Row, 1),
    nl,
    (   (N =:= 3 ; N =:= 6 ; N =:= 9)
    ->  write('+-------+-------+-------+'), nl
    ;   true
    ),
    N1 is N + 1,
    print_rows(Rest, N1).

% print_cells/2
% Prints each cell in a row, adding vertical separators after columns 3 and 6.
print_cells([], _).
print_cells([C|Rest], N) :-
    write(C), write(' '),
    (   (N =:= 3 ; N =:= 6)
    ->  write('| ')
    ;   true
    ),
    N1 is N + 1,
    print_cells(Rest, N1).
