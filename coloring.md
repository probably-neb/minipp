# 1 liveout

liveout(n) = ⋃(m ∈ succ(n)) gen(n) ⋃ (liveout(m) ∩ ¬(kill(n)))
    | succ[n] := successor basic blocks to bb n
    | gen(n) := source register used in n but not killed
    | kill(n) := dest reg  (e.x. `r1` in `r1 <- r2 + r3`) i.e. the register whose previous value is now gone

computing liveout notes:
    - first pass: assume all registers are dead
    - iterate over basic blocks in reverse order (starting at exit then going to incomers)
    - within each bb iterate over instructions in normal order
    - beards orders - store live in bitset


# 2 interference
live now := live out
for inst I (bottom to top)
    1) add interference edge between live now and I res
    2) remove I res from live now
    3) add sources of I to live now (see sccp for how to do this in a big switch for fun and $profit)

# Stackin constraints bby
oooooooo
while interference nodes left
    1) select unconstrained node N (node with fewer neighbors than available num registers)
        -> if no unconstrained nodes
        -> use one of following heuristics to choose from the constrained nodes
            - Pick most/least constrained (whatever you want bruv)
            - Pick least used
            - Pick random not used in loop
   2) remove node from graph
   3) push node onto on stack


# 4 Colorin
while stack not empty
    1) pop from stack
    2) reinstate + readd edges
    3) color = next in priority queue of colors

```{color queue}
const ColorIter = {
    colors: []Color,
    i: u32 = 0,
    
    pub fn next(self: *Self) Color {
        const i = self.i;
        const color = self.colors[i];
        if (i + 1 == self.colors.len) {
            self.i = 0;
        } else {
            self.i = i + 1;
        }
        return color;
    }
}
```
