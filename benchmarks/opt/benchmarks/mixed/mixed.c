#include <stdio.h>
#include <stdlib.h>
struct _mini_simple
{
long _mini_one;
};
struct _mini_foo
{
long _mini_bar;
long _mini_cool;
struct _mini_simple* _mini_simp;
};
struct _mini_foo* _mini_globalfoo;
void _mini_tailrecursive(long _mini_num)
{
if ((_mini_num<=0L))
{
return;
}
_mini_tailrecursive((_mini_num-1L));
}
long _mini_add(long _mini_x, long _mini_y)
{
return (_mini_x+_mini_y);
}
void _mini_domath(long _mini_num)
{
struct _mini_foo* _mini_math1;
struct _mini_foo* _mini_math2;
long _mini_tmp;
_mini_math1 = malloc(sizeof(struct _mini_foo));
_mini_math1->_mini_simp = malloc(sizeof(struct _mini_simple));
_mini_math2 = malloc(sizeof(struct _mini_foo));
_mini_math2->_mini_simp = malloc(sizeof(struct _mini_simple));
_mini_math1->_mini_bar = _mini_num;
_mini_math2->_mini_bar = 3L;
_mini_math1->_mini_simp->_mini_one = _mini_math1->_mini_bar;
_mini_math2->_mini_simp->_mini_one = _mini_math2->_mini_bar;
while ((_mini_num>0L))
{
_mini_tmp = (_mini_math1->_mini_bar*_mini_math2->_mini_bar);
_mini_tmp = (((_mini_tmp*_mini_math1->_mini_simp->_mini_one))/_mini_math2->_mini_bar);
_mini_tmp = _mini_add(_mini_math2->_mini_simp->_mini_one, _mini_math1->_mini_bar);
_mini_tmp = (_mini_math2->_mini_bar-_mini_math1->_mini_bar);
_mini_num = (_mini_num-1L);
}
free(_mini_math1);
free(_mini_math2);
}
void _mini_objinstantiation(long _mini_num)
{
struct _mini_foo* _mini_tmp;
while ((_mini_num>0L))
{
_mini_tmp = malloc(sizeof(struct _mini_foo));
free(_mini_tmp);
_mini_num = (_mini_num-1L);
}
}
long _mini_ackermann(long _mini_m, long _mini_n)
{
if ((_mini_m==0L))
{
return (_mini_n+1L);
}
if ((_mini_n==0L))
{
return _mini_ackermann((_mini_m-1L), 1L);
}
else
{
return _mini_ackermann((_mini_m-1L), _mini_ackermann(_mini_m, (_mini_n-1L)));
}
}
long _mini_main()
{
long _mini_a;
long _mini_b;
long _mini_c;
long _mini_d;
long _mini_e;
scanf("%ld", &_mini_a);
scanf("%ld", &_mini_b);
scanf("%ld", &_mini_c);
scanf("%ld", &_mini_d);
scanf("%ld", &_mini_e);
_mini_tailrecursive(_mini_a);
printf("%ld\n", _mini_a);
_mini_domath(_mini_b);
printf("%ld\n", _mini_b);
_mini_objinstantiation(_mini_c);
printf("%ld\n", _mini_c);
printf("%ld\n", _mini_ackermann(_mini_d, _mini_e));
return 0L;
}
int main(void)
{
   return _mini_main();
}

