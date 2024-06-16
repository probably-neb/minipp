#include <stdio.h>
#include <stdlib.h>
struct _mini_thing
{
long _mini_i;
long _mini_b;
struct _mini_thing* _mini_s;
};
long _mini_gi1;
long _mini_gb1;
struct _mini_thing* _mini_gs1;
long _mini_counter;
void _mini_printgroup(long _mini_groupnum)
{
printf("%ld ", 1L);
printf("%ld ", 0L);
printf("%ld ", 1L);
printf("%ld ", 0L);
printf("%ld ", 1L);
printf("%ld ", 0L);
printf("%ld\n", _mini_groupnum);
return;
}
long _mini_setcounter(long _mini_val)
{
_mini_counter = _mini_val;
return 1L;
}
void _mini_takealltypes(long _mini_i, long _mini_b, struct _mini_thing* _mini_s)
{
if ((_mini_i==3L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if (_mini_b)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if (_mini_s->_mini_b)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
}
void _mini_tonofargs(long _mini_a1, long _mini_a2, long _mini_a3, long _mini_a4, long _mini_a5, long _mini_a6, long _mini_a7, long _mini_a8)
{
if ((_mini_a5==5L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_a5);
}
if ((_mini_a6==6L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_a6);
}
if ((_mini_a7==7L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_a7);
}
if ((_mini_a8==8L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_a8);
}
}
long _mini_returnint(long _mini_ret)
{
return _mini_ret;
}
long _mini_returnbool(long _mini_ret)
{
return _mini_ret;
}
struct _mini_thing* _mini_returnstruct(struct _mini_thing* _mini_ret)
{
return _mini_ret;
}
long _mini_main()
{
long _mini_b1;
long _mini_b2;
long _mini_i1;
long _mini_i2;
long _mini_i3;
struct _mini_thing* _mini_s1;
struct _mini_thing* _mini_s2;
_mini_counter = 0L;
_mini_printgroup(1L);
_mini_b1 = 0L;
_mini_b2 = 0L;
if ((_mini_b1&&_mini_b2))
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
_mini_b1 = 1L;
_mini_b2 = 0L;
if ((_mini_b1&&_mini_b2))
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
_mini_b1 = 0L;
_mini_b2 = 1L;
if ((_mini_b1&&_mini_b2))
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
_mini_b1 = 1L;
_mini_b2 = 1L;
if ((_mini_b1&&_mini_b2))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_counter = 0L;
_mini_printgroup(2L);
_mini_b1 = 1L;
_mini_b2 = 1L;
if ((_mini_b1||_mini_b2))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_b1 = 1L;
_mini_b2 = 0L;
if ((_mini_b1||_mini_b2))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_b1 = 0L;
_mini_b2 = 1L;
if ((_mini_b1||_mini_b2))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_b1 = 0L;
_mini_b2 = 0L;
if ((_mini_b1||_mini_b2))
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
_mini_printgroup(3L);
if ((42L>1L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if ((42L>=1L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if ((42L<1L))
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
if ((42L<=1L))
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
if ((42L==1L))
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
if ((42L!=1L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if (1L)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if (!1L)
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
if (0L)
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
if (!0L)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if (!0L)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_printgroup(4L);
if ((((2L+3L))==5L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", ((2L+3L)));
}
if ((((2L*3L))==6L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", ((2L*3L)));
}
if ((((3L-2L))==1L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", ((3L-2L)));
}
if ((((6L/3L))==2L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", ((6L/3L)));
}
if ((-6L<0L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_printgroup(5L);
_mini_i1 = 42L;
if ((_mini_i1==42L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_i1 = 3L;
_mini_i2 = 2L;
_mini_i3 = (_mini_i1+_mini_i2);
if ((_mini_i3==5L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_b1 = 1L;
if (_mini_b1)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if (!_mini_b1)
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
_mini_b1 = 0L;
if (_mini_b1)
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
if (!_mini_b1)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if (_mini_b1)
{
printf("%ld\n", 0L);
}
else
{
printf("%ld\n", 1L);
}
_mini_printgroup(6L);
_mini_i1 = 0L;
while ((_mini_i1<5L))
{
if ((_mini_i1>=5L))
{
printf("%ld\n", 0L);
}
_mini_i1 = (_mini_i1+5L);
}
if ((_mini_i1==5L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_i1);
}
_mini_printgroup(7L);
_mini_s1 = malloc(sizeof(struct _mini_thing));
_mini_s1->_mini_i = 42L;
_mini_s1->_mini_b = 1L;
if ((_mini_s1->_mini_i==42L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_s1->_mini_i);
}
if (_mini_s1->_mini_b)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_s1->_mini_s = malloc(sizeof(struct _mini_thing));
_mini_s1->_mini_s->_mini_i = 13L;
_mini_s1->_mini_s->_mini_b = 0L;
if ((_mini_s1->_mini_s->_mini_i==13L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_s1->_mini_s->_mini_i);
}
if (!_mini_s1->_mini_s->_mini_b)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if ((_mini_s1==_mini_s1))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
if ((_mini_s1!=_mini_s1->_mini_s))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
free(_mini_s1->_mini_s);
free(_mini_s1);
_mini_printgroup(8L);
_mini_gi1 = 7L;
if ((_mini_gi1==7L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_gi1);
}
_mini_gb1 = 1L;
if (_mini_gb1)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_gs1 = malloc(sizeof(struct _mini_thing));
_mini_gs1->_mini_i = 34L;
_mini_gs1->_mini_b = 0L;
if ((_mini_gs1->_mini_i==34L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_gs1->_mini_i);
}
if (!_mini_gs1->_mini_b)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_gs1->_mini_s = malloc(sizeof(struct _mini_thing));
_mini_gs1->_mini_s->_mini_i = 16L;
_mini_gs1->_mini_s->_mini_b = 1L;
if ((_mini_gs1->_mini_s->_mini_i==16L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_gs1->_mini_s->_mini_i);
}
if (_mini_gs1->_mini_s->_mini_b)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
free(_mini_gs1->_mini_s);
free(_mini_gs1);
_mini_printgroup(9L);
_mini_s1 = malloc(sizeof(struct _mini_thing));
_mini_s1->_mini_b = 1L;
_mini_takealltypes(3L, 1L, _mini_s1);
printf("%ld\n", 2L);
_mini_tonofargs(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L);
printf("%ld\n", 3L);
_mini_i1 = _mini_returnint(3L);
if ((_mini_i1==3L))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld ", 0L);
printf("%ld\n", _mini_i1);
}
_mini_b1 = _mini_returnbool(1L);
if (_mini_b1)
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_s1 = malloc(sizeof(struct _mini_thing));
_mini_s2 = _mini_returnstruct(_mini_s1);
if ((_mini_s1==_mini_s2))
{
printf("%ld\n", 1L);
}
else
{
printf("%ld\n", 0L);
}
_mini_printgroup(10L);
return 0L;
}
int main(void)
{
   return _mini_main();
}

