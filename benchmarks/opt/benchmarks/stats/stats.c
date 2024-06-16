#include <stdio.h>
#include <stdlib.h>
struct _mini_linkedNums
{
long _mini_num;
struct _mini_linkedNums* _mini_next;
};
struct _mini_linkedNums* _mini_getRands(long _mini_seed, long _mini_num)
{
long _mini_cur;
long _mini_prev;
struct _mini_linkedNums* _mini_curNode;
struct _mini_linkedNums* _mini_prevNode;
_mini_curNode = NULL;
_mini_cur = (_mini_seed*_mini_seed);
_mini_prevNode = malloc(sizeof(struct _mini_linkedNums));
_mini_prevNode->_mini_num = _mini_cur;
_mini_prevNode->_mini_next = NULL;
_mini_num = (_mini_num-1L);
_mini_prev = _mini_cur;
while ((_mini_num>0L))
{
_mini_cur = (((((_mini_prev*_mini_prev))/_mini_seed)*((_mini_seed/2L)))+1L);
_mini_cur = (_mini_cur-(((_mini_cur/1000000000L))*1000000000L));
_mini_curNode = malloc(sizeof(struct _mini_linkedNums));
_mini_curNode->_mini_num = _mini_cur;
_mini_curNode->_mini_next = _mini_prevNode;
_mini_prevNode = _mini_curNode;
_mini_num = (_mini_num-1L);
_mini_prev = _mini_cur;
}
return _mini_curNode;
}
long _mini_calcMean(struct _mini_linkedNums* _mini_nums)
{
long _mini_sum;
long _mini_num;
long _mini_mean;
_mini_sum = 0L;
_mini_num = 0L;
_mini_mean = 0L;
while ((_mini_nums!=NULL))
{
_mini_num = (_mini_num+1L);
_mini_sum = (_mini_sum+_mini_nums->_mini_num);
_mini_nums = _mini_nums->_mini_next;
}
if ((_mini_num!=0L))
{
_mini_mean = (_mini_sum/_mini_num);
}
return _mini_mean;
}
long _mini_approxSqrt(long _mini_num)
{
long _mini_guess;
long _mini_result;
long _mini_prev;
_mini_guess = 1L;
_mini_prev = _mini_guess;
_mini_result = 0L;
while ((_mini_result<_mini_num))
{
_mini_result = (_mini_guess*_mini_guess);
_mini_prev = _mini_guess;
_mini_guess = (_mini_guess+1L);
}
return _mini_prev;
}
void _mini_approxSqrtAll(struct _mini_linkedNums* _mini_nums)
{
while ((_mini_nums!=NULL))
{
printf("%ld\n", _mini_approxSqrt(_mini_nums->_mini_num));
_mini_nums = _mini_nums->_mini_next;
}
}
void _mini_range(struct _mini_linkedNums* _mini_nums)
{
long _mini_min;
long _mini_max;
long _mini_first;
_mini_min = 0L;
_mini_max = 0L;
_mini_first = 1L;
while ((_mini_nums!=NULL))
{
if (_mini_first)
{
_mini_min = _mini_nums->_mini_num;
_mini_max = _mini_nums->_mini_num;
_mini_first = 0L;
}
else
{
if ((_mini_nums->_mini_num<_mini_min))
{
_mini_min = _mini_nums->_mini_num;
}
else
{
if ((_mini_nums->_mini_num>_mini_max))
{
_mini_max = _mini_nums->_mini_num;
}
}
}
_mini_nums = _mini_nums->_mini_next;
}
printf("%ld\n", _mini_min);
printf("%ld\n", _mini_max);
}
long _mini_main()
{
long _mini_seed;
long _mini_num;
long _mini_mean;
struct _mini_linkedNums* _mini_nums;
scanf("%ld", &_mini_seed);
scanf("%ld", &_mini_num);
_mini_nums = _mini_getRands(_mini_seed, _mini_num);
_mini_mean = _mini_calcMean(_mini_nums);
printf("%ld\n", _mini_mean);
_mini_range(_mini_nums);
_mini_approxSqrtAll(_mini_nums);
return 0L;
}
int main(void)
{
   return _mini_main();
}

