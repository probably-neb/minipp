#include <stdio.h>
#include <stdlib.h>
long _mini_mod(long _mini_a, long _mini_b)
{
return ((_mini_a-((((_mini_a/_mini_b))*_mini_b))));
}
void _mini_hailstone(long _mini_n)
{
while (1L)
{
printf("%ld ", _mini_n);
if ((_mini_mod(_mini_n, 2L)==1L))
{
_mini_n = (((3L*_mini_n))+1L);
}
else
{
_mini_n = (_mini_n/2L);
}
if ((_mini_n<=1L))
{
printf("%ld\n", _mini_n);
return;
}
}
}
long _mini_main()
{
long _mini_num;
scanf("%ld", &_mini_num);
_mini_hailstone(_mini_num);
return 0L;
}
int main(void)
{
   return _mini_main();
}

