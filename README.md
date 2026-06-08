# E4 — Logic Programming Paradigm

### Facundo Gael Piñeiro González
### Sudoku Solver in Prolog

---

## Introduction

Sudoku is a logic-based puzzle played on a 9×9 grid. The goal is to fill every cell with a number from 1 to 9 so that each number appears only once in every row, every column, and each of the nine 3×3 subgrids. Although the rules are straightforward, solving Sudoku efficiently can be computationally difficult. In fact, the generalized n×n version of Sudoku is considered NP-complete, meaning there is no known algorithm capable of solving every possible instance in polynomial time (Russell & Norvig, 2021, Chapter 6, p. 202).

Sudoku is also an example of a **Constraint Satisfaction Problem (CSP)**. A CSP consists of a set of variables, a domain of possible values, and a group of constraints that determine which assignments are valid. The objective is to find a solution that satisfies all constraints at the same time (Russell & Norvig, 2021, Chapter 6, p. 202). Problems of this type are common in areas such as scheduling, resource allocation, and compiler optimization.

The **Logic Programming paradigm** is especially well suited for CSPs because it focuses on describing the conditions a solution must satisfy instead of explicitly defining the steps to reach it. In Prolog, the inference engine automatically searches for solutions using resolution and backtracking. When one possible solution fails, Prolog returns to a previous decision point and tries another alternative, allowing it to systematically explore the search space without requiring the programmer to manually control the process (Sterling & Shapiro, 1994, Chapter 2).

For Sudoku, the main constraints are the uniqueness across rows, columns, and 3×3 subgrids which can be represented directly as Prolog rules. The solver is then produced naturally from these constraints. To improve efficiency, this project uses SWI-Prolog's **CLP(FD)** library (Constraint Logic Programming over Finite Domains), which applies constraint propagation techniques to reduce the search space before backtracking occurs (Triska, 2016).

---

## Models

The solution models Sudoku directly as a Constraint Satisfaction Problem. The 9×9 grid is represented as a list of 9 rows, where each cell is a variable that can take a value from 1 to 9. Three sets of constraints are then declared over these variables:

- **Row constraint:** all digits in a row must be distinct.
- **Column constraint:** all digits in a column must be distinct.
- **Box constraint:** all digits in each 3×3 subgrid must be distinct.

The following diagram illustrates how the board is structured as a CSP, mapping each cell to a variable and defining its domain and constraints:

<img width="1075" height="931" alt="sudokuview drawio" src="https://github.com/user-attachments/assets/4f7504b1-0433-4780-a877-00fc42c119e3" />

---

What makes this solution a Logic Programming solution and not simply a search algorithm is that the program never explicitly describes *how* to find a valid assignment. Instead, the three constraints above are declared as Prolog rules, and SWI-Prolog's inference engine handles the search automatically. The solver exists because the constraints exist; there is no separate solving logic.

The search mechanism Prolog uses internally is **backtracking**. Starting from the first empty cell, Prolog attempts to assign a value from the domain. If all constraints are satisfied, it moves to the next cell. If any constraint is violated, it backtracks to the previous decision point and tries the next available value. This continues until a complete valid assignment is found or the entire search space is exhausted.

The following diagram shows this backtracking process over a partial board:

<img width="611" height="1171" alt="FlowChart drawio" src="https://github.com/user-attachments/assets/5f7fd447-5461-430d-b081-0386cd106d09" />

With CLP(FD), constraint propagation runs before backtracking begins. When a value is assigned to a cell, the library automatically eliminates that value from the domains of all related cells in the same row, column, and box. This reduces the number of states explored significantly compared to naive backtracking.

### Formal model: Pushdown Automaton (PDA)

To formally characterize the computational behavior of the solver, it is useful to compare it against the automata models covered in the course: DFA, NFA, ε-NFA, and PDA.

A **DFA or NFA** cannot model this solver because both are finite state machines with no memory beyond their current state. The solver needs to remember every assignment it has made so far in order to undo them during backtracking. A finite automaton has no mechanism for that, so DFA and NFA are ruled out. An **ε-NFA** adds epsilon transitions but still has no stack memory, so it falls short for the same reason.

A **Pushdown Automaton** is the right fit. A PDA extends an NFA with a stack, and that stack is exactly what backtracking needs. Every time the solver assigns a value to a cell, that decision gets pushed onto the stack. When a domain is exhausted and the solver needs to backtrack, it pops the stack to restore the previous cell and resume trying other values from there. Without that push and pop behavior, backtracking is not possible.

It is worth noting that the solver is not a PDA in the strict classical sense, since a classical PDA reads symbols from an input tape one at a time, and this solver does not have an input tape. The board itself serves as both the input and the working memory. So it is more accurate to say the solver behaves like an extended PDA, one where the stack holds full board state snapshots rather than single symbols. The formal model below captures the essential structure.

The PDA has 7 states:

