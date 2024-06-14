#include <stdio.h>
#include <stdlib.h>
long _mini_GLOBAL;
long _mini_count;
long _mini_fun2(long _mini_x, long _mini_y)
{
if ((_mini_x==0L))
{
return _mini_y;
}
else
{
return _mini_fun2((_mini_x-1L), _mini_y);
}
}
long _mini_fun1(long _mini_x, long _mini_y, long _mini_z)
{
long _mini_retVal;
_mini_retVal = ((((5L+6L)-(_mini_x*2L))+(4L/_mini_y))+_mini_z);
if ((_mini_retVal>_mini_y))
{
return _mini_fun2(_mini_retVal, _mini_x);
}
else
{
if (((5L<6L)&&(_mini_retVal<=_mini_y)))
{
return _mini_fun2(_mini_retVal, _mini_y);
}
}
return _mini_retVal;
}
long _mini_main()
{
long _mini_i;
_mini_i = 0L;
scanf("%ld", &_mini_i);
while ((_mini_i<10000L))
{
printf("%ld\n", _mini_fun1(3L, _mini_i, 5L));
_mini_i = (_mini_i+1L);
}
return 0L;
}
int main(void)
{
   return _mini_main();
}

