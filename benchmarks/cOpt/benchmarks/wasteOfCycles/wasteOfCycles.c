#include <stdio.h>
#include <stdlib.h>
long _mini_function(long _mini_n)
{
long _mini_i;
long _mini_j;
if ((_mini_n<=0L))
{
return 0L;
}
_mini_i = 0L;
while ((_mini_i<(_mini_n*_mini_n)))
{
_mini_j = (_mini_i+_mini_n);
printf("%ld ", _mini_j);
_mini_i = (_mini_i+1L);
}
return _mini_function((_mini_n-1L));
}
long _mini_main()
{
long _mini_num;
scanf("%ld", &_mini_num);
_mini_function(_mini_num);
printf("%ld\n", 0L);
return 0L;
}
int main(void)
{
   return _mini_main();
}

