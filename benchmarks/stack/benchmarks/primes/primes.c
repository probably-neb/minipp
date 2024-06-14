#include <stdio.h>
#include <stdlib.h>
long _mini_isqrt(long _mini_a)
{
long _mini_square;
long _mini_delta;
_mini_square = 1L;
_mini_delta = 3L;
while ((_mini_square<=_mini_a))
{
_mini_square = (_mini_square+_mini_delta);
_mini_delta = (_mini_delta+2L);
}
return (((_mini_delta/2L)-1L));
}
long _mini_prime(long _mini_a)
{
long _mini_max;
long _mini_divisor;
long _mini_remainder;
if ((_mini_a<2L))
{
return 0L;
}
else
{
_mini_max = _mini_isqrt(_mini_a);
_mini_divisor = 2L;
while ((_mini_divisor<=_mini_max))
{
_mini_remainder = (_mini_a-((((_mini_a/_mini_divisor))*_mini_divisor)));
if ((_mini_remainder==0L))
{
return 0L;
}
_mini_divisor = (_mini_divisor+1L);
}
return 1L;
}
}
long _mini_main()
{
long _mini_limit;
long _mini_a;
scanf("%ld", &_mini_limit);
_mini_a = 0L;
while ((_mini_a<=_mini_limit))
{
if (_mini_prime(_mini_a))
{
printf("%ld\n", _mini_a);
}
_mini_a = (_mini_a+1L);
}
return 0L;
}
int main(void)
{
   return _mini_main();
}

