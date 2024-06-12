#include <stdio.h>
#include <stdlib.h>
long _mini_global1;
long _mini_global2;
long _mini_global3;
long _mini_constantFolding()
{
long _mini_a;
_mini_a = ((((((((((8L*9L)/4L)+2L)-(5L*8L))+9L)-12L)+6L)-9L)-18L)+(((23L*3L)/23L)*90L));
return _mini_a;
}
long _mini_constantPropagation()
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
long _mini_j;
long _mini_k;
long _mini_l;
long _mini_m;
long _mini_n;
long _mini_o;
long _mini_p;
long _mini_q;
long _mini_r;
long _mini_s;
long _mini_t;
long _mini_u;
long _mini_v;
long _mini_w;
long _mini_x;
long _mini_y;
long _mini_z;
_mini_a = 4L;
_mini_b = 7L;
_mini_c = 8L;
_mini_d = 5L;
_mini_e = 11L;
_mini_f = 21L;
_mini_g = (_mini_a+_mini_b);
_mini_h = (_mini_c+_mini_d);
_mini_i = (_mini_e+_mini_f);
_mini_j = (_mini_g+_mini_h);
_mini_k = (_mini_i*_mini_j);
_mini_l = ((_mini_e+(_mini_h*_mini_i))-_mini_k);
_mini_m = ((_mini_h-(_mini_i*_mini_j))+(_mini_k/_mini_l));
_mini_n = (((((_mini_e+_mini_f)+_mini_g)+_mini_h)+_mini_i)-_mini_j);
_mini_o = ((((_mini_n-_mini_m)+_mini_h)-_mini_a)-_mini_b);
_mini_p = (((_mini_k+_mini_l)-_mini_g)-_mini_h);
_mini_q = ((((_mini_b-_mini_a))*_mini_d)-_mini_i);
_mini_r = (((_mini_l*_mini_c)*_mini_d)+_mini_o);
_mini_s = ((((_mini_b*_mini_a)*_mini_c)/_mini_e)-_mini_o);
_mini_t = (((_mini_i+_mini_k)+_mini_c)-_mini_p);
_mini_u = ((_mini_n+_mini_o)-(_mini_f*_mini_a));
_mini_v = (((_mini_a*_mini_b)-_mini_k)-_mini_l);
_mini_w = ((_mini_v-_mini_s)-(_mini_r*_mini_d));
_mini_x = (((_mini_o-_mini_w)-_mini_v)-_mini_n);
_mini_y = (((_mini_p*_mini_x)+_mini_t)-_mini_w);
_mini_z = (((_mini_w-_mini_x)+_mini_y)+_mini_k);
return _mini_z;
}
long _mini_deadCodeElimination()
{
long _mini_a;
long _mini_b;
long _mini_c;
long _mini_d;
long _mini_e;
_mini_a = 4L;
_mini_a = 5L;
_mini_a = 7L;
_mini_a = 8L;
_mini_b = 6L;
_mini_b = 9L;
_mini_b = 12L;
_mini_b = 8L;
_mini_c = 10L;
_mini_c = 13L;
_mini_c = 9L;
_mini_d = 45L;
_mini_d = 12L;
_mini_d = 3L;
_mini_e = 23L;
_mini_e = 10L;
_mini_global1 = 11L;
_mini_global1 = 5L;
_mini_global1 = 9L;
return ((((_mini_a+_mini_b)+_mini_c)+_mini_d)+_mini_e);
}
long _mini_sum(long _mini_number)
{
long _mini_total;
_mini_total = 0L;
while ((_mini_number>0L))
{
_mini_total = (_mini_total+_mini_number);
_mini_number = (_mini_number-1L);
}
return _mini_total;
}
long _mini_doesntModifyGlobals()
{
long _mini_a;
long _mini_b;
_mini_a = 1L;
_mini_b = 2L;
return (_mini_a+_mini_b);
}
long _mini_interProceduralOptimization()
{
long _mini_a;
_mini_global1 = 1L;
_mini_global2 = 0L;
_mini_global3 = 0L;
_mini_a = _mini_sum(100L);
if ((_mini_global1==1L))
{
_mini_a = _mini_sum(10000L);
}
else
{
if ((_mini_global2==2L))
{
_mini_a = _mini_sum(20000L);
}
if ((_mini_global3==3L))
{
_mini_a = _mini_sum(30000L);
}
}
return _mini_a;
}
long _mini_commonSubexpressionElimination()
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
long _mini_j;
long _mini_k;
long _mini_l;
long _mini_m;
long _mini_n;
long _mini_o;
long _mini_p;
long _mini_q;
long _mini_r;
long _mini_s;
long _mini_t;
long _mini_u;
long _mini_v;
long _mini_w;
long _mini_x;
long _mini_y;
long _mini_z;
_mini_a = 11L;
_mini_b = 22L;
_mini_c = 33L;
_mini_d = 44L;
_mini_e = 55L;
_mini_f = 66L;
_mini_g = 77L;
_mini_h = (_mini_a*_mini_b);
_mini_i = (_mini_c/_mini_d);
_mini_j = (_mini_e*_mini_f);
_mini_k = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_l = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_m = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_n = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_o = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_p = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_q = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_r = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_s = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_t = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_u = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_v = ((((_mini_b*_mini_a)+(_mini_c/_mini_d))-(_mini_e*_mini_f))+_mini_g);
_mini_w = ((((_mini_a*_mini_b)+(_mini_c/_mini_d))-(_mini_f*_mini_e))+_mini_g);
_mini_x = (((_mini_g+(_mini_a*_mini_b))+(_mini_c/_mini_d))-(_mini_e*_mini_f));
_mini_y = (((((_mini_a*_mini_b))+((_mini_c/_mini_d)))-((_mini_e*_mini_f)))+_mini_g);
_mini_z = (((((_mini_c/_mini_d))+((_mini_a*_mini_b)))-((_mini_e*_mini_f)))+_mini_g);
return (((((((((((((((((((((((((_mini_a+_mini_b)+_mini_c)+_mini_d)+_mini_e)+_mini_f)+_mini_g)+_mini_h)+_mini_i)+_mini_j)+_mini_k)+_mini_l)+_mini_m)+_mini_n)+_mini_o)+_mini_p)+_mini_q)+_mini_r)+_mini_s)+_mini_t)+_mini_u)+_mini_v)+_mini_w)+_mini_x)+_mini_y)+_mini_z);
}
long _mini_hoisting()
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
_mini_a = 1L;
_mini_b = 2L;
_mini_c = 3L;
_mini_d = 4L;
_mini_i = 0L;
while ((_mini_i<1000000L))
{
_mini_e = 5L;
_mini_g = ((_mini_a+_mini_b)+_mini_c);
_mini_h = ((_mini_c+_mini_d)+_mini_g);
_mini_i = (_mini_i+1L);
}
return _mini_b;
}
long _mini_doubleIf()
{
long _mini_a;
long _mini_b;
long _mini_c;
long _mini_d;
_mini_a = 1L;
_mini_b = 2L;
_mini_c = 3L;
_mini_d = 0L;
if ((_mini_a==1L))
{
_mini_b = 20L;
if ((_mini_a==1L))
{
_mini_b = 200L;
_mini_c = 300L;
}
else
{
_mini_a = 1L;
_mini_b = 2L;
_mini_c = 3L;
}
_mini_d = 50L;
}
return _mini_d;
}
long _mini_integerDivide()
{
long _mini_a;
_mini_a = 3000L;
_mini_a = (_mini_a/2L);
_mini_a = (_mini_a*4L);
_mini_a = (_mini_a/8L);
_mini_a = (_mini_a/16L);
_mini_a = (_mini_a*32L);
_mini_a = (_mini_a/64L);
_mini_a = (_mini_a*128L);
_mini_a = (_mini_a/4L);
return _mini_a;
}
long _mini_association()
{
long _mini_a;
_mini_a = 10L;
_mini_a = (_mini_a*2L);
_mini_a = (_mini_a/2L);
_mini_a = (3L*_mini_a);
_mini_a = (_mini_a/3L);
_mini_a = (_mini_a*4L);
_mini_a = (_mini_a/4L);
_mini_a = (_mini_a+4L);
_mini_a = (_mini_a-4L);
_mini_a = (_mini_a*50L);
_mini_a = (_mini_a/50L);
return _mini_a;
}
long _mini_tailRecursionHelper(long _mini_value, long _mini_sum)
{
if ((_mini_value==0L))
{
return _mini_sum;
}
else
{
return _mini_tailRecursionHelper((_mini_value-1L), (_mini_sum+_mini_value));
}
}
long _mini_tailRecursion(long _mini_value)
{
return _mini_tailRecursionHelper(_mini_value, 0L);
}
long _mini_unswitching()
{
long _mini_a;
long _mini_b;
_mini_a = 1L;
_mini_b = 2L;
while ((_mini_a<1000000L))
{
if ((_mini_b==2L))
{
_mini_a = (_mini_a+1L);
}
else
{
_mini_a = (_mini_a+2L);
}
}
return _mini_a;
}
long _mini_randomCalculation(long _mini_number)
{
long _mini_a;
long _mini_b;
long _mini_c;
long _mini_d;
long _mini_e;
long _mini_i;
long _mini_sum;
_mini_i = 0L;
_mini_sum = 0L;
while ((_mini_i<_mini_number))
{
_mini_a = 4L;
_mini_b = 7L;
_mini_c = 8L;
_mini_d = (_mini_a+_mini_b);
_mini_e = (_mini_d+_mini_c);
_mini_sum = (_mini_sum+_mini_e);
_mini_i = (_mini_i*2L);
_mini_i = (_mini_i/2L);
_mini_i = (3L*_mini_i);
_mini_i = (_mini_i/3L);
_mini_i = (_mini_i*4L);
_mini_i = (_mini_i/4L);
_mini_i = (_mini_i+1L);
}
return _mini_sum;
}
long _mini_iterativeFibonacci(long _mini_number)
{
long _mini_previous;
long _mini_result;
long _mini_count;
long _mini_i;
long _mini_sum;
_mini_previous = -1L;
_mini_result = 1L;
_mini_i = 0L;
while ((_mini_i<_mini_number))
{
_mini_sum = (_mini_result+_mini_previous);
_mini_previous = _mini_result;
_mini_result = _mini_sum;
_mini_i = (_mini_i+1L);
}
return _mini_result;
}
long _mini_recursiveFibonacci(long _mini_number)
{
if (((_mini_number<=0L)||(_mini_number==1L)))
{
return _mini_number;
}
else
{
return (_mini_recursiveFibonacci((_mini_number-1L))+_mini_recursiveFibonacci((_mini_number-2L)));
}
}
long _mini_main()
{
long _mini_input;
long _mini_result;
long _mini_i;
scanf("%ld", &_mini_input);
_mini_i = 1L;
while ((_mini_i<_mini_input))
{
_mini_result = _mini_constantFolding();
printf("%ld\n", _mini_result);
_mini_result = _mini_constantPropagation();
printf("%ld\n", _mini_result);
_mini_result = _mini_deadCodeElimination();
printf("%ld\n", _mini_result);
_mini_result = _mini_interProceduralOptimization();
printf("%ld\n", _mini_result);
_mini_result = _mini_commonSubexpressionElimination();
printf("%ld\n", _mini_result);
_mini_result = _mini_hoisting();
printf("%ld\n", _mini_result);
_mini_result = _mini_doubleIf();
printf("%ld\n", _mini_result);
_mini_result = _mini_integerDivide();
printf("%ld\n", _mini_result);
_mini_result = _mini_association();
printf("%ld\n", _mini_result);
_mini_result = _mini_tailRecursion((_mini_input/1000L));
printf("%ld\n", _mini_result);
_mini_result = _mini_unswitching();
printf("%ld\n", _mini_result);
_mini_result = _mini_randomCalculation(_mini_input);
printf("%ld\n", _mini_result);
_mini_result = _mini_iterativeFibonacci((_mini_input/5L));
printf("%ld\n", _mini_result);
_mini_result = _mini_recursiveFibonacci((_mini_input/1000L));
printf("%ld\n", _mini_result);
_mini_i = (_mini_i+1L);
}
printf("%ld\n", 9999L);
return 0L;
}
int main(void)
{
   return _mini_main();
}