| State | Role |
|---|---|
| q0 | Load board, initialize stack |
| q1 | Select next empty cell |
| q2 | Try next value from domain |
| q3 | Check constraints |
| q4 | Backtrack |
| q5 | Accept (puzzle solved) |
| q6 | Reject (no solution exists) |

The transitions are:

| From | To | Label | Meaning |
|---|---|---|---|
| q0 | q1 | push(B) | initialize stack with bottom marker |
| q1 | q2 | push(A) | empty cell found, save assignment |
| q1 | q5 | ε | no empty cells left, puzzle solved |
| q2 | q3 | ε | value picked from domain |
| q3 | q1 | ε | all constraints pass, move to next cell |
| q3 | q2 | ε | constraint fails, values still remain |
| q2 | q4 | ε | domain exhausted, no values left |
| q4 | q2 | pop(A) | undo last assignment, resume previous cell |
| q4 | q6 | pop(B) | stack is empty, no solution exists |

The following diagram shows the PDA in theory:

<img width="1045" height="576" alt="PDA" src="https://github.com/user-attachments/assets/2bfbf8a9-a0db-490c-a4b4-5a2a90c59589" />


---

## Implementation

The full solution is contained in a single file:
- `sudoku.pl` — contains the solver.

**How to run:**

```bash
# Open the solver
swipl sudoku.pl
```

Then enter a query manually in the Prolog console. Empty cells are represented as `_` (unbound Prolog variables), and fixed cells as their digit:

```prolog
?- Rows = [
     [5,3,_,_,7,_,_,_,_],
     [6,_,_,1,9,5,_,_,_],
     [_,9,8,_,_,_,_,6,_],
     [8,_,_,_,6,_,_,_,3],
     [4,_,_,8,_,3,_,_,1],
     [7,_,_,_,2,_,_,_,6],
     [_,6,_,_,_,_,2,8,_],
     [_,_,_,4,1,9,_,_,5],
     [_,_,_,_,8,_,_,7,9]
   ], sudoku(Rows), pretty_print(Rows).
```

**Code explanation:**

`sudoku/1` is the entry predicate. It takes the board, checks that it is a 9×9 structure, sets the domain of every cell to 1..9, and applies the three constraint sets. One thing worth noting is that labeling is done last on purpose. CLP(FD) works in two phases: first you declare all the constraints, and then `label` actually kicks off the search. Doing it this way lets the library run as much constraint propagation as possible before any backtracking starts, which cuts down the search space a lot.

`append(Rows, Cells)` flattens the 9 rows into a single list of 81 cells, so the domain constraint `Cells ins 1..9` can be applied to everything at once instead of going row by row:

```prolog
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
```

`boxes/1` takes all 9 rows and splits them into three horizontal bands of 3 rows each, rows 1–3, 4–6, and 7–9, then passes each band to `box/3`.

`box/3` works on three rows at a time. It uses Prolog's pattern matching `[A,B,C|Rest]` to pull exactly 3 elements from each row, giving 9 elements total that form one complete 3×3 subgrid. Those 9 elements go into `all_distinct`, and then the predicate recurses on the remaining columns until all three blocks in the band are covered:

```prolog
boxes([A,B,C,D,E,F,G,H,I]) :-
    box(A, B, C),
    box(D, E, F),
    box(G, H, I).

box([], [], []).
box([A,B,C|R1], [D,E,F|R2], [G,H,I|R3]) :-
    all_distinct([A,B,C,D,E,F,G,H,I]),
    box(R1, R2, R3).
```

`maplist(label, Rows)` is what actually triggers the search. It tells CLP(FD) to find concrete values for all the remaining variables, using constraint propagation and backtracking under the hood.

`pretty_print/1`, `print_rows/2`, and `print_cells/2` handle the output. They use counters to insert horizontal and vertical separators after every 3rd row and column, which gives you the readable grid format.

---

## Tests

To run the solver, load the file in SWI-Prolog:

```bash
swipl sudoku.pl
```

**Test 1 — Easy puzzle**

Many cells are given, minimal backtracking required.

```prolog
?- Rows = [
     [5,3,_,_,7,_,_,_,_],
     [6,_,_,1,9,5,_,_,_],
     [_,9,8,_,_,_,_,6,_],
     [8,_,_,_,6,_,_,_,3],
     [4,_,_,8,_,3,_,_,1],
     [7,_,_,_,2,_,_,_,6],
     [_,6,_,_,_,_,2,8,_],
     [_,_,_,4,1,9,_,_,5],
     [_,_,_,_,8,_,_,7,9]
   ], sudoku(Rows), pretty_print(Rows).
```

```
+-------+-------+-------+
| 5 3 4 | 6 7 8 | 9 1 2 
| 6 7 2 | 1 9 5 | 3 4 8 
| 1 9 8 | 3 4 2 | 5 6 7 
+-------+-------+-------+
| 8 5 9 | 7 6 1 | 4 2 3 
| 4 2 6 | 8 5 3 | 7 9 1 
| 7 1 3 | 9 2 4 | 8 5 6 
+-------+-------+-------+
| 9 6 1 | 5 3 7 | 2 8 4 
| 2 8 7 | 4 1 9 | 6 3 5 
| 3 4 5 | 2 8 6 | 1 7 9 
+-------+-------+-------+
```

