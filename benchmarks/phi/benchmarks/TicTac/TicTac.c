#include <stdio.h>
#include <stdlib.h>
struct _mini_gameBoard
{
long _mini_a;
long _mini_b;
long _mini_c;
long _mini_d;
long _mini_e;
long _mini_f;
long _mini_g;
long _mini_h;
long _mini_i;
};
void _mini_cleanBoard(struct _mini_gameBoard* _mini_board)
{
_mini_board->_mini_a = 0L;
_mini_board->_mini_b = 0L;
_mini_board->_mini_c = 0L;
_mini_board->_mini_d = 0L;
_mini_board->_mini_e = 0L;
_mini_board->_mini_f = 0L;
_mini_board->_mini_g = 0L;
_mini_board->_mini_h = 0L;
_mini_board->_mini_i = 0L;
}
void _mini_printBoard(struct _mini_gameBoard* _mini_board)
{
printf("%ld ", _mini_board->_mini_a);
printf("%ld ", _mini_board->_mini_b);
printf("%ld\n", _mini_board->_mini_c);
printf("%ld ", _mini_board->_mini_d);
printf("%ld ", _mini_board->_mini_e);
printf("%ld\n", _mini_board->_mini_f);
printf("%ld ", _mini_board->_mini_g);
printf("%ld ", _mini_board->_mini_h);
printf("%ld\n", _mini_board->_mini_i);
}
void _mini_printMoveBoard()
{
printf("%ld\n", 123L);
printf("%ld\n", 456L);
printf("%ld\n", 789L);
}
void _mini_placePiece(struct _mini_gameBoard* _mini_board, long _mini_turn, long _mini_placement)
{
if ((_mini_placement==1L))
{
_mini_board->_mini_a = _mini_turn;
}
else
{
if ((_mini_placement==2L))
{
_mini_board->_mini_b = _mini_turn;
}
else
{
if ((_mini_placement==3L))
{
_mini_board->_mini_c = _mini_turn;
}
else
{
if ((_mini_placement==4L))
{
_mini_board->_mini_d = _mini_turn;
}
else
{
if ((_mini_placement==5L))
{
_mini_board->_mini_e = _mini_turn;
}
else
{
if ((_mini_placement==6L))
{
_mini_board->_mini_f = _mini_turn;
}
else
{
if ((_mini_placement==7L))
{
_mini_board->_mini_g = _mini_turn;
}
else
{
if ((_mini_placement==8L))
{
_mini_board->_mini_h = _mini_turn;
}
else
{
if ((_mini_placement==9L))
{
_mini_board->_mini_i = _mini_turn;
}
}
}
}
}
}
}
}
}
}
long _mini_checkWinner(struct _mini_gameBoard* _mini_board)
{
if ((_mini_board->_mini_a==1L))
{
if ((_mini_board->_mini_b==1L))
{
if ((_mini_board->_mini_c==1L))
{
return 0L;
}
}
}
if ((_mini_board->_mini_a==2L))
{
if ((_mini_board->_mini_b==2L))
{
if ((_mini_board->_mini_c==2L))
{
return 1L;
}
}
}
if ((_mini_board->_mini_d==1L))
{
if ((_mini_board->_mini_e==1L))
{
if ((_mini_board->_mini_f==1L))
{
return 0L;
}
}
}
if ((_mini_board->_mini_d==2L))
{
if ((_mini_board->_mini_e==2L))
{
if ((_mini_board->_mini_f==2L))
{
return 1L;
}
}
}
if ((_mini_board->_mini_g==1L))
{
if ((_mini_board->_mini_h==1L))
{
if ((_mini_board->_mini_i==1L))
{
return 0L;
}
}
}
if ((_mini_board->_mini_g==2L))
{
if ((_mini_board->_mini_h==2L))
{
if ((_mini_board->_mini_i==2L))
{
return 1L;
}
}
}
if ((_mini_board->_mini_a==1L))
{
if ((_mini_board->_mini_d==1L))
{
if ((_mini_board->_mini_g==1L))
{
return 0L;
}
}
}
if ((_mini_board->_mini_a==2L))
{
if ((_mini_board->_mini_d==2L))
{
if ((_mini_board->_mini_g==2L))
{
return 1L;
}
}
}
if ((_mini_board->_mini_b==1L))
{
if ((_mini_board->_mini_e==1L))
{
if ((_mini_board->_mini_h==1L))
{
return 0L;
}
}
}
if ((_mini_board->_mini_b==2L))
{
if ((_mini_board->_mini_e==2L))
{
if ((_mini_board->_mini_h==2L))
{
return 1L;
}
}
}
if ((_mini_board->_mini_c==1L))
{
if ((_mini_board->_mini_f==1L))
{
if ((_mini_board->_mini_i==1L))
{
return 0L;
}
}
}
if ((_mini_board->_mini_c==2L))
{
if ((_mini_board->_mini_f==2L))
{
if ((_mini_board->_mini_i==2L))
{
return 1L;
}
}
}
return -1L;
}
long _mini_main()
{
long _mini_turn;
long _mini_space1;
long _mini_space2;
long _mini_winner;
long _mini_i;
struct _mini_gameBoard* _mini_board;
_mini_i = 0L;
_mini_turn = 0L;
_mini_space1 = 0L;
_mini_space2 = 0L;
_mini_winner = -1L;
_mini_board = malloc(sizeof(struct _mini_gameBoard));
_mini_cleanBoard(_mini_board);
while (((_mini_winner<0L)&&(_mini_i!=8L)))
{
_mini_printBoard(_mini_board);
if ((_mini_turn==0L))
{
_mini_turn = (_mini_turn+1L);
scanf("%ld", &_mini_space1);
_mini_placePiece(_mini_board, 1L, _mini_space1);
}
else
{
_mini_turn = (_mini_turn-1L);
scanf("%ld", &_mini_space2);
_mini_placePiece(_mini_board, 2L, _mini_space2);
}
_mini_winner = _mini_checkWinner(_mini_board);
_mini_i = (_mini_i+1L);
}
printf("%ld\n", ((_mini_winner+1L)));
return 0L;
}
int main(void)
{
   return _mini_main();
}

