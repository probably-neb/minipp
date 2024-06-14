#include <stdio.h>
#include <stdlib.h>
struct _mini_IntHolder
{
long _mini_num;
};
long _mini_interval;
long _mini_end;
long _mini_multBy4xTimes(struct _mini_IntHolder* _mini_num, long _mini_timesLeft)
{
if ((_mini_timesLeft<=0L))
{
return _mini_num->_mini_num;
}
_mini_num->_mini_num = (4L*_mini_num->_mini_num);
_mini_multBy4xTimes(_mini_num, (_mini_timesLeft-1L));
return _mini_num->_mini_num;
}
void _mini_divideBy8(struct _mini_IntHolder* _mini_num)
{
_mini_num->_mini_num = (_mini_num->_mini_num/2L);
_mini_num->_mini_num = (_mini_num->_mini_num/2L);
_mini_num->_mini_num = (_mini_num->_mini_num/2L);
}
long _mini_main()
{
long _mini_start;
long _mini_countOuter;
long _mini_countInner;
long _mini_calc;
long _mini_tempAnswer;
long _mini_tempInterval;
struct _mini_IntHolder* _mini_x;
long _mini_uselessVar;
long _mini_uselessVar2;
_mini_x = malloc(sizeof(struct _mini_IntHolder));
_mini_end = 1000000L;
scanf("%ld", &_mini_start);
scanf("%ld", &_mini_interval);
printf("%ld\n", _mini_start);
printf("%ld\n", _mini_interval);
_mini_countOuter = 0L;
_mini_countInner = 0L;
_mini_calc = 0L;
while ((_mini_countOuter<50L))
{
_mini_countInner = 0L;
while ((_mini_countInner<=_mini_end))
{
_mini_calc = ((((((((((1L*2L)*3L)*4L)*5L)*6L)*7L)*8L)*9L)*10L)*11L);
_mini_countInner = (_mini_countInner+1L);
_mini_x->_mini_num = _mini_countInner;
_mini_tempAnswer = _mini_x->_mini_num;
_mini_multBy4xTimes(_mini_x, 2L);
_mini_divideBy8(_mini_x);
_mini_tempInterval = (_mini_interval-1L);
_mini_uselessVar = (_mini_tempInterval<=0L);
if ((_mini_tempInterval<=0L))
{
_mini_tempInterval = 1L;
}
_mini_countInner = (_mini_countInner+_mini_tempInterval);
}
_mini_countOuter = (_mini_countOuter+1L);
}
printf("%ld\n", _mini_countInner);
printf("%ld\n", _mini_calc);
return 0L;
}
int main(void)
{
   return _mini_main();
}

