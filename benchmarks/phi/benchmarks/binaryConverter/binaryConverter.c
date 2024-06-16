#include <stdio.h>
#include <stdlib.h>
long _mini_wait(long _mini_waitTime)
{
while ((_mini_waitTime>0L))
{
_mini_waitTime = (_mini_waitTime-1L);
}
return 0L;
}
long _mini_power(long _mini_base, long _mini_exponent)
{
long _mini_product;
_mini_product = 1L;
while ((_mini_exponent>0L))
{
_mini_product = (_mini_product*_mini_base);
_mini_exponent = (_mini_exponent-1L);
}
return _mini_product;
}
long _mini_recursiveDecimalSum(long _mini_binaryNum, long _mini_decimalSum, long _mini_recursiveDepth)
{
long _mini_tempNum;
long _mini_base;
long _mini_remainder;
if ((_mini_binaryNum>0L))
{
_mini_base = 2L;
_mini_tempNum = (_mini_binaryNum/10L);
_mini_tempNum = (_mini_tempNum*10L);
_mini_tempNum = (_mini_binaryNum-_mini_tempNum);
if ((_mini_tempNum==1L))
{
_mini_decimalSum = (_mini_decimalSum+_mini_power(_mini_base, _mini_recursiveDepth));
}
return _mini_recursiveDecimalSum((_mini_binaryNum/10L), _mini_decimalSum, (_mini_recursiveDepth+1L));
}
return _mini_decimalSum;
}
long _mini_convertToDecimal(long _mini_binaryNum)
{
long _mini_recursiveDepth;
long _mini_decimalSum;
_mini_recursiveDepth = 0L;
_mini_decimalSum = 0L;
return _mini_recursiveDecimalSum(_mini_binaryNum, _mini_decimalSum, _mini_recursiveDepth);
}
long _mini_main()
{
long _mini_number;
long _mini_waitTime;
scanf("%ld", &_mini_number);
_mini_number = _mini_convertToDecimal(_mini_number);
_mini_waitTime = (_mini_number*_mini_number);
while ((_mini_waitTime>0L))
{
_mini_wait(_mini_waitTime);
_mini_waitTime = (_mini_waitTime-1L);
}
printf("%ld\n", _mini_number);
return 0L;
}
int main(void)
{
   return _mini_main();
}

