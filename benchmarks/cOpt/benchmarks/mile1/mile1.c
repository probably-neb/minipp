#include <stdio.h>
#include <stdlib.h>
struct _mini_Power
{
long _mini_base;
long _mini_exp;
};
long _mini_calcPower(long _mini_base, long _mini_exp)
{
long _mini_result;
_mini_result = 1L;
while ((_mini_exp>0L))
{
_mini_result = (_mini_result*_mini_base);
_mini_exp = (_mini_exp-1L);
}
return _mini_result;
}
long _mini_main()
{
struct _mini_Power* _mini_power;
long _mini_input;
long _mini_result;
long _mini_exp;
long _mini_i;
_mini_result = 0L;
_mini_power = malloc(sizeof(struct _mini_Power));
scanf("%ld", &_mini_input);
_mini_power->_mini_base = _mini_input;
scanf("%ld", &_mini_input);
if ((_mini_input<0L))
{
return -1L;
}
_mini_power->_mini_exp = _mini_input;
_mini_i = 0L;
while ((_mini_i<1000000L))
{
_mini_i = (_mini_i+1L);
_mini_result = _mini_calcPower(_mini_power->_mini_base, _mini_power->_mini_exp);
}
printf("%ld\n", _mini_result);
return 0L;
}
int main(void)
{
   return _mini_main();
}

