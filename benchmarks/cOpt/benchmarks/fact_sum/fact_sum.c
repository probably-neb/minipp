#include <stdio.h>
#include <stdlib.h>
long _mini_sum(long _mini_a, long _mini_b)
{
return ((_mini_a+_mini_b));
}
long _mini_fact(long _mini_n)
{
long _mini_t;
if (((_mini_n==1L)||(_mini_n==0L)))
{
return 1L;
}
if ((_mini_n<=1L))
{
return _mini_fact((-1L*_mini_n));
}
_mini_t = (_mini_n*_mini_fact((_mini_n-1L)));
return _mini_t;
}
long _mini_main()
{
long _mini_num1;
long _mini_num2;
long _mini_flag;
_mini_flag = 0L;
while ((_mini_flag!=-1L))
{
scanf("%ld", &_mini_num1);
scanf("%ld", &_mini_num2);
_mini_num1 = (_mini_fact(_mini_num1));
_mini_num2 = (_mini_fact(_mini_num2));
printf("%ld\n", (_mini_sum(_mini_num1, _mini_num2)));
scanf("%ld", &_mini_flag);
}
return 0L;
}
int main(void)
{
   return _mini_main();
}

