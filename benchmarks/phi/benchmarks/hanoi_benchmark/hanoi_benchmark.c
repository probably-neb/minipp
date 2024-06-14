#include <stdio.h>
#include <stdlib.h>
struct _mini_plate
{
long _mini_size;
struct _mini_plate* _mini_plateUnder;
};
struct _mini_plate* _mini_peg1;
struct _mini_plate* _mini_peg2;
struct _mini_plate* _mini_peg3;
long _mini_numMoves;
void _mini_move(long _mini_from, long _mini_to)
{
struct _mini_plate* _mini_plateToMove;
if ((_mini_from==1L))
{
_mini_plateToMove = _mini_peg1;
_mini_peg1 = _mini_peg1->_mini_plateUnder;
}
else
{
if ((_mini_from==2L))
{
_mini_plateToMove = _mini_peg2;
_mini_peg2 = _mini_peg2->_mini_plateUnder;
}
else
{
_mini_plateToMove = _mini_peg3;
_mini_peg3 = _mini_peg3->_mini_plateUnder;
}
}
if ((_mini_to==1L))
{
_mini_plateToMove->_mini_plateUnder = _mini_peg1;
_mini_peg1 = _mini_plateToMove;
}
else
{
if ((_mini_to==2L))
{
_mini_plateToMove->_mini_plateUnder = _mini_peg2;
_mini_peg2 = _mini_plateToMove;
}
else
{
_mini_plateToMove->_mini_plateUnder = _mini_peg3;
_mini_peg3 = _mini_plateToMove;
}
}
_mini_numMoves = (_mini_numMoves+1L);
}
void _mini_hanoi(long _mini_n, long _mini_from, long _mini_to, long _mini_other)
{
if ((_mini_n==1L))
{
_mini_move(_mini_from, _mini_to);
}
else
{
_mini_hanoi((_mini_n-1L), _mini_from, _mini_other, _mini_to);
_mini_move(_mini_from, _mini_to);
_mini_hanoi((_mini_n-1L), _mini_other, _mini_to, _mini_from);
}
}
void _mini_printPeg(struct _mini_plate* _mini_peg)
{
struct _mini_plate* _mini_aPlate;
_mini_aPlate = _mini_peg;
while ((_mini_aPlate!=NULL))
{
printf("%ld\n", _mini_aPlate->_mini_size);
_mini_aPlate = _mini_aPlate->_mini_plateUnder;
}
}
long _mini_main()
{
long _mini_count;
long _mini_numPlates;
struct _mini_plate* _mini_aPlate;
_mini_peg1 = NULL;
_mini_peg2 = NULL;
_mini_peg3 = NULL;
_mini_numMoves = 0L;
scanf("%ld", &_mini_numPlates);
if ((_mini_numPlates>=1L))
{
_mini_count = _mini_numPlates;
while ((_mini_count!=0L))
{
_mini_aPlate = malloc(sizeof(struct _mini_plate));
_mini_aPlate->_mini_size = _mini_count;
_mini_aPlate->_mini_plateUnder = _mini_peg1;
_mini_peg1 = _mini_aPlate;
_mini_count = (_mini_count-1L);
}
printf("%ld\n", 1L);
_mini_printPeg(_mini_peg1);
printf("%ld\n", 2L);
_mini_printPeg(_mini_peg2);
printf("%ld\n", 3L);
_mini_printPeg(_mini_peg3);
_mini_hanoi(_mini_numPlates, 1L, 3L, 2L);
printf("%ld\n", 1L);
_mini_printPeg(_mini_peg1);
printf("%ld\n", 2L);
_mini_printPeg(_mini_peg2);
printf("%ld\n", 3L);
_mini_printPeg(_mini_peg3);
printf("%ld\n", _mini_numMoves);
while ((_mini_peg3!=NULL))
{
_mini_aPlate = _mini_peg3;
_mini_peg3 = _mini_peg3->_mini_plateUnder;
free(_mini_aPlate);
}
}
return 0L;
}
int main(void)
{
   return _mini_main();
}