**Test 2 — Hard puzzle**

Fewer given cells, requires deeper backtracking. Sourced from Project Euler problem 96.

```prolog
?- Rows = [
     [_,_,3,_,2,_,6,_,_],
     [9,_,_,3,_,5,_,_,1],
     [_,_,1,8,_,6,4,_,_],
     [_,_,8,1,_,2,9,_,_],
     [7,_,_,_,_,_,_,_,8],
     [_,_,6,7,_,8,2,_,_],
     [_,_,2,6,_,9,5,_,_],
     [8,_,_,2,_,3,_,_,9],
     [_,_,5,_,1,_,3,_,_]
   ], sudoku(Rows), pretty_print(Rows).
```

```
+-------+-------+-------+
| 4 8 3 | 9 2 1 | 6 5 7 
| 9 6 7 | 3 4 5 | 8 2 1 
| 2 5 1 | 8 7 6 | 4 9 3 
+-------+-------+-------+
| 5 4 8 | 1 3 2 | 9 7 6 
| 7 2 9 | 5 6 4 | 1 3 8 
| 1 3 6 | 7 9 8 | 2 4 5 
+-------+-------+-------+
| 3 7 2 | 6 8 9 | 5 1 4 
| 8 1 4 | 2 5 3 | 7 6 9 
| 6 9 5 | 4 1 7 | 3 8 2 
+-------+-------+-------+
```

**Test 3 — Invalid puzzle**

Row 1 contains two 5s, directly violating the row constraint. The solver returns `false` immediately after constraint propagation detects the conflict, no backtracking needed.

```prolog
?- Rows = [
     [5,5,_,_,7,_,_,_,_],
     [6,_,_,1,9,5,_,_,_],
     [_,9,8,_,_,_,_,6,_],
     [8,_,_,_,6,_,_,_,3],
     [4,_,_,8,_,3,_,_,1],
     [7,_,_,_,2,_,_,_,6],
     [_,6,_,_,_,_,2,8,_],
     [_,_,_,4,1,9,_,_,5],
     [_,_,_,_,8,_,_,7,9]
   ], sudoku(Rows), pretty_print(Rows).
```

```
false.
```

---

## Analysis

### Time Complexity

The solver works by doing constraint propagation first, then backtracking search. If you think about it naively, each of the 81 cells could take any value from 1 to 9, which gives a theoretical upper bound of O(9⁸¹), but that is never actually what happens.

CLP(FD) brings that number way down. Every time a cell gets assigned a value, `all_distinct` automatically removes that value from the domains of every related cell in the same row, column, and box. So by the time backtracking starts, most of the impossible branches have already been cut off.

If we let **n** be the number of empty cells, the complexity looks like this:

```
O(9^n)  — worst case with backtracking only
O(9^n)  — still exponential, but n is effectively much smaller in practice
          because constraint propagation prunes the domain at each step
```

For a typical 9×9 puzzle with a unique solution, propagation alone resolves most cells before any search is needed. The solver finishes in milliseconds.

### Other Paradigms and Tradeoffs

| Paradigm | Language | Approach | Time Complexity | Tradeoff |
|---|---|---|---|---|
| **Logic** (this solution) | Prolog | Declare constraints, engine searches | O(9^n) pruned | Minimal code, paradigm handles search automatically |
| **Functional** | Haskell / Racket | Recursive backtracking with pure functions | O(9^n) | Search must be written explicitly, but stays declarative |
| **Object-Oriented** | Java / Python | Backtracking solver as a class with methods | O(9^n) | More code, but full control over heuristics |
| **Parallel** | C++ / CUDA | Explore multiple branches simultaneously | O(9^n / cores) | Fastest in theory, but coordination overhead adds real complexity |

The biggest difference between the Logic approach and the rest is not the complexity class, since every backtracking solution shares the same worst case. The real difference is who is responsible for writing the search. In Prolog, the language handles it. In every other paradigm, you have to implement it yourself.

The closest practical alternative would be a Python OOP solver using a Minimum Remaining Values (MRV) heuristic, which always picks the cell with the fewest legal options left. That can seriously shrink the search tree (Russell & Norvig, 2021, Chapter 6, p. 143). Interestingly, CLP(FD) applies something equivalent internally, which is a big part of why both approaches end up performing similarly in practice despite being structured so differently.

---

## References

Russell, S. J., & Norvig, P. (2021). *Artificial Intelligence: A Modern Approach* (4th ed.). Pearson..

Sterling, L., & Shapiro, E. (1994). *The Art of Prolog: Advanced Programming Techniques* (2nd ed.). MIT Press.

Triska, M. (2016). The Finite Domain Constraint Solver of SWI-Prolog. Available at: https://www.swi-prolog.org/man/clpfd.html
